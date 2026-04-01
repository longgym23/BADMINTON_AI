import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:badminton_ai/services/push_notification_service.dart';
import 'package:badminton_ai/data/repositories/auth_repository.dart';
import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/providers/language_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/blocs/chat/chat_bloc.dart';
import 'package:badminton_ai/data/repositories/chat_repository.dart';
import 'package:badminton_ai/screens/splash/splash_screen.dart';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/repositories/friend_repository.dart';
import 'package:badminton_ai/providers/favorite_courts_provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';

import 'package:badminton_ai/domain/repositories/course_repository.dart';
import 'package:badminton_ai/data/repositories/course_repository_impl.dart';
import 'package:badminton_ai/providers/course_provider.dart';

// Helper bỏ túi nếu cần cấu hình thông báo nền sâu hơn về sau
// (Hiện tại thiết bị tự hiện thông báo nhờ FCM Native)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Không cần xử lý LocalNotifications ở đây
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await PushNotificationService().initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://olqwfnlycbtrcpywnvvf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9scXdmbmx5Y2J0cmNweXdudnZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNTYxMjIsImV4cCI6MjA4NjczMjEyMn0.owENmaiBwqlg03TRAXN1qhrI8cqo_mfy3ukfhIddaGY',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<SupabaseRepository>(create: (_) => SupabaseRepository()),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<ChatRoomRepository>(create: (_) => ChatRoomRepository()),
        Provider<FriendRepository>(create: (_) => FriendRepository()),

        // Language (must be first so MaterialApp can read it)
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),

        // Auth
        ChangeNotifierProvider<AppAuthProvider>(
          create: (context) =>
              AppAuthProvider(authRepository: context.read<AuthRepository>())
                ..checkAuthState(),
        ),

        // Chat
        Provider<ChatRepository>(
          create: (context) => ChatRepository(
            firestoreRepository: context.read<SupabaseRepository>(),
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (context) =>
              ChatBloc(chatRepository: context.read<ChatRepository>()),
        ),

        // Friends
        ChangeNotifierProvider<FriendProvider>(
          create: (context) => FriendProvider(context.read<FriendRepository>()),
        ),
      ],
      child: AppWithProviders(),
    );
  }
}

class AppWithProviders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingProvider>(
          create: (context) => BookingProvider(
            firestoreRepository: context.read<SupabaseRepository>(),
            authProvider: context.read<AppAuthProvider>(),
          ),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (context) =>
              NotificationProvider(context.read<SupabaseRepository>()),
        ),
        ChangeNotifierProvider<FavoriteCourtsProvider>(
          create: (_) => FavoriteCourtsProvider(),
        ),
        Provider<ICourseRepository>(
          create: (_) => CourseRepositoryImpl(
            supabase: Supabase.instance.client,
          ),
        ),
        ChangeNotifierProvider<CourseProvider>(
          create: (context) => CourseProvider(
            courseRepository: context.read<ICourseRepository>(),
          ),
        ),
      ],
      // Consumer<LanguageProvider> đảm bảo toàn bộ MaterialApp rebuild khi đổi ngôn ngữ
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) => MaterialApp(
          title: 'Badminton Court Booking',
          locale: langProvider.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.primaryLight,
              surface: AppColors.surface,
              error: AppColors.error,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textBlack,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppColors.textBlack),
              titleTextStyle: TextStyle(
                color: AppColors.textBlack,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintStyle: const TextStyle(color: AppColors.textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: SplashScreen(),
        ),
      ),
    );
  }
}
