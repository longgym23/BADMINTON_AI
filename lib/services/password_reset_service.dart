import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordResetService {
  static const String _baseUrl = 'https://badminton-ai-fgsz.onrender.com';

  /// Gửi OTP đến email
  /// Trả về: null nếu thành công, chuỗi lỗi nếu thất bại
  static Future<String?> sendOtp(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return data['error'] ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
      }
    } on Exception catch (e) {
      return 'Không thể kết nối server: $e';
    }
  }

  /// Xác thực OTP
  /// Trả về: resetToken nếu thành công, null nếu thất bại (kèm error message)
  static Future<({String? resetToken, String? error})> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'otp': otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (resetToken: data['resetToken'] as String?, error: null as String?);
      } else {
        return (resetToken: null as String?, error: (data['error'] as String?) ?? 'OTP không hợp lệ.');
      }
    } on Exception catch (e) {
      return (resetToken: null as String?, error: 'Không thể kết nối server: $e');
    }
  }

  /// Đặt lại mật khẩu mới
  /// Trả về: null nếu thành công, chuỗi lỗi nếu thất bại
  static Future<String?> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'resetToken': resetToken,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return data['error'] ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
      }
    } on Exception catch (e) {
      return 'Không thể kết nối server: $e';
    }
  }
}
