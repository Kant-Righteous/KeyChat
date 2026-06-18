import 'package:keychat/features/providers/data/provider_config.dart';

abstract class ProviderConfigStore {
  Future<void> saveConfig(ProviderConfigData config);
  Future<ProviderConfigData?> readConfig(String providerId);
  Future<List<ProviderConfigData>> readAllConfigs();
  Future<void> deleteConfig(String providerId);
}
