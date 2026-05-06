import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _kLangKey = 'app_language_code';

  Locale _locale = const Locale('vi');
  Locale get locale => _locale;

  bool get isVietnamese => _locale.languageCode == 'vi';

  LanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey) ?? 'vi';
    _locale = code == 'en' ? const Locale('en') : const Locale('vi');
    notifyListeners();
  }

  /// Đổi ngôn ngữ: cập nhật ngay + lưu vào storage
  Future<void> setLocale(BuildContext context, Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;

    // 1. notifyListeners TRƯỚC → Consumer<LanguageProvider> rebuild MaterialApp với key mới
    //    → Flutter destroy & recreate toàn bộ widget tree (tất cả tab, route)
    notifyListeners();

    // 2. Cập nhật EasyLocalization để .tr() trả về đúng ngôn ngữ
    if (context.mounted) {
      await context.setLocale(locale);
    }

    // 3. Lưu xuống SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, locale.languageCode);
  }

  Future<void> setVietnamese(BuildContext context) =>
      setLocale(context, const Locale('vi'));

  Future<void> setEnglish(BuildContext context) =>
      setLocale(context, const Locale('en'));
}
