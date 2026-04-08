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
    dynamic firestore,
  }) : _client = client ?? Supabase.instance.client;

  static const String _backendUrl = 'https://badminton-ai-fgsz.onrender.com';

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

  // ─── Helper: HTTP Headers ────────────────────────────────────────────────
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
      };

  // ─── Helper: Gọi backend với retry 1 lần khi SocketException ────────────
  // Render free tier có thể bị cold start (~30-60s) gây Connection reset.
  // Tự động retry 1 lần sau delay để cho server warm up.
  Future<http.Response> _postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
    Duration retryDelay = const Duration(seconds: 4),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 90));
      } on SocketException catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          print('ChatRepository: SocketException, retry $attempt/$maxRetries sau ${retryDelay.inSeconds}s — $e');
          await Future.delayed(retryDelay);
          continue;
        }
        rethrow;
      }
    }
  }

  // ─── Gửi tin nhắn → Backend RAG Pipeline ────────────────────────────────
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
    String answer = 'Xin lỗi, tôi chưa hiểu ý bạn.';
    final askUrl = Uri.parse('$_backendUrl/ask');

    try {
      http.Response response;

      if (imagePath != null) {
        // ── Gửi ảnh kèm user_id qua multipart ───────────────────────────
        // Có retry tự động khi Render cold start gây Connection reset
        int attempt = 0;
        const maxRetries = 1;
        http.StreamedResponse? streamedResponse;

        while (true) {
          try {
            final request = http.MultipartRequest('POST', askUrl);
            request.headers['Connection'] = 'keep-alive';
            request.fields['prompt']  = text.isNotEmpty ? text : 'Phân tích ảnh này';
            request.fields['user_id'] = userId;
            request.files.add(await http.MultipartFile.fromPath('image', imagePath));
            streamedResponse = await request.send().timeout(const Duration(seconds: 120));
            break; // Thành công
          } on SocketException catch (e) {
            if (attempt < maxRetries) {
              attempt++;
              print('ChatRepository [image]: SocketException, retry $attempt/$maxRetries — $e');
              await Future.delayed(const Duration(seconds: 5));
              continue;
            }
            rethrow;
          }
        }

        response = await http.Response.fromStream(streamedResponse!)
            .timeout(const Duration(seconds: 30));

      } else if (audioPath != null) {
        // ── Gửi audio ────────────────────────────────────────────────────
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_backendUrl/ask/audio'),
        );
        request.headers['Connection'] = 'keep-alive';
        request.fields['prompt']  = text;
        request.fields['user_id'] = userId;
        request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
        final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
        response = await http.Response.fromStream(streamedResponse)
            .timeout(const Duration(seconds: 30));

      } else {
        // ── Gửi text + user_id → Full RAG pipeline với auto-retry ───────
        response = await _postWithRetry(
          askUrl,
          headers: _jsonHeaders,
          body: jsonEncode({'prompt': text, 'user_id': userId}),
        );
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        answer = responseBody['answer'] ?? 'Xin lỗi, tôi chưa hiểu ý bạn.';
      } else {
        try {
          final responseBody = jsonDecode(response.body);
          answer = responseBody['error'] ?? 'Máy chủ phản hồi lỗi. Vui lòng thử lại!';
        } catch (_) {
          answer = 'Máy chủ phản hồi lỗi (${response.statusCode}). Vui lòng thử lại!';
        }
      }

    } on TimeoutException {
      answer = 'Trợ lý AI đang khởi động (có thể mất 30-60 giây lần đầu). Vui lòng gửi lại tin nhắn nhé!';
      print('ChatRepository: TimeoutException');
    } on SocketException catch (e) {
      answer = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và thử lại!';
      print('ChatRepository: SocketException sau retry: $e');
    } catch (e) {
      answer = 'Đã xảy ra lỗi, vui lòng thử lại sau!';
      print('ChatRepository: Unexpected error: $e');
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

  // ─── Lấy lời khuyên thể thao từ backend ─────────────────────────────────
  Future<Map<String, dynamic>?> getSportsTips(String sport) async {
    try {
      final response = await _postWithRetry(
        Uri.parse('$_backendUrl/sports-tips'),
        headers: _jsonHeaders,
        body: jsonEncode({'sport': sport}),
        retryDelay: const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ChatRepository getSportsTips error: $e');
    }
    return null;
  }
}
