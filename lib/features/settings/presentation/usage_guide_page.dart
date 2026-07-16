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
          _buildDeepSeekExample(context, l10n, theme),
          const SizedBox(height: 16),
          _buildMimoExample(context, l10n, theme),
          const SizedBox(height: 16),
          _buildCustomProvider(context, l10n, theme),
          const SizedBox(height: 16),
          _buildAgentGuide(context, l10n, theme),
          const SizedBox(height: 16),
          _buildFAQ(context, l10n, theme),
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
            _buildFieldGuide(l10n.providerNameGuideTitle,
                l10n.providerNameGuideContent, theme),
            const Divider(height: 24),
            _buildFieldGuide(
                l10n.baseUrlGuideTitle, l10n.baseUrlGuideContent, theme),
            const Divider(height: 24),
            _buildFieldGuide(
                l10n.apiKeyGuideTitle, l10n.apiKeyGuideContent, theme),
            const Divider(height: 24),
            _buildFieldGuide(l10n.defaultModelGuideTitle,
                l10n.defaultModelGuideContent, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGuide(String title, String content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(content),
      ],
    );
  }

  Widget _buildDeepSeekExample(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deepSeekExampleTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildExampleField(l10n.configurationMethod, l10n.builtInProvider),
            _buildExampleField(l10n.providerNameLabel, 'DeepSeek'),
            _buildExampleField(l10n.baseUrlLabel, 'https://api.deepseek.com'),
            _buildExampleField(l10n.apiKeyLabel, l10n.deepSeekApiKeyHint),
            _buildExampleField(
                l10n.defaultModelLabel, 'deepseek-v4-flash, deepseek-v4-pro'),
            const SizedBox(height: 8),
            Text(l10n.modelNameMayChange),
            const SizedBox(height: 8),
            Text(l10n.doNotAppendChatCompletions),
          ],
        ),
      ),
    );
  }

  Widget _buildMimoExample(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.mimoExampleTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(l10n.mimoRequiresCustomProvider),
            ),
            const SizedBox(height: 16),
            Text(l10n.mimoPayAsYouGoTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildExampleField(l10n.configurationMethod, l10n.customProvider),
            _buildExampleField(l10n.providerNameLabel, 'Xiaomi MiMo'),
            _buildExampleField(
                l10n.baseUrlLabel, 'https://api.xiaomimimo.com/v1'),
            _buildExampleField(l10n.apiKeyLabel, 'sk-••••••••'),
            _buildExampleField(
                l10n.defaultModelLabel, 'mimo-v2.5-pro, mimo-v2.5'),
            const SizedBox(height: 8),
            Text(l10n.doNotAppendChatCompletions),
            const SizedBox(height: 8),
            Text(l10n.modelNameMayChange),
            const SizedBox(height: 8),
            Text(l10n.mimoPayAsYouGoKeyWarning),
            const Divider(height: 24),
            Text(l10n.mimoTokenPlanTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildExampleField(l10n.configurationMethod, l10n.customProvider),
            _buildExampleField(l10n.providerNameLabel, 'MiMo Token Plan'),
            _buildExampleField(l10n.baseUrlLabel, l10n.mimoTokenPlanUrlHint),
            _buildExampleField(l10n.baseUrlExampleLabel,
                'https://token-plan-cn.xiaomimimo.com/v1'),
            _buildExampleField(l10n.apiKeyLabel, 'tp-••••••••'),
            _buildExampleField(l10n.defaultModelLabel, 'mimo-v2.5-pro'),
            const SizedBox(height: 8),
            Text(l10n.mimoTokenPlanWarning),
            const SizedBox(height: 8),
            Text(l10n.mimoTokenPlanRegionHint),
            const SizedBox(height: 8),
            Text(l10n.mimoOpenAiCompatibleAddressHint),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label：',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCustomProvider(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customProviderGuideTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.customProviderGuideContent),
            const SizedBox(height: 8),
            Text(l10n.mimoCustomProviderNote),
            const SizedBox(height: 8),
            Text(l10n.customProviderCompatibilityWarning),
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
            Text(l10n.agentGuideContent),
            const SizedBox(height: 8),
            Text(l10n.agentGuideExample),
            const SizedBox(height: 8),
            Text(l10n.agentGuideNote),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.frequentlyAskedQuestionsTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildFAQItem(l10n.noAvailableModelsQuestion,
                l10n.noAvailableModelsAnswer, theme),
            _buildFAQItem(l10n.connectionTestFailedQuestion,
                l10n.connectionTestFailedAnswer, theme),
            _buildFAQItem(
                l10n.invalidApiKeyQuestion, l10n.invalidApiKeyAnswer, theme),
            _buildFAQItem(l10n.modelAccessDeniedQuestion,
                l10n.modelAccessDeniedAnswer, theme),
            _buildFAQItem(l10n.rateLimitQuestion, l10n.rateLimitAnswer, theme),
            _buildFAQItem(
                l10n.httpsRequiredQuestion, l10n.httpsRequiredAnswer, theme),
            _buildFAQItem(l10n.mimoConnectionFailedQuestion,
                l10n.mimoConnectionFailedAnswer, theme),
            _buildFAQItem(l10n.mimoNoDedicatedProviderQuestion,
                l10n.mimoNoDedicatedProviderAnswer, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, ThemeData theme) {
    return ExpansionTile(
      title: Text(question, style: theme.textTheme.titleSmall),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
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
