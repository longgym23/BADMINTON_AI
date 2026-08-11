import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/auth/views/pages/forgot_password_screen.dart';
import 'package:badminton_ai/modules/auth/views/pages/register_screen.dart';
import 'package:badminton_ai/modules/splash/views/pages/splash_screen.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/components/ui/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  static final Color _orange = Color(0xFFE8722A);
  static final Color _inputBg = Color(0xFFF5F5F5);
  static final Color _hintColor = Color(0xFFAAAAAA);
  static final Color _textDark = Color(0xFF1A1A1A);
  static final Color _textGray = Color(0xFF888888);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    FocusScope.of(context).unfocus(); // Đóng bàn phím để hiển thị Toast rõ ràng
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AppAuthProvider>();
      String? error = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (error != null && mounted) {
        String displayError = error;
        if (error.contains('Email not confirmed')) {
          displayError = 'screens.emailHasNotBeenVerifiedP'.tr();
        } else if (error.contains('Invalid login credentials')) {
          displayError = 'screens.emailOrPasswordIsIncorrect'.tr();
        }
        AppToast.show(context, displayError, type: ToastType.error);
      } else if (error == null && mounted) {
        AppToast.show(context, 'screens.logInSuccessfully'.tr(), type: ToastType.success);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  void _loginWithGoogle() async {
    final authProvider = context.read<AppAuthProvider>();
    bool success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      AppToast.show(
        context,
        'screens.signInToGoogleSuccessfully'.tr(),
        type: ToastType.success,
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SplashScreen()),
        (route) => false,
      );
    } else if (mounted) {
      AppToast.show(
        context,
        'screens.googleLoginFailedOrWasCan'.tr(),
        type: ToastType.error,
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textGray,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: TextStyle(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _hintColor, fontSize: 14),
            filled: true,
            fillColor: _inputBg,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Icon(icon, color: _orange, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _hintColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _orange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final isLoading = authProvider.isSigningIn;
    final size = MediaQuery.of(context).size;
    final imageH = size.height * 0.40; // Adjust proportionally

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // ── Phần ảnh nền phía trên ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageH,
              child: Image.asset(
                'assets/images/background_badminton.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // ── Card trắng phía dưới ──
            Positioned(
              top: imageH - 24,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: 'screens.welcomeBack'.tr() + Avatar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('screens.welcomeNbackToKLOO'.tr(),
                                    style: TextStyle(
                                      fontSize: 26, // Reduced slightly
                                      fontWeight: FontWeight.bold,
                                      color: VColors.brandPrimary,
                                      height: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('screens.yourPlayground'.tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Image.asset(
                                'assets/images/teamwork.gif',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Email field
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'screens.enterYourEmail'.tr(),
                          icon: Icons.email,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'screens.pleaseEnterEmail'.tr();
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(val)) {
                              return 'screens.invalidEmail'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12), // Reduced from 16

                        // Password field
                        _buildField(
                          controller: _passwordController,
                          label: 'screens.password'.tr(),
                          hint: '••••••',
                          icon: Icons.lock,
                          isPassword: true,
                          validator: (val) => (val?.isEmpty ?? true)
                              ? 'screens.pleaseEnterYourPassword'.tr()
                              : null,
                        ),

                        // Quên mật khẩu
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('screens.forgotPassword'.tr(),
                                style: TextStyle(
                                  color: VColors.brandPrimary, 
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12), // Reduced from 16

                        // Nút đăng nhập
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Reduced from 52
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('screens.logIn'.tr(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 12), // Reduced from 20
                        
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('screens.donTHaveAnAccountYet'.tr(),
                                style: TextStyle(
                                  color: _textGray,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterScreen(),
                                  ),
                                ),
                                child: Text('screens.register'.tr(),
                                  style: TextStyle(
                                    color: _orange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12), // Reduced from 16

                        // Social buttons
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Reduced from 52
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _loginWithGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF0D6331), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google.png',
                                  width: 24,
                                  height: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF0D6331),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
