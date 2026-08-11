import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/auth/views/pages/login_screen.dart';
import 'package:badminton_ai/modules/auth/views/widgets/welcome_pages.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VPage(
      backgroundColor: const Color(0xFFFCFAF8),
      padding: EdgeInsets.zero,
      useSafeArea: false,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: const [WelcomePage1(), WelcomePage2(), WelcomePage3()],
            ),
          ),
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIndicatorRow(),
            const VGap.lg(),
            if (_currentPage == 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      'screens.skip'.tr(),
                      style: VTypography.headingSm.copyWith(color: Colors.black87),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        Text('screens.continue'.tr(), style: VTypography.headingSm.copyWith(color: Colors.white)),
                        const VGap.xs(),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 0 ? 'screens.continue'.tr() : 'screens.getStartedNow'.tr(),
                        style: VTypography.headingSm.copyWith(color: Colors.white),
                      ),
                      const VGap.xs(),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            color: isActive ? VColors.brandPrimary : VColors.borderDefault,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
