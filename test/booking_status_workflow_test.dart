import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

bool occupiesSlot(BookingModel booking, DateTime now) {
  if (booking.status == 'PAID') return true;
  if (booking.status != 'PENDING_PAYMENT') return false;
  final expiresAt = booking.expiresAt;
  return expiresAt != null && expiresAt.isAfter(now);
}

bool hasSlotConflict({
  required String courtId,
  required DateTime date,
  required int courtNumber,
  required int timeSlot,
  required List<BookingModel> existingBookings,
  required DateTime now,
}) {
  return existingBookings.any((booking) {
    return booking.courtId == courtId &&
        booking.date.year == date.year &&
        booking.date.month == date.month &&
        booking.date.day == date.day &&
        booking.courtNumber == courtNumber &&
        booking.timeSlot == timeSlot &&
        occupiesSlot(booking, now);
  });
}

BookingModel booking({
  required String id,
  required String status,
  DateTime? expiresAt,
  String transactionId = 'TXN_GROUP_001',
}) {
  return BookingModel(
    id: id,
    userId: 'user-001',
    userName: 'Test User',
    courtId: 'court-001',
    courtName: 'KLOO Badminton',
    courtNumber: 2,
    date: DateTime(2026, 5, 20),
    timeSlot: 19,
    price: 120000,
    status: status,
    transactionId: transactionId,
    expiresAt: expiresAt,
  );
}

void main() {
  group('Booking status workflow', () {
    final now = DateTime(2026, 5, 13, 10);

    test('PENDING_PAYMENT occupies slot before hold expires', () {
      final pending = booking(
        id: 'booking-pending',
        status: 'PENDING_PAYMENT',
        expiresAt: now.add(const Duration(minutes: 5)),
      );

      expect(occupiesSlot(pending, now), isTrue);
      expect(
        hasSlotConflict(
          courtId: 'court-001',
          date: DateTime(2026, 5, 20),
          courtNumber: 2,
          timeSlot: 19,
          existingBookings: [pending],
          now: now,
        ),
        isTrue,
      );
    });

    test('expired PENDING_PAYMENT no longer occupies slot', () {
      final expired = booking(
        id: 'booking-expired',
        status: 'PENDING_PAYMENT',
        expiresAt: now.subtract(const Duration(seconds: 1)),
      );

      expect(occupiesSlot(expired, now), isFalse);
    });

    test('PAID occupies slot and cancelled does not', () {
      final paid = booking(id: 'booking-paid', status: 'PAID');
      final cancelled = booking(id: 'booking-cancelled', status: 'cancelled');

      expect(occupiesSlot(paid, now), isTrue);
      expect(occupiesSlot(cancelled, now), isFalse);
    });

    test('fromSupabase parses expires_at used by hold timeout workflow', () {
      final model = BookingModel.fromSupabase({
        'id': 'booking-hold',
        'user_id': 'user-001',
        'court_id': 'court-001',
        'court_name': 'KLOO Badminton',
        'court_number': 2,
        'booking_date': '2026-05-20',
        'time_slot': 19,
        'price': 120000,
        'status': 'PENDING_PAYMENT',
        'transaction_id': 'TXN_HOLD',
        'created_at': '2026-05-13T10:00:00.000Z',
        'expires_at': '2026-05-13T10:05:00.000Z',
      });

      expect(model.status, 'PENDING_PAYMENT');
      expect(model.transactionId, 'TXN_HOLD');
      expect(model.expiresAt, DateTime.parse('2026-05-13T10:05:00.000Z'));
    });

    test('toSupabase serializes transaction_id for grouped slots', () {
      final slot19 = booking(
        id: 'booking-slot-19',
        status: 'PENDING_PAYMENT',
        transactionId: 'TXN_MULTI_SLOT',
      );
      final slot20 = slot19.copyWith(
        id: 'booking-slot-20',
        timeSlot: 20,
        transactionId: 'TXN_MULTI_SLOT',
      );

      expect(slot19.toSupabase()['transaction_id'], 'TXN_MULTI_SLOT');
      expect(slot20.toSupabase()['transaction_id'], 'TXN_MULTI_SLOT');
      expect(slot19.toSupabase()['booking_date'], '2026-05-20');
      expect(slot20.toSupabase()['time_slot'], 20);
    });
  });
}
