import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/domain/provider_url_policy.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProvidersPage extends StatefulWidget {
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ConnectionTesterResolver? connectionTesterResolver;

  const ProvidersPage({
    super.key,
    required this.apiKeyStore,
    required this.configStore,
    this.connectionTesterResolver,
  });

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final Map<String, bool> _keyStatus = {};
  final Map<String, String> _displayNames = {};
  final Map<String, bool> _httpsStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final keyStatuses = <String, bool>{};
    final displayNames = <String, String>{};
    final httpsStatuses = <String, bool>{};

    for (final preset in providerPresets) {
      keyStatuses[preset.id] = await widget.apiKeyStore.hasKey(preset.id);
      final config = await widget.configStore.readConfig(preset.id);
      displayNames[preset.id] = config?.displayName ?? preset.name;
      httpsStatuses[preset.id] =
          config == null || ProviderUrlPolicy.isHttps(config.baseUrl);
    }

    if (mounted) {
      setState(() {
        _keyStatus.clear();
        _keyStatus.addAll(keyStatuses);
        _displayNames.clear();
        _displayNames.addAll(displayNames);
        _httpsStatus.clear();
        _httpsStatus.addAll(httpsStatuses);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providers),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: providerPresets.length,
              itemBuilder: (context, index) {
                final preset = providerPresets[index];
                final configured = _keyStatus[preset.id] ?? false;
                final displayName = _displayNames[preset.id] ?? preset.name;
                final isHttps = _httpsStatus[preset.id] ?? true;
                final needsHttpsUpdate = configured && !isHttps;

                String statusText;
                Color statusColor;
                if (needsHttpsUpdate) {
                  statusText = 'Update to HTTPS required';
                  statusColor = Colors.orange;
                } else if (configured) {
                  statusText = 'Configured';
                  statusColor = Colors.green;
                } else {
                  statusText = 'Not configured';
                  statusColor = Colors.grey;
                }

                return ListTile(
                  leading: Icon(
                    preset.isCustom
                        ? Icons.add_circle_outline
                        : Icons.cloud_outlined,
                  ),
                  title: Text(displayName),
                  subtitle: Text(preset.description),
                  trailing: Text(
                    statusText,
                    style: TextStyle(color: statusColor),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderConfigPage(
                          preset: preset,
                          apiKeyStore: widget.apiKeyStore,
                          configStore: widget.configStore,
                          connectionTesterResolver:
                              widget.connectionTesterResolver,
                        ),
                      ),
                    );
                    _loadStatus();
                  },
                );
              },
            ),
    );
  }
}
