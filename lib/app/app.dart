import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_system/theme/app_theme.dart';
import '../core/cqrs/command_bus.dart';
import '../core/cqrs/query_bus.dart';
import '../core/data/repositories/chat_room_repository.dart';
import '../core/data/repositories/supabase_repository.dart';
import '../modules/auth/repositories/auth_repository.dart';
import '../modules/auth/viewmodels/auth_provider.dart';
import '../modules/booking/application/mediator/booking_module_mediator.dart';
import '../modules/booking/domain/repositories/i_booking_repository.dart';
import '../modules/booking/infrastructure/booking_startup.dart';
import '../modules/booking/presentation/controllers/booking_provider.dart';
import '../modules/chat/repositories/chat_repository.dart';
import '../modules/chat/viewmodels/chat_bloc.dart';
import '../modules/chat/viewmodels/chat_rooms_bloc.dart';
import '../modules/chat/viewmodels/unread_count_provider.dart';
import '../modules/course/repositories/course_repository.dart';
import '../modules/course/viewmodels/course_provider.dart';
import '../modules/friends/repositories/friend_repository.dart';
import '../modules/friends/viewmodels/friend_provider.dart';
import '../modules/home/repositories/home_repository.dart';
import '../modules/notifications/repositories/notification_repository.dart';
import '../modules/notifications/viewmodels/notification_provider.dart';
import '../modules/profile/repositories/favorite_repository.dart';
import '../modules/profile/viewmodels/favorite_courts_provider.dart';
import '../modules/splash/views/pages/splash_screen.dart';
import 'providers/language_provider.dart';

/// Composition Root — dây điện DI cho toàn bộ app theo MVVM.
/// Repositories và ViewModels được khởi tạo một lần duy nhất ở đây.
class BadmintonAiApp extends StatelessWidget {
  const BadmintonAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Infrastructure: Supabase client & repositories
    final supabaseRepository = SupabaseRepository();
    final authRepository = AuthRepository();
    final chatRoomRepository = ChatRoomRepository();
    final friendRepository = FriendRepository();
    final notificationRepository = NotificationRepository(
      supabaseRepository: supabaseRepository,
    );
    final favoriteRepository = FavoriteRepository();
    final courseRepository = CourseRepository(
      client: Supabase.instance.client,
    );
    final chatRepository = ChatRepository(
      firestoreRepository: supabaseRepository,
    );
    final homeRepository = HomeRepository(supabaseRepository);

    // --- Booking: sử dụng Startup để wiring CommandBus/handlers
    final bookingStartup = BookingStartup.initialize(
      supabaseRepository: supabaseRepository,
    );

    // --- Auth ViewModel khởi chạy sớm nhất
    final authProvider = AppAuthProvider(authRepository: authRepository)
      ..checkAuthState();

    return MultiProvider(
      providers: [
        // Infrastructure
        Provider<SupabaseRepository>.value(value: supabaseRepository),
        Provider<IHomeRepository>.value(value: homeRepository),
        Provider<IBookingRepository>.value(
          value: bookingStartup.bookingRepository,
        ),
        Provider<IBookingModule>.value(value: bookingStartup.bookingModule),
        Provider<CommandBus>.value(value: bookingStartup.commandBus),
        Provider<QueryBus>.value(value: bookingStartup.queryBus),

        // Auth
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider<AppAuthProvider>.value(value: authProvider),

        // Booking ViewModel (dùng IBookingModule từ Startup)
        ChangeNotifierProvider<BookingProvider>(
          create: (ctx) => BookingProvider(
            bookingModule: ctx.read<IBookingModule>(),
            bookingRepository: ctx.read<IBookingRepository>(),
            authProvider: authProvider,
          ),
        ),

        // Chat
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(chatRepository: chatRepository),
        ),
        BlocProvider<ChatRoomsBloc>(
          create: (_) => ChatRoomsBloc(
            chatRoomRepository: chatRoomRepository,
          ),
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

        // Course
        ChangeNotifierProxyProvider<AppAuthProvider, CourseProvider>(
          create: (_) => CourseProvider(courseRepository: courseRepository),
          update: (_, auth, previous) {
            final provider = previous ??
                CourseProvider(courseRepository: courseRepository);
            provider.updateUserId(auth.userId);
            return provider;
          },
        ),

        // Friends
        ChangeNotifierProvider<FriendProvider>(
          create: (_) =>
              FriendProvider(friendRepository: friendRepository),
        ),

        // Notifications
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            notificationRepository: notificationRepository,
          ),
        ),

        // Profile Favorites
        ChangeNotifierProxyProvider<AppAuthProvider, FavoriteCourtsProvider>(
          create: (_) =>
              FavoriteCourtsProvider(favoriteRepository: favoriteRepository),
          update: (_, auth, previous) {
            final provider = previous ??
                FavoriteCourtsProvider(favoriteRepository: favoriteRepository);
            provider.updateUserId(auth.userId);
            return provider;
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) => MaterialApp(
          key: ValueKey(langProvider.locale.languageCode),
          title: 'Badminton Court Booking',
          locale: langProvider.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final clamped = mq.textScaler.scale(1.0).clamp(0.8, 1.2);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
              child: child!,
            );
          },
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
