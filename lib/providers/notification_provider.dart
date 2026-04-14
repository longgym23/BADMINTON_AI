import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseRepository _repository;
  Stream<List<NotificationModel>>? _notificationsStream;

  NotificationProvider(this._repository);

  // Lấy stream notifications của user
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    _notificationsStream = _repository.getUserNotificationsStream(userId);
    return _notificationsStream!;
  }

  // Tạo notification khi đặt sân thành công
  Future<void> createBookingSuccessNotification({
    required String userId,
    required String bookingId,
    required String courtName,
    required String? courtAddress,
    required int courtNumber,
    required DateTime bookingDate,
    required int timeSlot,
    required int price,
    int durationHours = 1,
  }) async {
    final dateStr = _formatDate(bookingDate);
    final endTime = timeSlot + durationHours;
    final timeStr = '$timeSlot:00 - $endTime:00 (${durationHours}h)';

    final priceStr = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(price);
    final notification = NotificationModel(
      userId: userId,
      type: 'booking_success',
      title: 'Đặt sân thành công!',
      message:
          'Bạn đã đặt sân $courtName ($courtAddress) - Sân $courtNumber vào $dateStr từ $timeStr với giá $priceStr',
      createdAt: DateTime.now(),
      isRead: false,
      bookingId: bookingId,
      courtName: courtName,
      courtAddress: courtAddress,
      courtNumber: courtNumber,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      price: price,
    );

    await _repository.createNotification(notification);
  }

  // Tạo notification khi tham gia sự kiện thành công
  Future<void> createEventSuccessNotification({
    required String userId,
    required String eventTitle,
    required String startTime,
    required String endTime,
    required DateTime date,
    required int quantity,
  }) async {
    final dateStr = _formatDate(date);
    final notification = NotificationModel(
      userId: userId,
      type: 'booking_success',
      title: 'Đăng ký sự kiện thành công!',
      message: 'Bạn đã đăng ký $quantity vé tham gia Sự kiện "$eventTitle" diễn ra vào $dateStr từ $startTime đến $endTime',
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _repository.createNotification(notification);
  }

  // Đánh dấu notification là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _repository.markNotificationAsRead(notificationId);
    notifyListeners();
  }

  // Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead(String userId) async {
    await _repository.markAllNotificationsAsRead(userId);
    notifyListeners();
  }

  // Xóa notification
  Future<void> deleteNotification(String notificationId) async {
    await _repository.deleteNotification(notificationId);
    notifyListeners();
  }

  // Format ngày
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
