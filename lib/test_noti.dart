import 'package:flutter_local_notifications/flutter_local_notifications.dart';
void main() async {
  final plugin = FlutterLocalNotificationsPlugin();
  
  const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInitSettings);
  await plugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails('a', 'b');
  const details = NotificationDetails(android: androidDetails);
  await plugin.show(0, 'title', 'body', details);
}
