import 'package:badminton_ai/core/services/password_reset_service.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/components/ui/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const _orange = Color(0xFFFF6B00);
  static const _inputBg = Color(0xFFF5F5F5);
  static const _hintColor = Color(0xFFAAAAAA);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textGray = Color(0xFF888888);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final error = await PasswordResetService.resetPassword(
      email: widget.email,
      resetToken: widget.resetToken,
      newPassword: _newPasswordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      AppToast.show(context, error, type: ToastType.error);
    } else {
      AppToast.show(
        context,
        'screens.passwordResetSuccessful'.tr(),
        type: ToastType.success,
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      // Xóa toàn bộ stack navigation, về Login
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
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
          obscureText: obscure,
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
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: _orange,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _hintColor,
                size: 20,
              ),
              onPressed: onToggle,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),

                  // Nút back
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFFF5F5F5),
                      foregroundColor: _textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: VColors.brandPrimarySubdued,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: VColors.brandPrimary,
                      size: 34,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tiêu đề
                  Text('screens.setANewPassword'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('screens.theNewPasswordMustBeDiffe'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _textGray,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 36),

                  // Mật khẩu mới
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'screens.newPassword'.tr(),
                    hint: '••••••••',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'screens.pleaseEnterANewPassword'.tr();
                      }
                      if (val.length < 6) {
                        return 'screens.passwordMustHaveAtLeast6'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Xác nhận mật khẩu
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'screens.confirmPassword'.tr(),
                    hint: '••••••••',
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'screens.pleaseConfirmYourPassword'.tr();
                      }
                      if (val != _newPasswordController.text) {
                        return 'screens.confirmationPasswordDoesNot1'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 36),

                  // Nút đặt lại mật khẩu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('screens.resetPassword'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Strength indicators
                  _buildPasswordStrengthHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthHint() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _newPasswordController,
      builder: (_, value, __) {
        final password = value.text;
        if (password.isEmpty) return SizedBox.shrink();

        final hasLength = password.length >= 6;
        final hasUpper = password.contains(RegExp(r'[A-Z]'));
        final hasNumber = password.contains(RegExp(r'[0-9]'));

        return Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('screens.passwordStrength'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textGray,
                ),
              ),
              SizedBox(height: 8),
              _buildHintRow('screens.atLeast6Characters'.tr(), hasLength),
              SizedBox(height: 4),
              _buildHintRow('screens.withUppercaseLettersAZ'.tr(), hasUpper),
              SizedBox(height: 4),
              _buildHintRow('screens.hasDigits09'.tr(), hasNumber),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintRow(String label, bool satisfied) {
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: satisfied ? VColors.statusSuccess : _hintColor,
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: satisfied ? VColors.statusSuccess : _textGray,
          ),
        ),
      ],
    );
  }
}
