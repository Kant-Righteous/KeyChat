import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';
import '../data/fake_api_key_store.dart';
import '../data/fake_provider_config_store.dart';
import '../data/fake_provider_connection_tester.dart';
import '../data/fake_connection_tester_resolver.dart';

class _FailingApiKeyStore extends FakeApiKeyStore {
  @override
  Future<void> saveKey(String providerId, String apiKey) async {
    throw Exception('Storage failure');
  }
}

class _SlowApiKeyStore extends FakeApiKeyStore {
  Completer<void>? _saveCompleter;

  Completer<void> startSave() {
    _saveCompleter = Completer<void>();
    return _saveCompleter!;
  }

  @override
  Future<void> saveKey(String providerId, String apiKey) async {
    if (_saveCompleter != null && !_saveCompleter!.isCompleted) {
      await _saveCompleter!.future;
    }
    await super.saveKey(providerId, apiKey);
  }
}

class _FailingConfigStore extends FakeProviderConfigStore {
  @override
  Future<void> saveConfig(ProviderConfigData config) async {
    throw Exception('Database failure');
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
        protocol: ProviderProtocol.openAiCompatible,
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

    testWidgets('save button is disabled while saving',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      final slowStore = _SlowApiKeyStore();

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
                        apiKeyStore: slowStore,
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
        'test-marker-123',
      );

      final completer = slowStore.startSave();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
    });

    testWidgets('existing API key is preserved when key field is left empty',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'old-key-value');

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
      expect(
        find.widgetWithText(TextFormField, 'New API Key (leave blank to keep)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(await apiKeyStore.readKey('openai'), 'old-key-value');
    });

    testWidgets('save failure does not leak API key in error message',
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
        'test-marker-xyz',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to save configuration'), findsOneWidget);
      final snackBarText = tester.widget<Text>(
        find.text('Failed to save configuration'),
      );
      expect(snackBarText.data, isNot(contains('test-marker-xyz')));
    });

    testWidgets(
        'rollback restores old key when config save fails after new key saved',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'old-key-value');
      final failingConfig = _FailingConfigStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: failingConfig,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New API Key (leave blank to keep)'),
        'new-key-value',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('Failed to save configuration'), findsOneWidget);
      expect(await apiKeyStore.readKey('openai'), 'old-key-value');
    });

    testWidgets(
        'rollback deletes new key when config save fails and no old key existed',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      final failingConfig = _FailingConfigStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: failingConfig,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Key'),
        'new-key-value',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('Failed to save configuration'), findsOneWidget);
      expect(await apiKeyStore.hasKey('openai'), false);
    });

    testWidgets('old key preserved when config save fails with empty key field',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'old-key-value');
      final failingConfig = _FailingConfigStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: failingConfig,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('Failed to save configuration'), findsOneWidget);
      expect(await apiKeyStore.readKey('openai'), 'old-key-value');
    });

    testWidgets('both config and key saved on successful submission',
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
        'new-key-value',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(await apiKeyStore.readKey('openai'), 'new-key-value');
      final config = await configStore.readConfig('openai');
      expect(config, isNotNull);
      expect(config!.displayName, 'OpenAI');
    });

    group('Test Connection', () {
      testWidgets('does not call tester when no API key available',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(find.text('API key required'), findsOneWidget);
        expect(connTester.lastBaseUrl, isNull);
      });

      testWidgets('uses new key from input when available',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.success(modelIds: ['gpt-4']),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'new-test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(connTester.lastApiKey, 'new-test-key');
      });

      testWidgets('reads old key when input is empty',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        await apiKeyStore.saveKey('openai', 'old-key-value');
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.success(modelIds: ['gpt-4']),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(connTester.lastApiKey, 'old-key-value');
      });

      testWidgets('shows loading during test', (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        final completer = connTester.startSlowResponse();

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);

        completer.complete();
        connTester.setResult(
          const ConnectionTestResult.success(modelIds: ['gpt-4']),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('shows success message with model count',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.success(
              modelIds: ['gpt-4', 'gpt-3.5-turbo']),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(find.text('Connected: 2 models found'), findsOneWidget);
      });

      testWidgets('shows failure message on error',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.failure(
            errorType: ConnectionErrorType.unauthorized,
            userMessage: 'Invalid API key',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'bad-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid API key'), findsOneWidget);
      });

      testWidgets('shows model selection when models found',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.success(
              modelIds: ['gpt-4', 'gpt-3.5-turbo']),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(find.text('gpt-4'), findsWidgets);
        expect(find.text('gpt-3.5-turbo'), findsWidgets);
      });

      testWidgets('selecting model updates default model field',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.success(
              modelIds: ['gpt-4', 'gpt-3.5-turbo']),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('gpt-4').last);
        await tester.pumpAndSettle();

        final modelField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Default Model'),
        );
        expect(modelField.controller?.text, 'gpt-4');
      });

      testWidgets('does not auto-save config or key on test',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.success(modelIds: ['gpt-4']),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        expect(await apiKeyStore.hasKey('openai'), false);
        expect(await configStore.readConfig('openai'), isNull);
      });

      testWidgets('failure does not clear default model',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.failure(
            errorType: ConnectionErrorType.unauthorized,
            userMessage: 'Invalid API key',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Default Model'),
          'my-model',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        final modelField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Default Model'),
        );
        expect(modelField.controller?.text, 'my-model');
      });

      testWidgets('tester call count is zero on page open',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(connTester.callCount, 0);
      });

      testWidgets('does not leak server response in userMessage',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.failure(
            errorType: ConnectionErrorType.serverError,
            userMessage: 'Provider server error',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              connectionTesterResolver: FakeConnectionTesterResolver(
                  openAiCompatibleTester: connTester),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-marker-abc',
        );

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        final snackBarText = tester.widget<Text>(
          find.text('Provider server error'),
        );
        expect(snackBarText.data, isNot(contains('test-marker-abc')));
      });

      testWidgets('unknown protocol shows invalid config error',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final throwingStore = _ThrowingConfigStore();

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: throwingStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Provider configuration is invalid'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
      });

      testWidgets('unknown protocol does not show form fields',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final throwingStore = _ThrowingConfigStore();

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: throwingStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Provider Name'), findsNothing);
        expect(find.text('Base URL'), findsNothing);
        expect(find.text('API Key'), findsNothing);
      });
    });
  });
}

class _ThrowingConfigStore extends FakeProviderConfigStore {
  @override
  Future<ProviderConfigData?> readConfig(String providerId) async {
    throw StateError('Unknown protocol for provider: $providerId');
  }
}
