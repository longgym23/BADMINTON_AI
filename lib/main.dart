import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'config/api_keys.dart';
import 'core/services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  final prefs = await SharedPreferences.getInstance();
  final savedLangCode = prefs.getString('app_language_code') ?? 'vi';
  final startLocale = savedLangCode == 'en' ? const Locale('en') : const Locale('vi');

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  PushNotificationService().initialize().catchError((e) {
    debugPrint('PushNotificationService initialization error: $e');
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('vi'), Locale('en')],
      path: 'assets',
      fallbackLocale: const Locale('vi'),
      startLocale: startLocale,
      child: const BadmintonAiApp(),
    ),
  );
}
