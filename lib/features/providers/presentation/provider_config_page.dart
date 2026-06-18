import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';

class ProviderConfigPage extends StatefulWidget {
  final ProviderPreset preset;
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ProviderConnectionTester? connectionTester;

  const ProviderConfigPage({
    super.key,
    required this.preset,
    required this.apiKeyStore,
    required this.configStore,
    this.connectionTester,
  });

  @override
  State<ProviderConfigPage> createState() => _ProviderConfigPageState();
}

class _ProviderConfigPageState extends State<ProviderConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _modelController;
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _hasExistingKey = false;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  List<String> _discoveredModels = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
    _modelController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final config = await widget.configStore.readConfig(widget.preset.id);
    final hasKey = await widget.apiKeyStore.hasKey(widget.preset.id);

    if (mounted) {
      setState(() {
        _nameController.text = config?.displayName ?? widget.preset.name;
        _urlController.text = config?.baseUrl ?? widget.preset.defaultBaseUrl;
        _modelController.text = config?.defaultModel ?? '';
        _hasExistingKey = hasKey;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Base URL is required';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid HTTP or HTTPS URL';
    }
    return null;
  }

  String? _validateApiKey(String? value) {
    if (!_hasExistingKey && (value == null || value.trim().isEmpty)) {
      return 'API Key is required';
    }
    return null;
  }

  Future<void> _testConnection() async {
    if (widget.connectionTester == null) return;

    final baseUrl = _urlController.text.trim();
    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Base URL')),
      );
      return;
    }

    String apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty && _hasExistingKey) {
      final stored = await widget.apiKeyStore.readKey(widget.preset.id);
      if (stored != null) apiKey = stored;
    }

    if (apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key required')),
        );
      }
      return;
    }

    setState(() => _testing = true);

    try {
      final result = await widget.connectionTester!.testConnection(
        baseUrl: baseUrl,
        apiKey: apiKey,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _discoveredModels = result.modelIds;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connected: ${result.modelIds.length} models found',
            ),
          ),
        );
      } else {
        setState(() {
          _discoveredModels = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.userMessage ?? 'Unable to connect')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to connect')),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final apiKey = _apiKeyController.text.trim();
    final hasNewKey = apiKey.isNotEmpty;
    final hadExistingKey = _hasExistingKey;
    String? oldKeyValue;

    if (hasNewKey && hadExistingKey) {
      oldKeyValue = await widget.apiKeyStore.readKey(widget.preset.id);
    }

    try {
      if (hasNewKey) {
        await widget.apiKeyStore.saveKey(widget.preset.id, apiKey);
      }

      final config = ProviderConfigData(
        providerId: widget.preset.id,
        displayName: _nameController.text.trim(),
        baseUrl: _urlController.text.trim(),
        defaultModel: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await widget.configStore.saveConfig(config);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider configured')),
        );
      }
    } catch (e) {
      if (hasNewKey) {
        try {
          if (hadExistingKey && oldKeyValue != null) {
            await widget.apiKeyStore.saveKey(widget.preset.id, oldKeyValue);
          } else {
            await widget.apiKeyStore.deleteKey(widget.preset.id);
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save configuration')),
        );
      }
    }
  }

  Future<void> _deleteKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove API Key'),
        content: const Text('Are you sure you want to remove the API key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.apiKeyStore.deleteKey(widget.preset.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset.name),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Provider Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateName,
                      enabled: widget.preset.isCustom,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateUrl,
                      enabled: widget.preset.isCustom,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Default Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_discoveredModels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _discoveredModels.map((model) {
                          return ActionChip(
                            label: Text(model),
                            onPressed: () {
                              _modelController.text = model;
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_hasExistingKey)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'API key is already configured',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: _hasExistingKey
                            ? 'New API Key (leave blank to keep)'
                            : 'API Key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureApiKey = !_obscureApiKey;
                            });
                          },
                        ),
                      ),
                      validator: _validateApiKey,
                      obscureText: _obscureApiKey,
                    ),
                    const SizedBox(height: 24),
                    if (widget.connectionTester != null)
                      OutlinedButton.icon(
                        onPressed: _testing ? null : _testConnection,
                        icon: _testing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find),
                        label: const Text('Test Connection'),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                    if (_hasExistingKey) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _deleteKey,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Remove API Key'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
