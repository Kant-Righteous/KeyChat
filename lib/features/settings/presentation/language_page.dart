import 'package:flutter/material.dart';
import 'package:keychat/l10n/generated/app_localizations.dart';

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
      body: RadioGroup<String>(
        groupValue: currentLocale.languageCode,
        onChanged: (value) async {
          if (value == null || _saving) return;

          setState(() => _saving = true);
          widget.onLocaleChanged(Locale(value));
          if (mounted) {
            setState(() => _saving = false);
          }
        },
        child: ListView(
          children: [
            RadioListTile<String>(
              title: Text(l10n.chinese),
              value: 'zh',
              enabled: !_saving,
            ),
            RadioListTile<String>(
              title: Text(l10n.english),
              value: 'en',
              enabled: !_saving,
            ),
          ],
        ),
      ),
    );
  }
}
