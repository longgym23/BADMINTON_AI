import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  RealtimeChannel? _notificationChannel;

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  Future<void> initialize() async {
    // Xin quyền thông báo
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permission');
      }
    }

    // Khởi tạo Local Notifications (Android & iOS)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          if (kDebugMode) print('Local notification payload: ${response.payload}');
        }
      },
    );

    // Cấp quyền kênh Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    // Lấy FCM Token để gửi Push sau này via backend
    try {
      String? token = await _fcm.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Không lấy được FCM token: $e');
      }
    }

    // Lắng nghe token bị thay đổi
    _fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM Token Refreshed: $newToken');
      }
      _saveTokenToSupabase(newToken);
    });

    // Lắng nghe thông báo khi đang mở app (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Nhận được thông báo foreground: ${message.notification?.title}');
      }
      
      RemoteNotification? notification = message.notification;
      
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              priority: Priority.high,
              importance: Importance.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Xử lý khi user bấm vào thông báo từ background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('User bấm vào thông báo: ${message.data}');
      }
      // Điều hướng tới page tương ứng (ví dụ màn chat hoặc sân) nếu cần thiết
    });
  }

  void listenToRealtimeNotifications(String userId) {
    _notificationChannel?.unsubscribe();
    // Lắng nghe bảng notifications chung
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
            final title = newRow['title'] ?? 'Thông báo hệ thống';
            final body = newRow['message'] ?? 'Bạn có một thông báo mới';
            final id = DateTime.now().millisecondsSinceEpoch.remainder(10000);
            
            _showLocalPush(id, title, body);
          },
        )
        .subscribe((status, [error]) {
          if (kDebugMode) {
            print('Realtime notification channel status: $status, error: $error');
          }
          // Nếu timeout hoặc lỗi, thử subscribe lại sau 5 giây
          if (status == RealtimeSubscribeStatus.timedOut ||
              status == RealtimeSubscribeStatus.channelError) {
            if (kDebugMode) print('Retrying realtime notification subscription...');
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
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        if (kDebugMode) {
          print('Saved FCM token to Supabase for user ${user.id}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // Tắt thông báo (xóa token ở local VÀ trên Supabase để backend không push nữa)
  Future<void> deleteToken() async {
    try {
      // 1. Xóa trên Firebase local
      await _fcm.deleteToken();
      _notificationChannel?.unsubscribe();
      _notificationChannel = null;
      
      // 2. Xóa trên Supabase db
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': null})
            .eq('id', user.id);
        if (kDebugMode) {
          print('Deleted FCM token from Supabase for user ${user.id} (Notifications Disabled)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
         print('Error deleting FCM token: $e');
      }
    }
  }
}
