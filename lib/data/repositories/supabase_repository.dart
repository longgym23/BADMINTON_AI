import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/models/user_model.dart';

class SupabaseRepository {
  final SupabaseClient _client;

  SupabaseRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  // --- Court Location Functions (Admin & User) ---

  // Lấy stream các sân (Realtime)
  Stream<List<CourtLocationModel>> getCourtLocationsStream() {
    return _client
        .from('courts')
        .stream(primaryKey: ['id'])
        .map(
          (data) =>
              data.map((e) => CourtLocationModel.fromSupabase(e)).toList(),
        );
  }

  // Thêm sân mới
  Future<void> addCourtLocation(CourtLocationModel court) async {
    await _client.from('courts').insert(court.toSupabase());
  }

  // Cập nhật sân
  Future<void> updateCourtLocation(CourtLocationModel court) async {
    await _client.from('courts').update(court.toSupabase()).eq('id', court.id);
  }

  // Xóa sân
  Future<void> deleteCourtLocation(String courtId) async {
    await _client.from('courts').delete().eq('id', courtId);
  }

  // Lấy thông tin sân theo ID
  Future<CourtLocationModel?> getCourtLocationById(String courtId) async {
    try {
      final data = await _client
          .from('courts')
          .select()
          .eq('id', courtId)
          .single();
      return CourtLocationModel.fromSupabase(data);
    } catch (e) {
      print("Lỗi getCourtLocationById: $e");
      return null;
    }
  }

  // --- Booking Functions (User & Admin) ---

  // Lấy stream các booking của 1 Sân Lớn trong 1 Ngày
  Stream<List<BookingModel>> getBookingsStreamForDay(
    String courtId,
    DateTime date,
  ) {
    // Supabase lưu date dạng chuỗi YYYY-MM-DD
    String dateStr = date.toIso8601String().split('T')[0];

    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('court_id', courtId)
        .map(
          (data) => data
              .where((e) =>
                  e['booking_date'] == dateStr &&
                  // Chỉ hiển thị slot là "đã đặt" khi đã thanh toán thực sự
                  // PENDING_PAYMENT = chưa thanh toán → không được chiếm chỗ
                  e['status'] != 'PENDING_PAYMENT' &&
                  e['status'] != 'cancelled')
              .map((e) => BookingModel.fromSupabase(e))
              .toList(),
        );
  }

  // Tạo booking mới - bookingId tự sinh
  Future<String> createBooking(BookingModel booking) async {
    final response = await _client
        .from('bookings')
        .insert(booking.toSupabase())
        .select()
        .single();
    return response['id'];
  }

  // Xóa tất cả booking PENDING_PAYMENT của một giao dịch (khi hết giờ thanh toán)
  Future<void> deletePendingBookingsByTransactionId(String transactionId) async {
    await _client
        .from('bookings')
        .delete()
        .eq('transaction_id', transactionId)
        .eq('status', 'PENDING_PAYMENT');
  }

  // Lấy lịch sử đặt sân của user
  Stream<List<BookingModel>> getUserBookingHistoryStream(String userId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('booking_date', ascending: false) // Sắp xếp giảm dần
        .map((data) => data.map((e) => BookingModel.fromSupabase(e)).toList());
  }

  // Lấy TẤT CẢ booking trong ngày (cho Admin)
  Stream<List<BookingModel>> getAllBookingsForDay(DateTime date) {
    String dateStr = date.toIso8601String().split('T')[0];
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('booking_date', dateStr)
        .map((data) => data.map((e) => BookingModel.fromSupabase(e)).toList());
  }

  // Xóa/Hủy booking
  Future<void> deleteBooking(String bookingId) async {
    await _client.from('bookings').delete().eq('id', bookingId);
  }

  // --- Notification Functions ---

  // Tạo notification mới
  Future<void> createNotification(NotificationModel notification) async {
    await _client.from('notifications').insert(notification.toSupabase());
  }

  // Lấy stream các notifications của user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((e) => NotificationModel.fromSupabase(e)).toList(),
        );
  }

  // Đánh dấu notification là đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Đánh dấu tất cả notifications là đã đọc
  Future<void> markAllNotificationsAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  // Xóa notification
  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }

  // --- User Management Functions (Admin) ---

  // Lấy stream tất cả users (profiles)
  Stream<List<UserModel>> getAllUsersStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((e) => UserModel.fromSupabase(e)).toList());
  }

  // Cập nhật thông tin user (admin)
  Future<void> updateUser(UserModel user) async {
    await _client.from('profiles').update(user.toSupabase()).eq('id', user.id);
  }

  // Xóa user (admin) - Lưu ý: Xóa user trong auth khó hơn, ở đây xóa profile
  Future<void> deleteUser(String userId) async {
    // Supabase Auth Admin API cần thiết để xóa user khỏi Auth, nhưng client thường không có quyền
    // Ở đây ta xóa profile
    await _client.from('profiles').delete().eq('id', userId);
  }

  // Thay đổi role của user (admin)
  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }

  // --- Storage Functions ---

  // Upload ảnh lên Supabase Storage
  Future<String> uploadImage(String filePath, String bucket) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File không tồn tại tại đường dẫn: $filePath');
      }

      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

      // Upload
      await _client.storage.from(bucket).upload(fileName, file);

      // Get Public URL
      final String publicUrl = _client.storage
          .from(bucket)
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print("Lỗi uploadImage Supabase: $e");
      throw e;
    }
  }
}
