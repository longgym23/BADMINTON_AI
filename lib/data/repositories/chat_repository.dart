import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository({
    SupabaseClient? client,
    required SupabaseRepository firestoreRepository,
    // giữ tham số cũ nếu cần để tránh lỗi compile tạm thời, nhưng ở đây ta bỏ luôn vì sẽ sửa main.dart
    dynamic firestore,
  }) : _client = client ?? Supabase.instance.client;

  // Fetch lịch sử chat 1 lần (Cho Chatbot AI)
  Future<List<ChatMessageModel>> fetchChatHistory(String userId) async {
    final data = await _client
        .from('chat_messages')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => ChatMessageModel.fromSupabase(e)).toList();
  }

  // Stream danh sách tin nhắn (Cho nhóm/1-1 nếu cần Realtime)
  Stream<List<ChatMessageModel>> getMessages(String userId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((e) => ChatMessageModel.fromSupabase(e)).toList(),
        );
  }

  // Gửi tin nhắn mới
  Future<void> sendMessage(String userId, ChatMessageModel message) async {
    // Convert to Supabase map
    var data = message.toSupabase();
    data['user_id'] = userId;

    await _client.from('chat_messages').insert(data);
  }

  // Xóa tin nhắn
  Future<void> deleteMessage(String userId, String messageId) async {
    await _client.from('chat_messages').delete().eq('id', messageId);
  }

  // Xóa toàn bộ lịch sử chat
  Future<void> clearChatHistory(String userId) async {
    await _client.from('chat_messages').delete().eq('user_id', userId);
  }

  // ─── RAG: Toàn bộ logic Retrieve + Augment + Generate đã được chuyển sang Backend ───
  // Backend (server.js) quản lý:
  //   1. Embed user query  →  vector 768 chiều (text-embedding-004)
  //   2. Search Supabase pgvector (match_documents RPC)
  //   3. Lấy lịch cá nhân của user từ Supabase
  //   4. Build augmented prompt
  //   5. Gọi Gemini sinh câu trả lời
  // Flutter chỉ cần gửi: { prompt, user_id }


  // Gửi tin nhắn → Backend RAG Pipeline → Lưu câu trả lời AI
  // Backend nhận user_id để tự lấy lịch cá nhân và thực hiện vector search
  Future<void> sendMessageWithRAG(
    String userId,
    String text, {
    String? imagePath,
    String? audioPath,
  }) async {
    // 1. Lưu tin nhắn của User vào Supabase
    final userMessage = ChatMessageModel(
      id: '',
      text: text.isEmpty ? (imagePath != null ? '[Ảnh]' : '[Audio]') : text,
      isUser: true,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      audioPath: audioPath,
    );
    await sendMessage(userId, userMessage);

    // 2. Gọi Backend RAG API
    //    Backend tự thực hiện: Embed → Vector Search → Augment → Gemini
    String answer = 'Xin lỗi, tôi chưa hiểu ý bạn.';
    const String backendUrl = 'https://badminton-ai-fgsz.onrender.com/ask';

    try {
      http.Response response;

      if (imagePath != null) {
        // Gửi ảnh kèm user_id qua multipart — có timeout 120s
        final request = http.MultipartRequest('POST', Uri.parse(backendUrl));
        request.fields['prompt']  = text.isNotEmpty ? text : 'Phân tích ảnh này';
        request.fields['user_id'] = userId;
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
        // Thêm timeout để tránh treo vĩnh viễn khi Render cold start
        final streamedResponse = await request.send()
            .timeout(const Duration(seconds: 120));
        response = await http.Response.fromStream(streamedResponse)
            .timeout(const Duration(seconds: 30));

      } else if (audioPath != null) {
        // Gửi audio kèm user_id qua multipart
        final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/audio'));
        request.fields['prompt']  = text;
        request.fields['user_id'] = userId;
        request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
        final streamedResponse = await request.send()
            .timeout(const Duration(seconds: 60));
        response = await http.Response.fromStream(streamedResponse)
            .timeout(const Duration(seconds: 30));

      } else {
        // Gửi text + user_id → Backend thực hiện full RAG pipeline
        response = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'prompt':  text,
                'user_id': userId,
              }),
            )
            .timeout(const Duration(seconds: 90));
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        answer = responseBody['answer'] ?? 'Xin lỗi, tôi chưa hiểu ý bạn.';
      } else {
        try {
          final responseBody = jsonDecode(response.body);
          answer = responseBody['error'] ?? 'Máy chủ phản hồi lỗi. Vui lòng thử lại!';
        } catch (_) {
          answer = 'Máy chủ phản hồi lỗi. Vui lòng thử lại!';
        }
      }
    } on TimeoutException {
      // Server Render free tier đang khởi động hoặc xử lý lâu
      answer = 'Trợ lý AI đang khởi động, vui lòng gửi lại sau vài giây nhé!';
      print('sendMessageWithRAG: Timeout');
    } on SocketException catch (e) {
      // Mất kết nối hoặc server reset connection (Render cold start)
      answer = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và thử lại!';
      print('sendMessageWithRAG SocketException: $e');
    } catch (e) {
      answer = 'Đã xảy ra lỗi, vui lòng thử lại sau!';
      print('sendMessageWithRAG error: $e');
    }

    // 3. Lưu câu trả lời của AI vào Supabase
    final aiMessage = ChatMessageModel(
      id: '',
      text: answer,
      isUser: false,
      timestamp: DateTime.now(),
    );
    await sendMessage(userId, aiMessage);
  }
}
