import 'package:flutter_test/flutter_test.dart';

// Helper: Tính refund theo chính sách hủy sân
double calcRefundAmount(double totalPaid, DateTime bookingDateTime) {
  final now = DateTime.now();
  final diffMinutes = bookingDateTime.difference(now).inMinutes;
  if (diffMinutes <= 0) return 0.0;       // Đã đến/qua giờ -> không hoàn
  if (diffMinutes > 120) return totalPaid; // Trước 2h -> hoàn 100%
  return totalPaid * 0.5;                 // Trong 2h -> hoàn 50%
}

// Helper: Validate email
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// Helper: Validate password
bool isValidPassword(String password) => password.length >= 6;

// Helper: Format giá tiền
String formatPrice(int price) {
  if (price <= 0) return '0 đ';
  final parts = price.toString().split('').reversed.toList();
  final result = <String>[];
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && i % 3 == 0) result.add('.');
    result.add(parts[i]);
  }
  return '${result.reversed.join('')} đ';
}

void main() {
  group('Chính sách hủy đặt sân', () {
    test('Hủy trước 2 tiếng -> hoàn 100%', () {
      final bookingTime = DateTime.now().add(const Duration(hours: 3));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 160000.0);
    });

    test('Hủy trong vòng 1 tiếng -> hoàn 50%', () {
      final bookingTime = DateTime.now().add(const Duration(minutes: 60));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 80000.0);
    });

    test('Đã đến giờ -> không được hủy (hoàn 0)', () {
      final bookingTime = DateTime.now().subtract(const Duration(minutes: 1));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 0.0);
    });
  });

  group('Validation Email & Password', () {
    test('Email hợp lệ -> true', () {
      expect(isValidEmail('user@gmail.com'), true);
      expect(isValidEmail('test@kloo.vn'), true);
    });

    test('Email không hợp lệ -> false', () {
      expect(isValidEmail('notanemail'), false);
      expect(isValidEmail(''), false);
    });

    test('Password >= 6 ký tự -> hợp lệ', () {
      expect(isValidPassword('123456'), true);
    });
  });

  group('Format giá tiền (VND)', () {
    test('80000 -> "80.000 đ"', () {
      expect(formatPrice(80000), '80.000 đ');
    });

    test('1000000 -> "1.000.000 đ"', () {
      expect(formatPrice(1000000), '1.000.000 đ');
    });
  });
}
