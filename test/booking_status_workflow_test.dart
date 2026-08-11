import 'package:badminton_ai/modules/booking/domain/entities/booking_entity.dart';
import 'package:flutter_test/flutter_test.dart';

bool occupiesSlot(BookingEntity booking, DateTime now) {
  if (booking.status == 'confirmed' || booking.status == 'PAID') return true;
  return false;
}

void main() {
  group('Booking status workflow', () {
    final now = DateTime(2026, 5, 13, 10);

    test('confirmed booking occupies slot', () {
      final b = BookingEntity(
        id: 'booking-01',
        courtId: 'court-01',
        courtName: 'KLOO Court',
        userId: 'user-01',
        userName: 'Tester',
        courtNumber: 1,
        date: DateTime(2026, 5, 20),
        timeSlot: 19,
        price: 120000,
        status: 'confirmed',
      );

      expect(occupiesSlot(b, now), isTrue);
    });

    test('cancelled booking does not occupy slot', () {
      final b = BookingEntity(
        id: 'booking-02',
        courtId: 'court-01',
        courtName: 'KLOO Court',
        userId: 'user-01',
        userName: 'Tester',
        courtNumber: 1,
        date: DateTime(2026, 5, 20),
        timeSlot: 19,
        price: 120000,
        status: 'cancelled',
      );

      expect(occupiesSlot(b, now), isFalse);
    });
  });
}
