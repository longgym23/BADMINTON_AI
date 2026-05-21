import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:badminton_ai/data/repositories/chat_rooms_repository_impl.dart';
import 'package:badminton_ai/data/repositories/home_filter_repository_impl.dart';
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
import 'package:badminton_ai/providers/unread_count_provider.dart';
import 'package:badminton_ai/screens/splash/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/repositories/friend_repository.dart';
import 'package:badminton_ai/providers/favorite_courts_provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';

import 'package:badminton_ai/domain/repositories/chat_rooms_repository.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';
import 'package:badminton_ai/domain/repositories/home_filter_repository.dart';
import 'package:badminton_ai/domain/usecases/chat_rooms/watch_user_chat_rooms_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/get_categories_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/get_courses_by_category_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/get_watched_courses_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/mark_course_as_watched_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_court_locations_stream_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_events_stream_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_fallback_courts_usecase.dart';
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
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  // Đọc ngôn ngữ đã lưu trước khi runApp để tránh flash ngôn ngữ sai lúc khởi động
  final prefs = await SharedPreferences.getInstance();
  final savedLangCode = prefs.getString('app_language_code') ?? 'vi';
  final startLocale = savedLangCode == 'en' ? const Locale('en') : const Locale('vi');

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase initialization error: \$e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://olqwfnlycbtrcpywnvvf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9scXdmbmx5Y2J0cmNweXdudnZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNTYxMjIsImV4cCI6MjA4NjczMjEyMn0.owENmaiBwqlg03TRAXN1qhrI8cqo_mfy3ukfhIddaGY',
  );

  try {
    await PushNotificationService().initialize();
  } catch (e) {
    print('PushNotificationService initialization error: \$e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('vi'), Locale('en')],
      path: 'assets',
      fallbackLocale: const Locale('vi'),
      startLocale: startLocale,
      child: MyApp(),
    ),
  );
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
        Provider<ChatRoomsRepository>(
          create: (context) =>
              ChatRoomsRepositoryImpl(context.read<ChatRoomRepository>()),
        ),
        Provider<HomeFilterRepository>(
          create: (context) =>
              HomeFilterRepositoryImpl(context.read<SupabaseRepository>()),
        ),
        Provider<FriendRepository>(create: (_) => FriendRepository()),

        // Language (must be first so MaterialApp can read it)
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),

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
        Provider<WatchUserChatRoomsUseCase>(
          create: (context) =>
              WatchUserChatRoomsUseCase(context.read<ChatRoomsRepository>()),
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
        ChangeNotifierProxyProvider<AppAuthProvider, FavoriteCourtsProvider>(
          create: (_) => FavoriteCourtsProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? FavoriteCourtsProvider();
            provider.updateUserId(auth.userId);
            return provider;
          },
        ),
        Provider<ICourseRepository>(
          create: (_) =>
              CourseRepositoryImpl(supabase: Supabase.instance.client),
        ),
        Provider<GetCategoriesUseCase>(
          create: (context) =>
              GetCategoriesUseCase(context.read<ICourseRepository>()),
        ),
        Provider<GetCoursesByCategoryUseCase>(
          create: (context) =>
              GetCoursesByCategoryUseCase(context.read<ICourseRepository>()),
        ),
        Provider<GetWatchedCoursesUseCase>(
          create: (context) =>
              GetWatchedCoursesUseCase(context.read<ICourseRepository>()),
        ),
        Provider<MarkCourseAsWatchedUseCase>(
          create: (context) =>
              MarkCourseAsWatchedUseCase(context.read<ICourseRepository>()),
        ),
        Provider<GetCourtLocationsStreamUseCase>(
          create: (context) => GetCourtLocationsStreamUseCase(
            context.read<HomeFilterRepository>(),
          ),
        ),
        Provider<GetFallbackCourtsUseCase>(
          create: (context) =>
              GetFallbackCourtsUseCase(context.read<HomeFilterRepository>()),
        ),
        Provider<GetEventsStreamUseCase>(
          create: (context) =>
              GetEventsStreamUseCase(context.read<HomeFilterRepository>()),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, CourseProvider>(
          create: (context) => CourseProvider(
            getCategoriesUseCase: context.read<GetCategoriesUseCase>(),
            getCoursesByCategoryUseCase: context
                .read<GetCoursesByCategoryUseCase>(),
            getWatchedCoursesUseCase: context.read<GetWatchedCoursesUseCase>(),
            markCourseAsWatchedUseCase: context
                .read<MarkCourseAsWatchedUseCase>(),
          ),
          update: (context, auth, previous) {
            final provider = previous ?? CourseProvider(
              getCategoriesUseCase: context.read<GetCategoriesUseCase>(),
              getCoursesByCategoryUseCase: context.read<GetCoursesByCategoryUseCase>(),
              getWatchedCoursesUseCase: context.read<GetWatchedCoursesUseCase>(),
              markCourseAsWatchedUseCase: context.read<MarkCourseAsWatchedUseCase>(),
            );
            provider.updateUserId(auth.userId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, UnreadCountProvider>(
          create: (_) => UnreadCountProvider(),
          update: (_, auth, unread) {
            final provider = unread ?? UnreadCountProvider();
            if (auth.userId != null) {
              provider.startListening(auth.userId!);
            } else {
              provider.stopListening();
            }
            return provider;
          },
        ),
      ],
      // Consumer<LanguageProvider> đảm bảo toàn bộ MaterialApp rebuild khi đổi ngôn ngữ
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) => MaterialApp(
          // Key thay đổi theo locale → Flutter destroy & recreate toàn bộ widget tree
          // → tất cả tab, route đều rebuild ngay lập tức khi đổi ngôn ngữ
          key: ValueKey(langProvider.locale.languageCode),
          title: 'Badminton Court Booking',
          locale: langProvider.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          debugShowCheckedModeBanner: false,
          // Khoá font scale [0.8–1.2] để bảo vệ layout khi user tăng font hệ thống
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final clampedScale = mq.textScaler.scale(1.0).clamp(0.8, 1.2);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(clampedScale),
              ),
              child: child!,
            );
          },
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
