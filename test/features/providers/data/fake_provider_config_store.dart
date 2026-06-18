import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';

class FakeProviderConfigStore implements ProviderConfigStore {
  final Map<String, ProviderConfigData> _configs = {};

  @override
  Future<void> saveConfig(ProviderConfigData config) async {
    _configs[config.providerId] = config;
  }

  @override
  Future<ProviderConfigData?> readConfig(String providerId) async {
    return _configs[providerId];
  }

  @override
  Future<List<ProviderConfigData>> readAllConfigs() async {
    return _configs.values.toList();
  }

  @override
  Future<void> deleteConfig(String providerId) async {
    _configs.remove(providerId);
  }
}
