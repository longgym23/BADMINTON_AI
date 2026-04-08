import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/admin/admin_dashboard_screen.dart';
import 'package:badminton_ai/screens/auth/login_screen.dart';
import 'package:badminton_ai/screens/auth/welcome_screen.dart';
import 'package:badminton_ai/screens/user/home/home_screen.dart';
import 'package:badminton_ai/widgets/loading_spinner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.authState) {
          case AuthState.authenticated:
            // Đã đăng nhập, kiểm tra vai trò
            if (authProvider.userRole == 'admin' || authProvider.userRole == 'court_owner') {
              return AdminDashboardScreen();
            } else {
              return HomeScreen(); // Màn hình cho người dùng thường
            }
          case AuthState.unauthenticated:
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingSpinner(message: 'Đang tải...');
                }
                final prefs = snapshot.data;
                final isFirstTime = prefs?.getBool('isFirstTime') ?? true;

                if (isFirstTime) {
                  return const WelcomeScreen(); // Màn hình chào mừng lần đầu
                } else {
                  return LoginScreen(); // Đã xem welcome thì vào thẳng login
                }
              },
            );
          case AuthState.loading:
          case AuthState.unknown:
            return LoadingSpinner(message: 'Đang tải...');
        }
      },
    );
  }
}
                                                                                                                                                                              