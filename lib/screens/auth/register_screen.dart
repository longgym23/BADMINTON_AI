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
        AppToast.show(context, 'Mật khẩu xác nhận không khớp.', type: ToastType.error);
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
          'Đăng ký thất bại. Email có thể đã tồn tại hoặc có lỗi khác.',
          type: ToastType.error,
        );
      }
    }
  }

  // --- UI THEME COLORS ---
  final Color _primaryGreen = const Color(0xFF006436); // Màu xanh lá sậm của Button/Text
  final Color _grayBorder = const Color(0xFFE0E0E0);
  final Color _hintTextColor = const Color(0xFF9E9E9E);

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: _primaryGreen,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool isConfirmPassword = false,
    String? Function(String?)? validator,
    Widget? customSuffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword) : false,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _hintTextColor, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _grayBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        suffixIcon: customSuffix ?? (isPassword
            ? IconButton(
                icon: Icon(
                  isConfirmPassword
                      ? (_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility)
                      : (_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  color: _primaryGreen,
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
            : IconButton(
                icon: Icon(Icons.cancel, color: _primaryGreen, size: 20),
                onPressed: () => controller.clear(),
              )),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng ký',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'lexend',
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background Layer (Gradient màu Cam)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD66A2C), // Cam đậm
                      const Color(0xFFB14E18), // Nâu cam
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            
            // Texture vòng cung giả lập vệt sóng
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 40),
                ),
              ),
            ),
            
            // Nội dung Form trắng
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          // LƯU Ý: Yêu cầu xoá nhập Số điện thoại đã được thực hiện
                          // 1. Email Field
                          _buildLabel('Email của bạn?'),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Nhập email của bạn',
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Vui lòng nhập email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // 2. Tên đầy đủ
                          _buildLabel('Tên đầy đủ (*)'),
                          _buildTextField(
                            controller: _displayNameController,
                            hint: 'Nhập họ và tên',
                            validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng nhập tên' : null,
                          ),
                          const SizedBox(height: 20),

                          // 3. Mật khẩu
                          _buildLabel('Mật khẩu (*)'),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Nhập mật khẩu (*)',
                            isPassword: true,
                            validator: (val) => (val?.isEmpty ?? true) || ((val?.length ?? 0) < 6)
                                ? 'Mật khẩu ít nhất 6 ký tự'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // 4. Nhập lại mật khẩu
                          _buildLabel('Nhập mật khẩu'),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: 'Nhập lại mật khẩu',
                            isPassword: true,
                            isConfirmPassword: true,
                            validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng xác nhận mật khẩu' : null,
                          ),
                          const SizedBox(height: 32),

                          // Nút Đăng Ký
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authProvider.authState == AuthState.loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: authProvider.authState == AuthState.loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'ĐĂNG KÝ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Đăng nhập Footer
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Bạn đã có tài khoản? ',
                                  style: TextStyle(color: Colors.black87, fontSize: 13),
                                ),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      color: _primaryGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

