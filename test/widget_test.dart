import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';

class FakeApiKeyStore implements ApiKeyStore {
  final Map<String, String> _keys = {};

  @override
  Future<void> saveKey(String providerId, String apiKey) async {
    _keys[providerId] = apiKey.trim();
  }

  @override
  Future<String?> readKey(String providerId) async => _keys[providerId];

  @override
  Future<bool> hasKey(String providerId) async => _keys.containsKey(providerId);

  @override
  Future<void> deleteKey(String providerId) async => _keys.remove(providerId);
}

class FakeProviderConfigStore implements ProviderConfigStore {
  final Map<String, ProviderConfigData> _configs = {};

  @override
  Future<void> saveConfig(ProviderConfigData config) async {
    _configs[config.providerId] = config;
  }

  @override
  Future<ProviderConfigData?> readConfig(String providerId) async =>
      _configs[providerId];

  @override
  Future<List<ProviderConfigData>> readAllConfigs() async =>
      _configs.values.toList();

  @override
  Future<void> deleteConfig(String providerId) async =>
      _configs.remove(providerId);
}

void main() {
  testWidgets('ChatPage shows KeyChat title and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChatPage()),
    );

    expect(find.text('KeyChat'), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('ProvidersPage shows presets', (WidgetTester tester) async {
    final apiKeyStore = FakeApiKeyStore();
    final configStore = FakeProviderConfigStore();
    await tester.pumpWidget(
      MaterialApp(
        home: ProvidersPage(
          apiKeyStore: apiKeyStore,
          configStore: configStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('DeepSeek'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    expect(find.text('Custom Provider'), findsOneWidget);
  });

  testWidgets('SettingsPage shows setting items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About KeyChat'), findsOneWidget);
  });
}
