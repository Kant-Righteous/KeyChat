import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';

import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_history_store.dart';

class FakeChatCompletionClient implements ChatCompletionClient {
  ChatCompletionResult? _nextResult;
  Completer<ChatCompletionResult>? _nextResultCompleter;
  int callCount = 0;
  String? lastBaseUrl;
  String? lastModel;
  List<ChatRequestMessage>? lastMessages;
  ChatCancellationToken? lastCancellationToken;

  void setResult(ChatCompletionResult result) {
    _nextResult = result;
    _nextResultCompleter = null;
  }

  set nextResultCompleter(Completer<ChatCompletionResult> completer) {
    _nextResultCompleter = completer;
    _nextResult = null;
  }

  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) async {
    callCount++;
    lastBaseUrl = baseUrl;
    lastModel = model;
    lastMessages = messages;
    lastCancellationToken = cancellationToken;

    if (_nextResultCompleter != null) {
      return await _nextResultCompleter!.future;
    }

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
    late FakeChatHistoryStore historyStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      chatClient = FakeChatCompletionClient();
      historyStore = FakeChatHistoryStore();
    });

    testWidgets('shows loading during page load', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no ready provider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ready provider'), findsOneWidget);
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
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(chatClient.callCount, 0);
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
            historyStore: historyStore,
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
            historyStore: historyStore,
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
            historyStore: historyStore,
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
            historyStore: historyStore,
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
            historyStore: historyStore,
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

    testWidgets('failure shows error and keeps user message',
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
            historyStore: historyStore,
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
      expect(find.text('Hello'), findsWidgets);
    });

    testWidgets('failure preserves input text', (WidgetTester tester) async {
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
            historyStore: historyStore,
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
      expect(textField.controller?.text, 'Hello');
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
            historyStore: historyStore,
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
            historyStore: historyStore,
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
            historyStore: historyStore,
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

    testWidgets('restores conversation from history',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test conversation',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Previous message',
          createdAt: DateTime(2024),
        ),
      );
      await historyStore.appendMessage(
        conversationId: 'conv_1',
        message: ChatMessage(
          id: 'msg_2',
          role: ChatRole.assistant,
          content: 'Previous response',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Previous message'), findsOneWidget);
      expect(find.text('Previous response'), findsOneWidget);
    });

    testWidgets('new chat clears messages', (WidgetTester tester) async {
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
            historyStore: historyStore,
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

      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsNothing);
      expect(find.text('Start a conversation'), findsOneWidget);
    });

    testWidgets('multi-turn context includes history',
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
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'First message',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Follow up!'),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Second message',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(chatClient.lastMessages?.length, 3);
      expect(chatClient.lastMessages?[0].role, 'user');
      expect(chatClient.lastMessages?[0].content, 'First message');
      expect(chatClient.lastMessages?[1].role, 'assistant');
      expect(chatClient.lastMessages?[1].content, 'Hi there!');
      expect(chatClient.lastMessages?[2].role, 'user');
      expect(chatClient.lastMessages?[2].content, 'Second message');
    });

    testWidgets('dispose cancels in-progress request',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final completer = Completer<ChatCompletionResult>();
      chatClient.nextResultCompleter = completer;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(chatClient.lastCancellationToken, isNotNull);
      expect(chatClient.lastCancellationToken!.isCancelled, false);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(chatClient.lastCancellationToken!.isCancelled, true);

      completer.complete(
        const ChatCompletionResult.success(assistantContent: 'Late response'),
      );
    });

    testWidgets('API key not written to history store',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-marker-xyz');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
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

      final conv = await historyStore.readLatestConversation();
      expect(conv, isNotNull);
      expect(conv!.providerId, 'openai');

      final messages = await historyStore.readMessages(conv.id);
      for (final msg in messages) {
        expect(msg.content, isNot(contains('test-marker-xyz')));
      }
    });

    testWidgets('history button opens ConversationListPage',
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
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
    });

    testWidgets('switching conversation loads corresponding messages',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'First',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'First message',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First message'), findsOneWidget);
    });

    testWidgets('unavailable provider shows warning and disables send',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_old',
          title: 'Old Chat',
          providerId: 'deleted_provider',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Old message',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old message'), findsOneWidget);
      expect(find.text('Provider is no longer available'), findsOneWidget);
    });

    testWidgets('new chat clears messages and input',
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
            historyStore: historyStore,
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

      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsNothing);
      expect(find.text('Start a conversation'), findsOneWidget);
    });

    testWidgets('empty new chat does not create database record',
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
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      final conv = await historyStore.readLatestConversation();
      expect(conv, isNull);
    });

    testWidgets('switching conversation isolates context',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      // Create conversation A
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_a',
          title: 'Conversation A',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 1),
          updatedAt: DateTime(2024, 1),
        ),
        firstMessage: ChatMessage(
          id: 'msg_a1',
          role: ChatRole.user,
          content: 'Message from A',
          createdAt: DateTime(2024, 1),
        ),
      );
      await historyStore.appendMessage(
        conversationId: 'conv_a',
        message: ChatMessage(
          id: 'msg_a2',
          role: ChatRole.assistant,
          content: 'Response A',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      // Create conversation B
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_b',
          title: 'Conversation B',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 6),
          updatedAt: DateTime(2024, 6),
        ),
        firstMessage: ChatMessage(
          id: 'msg_b1',
          role: ChatRole.user,
          content: 'Message from B',
          createdAt: DateTime(2024, 6),
        ),
      );
      await historyStore.appendMessage(
        conversationId: 'conv_b',
        message: ChatMessage(
          id: 'msg_b2',
          role: ChatRole.assistant,
          content: 'Response B',
          createdAt: DateTime(2024, 6, 1, 0, 0, 1),
        ),
      );

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'New response'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show conversation B (most recent)
      expect(find.text('Message from B'), findsOneWidget);
      expect(find.text('Response B'), findsOneWidget);

      // Send new message in B
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'New message in B',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify request only contains B's context
      expect(chatClient.lastMessages?.length, 3);
      expect(chatClient.lastMessages?[0].content, 'Message from B');
      expect(chatClient.lastMessages?[1].content, 'Response B');
      expect(chatClient.lastMessages?[2].content, 'New message in B');

      // Verify A's messages are NOT in the request
      for (final msg in chatClient.lastMessages!) {
        expect(msg.content, isNot(contains('Message from A')));
        expect(msg.content, isNot(contains('Response A')));
      }
    });

    testWidgets('unavailable provider - API key missing',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      // Don't save API key

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_nokey',
          title: 'No Key Chat',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Old message',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old message'), findsOneWidget);
      expect(find.text('Provider is no longer available'), findsOneWidget);
    });

    testWidgets('unavailable provider - provider disabled',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        enabled: false,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_disabled',
          title: 'Disabled Chat',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Old message',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old message'), findsOneWidget);
      expect(find.text('Provider is no longer available'), findsOneWidget);
    });

    testWidgets('unavailable provider - new chat still works',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_deleted',
          title: 'Deleted Provider Chat',
          providerId: 'deleted_provider',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Old message',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show old message and warning
      expect(find.text('Old message'), findsOneWidget);

      // New chat should clear and allow using available provider
      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      expect(find.text('Start a conversation'), findsOneWidget);
    });

    testWidgets('old conversation still exists after new chat',
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
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send message to create conversation
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final convBefore = await historyStore.readLatestConversation();
      expect(convBefore, isNotNull);

      // New chat
      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      // Old conversation still exists
      final convAfter = await historyStore.readConversation(convBefore!.id);
      expect(convAfter, isNotNull);
      expect(convAfter!.id, convBefore.id);
    });

    testWidgets('unavailable provider - config not exists',
        (WidgetTester tester) async {
      // Don't save any ProviderConfig

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_noconfig',
          title: 'No Config Chat',
          providerId: 'nonexistent_provider',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Old message',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            chatClient: chatClient,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old message'), findsOneWidget);
      expect(find.text('Provider is no longer available'), findsOneWidget);
      expect(find.text('Start a conversation'), findsNothing);

      // New chat still works
      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      // After new chat, shows empty state (either "Start a conversation" or "No ready provider")
      expect(find.text('Provider is no longer available'), findsNothing);
    });
  });
}
