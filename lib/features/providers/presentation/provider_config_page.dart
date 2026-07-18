import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability_resolver.dart';
import 'package:keychat/features/providers/domain/provider_l10n.dart';
import 'package:keychat/features/providers/domain/provider_url_policy.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

enum _CapabilityMode {
  automatic,
  supported,
  unsupported,
}

class ProviderConfigPage extends StatefulWidget {
  final ProviderPreset preset;
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ModelAttachmentCapabilityStore? modelAttachmentCapabilityStore;
  final ConnectionTesterResolver? connectionTesterResolver;
  final ExternalUrlLauncher? externalUrlLauncher;

  const ProviderConfigPage({
    super.key,
    required this.preset,
    required this.apiKeyStore,
    required this.configStore,
    this.modelAttachmentCapabilityStore,
    this.connectionTesterResolver,
    this.externalUrlLauncher,
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
  bool _configLoadError = false;
  List<String> _discoveredModels = [];
  String _selectedTemplateId = 'custom';
  String? _selectedEndpointId;
  late final ModelAttachmentCapabilityStore _capabilityStore;
  late final ModelAttachmentCapabilityResolver _capabilityResolver;
  _CapabilityMode _imageCapabilityMode = _CapabilityMode.automatic;
  _CapabilityMode _fileCapabilityMode = _CapabilityMode.automatic;

  ProviderTemplatePreset get _selectedTemplate => providerTemplatePresets
      .firstWhere((template) => template.id == _selectedTemplateId);

  ProviderEndpointPreset? get _selectedEndpoint {
    final endpointId = _selectedEndpointId;
    if (endpointId == null) return null;
    for (final endpoint in _selectedTemplate.endpoints) {
      if (endpoint.id == endpointId) return endpoint;
    }
    return null;
  }

  ProviderConnectionTester? get _connectionTester {
    if (widget.connectionTesterResolver == null) return null;
    return widget.connectionTesterResolver!.resolve(widget.preset.protocol);
  }

  bool get _connectionTestSupported {
    if (widget.connectionTesterResolver == null) return false;
    return widget.connectionTesterResolver!.supports(widget.preset.protocol);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
    _modelController = TextEditingController();
    _capabilityStore = widget.modelAttachmentCapabilityStore ??
        InMemoryModelAttachmentCapabilityStore();
    _capabilityResolver = ModelAttachmentCapabilityResolver(
      store: _capabilityStore,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final config = await widget.configStore.readConfig(widget.preset.id);
      final hasKey = await widget.apiKeyStore.hasKey(widget.preset.id);

      if (mounted) {
        setState(() {
          _nameController.text = config?.displayName ??
              localizedProviderName(context, widget.preset);
          _urlController.text = config?.baseUrl ?? widget.preset.defaultBaseUrl;
          _selectPresetForBaseUrl(_urlController.text);
          _modelController.text = config?.defaultModel ?? '';
          _hasExistingKey = hasKey;
          _loading = false;
        });
        unawaited(_loadCapabilityModes(_modelController.text));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nameController.text = localizedProviderName(context, widget.preset);
          _urlController.text = widget.preset.defaultBaseUrl;
          _selectPresetForBaseUrl(_urlController.text);
          _modelController.text = '';
          _imageCapabilityMode = _CapabilityMode.automatic;
          _fileCapabilityMode = _CapabilityMode.automatic;
          _hasExistingKey = false;
          _loading = false;
          _configLoadError = true;
        });
      }
    }
  }

  Future<void> _loadCapabilityModes(String modelId) async {
    final normalizedModelId = modelId.trim();
    if (normalizedModelId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _imageCapabilityMode = _CapabilityMode.automatic;
        _fileCapabilityMode = _CapabilityMode.automatic;
      });
      return;
    }

    try {
      final imageManual = await _capabilityStore.readCapability(
        providerId: widget.preset.id,
        modelId: normalizedModelId,
        modality: ModelInputModality.image,
        source: AttachmentCapabilitySource.manual,
      );
      final fileManual = await _capabilityStore.readCapability(
        providerId: widget.preset.id,
        modelId: normalizedModelId,
        modality: ModelInputModality.file,
        source: AttachmentCapabilitySource.manual,
      );
      if (!mounted || _modelController.text.trim() != normalizedModelId) return;
      setState(() {
        _imageCapabilityMode = _modeForManual(imageManual);
        _fileCapabilityMode = _modeForManual(fileManual);
      });
    } catch (_) {
      if (!mounted || _modelController.text.trim() != normalizedModelId) return;
      setState(() {
        _imageCapabilityMode = _CapabilityMode.automatic;
        _fileCapabilityMode = _CapabilityMode.automatic;
      });
    }
  }

  _CapabilityMode _modeForManual(ModelAttachmentCapability? capability) {
    return switch (capability?.status) {
      AttachmentCapabilityStatus.supported => _CapabilityMode.supported,
      AttachmentCapabilityStatus.unsupported => _CapabilityMode.unsupported,
      _ => _CapabilityMode.automatic,
    };
  }

  void _selectPresetForBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    for (final template in providerTemplatePresets) {
      for (final endpoint in template.endpoints) {
        final endpointUrl =
            endpoint.defaultBaseUrl.replaceFirst(RegExp(r'/$'), '');
        if (endpointUrl == normalized) {
          _selectedTemplateId = template.id;
          _selectedEndpointId = endpoint.id;
          return;
        }
      }
    }
    _selectedTemplateId = 'custom';
    _selectedEndpointId = null;
  }

  String _endpointLabel(
    AppLocalizations l10n,
    ProviderEndpointPreset endpoint,
  ) {
    return switch (endpoint.id) {
      'kimi_china' => l10n.chinaApiOption,
      'kimi_global' => l10n.globalApiOption,
      'kimi_code' => l10n.kimiCodeOption,
      'mimo_pay_as_you_go' => l10n.payAsYouGoApiOption,
      'mimo_token_china' => l10n.tokenPlanChinaOption,
      'mimo_token_singapore' => l10n.tokenPlanSingaporeOption,
      'mimo_token_europe' => l10n.tokenPlanEuropeOption,
      'glm_china_general' => l10n.chinaGeneralApiOption,
      'glm_global_general' => l10n.globalGeneralApiOption,
      'glm_china_coding' => l10n.chinaCodingPlanOption,
      'glm_global_coding' => l10n.globalCodingPlanOption,
      'qwen_pay_as_you_go_beijing' => l10n.payAsYouGoBeijingOption,
      'qwen_pay_as_you_go_singapore' => l10n.payAsYouGoSingaporeOption,
      'qwen_pay_as_you_go_us' => l10n.payAsYouGoUsOption,
      'qwen_token_beijing' => l10n.tokenPlanBeijingOption,
      'qwen_coding_beijing' => l10n.codingPlanBeijingOption,
      _ => endpoint.id,
    };
  }

  String _defaultDisplayName(
    AppLocalizations l10n,
    ProviderTemplatePreset template,
    ProviderEndpointPreset endpoint,
  ) {
    if (endpoint.id == 'kimi_code') return 'Kimi Code';
    if (template.endpoints.length == 1) return template.name;
    return '${template.name} · ${_endpointLabel(l10n, endpoint)}';
  }

  void _selectTemplate(String templateId) {
    final l10n = AppLocalizations.of(context)!;
    final template = providerTemplatePresets
        .firstWhere((candidate) => candidate.id == templateId);

    setState(() {
      _selectedTemplateId = template.id;
      if (template.endpoints.isEmpty) {
        _selectedEndpointId = null;
        _nameController.text = l10n.customProvider;
        _urlController.clear();
        return;
      }

      final endpoint = template.endpoints.first;
      _selectedEndpointId = endpoint.id;
      _nameController.text = _defaultDisplayName(l10n, template, endpoint);
      _urlController.text = endpoint.defaultBaseUrl;
    });
  }

  void _selectEndpoint(String endpointId) {
    final l10n = AppLocalizations.of(context)!;
    final template = _selectedTemplate;
    final endpoint = template.endpoints
        .firstWhere((candidate) => candidate.id == endpointId);

    setState(() {
      _selectedEndpointId = endpoint.id;
      _nameController.text = _defaultDisplayName(l10n, template, endpoint);
      _urlController.text = endpoint.defaultBaseUrl;
    });
  }

  Future<void> _openOfficialWebsite() async {
    final endpoint = _selectedEndpoint;
    if (endpoint == null) return;

    final uri = Uri.parse(endpoint.apiKeyUrl);
    var launched = false;
    try {
      launched = await (widget.externalUrlLauncher?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.unableToOpenOfficialWebsite),
        ),
      );
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
      return AppLocalizations.of(context)!.agentNameRequired;
    }
    return null;
  }

  String? _validateUrl(String? value) {
    final error = ProviderUrlPolicy.validateUrl(value);
    if (error == null) return null;
    return localizedUrlValidationError(AppLocalizations.of(context)!, error);
  }

  String? _validateApiKey(String? value) {
    if (!_hasExistingKey && (value == null || value.trim().isEmpty)) {
      return AppLocalizations.of(context)!.apiKeyRequired;
    }
    return null;
  }

  String? _validateModel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.modelRequired;
    }
    return null;
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    final tester = _connectionTester;
    if (tester == null) return;

    final baseUrl = _urlController.text.trim();
    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidBaseUrl)),
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
          SnackBar(content: Text(l10n.apiKeyRequired)),
        );
      }
      return;
    }

    setState(() => _testing = true);

    try {
      final result = await tester.testConnection(
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
            content: Text(l10n.modelsFound(result.modelIds.length)),
          ),
        );
      } else {
        setState(() {
          _discoveredModels = [];
        });
        final errorMessage = localizedConnectionError(
          l10n,
          result.errorType?.toString().split('.').last,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unableToConnect)),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
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
        protocol: widget.preset.protocol,
        supportsImageInput: _imageCapabilityMode == _CapabilityMode.supported,
        supportsFileInput: _fileCapabilityMode == _CapabilityMode.supported,
        updatedAt: DateTime.now(),
      );
      await widget.configStore.saveConfig(config);
      final modelId = _modelController.text.trim();
      if (modelId.isNotEmpty) {
        await _saveCapabilityMode(
          modelId: modelId,
          modality: ModelInputModality.image,
          mode: _imageCapabilityMode,
        );
        await _saveCapabilityMode(
          modelId: modelId,
          modality: ModelInputModality.file,
          mode: _fileCapabilityMode,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.providerConfiguredSuccess)),
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
          SnackBar(content: Text(l10n.failedToSaveProvider)),
        );
      }
    }
  }

  Future<void> _saveCapabilityMode({
    required String modelId,
    required ModelInputModality modality,
    required _CapabilityMode mode,
  }) async {
    switch (mode) {
      case _CapabilityMode.automatic:
        await _capabilityResolver.clearManual(
          providerId: widget.preset.id,
          modelId: modelId,
          modality: modality,
        );
      case _CapabilityMode.supported:
        await _capabilityResolver.saveManual(
          providerId: widget.preset.id,
          modelId: modelId,
          modality: modality,
          status: AttachmentCapabilityStatus.supported,
        );
      case _CapabilityMode.unsupported:
        await _capabilityResolver.saveManual(
          providerId: widget.preset.id,
          modelId: modelId,
          modality: modality,
          status: AttachmentCapabilityStatus.unsupported,
        );
    }
  }

  Future<void> _deleteKey() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeApiKeyButton),
        content: Text(l10n.removeApiKeyConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.apiKeyStore.deleteKey(widget.preset.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.apiKeyRemoved)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.configureProviderTitle),
      ),
      body: _loading
          ? Center(child: Text(l10n.loading))
          : _configLoadError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        l10n.providerConfigInvalid,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.configLoadError,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.goBack),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  key: const Key('provider_config_scroll'),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.preset.isCustom) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedTemplateId,
                            decoration: InputDecoration(
                              labelText: l10n.providerPresetLabel,
                              border: const OutlineInputBorder(),
                            ),
                            items: providerTemplatePresets.map((template) {
                              return DropdownMenuItem<String>(
                                value: template.id,
                                child: Text(
                                  template.id == 'custom'
                                      ? l10n.manualProviderPreset
                                      : template.name,
                                ),
                              );
                            }).toList(),
                            onChanged: _saving
                                ? null
                                : (value) {
                                    if (value != null) _selectTemplate(value);
                                  },
                          ),
                          if (_selectedTemplate.endpoints.length > 1) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedEndpointId,
                              decoration: InputDecoration(
                                labelText: l10n.accessOptionLabel,
                                border: const OutlineInputBorder(),
                              ),
                              items:
                                  _selectedTemplate.endpoints.map((endpoint) {
                                return DropdownMenuItem<String>(
                                  value: endpoint.id,
                                  child: Text(_endpointLabel(l10n, endpoint)),
                                );
                              }).toList(),
                              onChanged: _saving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _selectEndpoint(value);
                                      }
                                    },
                            ),
                          ],
                          if (_selectedEndpoint != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.providerEndpointKeyHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (_selectedEndpoint!.apiKeyPrefix != null)
                              Text(
                                l10n.apiKeyPrefixHint(
                                  _selectedEndpoint!.apiKeyPrefix!,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (_selectedEndpoint!.isPlan)
                              Text(
                                l10n.planEndpointWarning,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.orange[800]),
                              ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.providerNameLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateName,
                          enabled: widget.preset.isCustom,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: l10n.baseUrlLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateUrl,
                          enabled: widget.preset.isCustom,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _modelController,
                          decoration: InputDecoration(
                            labelText: l10n.defaultModelLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateModel,
                          onChanged: (modelId) {
                            unawaited(_loadCapabilityModes(modelId));
                          },
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
                                  unawaited(_loadCapabilityModes(model));
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
                              l10n.apiKeyConfigured,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: _hasExistingKey
                                ? l10n.newApiKeyLabel
                                : l10n.apiKeyLabel,
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
                        if (_selectedEndpoint != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _saving ? null : _openOfficialWebsite,
                              icon: const Icon(Icons.open_in_new),
                              label: Text(l10n.visitOfficialWebsite),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_connectionTestSupported)
                          OutlinedButton.icon(
                            onPressed: _testing ? null : _testConnection,
                            icon: _testing
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_find),
                            label: Text(l10n.testConnectionButton),
                          ),
                        if (!_connectionTestSupported)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l10n.connectionTestUnsupported,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l10n.saveButton),
                        ),
                        if (_hasExistingKey) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _deleteKey,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(l10n.removeApiKeyButton),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
    );
  }
}
