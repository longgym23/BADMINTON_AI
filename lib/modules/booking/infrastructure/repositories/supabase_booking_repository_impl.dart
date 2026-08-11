import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/event_model.dart';
import 'package:badminton_ai/core/data/models/review_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/booking/domain/entities/booking_entity.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';
import 'package:badminton_ai/modules/booking/infrastructure/mappers/booking_entity_mapper.dart';

/// Supabase implementation of [IBookingRepository].
///
/// Adapter over the existing "god repository" ([SupabaseRepository]) — the
/// underlying SQL/RPC calls are intentionally left untouched (strangler
/// migration); this class only translates between the Booking domain shape
/// and the legacy data models.
class SupabaseBookingRepositoryImpl implements IBookingRepository {
  SupabaseBookingRepositoryImpl({
    required SupabaseRepository repository,
    BookingEntityMapper mapper = const BookingEntityMapper(),
  })  : _repository = repository,
        _mapper = mapper;

  final SupabaseRepository _repository;
  final BookingEntityMapper _mapper;

  @override
  Future<String> createBooking(BookingEntity booking) {
    return _repository.createBooking(_mapper.toModel(booking));
  }

  @override
  Future<Map<String, dynamic>> reserveBookingSlots({
    required String courtId,
    required String courtName,
    required DateTime bookingDate,
    required String transactionId,
    required List<Map<String, dynamic>> slots,
    int holdMinutes = 5,
  }) {
    return _repository.reserveBookingSlots(
      courtId: courtId,
      courtName: courtName,
      bookingDate: bookingDate,
      transactionId: transactionId,
      slots: slots,
      holdMinutes: holdMinutes,
    );
  }

  @override
  Future<int> releaseBookingTransaction(String transactionId) {
    return _repository.releaseBookingTransaction(transactionId);
  }

  @override
  Future<void> markBookingsAsPaid(String transactionId) {
    return _repository.markBookingsAsPaid(transactionId);
  }

  @override
  Future<void> deletePendingBookingsByTransactionId(String transactionId) {
    return _repository.deletePendingBookingsByTransactionId(transactionId);
  }

  @override
  Future<void> cancelBooking(String bookingId) {
    return _repository.cancelBooking(bookingId);
  }

  @override
  Future<void> cancelBookingWithRefund(BookingEntity booking) {
    return _repository.cancelBookingWithRefund(_mapper.toModel(booking));
  }

  @override
  Future<void> deductBalance(String userId, int amount) {
    return _repository.deductBalance(userId, amount);
  }

  @override
  Future<void> addBalance(String userId, int amount) {
    return _repository.addBalance(userId, amount);
  }

  @override
  Future<void> createEventPaymentPlaceholder({
    required EventModel event,
    required String userId,
    required String transactionId,
    required int totalPrice,
    int holdMinutes = 5,
  }) {
    return _repository.createEventPaymentPlaceholder(
      event: event,
      userId: userId,
      transactionId: transactionId,
      totalPrice: totalPrice,
      holdMinutes: holdMinutes,
    );
  }

  @override
  Future<void> joinEvent(
    String eventId,
    String userId,
    double priceDeduction, {
    int quantity = 1,
    String? paymentTransactionId,
  }) {
    return _repository.joinEvent(
      eventId,
      userId,
      priceDeduction,
      quantity: quantity,
      paymentTransactionId: paymentTransactionId,
    );
  }

  @override
  Future<bool> isUserRegisteredForEvent(String eventId, String userId) {
    return _repository.isUserRegisteredForEvent(eventId, userId);
  }

  @override
  Future<void> submitReview({
    required String courtId,
    String? userId,
    required int rating,
    String? comment,
  }) {
    return _repository.submitReview(
      ReviewModel(
        id: '',
        courtId: courtId,
        userId: userId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<List<BookingEntity>> watchBookingsForDay(String courtId, DateTime date) {
    return _repository
        .getBookingsStreamForDay(courtId, date)
        .map((models) => models.map(_mapper.toEntity).toList());
  }

  @override
  Stream<List<BookingEntity>> watchUserBookingHistory(String userId) {
    return _repository
        .getUserBookingHistoryStream(userId)
        .map((models) => models.map(_mapper.toEntity).toList());
  }

  @override
  Future<List<BookingEntity>> getMoreBookingHistory({
    required String userId,
    required int offset,
    int limit = 20,
  }) async {
    final models = await _repository.getMoreBookingHistory(
      userId: userId,
      offset: offset,
      limit: limit,
    );
    return models.map(_mapper.toEntity).toList();
  }

  @override
  Stream<List<CourtLocationModel>> watchCourts({String? ownerId}) {
    return _repository.getCourtLocationsStream(ownerId: ownerId);
  }

  @override
  Future<CourtLocationModel?> getCourtById(String courtId) {
    return _repository.getCourtLocationById(courtId);
  }

  @override
  Stream<List<EventModel>> watchEvents({String? ownerId, String? courtId}) {
    return _repository.getEventsStream(ownerId: ownerId, courtId: courtId);
  }
}
