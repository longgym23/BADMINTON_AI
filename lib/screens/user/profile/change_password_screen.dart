import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/widgets/app_toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AppAuthProvider>().updatePassword(
          _newPasswordController.text,
        );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        AppToast.show(context, 'Đổi mật khẩu thành công!', type: ToastType.success);
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        AppToast.show(context, 'Lỗi khi đổi mật khẩu. Chỉ có thể đổi với tài khoản Email/Password trực tiếp.', type: ToastType.error);
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const Text(
                'Lưu ý: Tính năng đổi mật khẩu chỉ áp dụng cho tài khoản đăng ký bằng Email và Mật khẩu.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              // Mật khẩu mới
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (value.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Xác nhận mật khẩu mới
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                  if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Xác nhận đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
