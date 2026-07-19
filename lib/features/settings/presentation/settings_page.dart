import 'package:flutter/material.dart';
import 'package:keychat/features/settings/presentation/language_page.dart';
import 'package:keychat/features/settings/presentation/usage_guide_page.dart';
import 'package:keychat/features/settings/presentation/about_page.dart';
import 'package:keychat/l10n/generated/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;

  const SettingsPage({super.key, required this.onLocaleChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LanguagePage(onLocaleChanged: onLocaleChanged),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(l10n.usageGuide),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsageGuidePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.aboutKeyChat),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
