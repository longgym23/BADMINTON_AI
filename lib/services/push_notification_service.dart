import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:badminton_ai/utils/app_logger.dart';
import 'dart:convert';

class PushNotificationService {
  static const _tag = 'PushNotification';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  RealtimeChannel? _notificationChannel;

  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> initialize() async {
    // ─── Xin quyền thông báo ───────────────────────────────────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.i(_tag, 'Notification permission granted');
    } else {
      AppLogger.w(_tag, 'Notification permission denied: ${settings.authorizationStatus}');
    }

    // ─── Local Notifications (Android & iOS) ──────────────────────────────
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          AppLogger.d(_tag, 'Local notification tapped: ${response.payload}');
        }
      },
    );

    // ─── Android Notification Channel ─────────────────────────────────────
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ─── FCM Token — lấy và lưu lên Supabase ─────────────────────────────
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        AppLogger.d(_tag, 'FCM Token acquired');
        await _saveTokenToSupabase(token);
      } else {
        AppLogger.w(_tag, 'FCM token is null — notifications may not work');
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to get FCM token', e, st);
    }

    // ─── Tự động cập nhật khi token bị refresh (thiết bị cũ, re-install) ─
    // FIX #7: onTokenRefresh xử lý stale token tự động
    _fcm.onTokenRefresh.listen((newToken) {
      AppLogger.i(_tag, 'FCM token refreshed — updating Supabase');
      _saveTokenToSupabase(newToken);
    });

    // ─── Foreground messages ───────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.d(_tag, 'Foreground message: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              priority: Priority.high,
              importance: Importance.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // ─── Khi user bấm vào thông báo từ background/terminated ─────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.i(_tag, 'Notification opened: ${message.data}');
    });
  }

  /// Lắng nghe realtime notifications từ Supabase DB
  void listenToRealtimeNotifications(String userId) {
    _notificationChannel?.unsubscribe();
    _notificationChannel = Supabase.instance.client
        .channel('public:notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            final title = newRow['title'] as String? ?? 'Thông báo hệ thống';
            final body  = newRow['message'] as String? ?? 'Bạn có một thông báo mới';
            final id    = DateTime.now().millisecondsSinceEpoch.remainder(10000);
            _showLocalPush(id, title, body);
          },
        )
        .subscribe((status, [error]) {
          if (error != null) {
            AppLogger.e(_tag, 'Realtime channel error: $status', error);
          } else {
            AppLogger.d(_tag, 'Realtime channel status: $status');
          }
          if (status == RealtimeSubscribeStatus.timedOut ||
              status == RealtimeSubscribeStatus.channelError) {
            AppLogger.w(_tag, 'Realtime timeout — retrying in 5s');
            Future.delayed(const Duration(seconds: 5), () {
              listenToRealtimeNotifications(userId);
            });
          }
        });
  }

  void _showLocalPush(int id, String title, String body) {
    _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }

  /// Lưu FCM token lên Supabase profiles — ghi đè nếu đã có (xử lý stale)
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        AppLogger.w(_tag, 'Cannot save FCM token — user not logged in');
        return;
      }
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      AppLogger.i(_tag, 'FCM token saved for uid=${user.id}');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to save FCM token', e, st);
    }
  }

  /// Xóa token khi user tắt thông báo hoặc logout
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _notificationChannel?.unsubscribe();
      _notificationChannel = null;

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': null})
            .eq('id', user.id);
        AppLogger.i(_tag, 'FCM token deleted for uid=${user.id}');
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to delete FCM token', e, st);
    }
  }
}
