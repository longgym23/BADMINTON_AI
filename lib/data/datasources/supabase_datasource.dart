import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/models/user_model.dart';

abstract class SupabaseDataSource {
  Stream<List<CourtLocationModel>> getCourtLocationsStream();
  
  Future<void> addCourtLocation(CourtLocationModel court);
  
  Future<void> updateCourtLocation(CourtLocationModel court);
  
  Future<void> deleteCourtLocation(String courtId);
  
  Future<CourtLocationModel?> getCourtLocationById(String courtId);
  
  Stream<List<BookingModel>> getBookingsStreamForDay(String courtId, DateTime date);
  
  Future<String> createBooking(BookingModel booking);
  
  Future<void> deletePendingBookingsByTransactionId(String transactionId);
  
  Stream<List<BookingModel>> getUserBookingHistoryStream(String userId);
  
  Stream<List<BookingModel>> getAllBookingsForDay(DateTime date);
  
  Future<void> deleteBooking(String bookingId);
  
  Future<void> createNotification(NotificationModel notification);
  
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId);
  
  Future<void> markNotificationAsRead(String notificationId);
  
  Future<void> markAllNotificationsAsRead(String userId);
  
  Future<void> deleteNotification(String notificationId);
  
  Stream<List<UserModel>> getAllUsersStream();
  
  Future<void> updateUser(UserModel user);
  
  Future<void> deleteUser(String userId);
  
  Future<void> updateUserRole(String userId, String role);
  
  Future<String> uploadImage(String filePath, String bucket);
}