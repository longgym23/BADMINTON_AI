import 'package:flutter/material.dart';

/// KLOO brand + semantic color tokens (Polaris-style design system).
class VColors {
  VColors._();

  // ── Brand (KLOO Orange) ─────────────────────────────────────────────
  static const Color brandPrimary = Color(0xFFE8722A);
  static const Color brandPrimaryLight = Color(0xFFFFB347);
  static const Color brandPrimaryDark = Color(0xFFFF5722);
  static const Color brandPrimarySubdued = Color(0xFFFFF3ED);
  static const Color brandNavy = Color(0xFF0A1931);

  static const Color brandOrange = brandPrimary;
  static const Color brandOrangeLight = brandPrimaryLight;
  static const Color brandOrangeDark = brandPrimaryDark;

  // ── Welcome & Onboarding Semantics ──────────────────────────────────
  static const Color welcomeAccent = Color(0xFFE8722A);
  static const Color welcomeAccentSubdued = Color(0xFFFFF3ED);
  static const Color welcomeBackground = Color(0xFFFCFAF8);
  static const Color welcomeCardSecondary = Color(0xFFEFE8E3);

  // ── Surfaces ────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFCFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfacePrimary = background;
  static const Color surfaceSecondary = brandPrimarySubdued;
  static const Color surfaceCard = surface;

  static const Color appBackground = background;
  static const Color appSurface = surface;

  // ── Text ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textSubdued = Color(0xFF9E9E9E);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  static const Color appTextPrimary = textPrimary;
  static const Color appTextSecondary = textSecondary;
  static const Color appTextSubdued = textSubdued;

  // ── Border ──────────────────────────────────────────────────────────
  static const Color borderDefault = Color(0xFFEEEEEE);
  static const Color borderSubdued = Color(0xFFF5F5F5);
  static const Color appBorder = borderDefault;

  // ── Status ──────────────────────────────────────────────────────────
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusSuccessSubdued = Color(0xFFE8F5E9);
  static const Color statusWarning = Color(0xFFFF5722);
  static const Color statusWarningSubdued = Color(0xFFFFF3ED);
  static const Color statusCritical = Color(0xFFE63946);
  static const Color statusCriticalSubdued = Color(0xFFFFEBEE);

  static const Color appSuccess = statusSuccess;
  static const Color appSuccessSubdued = statusSuccessSubdued;
  static const Color appWarning = statusWarning;
  static const Color appWarningSubdued = statusWarningSubdued;
  static const Color appError = statusCritical;
  static const Color appErrorSubdued = statusCriticalSubdued;

  // ── Domain (booking grid) ───────────────────────────────────────────
  static const Color courtAvailable = statusSuccess;
  static const Color courtLocked = textSubdued;
  static const Color courtEvent = statusWarning;
  static const Color darkHeader = textPrimary;
}
