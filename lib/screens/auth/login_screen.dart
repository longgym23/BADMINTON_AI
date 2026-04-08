import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/auth/forgot_password_screen.dart';
import 'package:badminton_ai/screens/auth/register_screen.dart';
import 'package:badminton_ai/screens/splash/splash_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  static const Color _orange = Color(0xFFE8722A);
  static const Color _inputBg = Color(0xFFF5F5F5);
  static const Color _hintColor = Color(0xFFAAAAAA);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF888888);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AppAuthProvider>();
      String? error = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (error != null && mounted) {
        String displayError = error;
        if (error.contains('Email not confirmed')) {
          displayError = 'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.';
        } else if (error.contains('Invalid login credentials')) {
          displayError = 'Email hoặc mật khẩu không đúng.';
        }
        AppToast.show(context, displayError, type: ToastType.error);
      } else if (error == null && mounted) {
        AppToast.show(context, 'Đăng nhập thành công', type: ToastType.success);
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
        'Đăng nhập Google thành công',
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
        'Đăng nhập Google thất bại hoặc bị hủy.',
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
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
              borderSide: const BorderSide(color: _orange, width: 1.5),
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
    final isLoading = authProvider.authState == AuthState.loading;
    final size = MediaQuery.of(context).size;
    final imageH = size.height * 0.42;

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background_badminton.jpg',
                    fit: BoxFit.cover,
                  ),
                  // Overlay tối nhẹ
                  // Container(
                  //   decoration: BoxDecoration(
                  //     gradient: LinearGradient(
                  //       begin: Alignment.topCenter,
                  //       end: Alignment.bottomCenter,
                  //       colors: [
                  //         Colors.black.withOpacity(0.25),
                  //         Colors.black.withOpacity(0.50),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // // Logo nhỏ 44x44 góc trên trái
                  // Positioned(
                  //   top: MediaQuery.of(context).padding.top + 0.5,
                  //   left: 10,
                  //   child: Container(
                  //     width: 100,
                  //     height: 100,
                  //     // decoration: BoxDecoration(
                  //     //   color: Colors.white,
                  //     //   borderRadius: BorderRadius.circular(12),
                  //     //   boxShadow: [
                  //     //     BoxShadow(
                  //     //       color: Colors.black.withOpacity(0.15),
                  //     //       blurRadius: 8,
                  //     //       offset: const Offset(0, 3),
                  //     //     ),
                  //     //   ],
                  //     // ),
                  //     padding: const EdgeInsets.all(6),
                  //     child: Image.asset(
                  //       'assets/images/logo1.png',
                  //       fit: BoxFit.contain,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            // ── Card trắng phía dưới ──
            Positioned(
              top: imageH - 24,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: "Chào mừng trở lại" + Avatar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chào mừng\ntrở lại KLOO',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brandOrange,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sân chơi của bạn',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Avatar người dùng (placeholder khi chưa login)
                            Container(
                              width: 52,
                              height: 52,
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
                        const SizedBox(height: 28),

                        // Email field
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Nhập email của bạn',
                          icon: Icons.email,
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Vui lòng nhập email';
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(val)) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _buildField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hint: '••••••',
                          icon: Icons.lock,
                          isPassword: true,
                          validator: (val) => (val?.isEmpty ?? true)
                              ? 'Vui lòng nhập mật khẩu'
                              : null,
                        ),

                        // Quên mật khẩu
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0),   // ← Điều chỉnh số này để di chuyển xuống
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
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppColors.brandOrange, 
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nút đăng nhập
                        SizedBox(
                          width: double.infinity,
                          height: 52,
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
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // or sign in with
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Chưa có tài khoản? ',
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
                                child: const Text(
                                  'Đăng ký',
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
                        const SizedBox(height: 16),

                        // Social buttons
                        SizedBox(
                          width: double.infinity,
                          height: 52,
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
                                  width: 26,
                                  height: 26,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF0D6331),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
