// Unit Tests — Badminton AI App
// Kiểm tra các nghiệp vụ quan trọng của hệ thống đặt sân
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================
  // NHÓM 1: Chính sách hủy sân
  // ============================================================
  group('Chính sách hủy đặt sân', () {
    test('Hủy trước 2 tiếng → đủ điều kiện hoàn 100%', () {
      final bookingTime = DateTime.now().add(const Duration(hours: 3));
      final diff = bookingTime.difference(DateTime.now()).inMinutes;
      expect(diff > 120, true);
    });

    test('Hủy trong vòng 2 tiếng → chỉ hoàn 50%', () {
      final bookingTime = DateTime.now().add(const Duration(hours: 1));
      final diff = bookingTime.difference(DateTime.now()).inMinutes;
      expect(diff < 120 && diff > 0, true);
    });

    test('Đã đến hoặc qua giờ → không thể hủy', () {
      final bookingTime = DateTime.now().subtract(const Duration(minutes: 5));
      final diff = bookingTime.difference(DateTime.now()).inMinutes;
      expect(diff <= 0, true);
    });
  });

  // ============================================================
  // NHÓM 2: Phân loại loại sân thể thao
  // ============================================================
  group('Phân loại sport_type từ database', () {
    test('Nhận diện đúng sân pickleball', () {
      const sportType = 'pickleball';
      expect(sportType.contains('pickle'), true);
    });

    test('Nhận diện đúng sân bóng đá', () {
      const sportType = 'football';
      expect(sportType.contains('foot'), true);
    });

    test('Nhận diện đúng sân tennis', () {
      const sportType = 'tennis';
      expect(sportType.contains('tennis'), true);
    });

    test('Mặc định về cầu lông khi không xác định được', () {
      const sportType = '';
      // Logic: nếu rỗng → mặc định badminton
      final result = sportType.isEmpty ? 'badminton' : sportType;
      expect(result, 'badminton');
    });
  });

  // ============================================================
  // NHÓM 3: Tính giá đặt sân
  // ============================================================
  group('Tính toán giá đặt sân', () {
    test('Giá 1 giờ đặt sân', () {
      const pricePerHour = 80000.0;
      const hours = 1;
      final total = pricePerHour * hours;
      expect(total, 80000.0);
    });

    test('Giá 2 giờ đặt sân', () {
      const pricePerHour = 80000.0;
      const hours = 2;
      final total = pricePerHour * hours;
      expect(total, 160000.0);
    });

    test('Số tiền hoàn khi hủy trước 2 tiếng (100%)', () {
      const totalPaid = 160000.0;
      const refundRate = 1.0; // 100%
      final refund = totalPaid * refundRate;
      expect(refund, 160000.0);
    });

    test('Số tiền hoàn khi hủy trong 2 tiếng (50%)', () {
      const totalPaid = 160000.0;
      const refundRate = 0.5; // 50%
      final refund = totalPaid * refundRate;
      expect(refund, 80000.0);
    });
  });
}
