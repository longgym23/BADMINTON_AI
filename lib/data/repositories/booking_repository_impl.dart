import 'package:badminton_ai/data/mappers/booking_mapper.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/domain/entities/booking.dart';
import 'package:badminton_ai/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseRepository _supabaseRepository;

  BookingRepositoryImpl(this._supabaseRepository);

  @override
  Stream<List<Booking>> getBookingsStreamForDay(String courtId, DateTime date) {
    return _supabaseRepository
        .getBookingsStreamForDay(courtId, date)
        .map((models) => models.map(BookingMapper.toEntity).toList());
  }

  @override
  Stream<List<Booking>> getUserBookingHistoryStream(String userId) {
    return _supabaseRepository
        .getUserBookingHistoryStream(userId)
        .map((models) => models.map(BookingMapper.toEntity).toList());
  }

  @override
  Stream<List<Booking>> getAllBookingsForDay(DateTime date) {
    return _supabaseRepository
        .getAllBookingsForDay(date)
        .map((models) => models.map(BookingMapper.toEntity).toList());
  }

  @override
  Future<String> createBooking(Booking booking) {
    return _supabaseRepository.createBooking(BookingMapper.toModel(booking));
  }

  @override
  Future<void> deleteBooking(String bookingId) {
    return _supabaseRepository.deleteBooking(bookingId);
  }

  @override
  Future<void> cancelBooking(String bookingId) {
    return _supabaseRepository.cancelBooking(bookingId);
  }

  @override
  Future<void> deletePendingBookingsByTransactionId(String transactionId) {
    return _supabaseRepository.deletePendingBookingsByTransactionId(
      transactionId,
    );
  }
}
