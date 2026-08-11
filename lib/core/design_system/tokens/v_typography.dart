import 'package:flutter/material.dart';

import 'v_colors.dart';

/// Typography tokens (Polaris-style file: type scale only).
class VTypography {
  VTypography._();

  static const TextStyle headingLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: VColors.textPrimary,
  );
  static const TextStyle headingMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VColors.textPrimary,
  );
  static const TextStyle headingSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VColors.textPrimary,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    color: VColors.textPrimary,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    color: VColors.textPrimary,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    color: VColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: VColors.textSubdued,
  );
}
