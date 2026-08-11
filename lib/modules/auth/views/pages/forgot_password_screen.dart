import 'package:badminton_ai/modules/auth/views/pages/otp_verify_screen.dart';
import 'package:badminton_ai/core/services/password_reset_service.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/components/ui/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  static const _orange = Color(0xFFFF6B00);
  static const _inputBg = Color(0xFFF5F5F5);
  static const _hintColor = Color(0xFFAAAAAA);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textGray = Color(0xFF888888);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final error = await PasswordResetService.sendOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      AppToast.show(context, error, type: ToastType.error);
    } else {
      AppToast.show(
        context,
        'screens.oTPCodeHasBeenSentToYour'.tr(),
        type: ToastType.success,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpVerifyScreen(email: email)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageH = size.height * 0.32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // ── Ảnh nền phía trên ──
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

            // ── Nút back ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                style: IconButton.styleFrom(
                  // backgroundColor: Colors.white.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // ── Card trắng phía dưới ──
            Positioned(
              top: imageH - 28,
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
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon và tiêu đề
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: VColors.brandPrimarySubdued,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: _orange,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'screens.forgotPassword'.tr(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'screens.enterRegistrationEmailToRe'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: _textGray,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Label
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textGray,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'screens.enterYourEmail'.tr(),
                            hintStyle: const TextStyle(
                              color: _hintColor,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: _inputBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: _orange,
                              size: 20,
                            ),
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
                              borderSide: const BorderSide(
                                color: _orange,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'screens.pleaseEnterEmail'.tr();
                            }
                            if (!RegExp(
                              r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                            ).hasMatch(val)) {
                              return 'screens.invalidEmail'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Nút gửi OTP
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'screens.sendOTPCode'.tr(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quay lại đăng nhập
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: 'screens.rememberYourPassword'.tr(),
                                style: TextStyle(
                                  color: _textGray,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'screens.logIn'.tr(),
                                    style: TextStyle(
                                      color: _orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
