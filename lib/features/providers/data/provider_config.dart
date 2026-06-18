class ProviderConfigData {
  final String providerId;
  final String displayName;
  final String baseUrl;
  final String? defaultModel;
  final bool enabled;
  final DateTime updatedAt;

  const ProviderConfigData({
    required this.providerId,
    required this.displayName,
    required this.baseUrl,
    this.defaultModel,
    this.enabled = true,
    required this.updatedAt,
  });
}
