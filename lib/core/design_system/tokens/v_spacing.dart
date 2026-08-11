/// Spacing scale (Polaris-style file: spacing only).
///
/// Prefer [VGap] / [VSpacing] over raw `SizedBox` / `EdgeInsets.all(16)`.
class VSpacing {
  VSpacing._();

  // Polaris-like numbered scale
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  // Semantic aliases used across the app
  static const double xs = space1;
  static const double sm = space2;
  static const double md = space3;
  static const double lg = space4;
  static const double xl = space6;
  static const double xxl = space8;

  static const double screenMobile = space4;
  static const double minTouchTarget = 44;
}
