import 'package:flutter/material.dart';
import 'package:keychat/features/settings/data/locale_service.dart';

class FakeLocaleService implements LocaleService {
  final Locale? _initialLocale;
  final bool _shouldFail;
  int loadCallCount = 0;

  FakeLocaleService({
    Locale? initialLocale,
    bool shouldFail = false,
  })  : _initialLocale = initialLocale,
        _shouldFail = shouldFail;

  @override
  Future<Locale> loadLocale() async {
    loadCallCount++;
    if (_shouldFail) {
      throw Exception('Failed to load locale');
    }
    return _initialLocale ?? const Locale('zh');
  }

  @override
  Future<bool> saveLocale(Locale locale) async {
    if (_shouldFail) return false;
    return true;
  }

  @override
  Locale get defaultLocale => const Locale('zh');
}
