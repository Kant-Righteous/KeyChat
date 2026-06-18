import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';

class ProvidersPage extends StatefulWidget {
  final ApiKeyStore apiKeyStore;

  const ProvidersPage({super.key, required this.apiKeyStore});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final Map<String, bool> _keyStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final statuses = <String, bool>{};
    for (final preset in providerPresets) {
      statuses[preset.id] = await widget.apiKeyStore.hasKey(preset.id);
    }
    if (mounted) {
      setState(() {
        _keyStatus.clear();
        _keyStatus.addAll(statuses);
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
                return ListTile(
                  leading: Icon(
                    preset.isCustom
                        ? Icons.add_circle_outline
                        : Icons.cloud_outlined,
                  ),
                  title: Text(preset.name),
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
