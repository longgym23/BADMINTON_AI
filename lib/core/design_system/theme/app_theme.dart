import 'package:flutter/material.dart';
import '../tokens/v_tokens.dart';

/// Design System Theme Manager for Badminton AI (KLOO).
///
/// Built entirely from [VColors] brand tokens — orange primary, not ERP blue.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: VColors.background,
      primaryColor: VColors.brandPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VColors.brandPrimary,
        primary: VColors.brandPrimary,
        secondary: VColors.brandPrimaryLight,
        surface: VColors.surface,
        error: VColors.statusCritical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: VColors.surface,
        foregroundColor: VColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: VColors.textPrimary),
        titleTextStyle: TextStyle(
          color: VColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.brandPrimary,
          foregroundColor: VColors.textOnBrand,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: VRadius.borderMd,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VColors.brandPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VSpacing.lg,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: VColors.textSubdued),
        border: OutlineInputBorder(
          borderRadius: VRadius.borderLg,
          borderSide: const BorderSide(color: VColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VRadius.borderLg,
          borderSide: const BorderSide(color: VColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VRadius.borderLg,
          borderSide: const BorderSide(color: VColors.brandPrimary),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
