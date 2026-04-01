import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _kLangKey = 'app_language_code';

  Locale _locale = const Locale('vi', 'VN');
  Locale get locale => _locale;

  bool get isVietnamese => _locale.languageCode == 'vi';

  LanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey) ?? 'vi';
    _locale = code == 'en' ? const Locale('en', 'US') : const Locale('vi', 'VN');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, locale.languageCode);
  }

  void setVietnamese() => setLocale(const Locale('vi', 'VN'));
  void setEnglish() => setLocale(const Locale('en', 'US'));
}
