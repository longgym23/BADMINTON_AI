
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/widgets/loading_spinner.dart';
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

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mật khẩu xác nhận không khớp.')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Quay lại màn hình đăng nhập
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại. Email có thể đã tồn tại hoặc có lỗi khác.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký tài khoản')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
                  ),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                  validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng nhập tên hiển thị' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.secondary),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                  validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng nhập email' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.secondary),
                  ),
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                  validator: (val) => (val?.isEmpty ?? true) || ((val?.length ?? 0) < 6)
                      ? 'Mật khẩu phải có ít nhất 6 ký tự'
                      : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: Icon(Icons.lock_reset, color: Theme.of(context).colorScheme.secondary),
                  ),
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                  validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng xác nhận mật khẩu' : null,
                ),
                SizedBox(height: 25),
                if (authProvider.authState == AuthState.loading)
                  LoadingSpinner(message: "Đang đăng ký...")
                else
                  ElevatedButton(
                    onPressed: _register,
                    child: Text('Đăng ký'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 55),
                    ),
                  ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Quay lại màn hình đăng nhập
                  },
                  child: Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
