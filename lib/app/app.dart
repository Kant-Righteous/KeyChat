import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:keychat/app/app_shell.dart';
import 'package:keychat/features/settings/data/locale_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class KeyChatApp extends StatefulWidget {
  const KeyChatApp({super.key});

  @override
  State<KeyChatApp> createState() => _KeyChatAppState();
}

class _KeyChatAppState extends State<KeyChatApp> {
  final LocaleService _localeService = LocaleService();
  Locale? _locale;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await _localeService.loadLocale();
    if (mounted) {
      setState(() {
        _locale = locale;
        _loading = false;
      });
    }
  }

  void _onLocaleChanged(Locale locale) async {
    final success = await _localeService.saveLocale(locale);
    if (success && mounted) {
      setState(() {
        _locale = locale;
      });
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save language settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'KeyChat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      home: AppShell(onLocaleChanged: _onLocaleChanged),
    );
  }
}
