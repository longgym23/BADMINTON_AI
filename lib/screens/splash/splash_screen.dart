import 'package:easy_localization/easy_localization.dart';

import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/admin/admin_dashboard_screen.dart';
import 'package:badminton_ai/screens/auth/login_screen.dart';
import 'package:badminton_ai/screens/auth/welcome_screen.dart';
import 'package:badminton_ai/screens/user/home/home_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/loading_spinner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn hình khởi động — hiển thị logo ~2 giây rồi mới route sang auth logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _showApp = false; // Sau khi xong delay → chuyển sang app logic

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.78,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();

    // Giữ màn start 2.2 giây
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _showApp = true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) {
      return _AppRouter();
    }

    // Màn hình start: nền trắng + logo giữa
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo1.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                // Tên app
                Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        Text(
                          'common.appNameKloo'.tr(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'home_screen.smartBooking'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),
                // Dòng loading mỏng phía dưới
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Giữ nguyên logic auth routing cũ, tách riêng
class _AppRouter extends StatefulWidget {
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.authState) {
          case AuthState.authenticated:
            if (authProvider.userRole == 'admin' ||
                authProvider.userRole == 'court_owner') {
              return AdminDashboardScreen();
            } else {
              return HomeScreen();
            }
          case AuthState.unauthenticated:
            return FutureBuilder<SharedPreferences>(
              future: _prefsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingSpinner(message: 'screens.loading'.tr());
                }
                final prefs = snapshot.data;
                final isFirstTime = prefs?.getBool('isFirstTime') ?? true;
                if (isFirstTime) {
                  return const WelcomeScreen();
                } else {
                  return LoginScreen();
                }
              },
            );
          case AuthState.loading:
          case AuthState.unknown:
            return LoadingSpinner(message: 'screens.loading'.tr());
        }
      },
    );
  }
}
