import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:badminton_ai/config/api_keys.dart';

/// Service gọi Groq Whisper API để chuyển giọng nói thành text.
/// Dùng làm fallback khi thiết bị không hỗ trợ native STT tiếng Việt
/// (ví dụ: ROM Trung Quốc).
class GroqSttService {
  static const String _apiKey = ApiKeys.groqApiKey;
  static const String _endpoint =
      'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _model = 'whisper-large-v3-turbo';

  /// Transcribe file audio thành text tiếng Việt.
  /// [audioFilePath] là đường dẫn tuyệt đối tới file WAV/M4A đã ghi.
  /// Trả về chuỗi text đã nhận dạng, hoặc null nếu lỗi.
  static Future<String?> transcribe(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) return null;

      final fileSize = await file.length();
      if (fileSize < 100) return null;

      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      request.headers['Authorization'] = 'Bearer $_apiKey';

      request.files.add(
        await http.MultipartFile.fromPath('file', audioFilePath),
      );

      request.fields['model'] = _model;
      request.fields['language'] = 'vi';
      request.fields['response_format'] = 'json';
      request.fields['temperature'] = '0.0';

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final text = body['text']?.toString().trim() ?? '';
        return text.isNotEmpty ? text : null;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
