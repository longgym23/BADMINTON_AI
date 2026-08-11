import 'package:badminton_ai/core/data/models/notification_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';

abstract class INotificationRepository {
  Stream<List<NotificationModel>> watchUserNotifications(String userId);

  Future<void> createNotification(NotificationModel notification);

  /// Lấy danh sách ID của admin và chủ sân, dùng để phát thông báo liên quan.
  Future<List<String>> getAdminsAndCourtOwner(String courtId);

  Future<void> markNotificationAsRead(String notificationId);

  Future<void> markAllNotificationsAsRead(String userId);

  Future<void> deleteNotification(String notificationId);
}

class NotificationRepository implements INotificationRepository {
  NotificationRepository({required SupabaseRepository supabaseRepository})
      : _repository = supabaseRepository;

  final SupabaseRepository _repository;

  @override
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _repository.getUserNotificationsStream(userId);
  }

  @override
  Future<void> createNotification(NotificationModel notification) {
    return _repository.createNotification(notification);
  }

  @override
  Future<List<String>> getAdminsAndCourtOwner(String courtId) {
    return _repository.getAdminsAndCourtOwner(courtId);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) {
    return _repository.markNotificationAsRead(notificationId);
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) {
    return _repository.markAllNotificationsAsRead(userId);
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _repository.deleteNotification(notificationId);
  }
}
