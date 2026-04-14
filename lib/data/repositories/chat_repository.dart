import 'dart:convert';
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

  // Gửi tin nhắn User + Context -> AI -> Lưu tin nhắn AI
  Future<void> sendMessageWithRAG(
    String userId,
    String text, {
    String? imagePath,
    String? audioPath,
  }) async {
    // 1. Lưu tin nhắn User
    final userMessage = ChatMessageModel(
      id: '',
      text: text.isEmpty ? (imagePath != null ? '[Ảnh]' : '[Audio]') : text,
      isUser: true,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      audioPath: audioPath,
    );
    await sendMessage(userId, userMessage);

    // 2. Gọi API AI (RAG được xử lý ở backend)
    String answer = "Xin lỗi, tôi chưa hiểu ý bạn.";
    Map<String, dynamic>? aiMetadata;
    String aiType = 'text';
    const String backendUrl = 'https://badminton-ai-fgsz.onrender.com/ask';

    try {
      http.Response response;

      if (imagePath != null) {
        var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
        request.fields['prompt'] = text.isNotEmpty
            ? text
            : 'Phân tích ảnh này và cho biết đây là sân gì, tình trạng sân, hoặc đồ dùng thể thao gì, cách sử dụng';
        request.fields['user_id'] = userId;
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else if (audioPath != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$backendUrl/audio'),
        );
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioPath),
        );
        if (text.isNotEmpty) {
          request.fields['prompt'] = text;
        }
        request.fields['user_id'] = userId;
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'prompt': text, 'user_id': userId}),
            )
            .timeout(const Duration(seconds: 90));
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        answer = responseBody['answer'] ?? "Xin lỗi, tôi chưa hiểu ý bạn.";
        if (responseBody is Map<String, dynamic>) {
          aiMetadata = {
            if (responseBody['action'] != null) 'action': responseBody['action'],
            if (responseBody['citations'] != null) 'citations': responseBody['citations'],
            if (responseBody['used_sources'] != null) 'used_sources': responseBody['used_sources'],
          };
          aiType = (responseBody['type'] as String?) ?? 'text';
        }

        // --- Bắt trường hợp Gemini trả nguyên chuỗi JSON về ---
        try {
          String cleanAnswer = answer.trim();
          if (cleanAnswer.startsWith('```json')) {
            cleanAnswer = cleanAnswer.replaceAll('```json', '').replaceAll('```', '').trim();
          }
          if (cleanAnswer.startsWith('{') && cleanAnswer.endsWith('}')) {
            final parsedAnswer = jsonDecode(cleanAnswer);
            if (parsedAnswer is Map) {
              answer = parsedAnswer['answer'] ?? answer;
              if (parsedAnswer['action'] != null) {
                aiMetadata ??= {};
                aiMetadata['action'] = parsedAnswer['action'];
              }
            }
          }
        } catch (e) {
          // Xử lý lỗi parse JSON ngầm, không làm gián đoạn luồng
        }
        
      } else {
        try {
          final responseBody = jsonDecode(response.body);
          answer =
              "Lỗi: " +
              (responseBody['error'] ?? 'Lỗi server (${response.statusCode})');
        } catch (e) {
          answer = 'Lỗi server (${response.statusCode})';
        }
      }
    } catch (e) {
      answer = "Lỗi hệ thống/mạng: $e";
      print("Lỗi sendMessageWithRAG: $e");
    }

    // 4. Lưu tin nhắn AI
    final aiMessage = ChatMessageModel(
      id: '',
      text: answer,
      isUser: false,
      timestamp: DateTime.now(),
      type: aiType,
      metadata: aiMetadata,
    );
    await sendMessage(userId, aiMessage);
  }
}
