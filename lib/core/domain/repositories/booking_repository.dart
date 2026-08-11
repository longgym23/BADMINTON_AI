import 'package:badminton_ai/domain/entities/booking.dart';

abstract class BookingRepository {
  Stream<List<Booking>> getBookingsStreamForDay(String courtId, DateTime date);
  
  Stream<List<Booking>> getUserBookingHistoryStream(String userId);
  
  Stream<List<Booking>> getAllBookingsForDay(DateTime date);
  
  Future<String> createBooking(Booking booking);
  
  Future<void> deleteBooking(String bookingId);
  
  Future<void> cancelBooking(String bookingId);
  
  Future<void> deletePendingBookingsByTransactionId(String transactionId);
}