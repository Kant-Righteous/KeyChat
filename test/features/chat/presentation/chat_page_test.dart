import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';

import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';

class FakeChatCompletionClient implements ChatCompletionClient {
  ChatCompletionResult? _nextResult;
  int callCount = 0;
  String? lastBaseUrl;
  String? lastModel;
  List<ChatRequestMessage>? lastMessages;

  void setResult(ChatCompletionResult result) {
    _nextResult = result;
  }

  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    dynamic cancelToken,
  }) async {
    callCount++;
    lastBaseUrl = baseUrl;
    lastModel = model;
    lastMessages = messages;

    return _nextResult ??
        const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.unknown,
          userMessage: 'No result configured',
        );
  }
}

void main() {
  group('ChatPage', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatCompletionClient chatClient;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      chatClient = FakeChatCompletionClient();
    });

    testWidgets('shows empty state when no ready provider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ready provider'), findsOneWidget);
    });

    testWidgets('shows ready provider in dropdown',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OpenAI'), findsOneWidget);
    });

    testWidgets('only shows providers with config, key, and model',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await configStore.saveConfig(ProviderConfigData(
        providerId: 'incomplete',
        displayName: 'Incomplete',
        baseUrl: 'https://example.com',
        defaultModel: null,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('incomplete', 'test-key');

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Incomplete'), findsNothing);
    });

    testWidgets('blank message cannot be sent', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(chatClient.callCount, 0);
    });

    testWidgets('clicking send calls injected client',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi there!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(chatClient.callCount, 1);
      expect(chatClient.lastModel, 'gpt-4');
    });

    testWidgets('user message appears in message list',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('assistant message appears after success',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi there!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hi there!'), findsOneWidget);
    });

    testWidgets('input cleared after successful send',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Type a message...'),
      );
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('failure shows error and does not add empty assistant message',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.serverError,
          userMessage: 'Provider server error',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Provider server error'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('does not auto-send request on page open',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(chatClient.callCount, 0);
    });

    testWidgets('does not modify ProviderConfig', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final config = await configStore.readConfig('openai');
      expect(config?.displayName, 'OpenAI');
      expect(config?.defaultModel, 'gpt-4');
    });

    testWidgets('does not modify ApiKeyStore', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(await apiKeyStore.readKey('openai'), 'test-key');
    });

    testWidgets('error message does not contain test key',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-marker-secret-xyz');

      chatClient.setResult(
        const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.unauthorized,
          userMessage: 'Invalid API key',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Invalid API key'), findsOneWidget);
    });
  });
}
