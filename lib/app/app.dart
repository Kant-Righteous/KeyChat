import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:keychat/app/app_shell.dart';
import 'package:keychat/features/settings/data/locale_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class KeyChatApp extends StatefulWidget {
  final LocaleService? localeService;

  const KeyChatApp({super.key, this.localeService});

  @override
  State<KeyChatApp> createState() => _KeyChatAppState();
}

class _KeyChatAppState extends State<KeyChatApp> {
  late final LocaleService _localeService;
  Locale? _locale;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _localeService = widget.localeService ?? LocaleService();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final locale = await _localeService.loadLocale();
      if (mounted) {
        setState(() {
          _locale = locale;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locale = const Locale('zh');
          _loading = false;
        });
      }
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
      return MaterialApp(
        locale: const Locale('zh'),
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
        home: const _SplashScreen(),
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'KeyChat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.initializing ?? '正在初始化…',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
