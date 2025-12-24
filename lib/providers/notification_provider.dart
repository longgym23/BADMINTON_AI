import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreRepository _repository;
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
  }) async {
    final dateStr = _formatDate(bookingDate);
    final timeStr = '$timeSlot:00';

    final notification = NotificationModel(
      userId: userId,
      type: 'booking_success',
      title: 'Đặt sân thành công!',
      message: 'Bạn đã đặt sân $courtName - Sân $courtNumber vào $dateStr lúc $timeStr',
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

