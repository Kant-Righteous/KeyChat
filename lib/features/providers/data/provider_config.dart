import 'package:keychat/features/providers/domain/provider_protocol.dart';

class ProviderConfigData {
  final String providerId;
  final String displayName;
  final String baseUrl;
  final String? defaultModel;
  final bool enabled;
  final DateTime updatedAt;
  final ProviderProtocol protocol;

  const ProviderConfigData({
    required this.providerId,
    required this.displayName,
    required this.baseUrl,
    required this.protocol,
    this.defaultModel,
    this.enabled = true,
    required this.updatedAt,
  });
}
