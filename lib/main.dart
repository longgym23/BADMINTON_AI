import 'package:badminton_ai/data/repositories/auth_repository.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:badminton_ai/screens/splash/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Đã có sẵn
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- TÔI ĐÃ THÊM DÒNG NÀY

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
    // Định nghĩa bảng màu theo logo
    final MaterialColor primaryNavyBlue = MaterialColor(0xFF1E2B4B, <int, Color>{
      50: Color(0xFFE3E5E8),
      100: Color(0xFFB8BFCA),
      200: Color(0xFF8B96A8),
      300: Color(0xFF5E6D86),
      400: Color(0xFF3F4D6F),
      500: Color(0xFF1E2B4B), // Màu chính từ logo
      600: Color(0xFF1A2643),
      700: Color(0xFF16213B),
      800: Color(0xFF121C33),
      900: Color(0xFF0B1225),
    });

    final MaterialColor accentGold = MaterialColor(0xFFFBC02D, <int, Color>{
      50: Color(0xFFFFFDE7),
      100: Color(0xFFFFF9C4),
      200: Color(0xFFFFF59D),
      300: Color(0xFFFFF176),
      400: Color(0xFFFFEE58),
      500: Color(0xFFFBC02D), // Màu vàng từ logo
      600: Color(0xFFF9B300),
      700: Color(0xFFF7A700),
      800: Color(0xFFF59B00),
      900: Color(0xFFF28F00),
    });

    final MaterialColor accentBlue = MaterialColor(0xFF42A5F5, <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5), // Màu xanh dương từ logo
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    });

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
          create: (_) => FirestoreRepository(firebaseFirestore: _firebaseFirestore),
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
          create: (context) => NotificationProvider(
            context.read<FirestoreRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Badminton Court Booking',
        debugShowCheckedModeBanner: false, // Tắt debug banner (viền xanh)
        theme: ThemeData(
          primarySwatch: primaryNavyBlue, // Màu xanh đậm làm màu chính
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: primaryNavyBlue,
            accentColor: accentGold, // Màu vàng làm màu nhấn
          ).copyWith(
            secondary: accentBlue, // Màu xanh dương làm màu phụ
            surface: Colors.white, // Màu nền của các card, dialog
            onSurface: Colors.black87, // Màu chữ trên surface
            background: primaryNavyBlue, // Màu nền tổng thể của app (nếu không có Scaffold)
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: primaryNavyBlue[700], // Màu AppBar đậm hơn một chút
            foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          scaffoldBackgroundColor: primaryNavyBlue[900], // Màu nền cho Scaffold
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGold, // Màu vàng cho nút
              foregroundColor: primaryNavyBlue, // Màu chữ trên nút vàng
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: accentBlue, // Màu xanh dương cho text button
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.9), // Nền trắng cho input
            labelStyle: TextStyle(color: primaryNavyBlue[500]), // Màu label
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none, // Bỏ viền mặc định
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentBlue, width: 2), // Viền xanh khi focus
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            )
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: primaryNavyBlue[700], // Màu nền BottomNavBar
            selectedItemColor: accentGold, // Màu item được chọn
            unselectedItemColor: Colors.white70, // Màu item không được chọn
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          ),
          // cardTheme: CardTheme( // Tôi cũng đã bỏ comment dòng này (ban nãy bị comment)
          //   color: Colors.white,
          //   elevation: 4,
          //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // ),
          // Thêm các theme khác nếu cần
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(), // Bắt đầu với SplashScreen để kiểm tra auth
      ),
    );
  }
}

