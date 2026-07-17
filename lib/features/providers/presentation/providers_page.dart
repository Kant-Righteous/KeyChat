import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/domain/provider_url_policy.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProvidersPage extends StatefulWidget {
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ModelAttachmentCapabilityStore? modelAttachmentCapabilityStore;
  final ConnectionTesterResolver? connectionTesterResolver;

  const ProvidersPage({
    super.key,
    required this.apiKeyStore,
    required this.configStore,
    this.modelAttachmentCapabilityStore,
    this.connectionTesterResolver,
  });

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  List<ProviderConfigData> _configs = [];
  final Map<String, bool> _keyStatus = {};
  final Map<String, bool> _httpsStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final configs = await widget.configStore.readAllConfigs();
    final keyStatuses = <String, bool>{};
    final httpsStatuses = <String, bool>{};

    for (final config in configs) {
      keyStatuses[config.providerId] =
          await widget.apiKeyStore.hasKey(config.providerId);
      httpsStatuses[config.providerId] =
          ProviderUrlPolicy.isHttps(config.baseUrl);
    }

    if (mounted) {
      setState(() {
        _configs = configs;
        _keyStatus.clear();
        _keyStatus.addAll(keyStatuses);
        _httpsStatus.clear();
        _httpsStatus.addAll(httpsStatuses);
        _loading = false;
      });
    }
  }

  Future<void> _openConfig(ProviderPreset preset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderConfigPage(
          preset: preset,
          apiKeyStore: widget.apiKeyStore,
          configStore: widget.configStore,
          modelAttachmentCapabilityStore: widget.modelAttachmentCapabilityStore,
          connectionTesterResolver: widget.connectionTesterResolver,
        ),
      ),
    );
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providers),
      ),
      body: _loading
          ? Center(child: Text(l10n.loading))
          : ListView.builder(
              itemCount: _configs.length + 1,
              itemBuilder: (context, index) {
                if (index == _configs.length) {
                  return ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(l10n.addCustomProvider),
                    subtitle: Text(l10n.customProviderDescription),
                    onTap: () {
                      final preset = ProviderPreset(
                        id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
                        name: l10n.customProvider,
                        description: l10n.customProviderDescription,
                        defaultBaseUrl: '',
                        isCustom: true,
                        protocol: providerPresets.last.protocol,
                      );
                      _openConfig(preset);
                    },
                  );
                }

                final config = _configs[index];
                final hasKey = _keyStatus[config.providerId] ?? false;
                final isHttps = _httpsStatus[config.providerId] ?? true;
                final hasRequiredConfig = config.enabled &&
                    config.baseUrl.trim().isNotEmpty &&
                    config.defaultModel?.trim().isNotEmpty == true;
                final configured = hasKey && hasRequiredConfig && isHttps;
                final needsHttpsUpdate = hasKey && !isHttps;

                String statusText;
                Color statusColor;
                if (needsHttpsUpdate) {
                  statusText = l10n.httpsUpdateRequired;
                  statusColor = Colors.orange;
                } else if (configured) {
                  statusText = l10n.providerConfigured;
                  statusColor = Colors.green;
                } else {
                  statusText = l10n.providerNotConfigured;
                  statusColor = Colors.grey;
                }

                return ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(config.displayName),
                  subtitle: Text(config.baseUrl),
                  trailing: Text(
                    statusText,
                    style: TextStyle(color: statusColor),
                  ),
                  onTap: () {
                    final preset = ProviderPreset(
                      id: config.providerId,
                      name: config.displayName,
                      description: config.baseUrl,
                      defaultBaseUrl: config.baseUrl,
                      isCustom: true,
                      protocol: config.protocol,
                    );
                    _openConfig(preset);
                  },
                );
              },
            ),
    );
  }
}
