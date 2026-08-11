import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/event_model.dart';
import 'package:badminton_ai/modules/booking/domain/entities/booking_entity.dart';

/// Pure Dart Repository contract for the Booking bounded context.
/// Must stay Pure Dart — no Flutter / Supabase imports.
///
/// Note: [CourtLocationModel] and [EventModel] are plain Dart data classes
/// (no Flutter/Supabase imports) reused here during the strangler migration
/// to avoid duplicating court/event shapes before those modules are carved out.
abstract class IBookingRepository {
  /// Creates a new booking and returns its generated id.
  Future<String> createBooking(BookingEntity booking);

  /// Atomically holds one or more slots via the `reserve_booking_slots` RPC.
  Future<Map<String, dynamic>> reserveBookingSlots({
    required String courtId,
    required String courtName,
    required DateTime bookingDate,
    required String transactionId,
    required List<Map<String, dynamic>> slots,
    int holdMinutes = 5,
  });

  /// Releases a held/pending transaction (expired or abandoned checkout).
  Future<int> releaseBookingTransaction(String transactionId);

  /// Marks all bookings under a transaction as PAID.
  Future<void> markBookingsAsPaid(String transactionId);

  /// Deletes PENDING_PAYMENT bookings tied to a transaction.
  Future<void> deletePendingBookingsByTransactionId(String transactionId);

  /// Cancels a single booking (sets status to `cancelled`, no refund).
  Future<void> cancelBooking(String bookingId);

  /// Cancels a booking and triggers wallet refund logic (DB-side trigger).
  Future<void> cancelBookingWithRefund(BookingEntity booking);

  Future<void> deductBalance(String userId, int amount);

  Future<void> addBalance(String userId, int amount);

  Future<void> createEventPaymentPlaceholder({
    required EventModel event,
    required String userId,
    required String transactionId,
    required int totalPrice,
    int holdMinutes = 5,
  });

  Future<void> joinEvent(
    String eventId,
    String userId,
    double priceDeduction, {
    int quantity = 1,
    String? paymentTransactionId,
  });

  Future<bool> isUserRegisteredForEvent(String eventId, String userId);

  Future<void> submitReview({
    required String courtId,
    String? userId,
    required int rating,
    String? comment,
  });

  /// Emits bookings for a given court/day (excludes cancelled + expired pending).
  Stream<List<BookingEntity>> watchBookingsForDay(String courtId, DateTime date);

  /// Emits the latest 50 bookings for a user (Realtime).
  Stream<List<BookingEntity>> watchUserBookingHistory(String userId);

  /// Pagination for booking history ("load more").
  Future<List<BookingEntity>> getMoreBookingHistory({
    required String userId,
    required int offset,
    int limit = 20,
  });

  /// Emits the list of courts (optionally filtered by owner).
  Stream<List<CourtLocationModel>> watchCourts({String? ownerId});

  Future<CourtLocationModel?> getCourtById(String courtId);

  /// Emits events (optionally filtered by owner or court).
  Stream<List<EventModel>> watchEvents({String? ownerId, String? courtId});
}
