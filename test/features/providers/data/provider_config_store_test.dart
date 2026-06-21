import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';
import 'fake_provider_config_store.dart';

void main() {
  group('ProviderConfigStore', () {
    late FakeProviderConfigStore store;

    setUp(() {
      store = FakeProviderConfigStore();
    });

    test('save and read config', () async {
      final config = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      );

      await store.saveConfig(config);
      final result = await store.readConfig('openai');

      expect(result, isNotNull);
      expect(result!.providerId, 'openai');
      expect(result.displayName, 'OpenAI');
      expect(result.baseUrl, 'https://api.openai.com/v1');
    });

    test('update config', () async {
      final config1 = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      );
      await store.saveConfig(config1);

      final config2 = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI Updated',
        baseUrl: 'https://api.openai.com/v2',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024, 2),
      );
      await store.saveConfig(config2);

      final result = await store.readConfig('openai');
      expect(result!.displayName, 'OpenAI Updated');
      expect(result.baseUrl, 'https://api.openai.com/v2');
    });

    test('readAllConfigs returns all saved configs', () async {
      await store.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await store.saveConfig(ProviderConfigData(
        providerId: 'deepseek',
        displayName: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));

      final configs = await store.readAllConfigs();
      expect(configs.length, 2);
    });

    test('delete config', () async {
      await store.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));

      await store.deleteConfig('openai');
      final result = await store.readConfig('openai');
      expect(result, isNull);
    });

    test('readConfig returns null for non-existent provider', () async {
      final result = await store.readConfig('nonexistent');
      expect(result, isNull);
    });

    test('ProviderConfigData does not contain API key', () {
      final config = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      );

      expect(config.providerId, isNot(contains('sk-')));
    });

    test('config saves and reads protocol', () async {
      final config = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      );

      await store.saveConfig(config);
      final result = await store.readConfig('openai');

      expect(result, isNotNull);
      expect(result!.protocol, ProviderProtocol.openAiCompatible);
    });

    test('updating other fields preserves protocol', () async {
      final config1 = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      );
      await store.saveConfig(config1);

      final config2 = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI v2',
        baseUrl: 'https://api.openai.com/v2',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024, 2),
      );
      await store.saveConfig(config2);

      final result = await store.readConfig('openai');
      expect(result!.protocol, ProviderProtocol.openAiCompatible);
      expect(result.displayName, 'OpenAI v2');
    });

    test('unconfig uses preset protocol', () {
      final preset = providerPresets[0];
      expect(preset.protocol, ProviderProtocol.openAiCompatible);
    });

    test('all current presets use openAiCompatible', () {
      for (final preset in providerPresets) {
        expect(preset.protocol, ProviderProtocol.openAiCompatible);
      }
    });

    test('ProviderConfigData protocol does not contain API key', () {
      final config = ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      );

      expect(config.protocol.storageValue, isNot(contains('sk-')));
    });
  });
}
