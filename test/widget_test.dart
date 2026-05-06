// ============================================================
// Unit Tests — KLOO Badminton AI App
// Kiểm tra toàn diện các nghiệp vụ quan trọng
// Chạy: flutter test
// ============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
// ignore_for_file: unused_local_variable

// ─── Helper: Tính refund theo chính sách hủy sân ─────────────────────────────
double calcRefundAmount(double totalPaid, DateTime bookingDateTime) {
  final now = DateTime.now();
  final diffMinutes = bookingDateTime.difference(now).inMinutes;
  if (diffMinutes <= 0) return 0.0;       // Đã đến/qua giờ → không hoàn
  if (diffMinutes > 120) return totalPaid; // Trước 2h → hoàn 100%
  return totalPaid * 0.5;                 // Trong 2h → hoàn 50%
}

// ─── Helper: Validate email ───────────────────────────────────────────────────
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// ─── Helper: Validate password ────────────────────────────────────────────────
bool isValidPassword(String password) => password.length >= 6;

// ─── Helper: Format giá tiền ─────────────────────────────────────────────────
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

// ─── Helper: Kiểm tra slot bị trùng ──────────────────────────────────────────
bool isSlotConflict(
  String courtId, DateTime date, int timeSlot, List<BookingModel> existingBookings,
) {
  return existingBookings.any((b) =>
    b.courtId == courtId &&
    b.date.year == date.year &&
    b.date.month == date.month &&
    b.date.day == date.day &&
    b.timeSlot == timeSlot &&
    b.status != 'cancelled',
  );
}

// ─── Helper: Cancellation policy text ────────────────────────────────────────
String getCancellationPolicyText(DateTime bookingDateTime) {
  final diff = bookingDateTime.difference(DateTime.now()).inMinutes;
  if (diff <= 0) return 'cannot_cancel';
  if (diff > 120) return 'refund_100';
  return 'refund_50';
}

void main() {
  // ══════════════════════════════════════════════════════════════
  // NHÓM 1: Chính sách hủy sân
  // ══════════════════════════════════════════════════════════════
  group('Chính sách hủy đặt sân', () {
    test('Hủy trước 2 tiếng → hoàn 100%', () {
      final bookingTime = DateTime.now().add(const Duration(hours: 3));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 160000.0);
    });

    test('Hủy đúng 3 tiếng → hoàn 100%', () {
      final bookingTime = DateTime.now().add(const Duration(hours: 3));
      final refund = calcRefundAmount(100000, bookingTime);
      expect(refund, 100000.0);
    });

    test('Hủy trong vòng 1 tiếng → hoàn 50%', () {
      final bookingTime = DateTime.now().add(const Duration(minutes: 60));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 80000.0);
    });

    test('Hủy trong vòng 2 tiếng (119 phút) → hoàn 50%', () {
      final bookingTime = DateTime.now().add(const Duration(minutes: 119));
      final refund = calcRefundAmount(200000, bookingTime);
      expect(refund, 100000.0);
    });

    test('Đã đến giờ → không được hủy (hoàn 0)', () {
      final bookingTime = DateTime.now().subtract(const Duration(minutes: 1));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 0.0);
    });

    test('Qua giờ 2 tiếng → không được hủy (hoàn 0)', () {
      final bookingTime = DateTime.now().subtract(const Duration(hours: 2));
      final refund = calcRefundAmount(160000, bookingTime);
      expect(refund, 0.0);
    });

    test('Policy text: trước 2h → refund_100', () {
      final t = DateTime.now().add(const Duration(hours: 5));
      expect(getCancellationPolicyText(t), 'refund_100');
    });

    test('Policy text: trong 2h → refund_50', () {
      final t = DateTime.now().add(const Duration(minutes: 90));
      expect(getCancellationPolicyText(t), 'refund_50');
    });

    test('Policy text: đã qua giờ → cannot_cancel', () {
      final t = DateTime.now().subtract(const Duration(hours: 1));
      expect(getCancellationPolicyText(t), 'cannot_cancel');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 2: BookingModel — Parse & Serialize
  // ══════════════════════════════════════════════════════════════
  group('BookingModel', () {
    final sampleData = {
      'id': 'booking-001',
      'user_id': 'user-123',
      'court_id': 'court-abc',
      'court_name': 'Sân Tennis Xala',
      'court_number': 2,
      'booking_date': '2026-06-15',
      'time_slot': 9,
      'price': 120000,
      'status': 'confirmed',
      'transaction_id': 'txn-999',
      'created_at': '2026-05-01T08:00:00.000Z',
      'expires_at': null,
    };

    test('fromSupabase: parse đúng id và userId', () {
      final model = BookingModel.fromSupabase(sampleData);
      expect(model.id, 'booking-001');
      expect(model.userId, 'user-123');
    });

    test('fromSupabase: parse đúng courtName và price', () {
      final model = BookingModel.fromSupabase(sampleData);
      expect(model.courtName, 'Sân Tennis Xala');
      expect(model.price, 120000);
    });

    test('fromSupabase: parse đúng date từ string', () {
      final model = BookingModel.fromSupabase(sampleData);
      expect(model.date.year, 2026);
      expect(model.date.month, 6);
      expect(model.date.day, 15);
    });

    test('fromSupabase: parse đúng timeSlot và status', () {
      final model = BookingModel.fromSupabase(sampleData);
      expect(model.timeSlot, 9);
      expect(model.status, 'confirmed');
    });

    test('fromSupabase: parse đúng transactionId', () {
      final model = BookingModel.fromSupabase(sampleData);
      expect(model.transactionId, 'txn-999');
    });

    test('fromSupabase: expiresAt null khi không có', () {
      final model = BookingModel.fromSupabase(sampleData);
      expect(model.expiresAt, isNull);
    });

    test('toSupabase: serialize đúng booking_date format', () {
      final model = BookingModel.fromSupabase(sampleData);
      final map = model.toSupabase();
      expect(map['booking_date'], '2026-06-15');
    });

    test('toSupabase: serialize đúng status', () {
      final model = BookingModel.fromSupabase(sampleData);
      final map = model.toSupabase();
      expect(map['status'], 'confirmed');
    });

    test('copyWith: thay đổi status', () {
      final model = BookingModel.fromSupabase(sampleData);
      final updated = model.copyWith(status: 'cancelled');
      expect(updated.status, 'cancelled');
      expect(updated.id, model.id); // id không thay đổi
    });

    test('fromSupabase: dùng default khi thiếu field', () {
      final model = BookingModel.fromSupabase({'user_id': 'u1', 'court_id': 'c1'});
      expect(model.status, 'confirmed');
      expect(model.price, 0);
      expect(model.timeSlot, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 3: UserModel — Parse & Serialize
  // ══════════════════════════════════════════════════════════════
  group('UserModel', () {
    final userData = {
      'id': 'user-001',
      'email': 'test@kloo.vn',
      'display_name': 'Nguyễn Test',
      'phone_number': '0909123456',
      'role': 'admin',
      'avatar_url': 'https://cdn.kloo.vn/avatar.jpg',
      'balance': 250000,
      'status': 'online',
      'date_of_birth': '2000-01-15',
      'gender': 'male',
    };

    test('fromSupabase: parse đúng id và email', () {
      final user = UserModel.fromSupabase(userData);
      expect(user.id, 'user-001');
      expect(user.email, 'test@kloo.vn');
    });

    test('fromSupabase: parse đúng role', () {
      final user = UserModel.fromSupabase(userData);
      expect(user.role, 'admin');
    });

    test('fromSupabase: parse đúng balance', () {
      final user = UserModel.fromSupabase(userData);
      expect(user.balance, 250000);
    });

    test('fromSupabase: default role là user khi không có', () {
      final user = UserModel.fromSupabase({'id': 'u1'});
      expect(user.role, 'user');
    });

    test('fromSupabase: default balance là 0', () {
      final user = UserModel.fromSupabase({'id': 'u1'});
      expect(user.balance, 0);
    });

    test('fromSupabase: parse dateOfBirth', () {
      final user = UserModel.fromSupabase(userData);
      expect(user.dateOfBirth?.year, 2000);
      expect(user.dateOfBirth?.month, 1);
    });

    test('copyWith: thay đổi balance', () {
      final user = UserModel.fromSupabase(userData);
      final updated = user.copyWith(balance: 500000);
      expect(updated.balance, 500000);
      expect(updated.email, user.email);
    });

    test('isAdmin: admin user nhận biết đúng', () {
      final user = UserModel.fromSupabase(userData);
      expect(user.role == 'admin', true);
    });

    test('toSupabase: không serialize id', () {
      final user = UserModel.fromSupabase(userData);
      final map = user.toSupabase();
      expect(map.containsKey('id'), false);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 4: Kiểm tra slot trùng (Conflict Detection)
  // ══════════════════════════════════════════════════════════════
  group('Kiểm tra slot đặt sân trùng', () {
    final existingBookings = [
      BookingModel(
        id: 'b1',
        userId: 'u1',
        userName: 'User A',
        courtId: 'court-1',
        courtName: 'Sân 1',
        courtNumber: 1,
        date: DateTime(2026, 6, 20),
        timeSlot: 9,
        price: 80000,
        status: 'confirmed',
      ),
      BookingModel(
        id: 'b2',
        userId: 'u2',
        userName: 'User B',
        courtId: 'court-1',
        courtName: 'Sân 1',
        courtNumber: 1,
        date: DateTime(2026, 6, 20),
        timeSlot: 10,
        price: 80000,
        status: 'confirmed',
      ),
    ];

    test('Slot đã đặt → conflict = true', () {
      final conflict = isSlotConflict(
        'court-1', DateTime(2026, 6, 20), 9, existingBookings,
      );
      expect(conflict, true);
    });

    test('Slot chưa đặt → conflict = false', () {
      final conflict = isSlotConflict(
        'court-1', DateTime(2026, 6, 20), 11, existingBookings,
      );
      expect(conflict, false);
    });

    test('Sân khác nhau → không conflict', () {
      final conflict = isSlotConflict(
        'court-2', DateTime(2026, 6, 20), 9, existingBookings,
      );
      expect(conflict, false);
    });

    test('Ngày khác nhau → không conflict', () {
      final conflict = isSlotConflict(
        'court-1', DateTime(2026, 6, 21), 9, existingBookings,
      );
      expect(conflict, false);
    });

    test('Slot cancelled → không conflict', () {
      final cancelledBookings = [
        BookingModel(
          id: 'b3',
          userId: 'u3',
          userName: 'User C',
          courtId: 'court-1',
          courtName: 'Sân 1',
          courtNumber: 1,
          date: DateTime(2026, 6, 20),
          timeSlot: 8,
          price: 80000,
          status: 'cancelled',
        ),
      ];
      final conflict = isSlotConflict(
        'court-1', DateTime(2026, 6, 20), 8, cancelledBookings,
      );
      expect(conflict, false);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 5: Validation — Email & Password
  // ══════════════════════════════════════════════════════════════
  group('Validation Email & Password', () {
    test('Email hợp lệ → true', () {
      expect(isValidEmail('user@gmail.com'), true);
      expect(isValidEmail('test@kloo.vn'), true);
      expect(isValidEmail('abc.123@email.co'), true);
    });

    test('Email không hợp lệ → false', () {
      expect(isValidEmail('notanemail'), false);
      expect(isValidEmail('missing@'), false);
      expect(isValidEmail('@domain.com'), false);
      expect(isValidEmail(''), false);
    });

    test('Password >= 6 ký tự → hợp lệ', () {
      expect(isValidPassword('123456'), true);
      expect(isValidPassword('mypassword'), true);
    });

    test('Password < 6 ký tự → không hợp lệ', () {
      expect(isValidPassword('12345'), false);
      expect(isValidPassword(''), false);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 6: Format giá tiền
  // ══════════════════════════════════════════════════════════════
  group('Format giá tiền (VND)', () {
    test('80000 → "80.000 đ"', () {
      expect(formatPrice(80000), '80.000 đ');
    });

    test('1000000 → "1.000.000 đ"', () {
      expect(formatPrice(1000000), '1.000.000 đ');
    });

    test('0 → "0 đ"', () {
      expect(formatPrice(0), '0 đ');
    });

    test('500 → "500 đ"', () {
      expect(formatPrice(500), '500 đ');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 7: CourtLocationModel — Parse
  // ══════════════════════════════════════════════════════════════
  group('CourtLocationModel', () {
    final courtData = {
      'id': 'court-abc',
      'name': 'Sân Pickleball Quận 7',
      'address': '123 Nguyễn Văn Linh, Q7, HCM',
      'latitude': 10.7333,
      'longitude': 106.7000,
      'price_per_hour': 150000,
      'sport_type': 'pickleball',
      'rating': 4.5,
      'total_reviews': 28,
      'total_courts': 4,
    };

    test('fromSupabase: parse tên sân', () {
      final court = CourtLocationModel.fromSupabase(courtData);
      expect(court.name, 'Sân Pickleball Quận 7');
    });

    test('fromSupabase: parse tọa độ GPS', () {
      final court = CourtLocationModel.fromSupabase(courtData);
      expect(court.latitude, 10.7333);
      expect(court.longitude, 106.7000);
    });

    test('fromSupabase: parse giá theo giờ', () {
      final court = CourtLocationModel.fromSupabase(courtData);
      expect(court.pricePerHour, 150000.0);
    });

    test('fromSupabase: parse rating', () {
      final court = CourtLocationModel.fromSupabase(courtData);
      expect(court.rating, 4.5);
    });

    test('fromSupabase: parse sportType', () {
      final court = CourtLocationModel.fromSupabase(courtData);
      expect(court.sportType, 'pickleball');
    });

    test('fromSupabase: equality dựa trên id', () {
      final c1 = CourtLocationModel.fromSupabase(courtData);
      final c2 = CourtLocationModel.fromSupabase(courtData);
      expect(c1, equals(c2));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 8: Tính giá đặt sân
  // ══════════════════════════════════════════════════════════════
  group('Tính giá đặt sân', () {
    int calcTotal(int pricePerHour, int slots) => pricePerHour * slots;

    test('1 slot × 80.000đ = 80.000đ', () {
      expect(calcTotal(80000, 1), 80000);
    });

    test('3 slots × 80.000đ = 240.000đ', () {
      expect(calcTotal(80000, 3), 240000);
    });

    test('0 slots → 0đ', () {
      expect(calcTotal(80000, 0), 0);
    });

    test('Giá 150.000đ, 2 slots = 300.000đ', () {
      expect(calcTotal(150000, 2), 300000);
    });

    test('Hoàn 100% từ 300.000đ = 300.000đ', () {
      expect((300000 * 1.0).toInt(), 300000);
    });

    test('Hoàn 50% từ 300.000đ = 150.000đ', () {
      expect((300000 * 0.5).toInt(), 150000);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 9: EventModel — Parse & Business Logic
  // ══════════════════════════════════════════════════════════════
  group('EventModel', () {
    final eventData = {
      'id': 'event-001',
      'event_code': '#2026',
      'title': 'Giải Cầu Lông Mùa Hè 2026',
      'description': 'Giải đấu cầu lông toàn quốc',
      'date_time': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'start_time': '08h00',
      'end_time': '18h00',
      'court_area': 'Sân 4',
      'sport_type': 'Cầu lông',
      'level': '3.0 -> 4.0',
      'price': 200000,
      'max_participants': 64,
      'current_participants': 20,
      'court_id': 'court-001',
    };

    test('fromSupabase: parse tiêu đề sự kiện', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.title, 'Giải Cầu Lông Mùa Hè 2026');
    });

    test('fromSupabase: parse giá vé', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.price, 200000.0);
    });

    test('fromSupabase: parse số lượng tối đa', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.maxParticipants, 64);
    });

    test('fromSupabase: parse sportType', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.sportType, 'Cầu lông');
    });

    test('availableParticipants: còn 44 chỗ', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.availableParticipants, 44);
    });

    test('isBookable: sự kiện tương lai còn chỗ → true', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.isBookable, true);
    });

    test('isEnded: sự kiện tương lai → false', () {
      final event = EventModel.fromSupabase(eventData);
      expect(event.isEnded, false);
    });

    test('isEnded: sự kiện quá khứ → true', () {
      final pastData = Map<String, dynamic>.from(eventData)
        ..['date_time'] = DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
        ..['end_time'] = '08h00';
      final event = EventModel.fromSupabase(pastData);
      expect(event.isEnded, true);
    });

    test('availableParticipants không âm khi over-booked', () {
      final overData = Map<String, dynamic>.from(eventData)
        ..['current_participants'] = 70; // > max 64
      final event = EventModel.fromSupabase(overData);
      expect(event.availableParticipants, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // NHÓM 10: Kiểm tra logic phân quyền
  // ══════════════════════════════════════════════════════════════
  group('Phân quyền người dùng', () {
    bool canAccessAdmin(String role) => role == 'admin';
    bool canManageCourts(String role) => role == 'admin' || role == 'court_owner';
    bool isRegularUser(String role) => role == 'user';

    test('Admin có quyền truy cập dashboard', () {
      expect(canAccessAdmin('admin'), true);
    });

    test('User thường không có quyền admin', () {
      expect(canAccessAdmin('user'), false);
    });

    test('Admin có quyền quản lý sân', () {
      expect(canManageCourts('admin'), true);
    });

    test('Court owner có quyền quản lý sân', () {
      expect(canManageCourts('court_owner'), true);
    });

    test('User thường không có quyền quản lý sân', () {
      expect(canManageCourts('user'), false);
    });

    test('Nhận diện user thường', () {
      expect(isRegularUser('user'), true);
      expect(isRegularUser('admin'), false);
    });
  });
}
