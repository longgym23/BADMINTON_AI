import 'package:badminton_ai/data/repositories/auth_repository.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import flutter_bloc
import 'package:badminton_ai/blocs/chat/chat_bloc.dart'; // Import ChatBloc
import 'package:badminton_ai/data/repositories/chat_repository.dart'; // Import ChatRepository
import 'package:badminton_ai/screens/splash/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Đã có sẵn
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:badminton_ai/utils/app_colors.dart';

// Import file firebase_options.dart của bạn (tạo ra khi dùng FlutterFire CLI)
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo locale cho package 'intl' (SỬA LỖI)
  await initializeDateFormatting('vi_VN', null); // <-- TÔI ĐÃ THÊM DÒNG NÀY

  // Cấu hình Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // GIẢ LẬP: Xoá dòng này khi bạn có file firebase_options.dart
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Khởi tạo các services
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repository
        Provider<AuthRepository>(
          create: (_) => AuthRepository(
            firebaseAuth: _firebaseAuth,
            firebaseFirestore: _firebaseFirestore,
          ),
        ),
        Provider<FirestoreRepository>(
          create: (_) =>
              FirestoreRepository(firebaseFirestore: _firebaseFirestore),
        ),

        // AuthProvider
        ChangeNotifierProvider<AppAuthProvider>(
          create: (context) => AppAuthProvider(
            authRepository: context.read<AuthRepository>(),
          )..checkAuthState(), // Kiểm tra trạng thái đăng nhập khi app khởi động
        ),

        // BookingProvider
        ChangeNotifierProvider<BookingProvider>(
          create: (context) => BookingProvider(
            firestoreRepository: context.read<FirestoreRepository>(),
            authProvider: context.read<AppAuthProvider>(),
          ),
        ),

        // NotificationProvider
        ChangeNotifierProvider<NotificationProvider>(
          create: (context) =>
              NotificationProvider(context.read<FirestoreRepository>()),
        ),

        // ChatRepository
        Provider<ChatRepository>(
          create: (_) => ChatRepository(firestore: _firebaseFirestore),
        ),

        // ChatBloc (Thay thế ChatProvider)
        BlocProvider<ChatBloc>(
          create: (context) =>
              ChatBloc(chatRepository: context.read<ChatRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Badminton Court Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.primaryLight,
            background: AppColors.background,
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
    );
  }
}
