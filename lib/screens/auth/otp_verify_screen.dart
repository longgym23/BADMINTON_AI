import 'dart:async';
import 'package:badminton_ai/screens/auth/reset_password_screen.dart';
import 'package:badminton_ai/services/password_reset_service.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const int _otpLength = 6;
  static const int _countdownSeconds = 60;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;
  int _countdown = _countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Focus ô đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _countdownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < _otpLength) {
      AppToast.show(
        context,
        'Vui lòng nhập đủ 6 chữ số OTP',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isVerifying = true);

    final result = await PasswordResetService.verifyOtp(widget.email, otp);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.error != null) {
      AppToast.show(context, result.error!, type: ToastType.error);
    } else {
      AppToast.show(
        context,
        'Xác thực thành công!',
        type: ToastType.success,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            resetToken: result.resetToken!,
          ),
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0 || _isResending) return;
    setState(() => _isResending = true);

    final error = await PasswordResetService.sendOtp(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      AppToast.show(context, error, type: ToastType.error);
    } else {
      // Xóa các ô OTP
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      _startCountdown();
      AppToast.show(
        context,
        'Đã gửi lại mã OTP!',
        type: ToastType.success,
      );
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          counterText: '',
          filled: true,
          fillColor: _controllers[index].text.isNotEmpty
              ? AppColors.primaryBg
              : const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _controllers[index].text.isNotEmpty
                  ? AppColors.brandOrange
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.brandOrange,
              width: 2,
            ),
          ),
        ),
        onChanged: (val) {
          setState(() {}); // rebuild để cập nhật màu fill
          if (val.isNotEmpty && index < _otpLength - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Tự động xác thực khi điền đủ 6 số
          if (_otpValue.length == _otpLength) {
            _verifyOtp();
          }
        },
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Nút back
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.brandOrange,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                const Text(
                  'Nhập mã OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Mã OTP 6 số đã được gửi đến\n'),
                      TextSpan(
                        text: maskedEmail,
                        style: const TextStyle(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 6 ô OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _otpLength,
                    (i) => _buildOtpBox(i),
                  ),
                ),
                const SizedBox(height: 40),

                // Nút xác nhận
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Xác nhận OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Gửi lại OTP
                Center(
                  child: _countdown > 0
                      ? RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                            ),
                            children: [
                              const TextSpan(text: 'Gửi lại mã sau '),
                              TextSpan(
                                text: '${_countdown}s',
                                style: const TextStyle(
                                  color: AppColors.brandOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: _isResending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandOrange,
                                  ),
                                )
                              : const Text(
                                  'Gửi lại mã OTP',
                                  style: TextStyle(
                                    color: AppColors.brandOrange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.brandOrange,
                                  ),
                                ),
                        ),
                ),
                const SizedBox(height: 12),

                // Hint
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.brandOrange,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Kiểm tra hộp thư spam nếu không thấy email trong hộp thư đến.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                            height: 1.4,
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
    );
  }

  /// Che giấu email: abc***@gmail.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 3) return '***@$domain';
    return '${local.substring(0, 3)}***@$domain';
  }
}
