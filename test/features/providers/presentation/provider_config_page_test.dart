import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';
import '../data/fake_api_key_store.dart';
import '../data/fake_provider_config_store.dart';

class _FailingApiKeyStore extends FakeApiKeyStore {
  @override
  Future<void> saveKey(String providerId, String apiKey) async {
    throw Exception('Storage failure');
  }
}

void main() {
  group('ProviderConfigPage', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
    });

    testWidgets('OpenAI preset auto-fills Base URL',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('https://api.openai.com/v1'), findsOneWidget);
    });

    testWidgets('Custom Provider allows editing name and Base URL',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Custom Provider');
      expect(nameField, findsOneWidget);

      final urlField = find.widgetWithText(TextFormField, 'Base URL');
      expect(urlField, findsOneWidget);
    });

    testWidgets('Empty name shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Custom Provider');
      await tester.enterText(nameField, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('Invalid Base URL shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final urlField = find.widgetWithText(TextFormField, 'Base URL');
      await tester.enterText(urlField, 'not-a-url');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid HTTP or HTTPS URL'), findsOneWidget);
    });

    testWidgets('API Key is obscured by default', (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'API Key'),
      );
      expect(apiKeyField.obscureText, isTrue);
    });

    testWidgets('Toggle button switches API Key visibility',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      var apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'API Key'),
      );
      expect(apiKeyField.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'API Key'),
      );
      expect(apiKeyField.obscureText, isFalse);
    });

    testWidgets('shows configured status when key exists',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('API key is already configured'), findsOneWidget);
    });

    testWidgets('does not fill existing key into field',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'New API Key (leave blank to keep)'),
      );
      expect(apiKeyField.controller?.text, isEmpty);
    });

    testWidgets('shows Remove button when configured',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remove API Key'), findsOneWidget);
    });

    testWidgets('delete confirms and removes key', (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderConfigPage(
                        preset: preset,
                        apiKeyStore: apiKeyStore,
                        configStore: configStore,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove API Key'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(find.text('API key removed'), findsOneWidget);
      expect(await apiKeyStore.hasKey('openai'), false);
    });

    testWidgets('valid submission saves config and key',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderConfigPage(
                        preset: preset,
                        apiKeyStore: apiKeyStore,
                        configStore: configStore,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Key'),
        'sk-new-key',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(find.text('Provider configured'), findsOneWidget);
      expect(await apiKeyStore.readKey('openai'), 'sk-new-key');

      final config = await configStore.readConfig('openai');
      expect(config, isNotNull);
      expect(config!.displayName, 'OpenAI');
    });

    testWidgets('save failure shows generic error and stays on page',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      final failingStore = _FailingApiKeyStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: failingStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Key'),
        'sk-test',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('Failed to save configuration'), findsOneWidget);
    });

    testWidgets('save button is enabled before save',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Key'),
        'sk-test',
      );

      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('loads saved config for custom provider',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await configStore.saveConfig(ProviderConfigData(
        providerId: 'custom',
        displayName: 'My Custom AI',
        baseUrl: 'https://custom.example.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Custom AI'), findsOneWidget);
      expect(find.text('https://custom.example.com/v1'), findsOneWidget);
      expect(find.text('gpt-4'), findsOneWidget);
    });
  });
}
