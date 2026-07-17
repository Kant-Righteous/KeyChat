import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test_helpers.dart';
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

    test('Every provider endpoint has an HTTPS API key page', () {
      final endpoints = providerTemplatePresets
          .expand((template) => template.endpoints)
          .toList();

      expect(endpoints, isNotEmpty);
      for (final endpoint in endpoints) {
        final apiKeyUrl = endpoint.apiKeyUrl;
        expect(apiKeyUrl, isNotEmpty, reason: endpoint.id);

        final uri = Uri.parse(apiKeyUrl);
        expect(uri.scheme, 'https', reason: endpoint.id);
        expect(uri.host, isNotEmpty, reason: endpoint.id);
      }
    });

    testWidgets('OpenAI preset auto-fills Base URL',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        buildTestAppZh(
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
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, '自定义提供商');
      expect(nameField, findsOneWidget);

      final urlField = find.widgetWithText(TextFormField, '基础地址');
      expect(urlField, findsOneWidget);
    });

    testWidgets('Dynamic custom Provider does not expose its internal ID',
        (WidgetTester tester) async {
      const preset = ProviderPreset(
        id: 'custom_123456',
        name: '自定义提供商',
        description: '配置任意兼容 OpenAI 协议的服务',
        defaultBaseUrl: '',
        isCustom: true,
        protocol: ProviderProtocol.openAiCompatible,
      );

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, '自定义提供商'),
        findsOneWidget,
      );
      expect(find.text('custom_123456'), findsNothing);
    });

    testWidgets('Custom Provider shows provider preset selector',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('提供商预设'), findsOneWidget);
      expect(find.text('其他（手动填写）'), findsOneWidget);
    });

    testWidgets('Kimi Code preset fills editable name and Base URL',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('其他（手动填写）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kimi').last);
      await tester.pumpAndSettle();

      expect(find.text('接入方案 / 地域'), findsOneWidget);
      expect(find.text('中国普通 API'), findsOneWidget);

      await tester.tap(find.text('中国普通 API'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kimi Code').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Kimi Code'), findsOneWidget);
      expect(
        find.widgetWithText(
          TextFormField,
          'https://api.kimi.com/coding/v1',
        ),
        findsOneWidget,
      );

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Kimi Code'),
      );
      final urlField = tester.widget<TextFormField>(
        find.widgetWithText(
          TextFormField,
          'https://api.kimi.com/coding/v1',
        ),
      );
      expect(nameField.enabled, isTrue);
      expect(urlField.enabled, isTrue);
      expect(find.textContaining('套餐地址必须与套餐专用 API Key'), findsOneWidget);
    });

    testWidgets('Visit official website opens selected endpoint API key page',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom
      Uri? launchedUri;

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            externalUrlLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('前往官网'), findsNothing);

      await tester.tap(find.text('其他（手动填写）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kimi').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('中国普通 API'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kimi Code').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('前往官网'));
      await tester.pumpAndSettle();

      expect(launchedUri, Uri.parse('https://www.kimi.com/code/console'));
    });

    testWidgets('MiMo Token Plan regions and Qwen plans are selectable',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('其他（手动填写）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MiMo').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('普通按量 API'));
      await tester.pumpAndSettle();
      expect(find.text('Token Plan · 中国'), findsOneWidget);
      expect(find.text('Token Plan · 新加坡'), findsOneWidget);
      expect(find.text('Token Plan · 欧洲'), findsOneWidget);

      await tester.tap(find.text('Token Plan · 新加坡'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(
          TextFormField,
          'https://token-plan-sgp.xiaomimimo.com/v1',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('MiMo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Qwen').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('按量付费 · 北京'));
      await tester.pumpAndSettle();
      expect(find.text('Token Plan · 北京'), findsOneWidget);
      expect(find.text('Coding Plan · 北京'), findsOneWidget);
    });

    testWidgets('Empty name shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, '自定义提供商');
      await tester.enterText(nameField, '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('名称不能为空'), findsOneWidget);
    });

    testWidgets('Invalid Base URL shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[3]; // Custom

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final urlField = find.widgetWithText(TextFormField, '基础地址');
      await tester.enterText(urlField, 'not-a-url');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('无效的基础地址'), findsOneWidget);
    });

    testWidgets('Empty default model shows validation error',
        (WidgetTester tester) async {
      final preset = providerPresets[1]; // DeepSeek

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('请先选择模型'), findsOneWidget);
      expect(await configStore.readConfig('deepseek'), isNull);
    });

    testWidgets('API Key is obscured by default', (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        buildTestAppZh(
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
        buildTestAppZh(
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
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('已配置 API Key'), findsOneWidget);
    });

    testWidgets('does not fill existing key into field',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final apiKeyField = tester.widget<TextField>(
        find.widgetWithText(TextField, '新 API Key（留空保留原有）'),
      );
      expect(apiKeyField.controller?.text, isEmpty);
    });

    testWidgets('shows Remove button when configured',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('删除 API Key'), findsOneWidget);
    });

    testWidgets('delete confirms and removes key', (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'sk-existing');

      await tester.pumpWidget(
        buildTestAppZh(
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

      await tester.ensureVisible(find.text('删除 API Key'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除 API Key'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(find.text('API Key 已删除'), findsOneWidget);
      expect(await apiKeyStore.hasKey('openai'), false);
    });

    testWidgets('valid submission saves config and key',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        buildTestAppZh(
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(find.text('提供商已配置'), findsOneWidget);
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
        buildTestAppZh(
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('配置保存失败'), findsOneWidget);
    });

    testWidgets('save button is enabled before save',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        buildTestAppZh(
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
        find.widgetWithText(ElevatedButton, '保存'),
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
        buildTestAppZh(
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
        buildTestAppZh(
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      final completer = slowStore.startSave();

      await tester.tap(find.text('保存'));
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
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('已配置 API Key'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, '新 API Key（留空保留原有）'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsNothing);
      expect(await apiKeyStore.readKey('openai'), 'old-key-value');
    });

    testWidgets('save failure does not leak API key in error message',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      final failingStore = _FailingApiKeyStore();

      await tester.pumpWidget(
        buildTestAppZh(
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('配置保存失败'), findsOneWidget);
      final snackBarText = tester.widget<Text>(
        find.text('配置保存失败'),
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
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: failingConfig,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '新 API Key（留空保留原有）'),
        'new-key-value',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('配置保存失败'), findsOneWidget);
      expect(await apiKeyStore.readKey('openai'), 'old-key-value');
    });

    testWidgets(
        'rollback deletes new key when config save fails and no old key existed',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      final failingConfig = _FailingConfigStore();

      await tester.pumpWidget(
        buildTestAppZh(
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('配置保存失败'), findsOneWidget);
      expect(await apiKeyStore.hasKey('openai'), false);
    });

    testWidgets('old key preserved when config save fails with empty key field',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI
      await apiKeyStore.saveKey('openai', 'old-key-value');
      final failingConfig = _FailingConfigStore();

      await tester.pumpWidget(
        buildTestAppZh(
          home: ProviderConfigPage(
            preset: preset,
            apiKeyStore: apiKeyStore,
            configStore: failingConfig,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderConfigPage), findsOneWidget);
      expect(find.text('配置保存失败'), findsOneWidget);
      expect(await apiKeyStore.readKey('openai'), 'old-key-value');
    });

    testWidgets('both config and key saved on successful submission',
        (WidgetTester tester) async {
      final preset = providerPresets[0]; // OpenAI

      await tester.pumpWidget(
        buildTestAppZh(
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '默认模型'),
        'gpt-4',
      );

      await tester.tap(find.text('保存'));
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        expect(find.text('请先配置 API Key'), findsOneWidget);
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        expect(connTester.lastApiKey, 'old-key-value');
      });

      testWidgets('shows loading during test', (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        final completer = connTester.startSlowResponse();

        await tester.pumpWidget(
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        expect(find.text('找到 2 个模型'), findsOneWidget);
      });

      testWidgets('shows failure message on error',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();
        connTester.setResult(
          const ConnectionTestResult.failure(
            errorType: ConnectionErrorType.unauthorized,
            userMessage: 'API Key 无效',
          ),
        );

        await tester.pumpWidget(
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        expect(find.text('API Key 无效'), findsOneWidget);
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('gpt-4').last);
        await tester.pumpAndSettle();

        final modelField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '默认模型'),
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
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
            userMessage: 'API Key 无效',
          ),
        );

        await tester.pumpWidget(
          buildTestAppZh(
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
          find.widgetWithText(TextFormField, '默认模型'),
          'my-model',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Key'),
          'test-key',
        );

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        final modelField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '默认模型'),
        );
        expect(modelField.controller?.text, 'my-model');
      });

      testWidgets('tester call count is zero on page open',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final connTester = FakeProviderConnectionTester();

        await tester.pumpWidget(
          buildTestAppZh(
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
          buildTestAppZh(
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

        await tester.tap(find.text('测试连接'));
        await tester.pumpAndSettle();

        final snackBarText = tester.widget<Text>(
          find.text('提供商服务器错误'),
        );
        expect(snackBarText.data, isNot(contains('test-marker-abc')));
      });

      testWidgets('unknown protocol shows invalid config error',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final throwingStore = _ThrowingConfigStore();

        await tester.pumpWidget(
          buildTestAppZh(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: throwingStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('提供商配置无效'), findsOneWidget);
        expect(find.text('返回'), findsOneWidget);
      });

      testWidgets('unknown protocol does not show form fields',
          (WidgetTester tester) async {
        final preset = providerPresets[0]; // OpenAI
        final throwingStore = _ThrowingConfigStore();

        await tester.pumpWidget(
          buildTestAppZh(
            home: ProviderConfigPage(
              preset: preset,
              apiKeyStore: apiKeyStore,
              configStore: throwingStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('提供商名称'), findsNothing);
        expect(find.text('基础地址'), findsNothing);
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
