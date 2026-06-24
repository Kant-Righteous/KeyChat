import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguagePage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;

  const LanguagePage({super.key, required this.onLocaleChanged});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSettings),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text(l10n.chinese),
            value: 'zh',
            groupValue: currentLocale.languageCode,
            onChanged: _saving
                ? null
                : (value) async {
                    if (value != null) {
                      setState(() => _saving = true);
                      widget.onLocaleChanged(Locale(value));
                      if (mounted) {
                        setState(() => _saving = false);
                      }
                    }
                  },
          ),
          RadioListTile<String>(
            title: Text(l10n.english),
            value: 'en',
            groupValue: currentLocale.languageCode,
            onChanged: _saving
                ? null
                : (value) async {
                    if (value != null) {
                      setState(() => _saving = true);
                      widget.onLocaleChanged(Locale(value));
                      if (mounted) {
                        setState(() => _saving = false);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}
