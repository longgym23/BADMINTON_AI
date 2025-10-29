
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/auth/register_screen.dart';
import 'package:badminton_ai/widgets/loading_spinner.dart';
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

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AppAuthProvider>();
      bool success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // Nếu thành công, SplashScreen sẽ tự động điều hướng
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Đăng nhập')),
      body: Center(
        child: SingleChildScrollView( // Sử dụng SingleChildScrollView để tránh overflow khi bàn phím hiện lên
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo của bạn
                Image.asset(
                  'assets/images/badminton_logo.jpg', // Thay bằng đường dẫn đến logo của bạn
                  height: 120,
                ),
                SizedBox(height: 30),
                Text(
                  'Chào mừng bạn đến với Badminton Pro!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // Màu chữ trắng
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.secondary), // Icon màu xanh
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: Theme.of(context).primaryColor), // Màu chữ trong input
                  validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng nhập email' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.secondary), // Icon màu xanh
                  ),
                  obscureText: true,
                  style: TextStyle(color: Theme.of(context).primaryColor), // Màu chữ trong input
                  validator: (val) => (val?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu' : null,
                ),
                SizedBox(height: 25),
                if (authProvider.authState == AuthState.loading)
                  LoadingSpinner(message: "Đang đăng nhập...") // Sử dụng LoadingSpinner
                else
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Đăng nhập'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 55), // Nút to hơn
                    ),
                  ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                  },
                  child: Text('Chưa có tài khoản? Đăng ký ngay'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

