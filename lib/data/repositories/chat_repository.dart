import 'dart:convert';
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
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

  // RAG: Lấy ngữ cảnh hệ thống (Đã tối ưu Token triệt để - Hybrid Approach)
  Future<String> getSystemContext(String userId) async {
    try {
      // 1. Chỉ lấy tối đa 2 lịch trình SẮP TỚI của user để trả lời nhắc hẹn (Giảm tải Token).
      final nowStr = DateTime.now().toIso8601String();
      final bookingsData = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .gte('booking_date', nowStr)
          .order('booking_date', ascending: true)
          .limit(2);

      String context = "CTX_USER:\n";
      if (bookingsData.isEmpty) {
        context += "Lịch tới: Trống\n";
      } else {
        context += "Lịch tới: ";
        for (var bData in bookingsData) {
          final b = BookingModel.fromSupabase(bData);
          context += "${b.date.day}/${b.date.month} lúc ${b.timeSlot}h tại ${b.courtName}. ";
        }
        context += "\n";
      }

      // 2. Định nghĩa Quy tắc (System Prompts) thay vì nhồi mảng Dữ liệu vào
      context += """RULES:
- Bạn là trợ lý ảo App đặt sân thể thao (Bóng đá, Cầu lông, Tennis, Pickleball). Giải đáp siêu ngắn gọn, thân thiện bằng tiếng Việt.
- NẾU người dùng hỏi tìm sân, đặt sân hoặc gợi ý sân, HÃY TRẢ LỜI NGẮN và BẮT BUỘC chèn đoạn mã [ACTION_SEARCH:mon_the_thao] vào ngay cuối câu.
- Từ khoá môn thể thao: 'football', 'badminton', 'tennis', 'pickleball'.
- Ví dụ User: "Tôi muốn đá bóng" -> Bạn đáp: "Vâng, mời bạn tham khảo các sân Bóng Đá tốt nhất hệ thống: [ACTION_SEARCH:football]"
""";

      return context;
    } catch (e) {
      print("Lỗi getSystemContext: $e");
      return "RULES:\nTrả lời ngắn.\nBắt buộc thêm mã [ACTION_SEARCH:mon_the_thao] cuối câu nếu user muốn tìm/đặt sân.";
    }
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

    // 2. Chuẩn bị Context + Prompt
    String context = await getSystemContext(userId);
    String promptToSend = text;
    if (text.isNotEmpty) {
      // Rút gọn Prompt Template để tiết kiệm token
      promptToSend = "$context\nUSER_ASK: $text";
    }

    // 3. Gọi API AI
    String answer = "Xin lỗi, tôi chưa hiểu ý bạn.";
    const String backendUrl = 'https://badminton-ai-fgsz.onrender.com/ask';

    try {
      http.Response response;

      if (imagePath != null) {
        var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
        request.fields['prompt'] = text.isNotEmpty ? text : 'Phân tích ảnh này';
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
          request.fields['prompt'] = promptToSend;
        }
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'prompt': promptToSend}),
            )
            .timeout(const Duration(seconds: 90));
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        answer = responseBody['answer'] ?? "Xin lỗi, tôi chưa hiểu ý bạn.";
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
    );
    await sendMessage(userId, aiMessage);
  }
}
