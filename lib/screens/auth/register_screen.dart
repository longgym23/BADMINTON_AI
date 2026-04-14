import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _orange = Color(0xFFE8722A);
  static const Color _inputBg = Color(0xFFF5F5F5);
  static const Color _hintColor = Color(0xFFAAAAAA);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF888888);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppToast.show(
          context,
          'Mật khẩu xác nhận không khớp.',
          type: ToastType.error,
        );
        return;
      }

      final authProvider = context.read<AppAuthProvider>();
      bool success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _displayNameController.text.trim(),
      );

      if (success && mounted) {
        AppToast.show(
          context,
          'Đăng ký thành công! Vui lòng kiểm tra email và đăng nhập.',
          type: ToastType.success,
        );
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        Navigator.pop(context);
      } else if (mounted) {
        AppToast.show(
          context,
          'Đăng ký thất bại. Email có thể đã tồn tại.',
          type: ToastType.error,
        );
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    String? Function(String?)? validator,
  }) {
    bool obscure = isPassword
        ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword)
        : false;

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
          obscureText: obscure,
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
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _hintColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        } else {
                          _obscurePassword = !_obscurePassword;
                        }
                      });
                    },
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
    final imageH = size.height * 0.30;

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
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: "Tạo tài khoản" + Avatar upload
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tạo tài khoản',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tham gia cộng đồng KLOO',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textGray,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Image.asset(
                                'assets/images/badminton-player.gif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Họ và tên
                        _buildField(
                          controller: _displayNameController,
                          label: 'Họ và tên',
                          hint: 'Nhập họ và tên',
                          icon: Icons.person_outline,
                          validator: (val) => (val?.isEmpty ?? true)
                              ? 'Vui lòng nhập họ và tên'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'example@email.com',
                          icon: Icons.email_outlined,
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
                        const SizedBox(height: 14),

                        // Mật khẩu
                        _buildField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hint: '••••••',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (val) =>
                              (val?.isEmpty ?? true) || ((val?.length ?? 0) < 6)
                              ? 'Mật khẩu ít nhất 6 ký tự'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Nhập lại mật khẩu
                        _buildField(
                          controller: _confirmPasswordController,
                          label: 'Xác nhận mật khẩu',
                          hint: '••••••',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isConfirmPassword: true,
                          validator: (val) => (val?.isEmpty ?? true)
                              ? 'Vui lòng xác nhận mật khẩu'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Nút đăng ký
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _register,
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
                                    'Đăng ký ngay',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Đã có tài khoản
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Đã có tài khoản? ',
                                style: TextStyle(
                                  color: _textGray,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Đăng nhập',
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
