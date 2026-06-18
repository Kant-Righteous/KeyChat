import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';

class ProvidersPage extends StatefulWidget {
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ProviderConnectionTester? connectionTester;

  const ProvidersPage({
    super.key,
    required this.apiKeyStore,
    required this.configStore,
    this.connectionTester,
  });

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final Map<String, bool> _keyStatus = {};
  final Map<String, String> _displayNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final keyStatuses = <String, bool>{};
    final displayNames = <String, String>{};

    for (final preset in providerPresets) {
      keyStatuses[preset.id] = await widget.apiKeyStore.hasKey(preset.id);
      final config = await widget.configStore.readConfig(preset.id);
      displayNames[preset.id] = config?.displayName ?? preset.name;
    }

    if (mounted) {
      setState(() {
        _keyStatus.clear();
        _keyStatus.addAll(keyStatuses);
        _displayNames.clear();
        _displayNames.addAll(displayNames);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Providers'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: providerPresets.length,
              itemBuilder: (context, index) {
                final preset = providerPresets[index];
                final configured = _keyStatus[preset.id] ?? false;
                final displayName = _displayNames[preset.id] ?? preset.name;
                return ListTile(
                  leading: Icon(
                    preset.isCustom
                        ? Icons.add_circle_outline
                        : Icons.cloud_outlined,
                  ),
                  title: Text(displayName),
                  subtitle: Text(preset.description),
                  trailing: Text(
                    configured ? 'Configured' : 'Not configured',
                    style: TextStyle(
                      color: configured ? Colors.green : Colors.grey,
                    ),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderConfigPage(
                          preset: preset,
                          apiKeyStore: widget.apiKeyStore,
                          configStore: widget.configStore,
                          connectionTester: widget.connectionTester,
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
