import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UsageGuidePage extends StatelessWidget {
  const UsageGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usageGuideTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickStart(context, l10n, theme),
          const SizedBox(height: 16),
          _buildProviderFields(context, l10n, theme),
          const SizedBox(height: 16),
          _buildAgentGuide(context, l10n, theme),
          const SizedBox(height: 16),
          _buildSecurityTips(context, l10n, theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickStart(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickStartTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.quickStartContent),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderFields(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.providerFieldsTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.providerSetupSummary),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentGuide(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.agentGuideTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.chatAndAgentsContent),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTips(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.securityTipsTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.securityTipsContent),
          ],
        ),
      ),
    );
  }
}
