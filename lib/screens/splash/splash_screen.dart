import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/admin/admin_dashboard_screen.dart';
import 'package:badminton_ai/screens/auth/login_screen.dart';
import 'package:badminton_ai/screens/user/home/home_screen.dart';
import 'package:badminton_ai/widgets/loading_spinner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.authState) {
          case AuthState.authenticated:
            // Đã đăng nhập, kiểm tra vai trò
            if (authProvider.userRole == 'admin') {
              return AdminDashboardScreen();
            } else {
              return HomeScreen(); // Màn hình cho 'member'
            }
          case AuthState.unauthenticated:
            return LoginScreen(); // Màn hình đăng nhập
          case AuthState.loading:
          case AuthState.unknown:
          default:
            return LoadingSpinner(message: 'Đang tải...');
        }
      },                                           
    );
  }
}
                                                                                                                                                                              