import 'dart:convert';
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
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

  // Stream danh sách tin nhắn
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

  // RAG: Lấy ngữ cảnh hệ thống (Đã tối ưu Token)
  Future<String> getSystemContext(String userId) async {
    try {
      // 1. Lấy danh sách sân (Giới hạn tối đa 5 sân để tiết kiệm Token)
      final courtsData = await _client.from('courts').select().limit(5);
      final courts = courtsData
          .map((e) => CourtLocationModel.fromSupabase(e))
          .toList();

      // Dùng định dạng ngắn gọn (CSV/Pipe) thay vì câu văn dài
      String courtsContext = "SÂN:\n";
      if (courts.isEmpty) {
        courtsContext += "Trống\n";
      } else {
        for (var court in courts) {
          // Chỉ gửi Tên | Giá | Số sân
          courtsContext +=
              "${court.name}|${court.pricePerHour}đ|${court.totalCourts}sân\n";
        }
      }

      // 2. Lấy lịch đặt của user (Chỉ lấy 3 lịch mới nhất từ hôm nay)
      final nowStr = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      final bookingsData = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .gte('booking_date', nowStr)
          .order('booking_date', ascending: true)
          .limit(3);

      final bookings = bookingsData
          .map((e) => BookingModel.fromSupabase(e))
          .toList();

      String bookingContext = "\nLỊCH:\n";

      if (bookings.isEmpty) {
        bookingContext += "Trống\n";
      } else {
        for (var b in bookings) {
          // Format ngắn: Ngày/Tháng | Giờ | Tên Sân | Trạng thái
          bookingContext +=
              "${b.date.day}/${b.date.month}|${b.timeSlot}h|${b.courtName}|${b.status}\n";
        }
      }

      return "$courtsContext$bookingContext";
    } catch (e) {
      print("Lỗi getSystemContext: $e");
      return "";
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
      promptToSend = "CTX:\n$context\nQ:\n$text\n(TL ngắn gọn nhất có thể)";
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
      answer = "Lỗi kết nối tới server. Vui lòng thử lại sau.";
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
