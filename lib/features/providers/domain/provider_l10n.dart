import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/domain/provider_url_policy.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String localizedProviderName(
  BuildContext context,
  ProviderPreset preset,
) {
  final l10n = AppLocalizations.of(context)!;

  return switch (preset.id) {
    'openai' => 'OpenAI',
    'deepseek' => 'DeepSeek',
    'openrouter' => 'OpenRouter',
    'custom' => l10n.customProvider,
    _ => preset.name,
  };
}

String localizedProviderDescription(
  BuildContext context,
  ProviderPreset preset,
) {
  final l10n = AppLocalizations.of(context)!;

  return switch (preset.id) {
    'openai' => l10n.openAiDescription,
    'deepseek' => l10n.deepSeekDescription,
    'openrouter' => l10n.openRouterDescription,
    'custom' => l10n.customProviderDescription,
    _ => preset.description,
  };
}

String localizedProviderDisplayName(
  BuildContext context,
  ProviderPreset preset,
  String? savedDisplayName,
) {
  if (preset.isCustom) {
    return savedDisplayName ?? localizedProviderName(context, preset);
  }
  return localizedProviderName(context, preset);
}

String localizedConnectionError(
  AppLocalizations l10n,
  String? errorType,
) {
  return switch (errorType) {
    'unauthorized' => l10n.invalidApiKey,
    'forbidden' => l10n.accessForbidden,
    'rateLimited' => l10n.rateLimitExceeded,
    'timeout' => l10n.connectionTimedOut,
    'networkUnavailable' => l10n.networkUnavailable,
    'serverError' => l10n.providerServerError,
    'invalidUrl' => l10n.invalidBaseUrl,
    'invalidResponse' => l10n.invalidProviderResponse,
    _ => l10n.unableToConnect,
  };
}

String localizedUrlValidationError(
  AppLocalizations l10n,
  UrlValidationError error,
) {
  return switch (error) {
    UrlValidationError.empty => l10n.invalidBaseUrl,
    UrlValidationError.invalidFormat => l10n.invalidBaseUrl,
    UrlValidationError.httpsOnly => l10n.httpsOnly,
    UrlValidationError.userInfoNotAllowed => l10n.invalidBaseUrl,
    UrlValidationError.missingHost => l10n.invalidBaseUrl,
  };
}
