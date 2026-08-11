import 'package:flutter/material.dart';
import 'package:badminton_ai/core/design_system/tokens/v_colors.dart';

/// Legacy color facade — delegates to [VColors] (KLOO brand tokens).
/// Prefer importing `package:badminton_ai/core/design_system/design_system.dart`
/// and using [VColors] directly in new code.
class AppColors {
  AppColors._();

  static const Color primary = VColors.brandPrimary;
  static const Color primaryDark = VColors.brandPrimaryDark;
  static const Color primaryLight = VColors.brandPrimaryLight;
  static const Color primaryBg = VColors.brandPrimarySubdued;

  static const Color brandOrange = VColors.brandPrimary;
  static const Color brandOrangeLight = VColors.brandPrimaryLight;
  static const Color brandOrangeDark = VColors.brandPrimaryDark;

  static const Color success = VColors.statusSuccess;
  static const Color successBg = VColors.statusSuccessSubdued;

  static const Color error = VColors.statusCritical;
  static const Color errorBg = VColors.statusCriticalSubdued;

  static const Color warning = VColors.statusWarning;
  static const Color warningBg = VColors.statusWarningSubdued;

  static const Color textBlack = VColors.textPrimary;
  static const Color textGrey = VColors.textSecondary;
  static const Color textLight = VColors.textSubdued;
  static const Color borderColor = VColors.borderDefault;

  static const Color background = VColors.background;
  static const Color surface = VColors.surface;

  static const Color courtLocked = VColors.courtLocked;
  static const Color courtEvent = VColors.courtEvent;
  static const Color darkHeader = VColors.darkHeader;

  static const Color brandDarkBlue = VColors.brandNavy;
}
