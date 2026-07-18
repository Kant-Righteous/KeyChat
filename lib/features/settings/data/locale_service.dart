import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'keychat.settings.locale';
  static const Locale _defaultLocale = Locale('zh');

  Future<Locale> loadLocale() async {
    try {
      final prefs = await SharedPreferencesAsync().getString(_localeKey);
      if (prefs == null || prefs.isEmpty) {
        return _defaultLocale;
      }
      final locale = Locale(prefs);
      if (_isValidLocale(locale)) {
        return locale;
      }
      return _defaultLocale;
    } catch (_) {
      return _defaultLocale;
    }
  }

  Future<bool> saveLocale(Locale locale) async {
    if (!_isValidLocale(locale)) {
      return false;
    }
    try {
      await SharedPreferencesAsync().setString(_localeKey, locale.languageCode);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isValidLocale(Locale locale) {
    return locale.languageCode == 'zh' || locale.languageCode == 'en';
  }

  Locale get defaultLocale => _defaultLocale;
}
