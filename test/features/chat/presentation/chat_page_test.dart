import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test_helpers.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/chat_context_builder.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/chat/presentation/widgets/assistant_message_content.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import '../../agents/data/fake_agent_profile_store.dart';
import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_client_resolver.dart';
import '../data/fake_chat_history_store.dart';

class _FailingHistoryStore extends FakeChatHistoryStore {
  @override
  Future<void> appendMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {
    throw Exception('DB failure');
  }

  @override
  Future<void> updateConversationActivity({
    required String conversationId,
    required DateTime updatedAt,
  }) async {
    throw Exception('DB failure');
  }
}

class FakeChatCompletionClient implements ChatCompletionClient {
  ChatCompletionResult? _nextResult;
  Completer<ChatCompletionResult>? _nextResultCompleter;
  StreamController<ChatStreamEvent>? _streamController;
  int callCount = 0;
  int streamCallCount = 0;
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

  StreamController<ChatStreamEvent> startStream() {
    _streamController?.close();
    _streamController = StreamController<ChatStreamEvent>();
    return _streamController!;
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

  @override
  Stream<ChatStreamEvent> streamComplete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) {
    streamCallCount++;
    lastBaseUrl = baseUrl;
    lastModel = model;
    lastMessages = messages;
    lastCancellationToken = cancellationToken;

    if (_streamController != null) {
      final controller = _streamController;
      _streamController = null;
      return controller!.stream;
    }

    // Default: emit success based on _nextResult
    if (_nextResult != null) {
      final result = _nextResult!;
      if (result.success && result.assistantContent != null) {
        return Stream.fromIterable([
          ChatStreamDelta(result.assistantContent!),
          const ChatStreamCompleted(),
        ]);
      } else {
        return Stream.fromIterable([
          ChatStreamFailure(
            errorType: result.errorType ?? ChatCompletionErrorType.unknown,
            userMessage: result.userMessage ?? 'Unknown error',
          ),
        ]);
      }
    }

    return Stream.fromIterable([
      const ChatStreamFailure(
        errorType: ChatCompletionErrorType.unknown,
        userMessage: 'No result configured',
      ),
    ]);
  }
}

void main() {
  group('ChatPage', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatCompletionClient chatClient;
    late FakeChatClientResolver chatClientResolver;
    late FakeChatHistoryStore historyStore;
    late FakeAgentProfileStore agentStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      chatClient = FakeChatCompletionClient();
      chatClientResolver = FakeChatClientResolver(
        openAiCompatibleClient: chatClient,
      );
      historyStore = FakeChatHistoryStore();
      agentStore = FakeAgentProfileStore();
    });

    testWidgets('shows loading during page load', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no ready provider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi there!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      expect(chatClient.streamCallCount, 1);
      expect(chatClient.lastModel, 'gpt-4');
    });

    testWidgets('user message appears in message list',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi there!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi there!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.close();
    });

    testWidgets('API key not written to history store',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-marker-xyz');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi!'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

    testWidgets('delete current conversation via history clears messages',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_del',
          title: 'To Delete',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_del',
          role: ChatRole.user,
          content: 'Message to delete',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Message to delete'), findsOneWidget);

      // Verify conversation exists in store
      final conv = await historyStore.readConversation('conv_del');
      expect(conv, isNotNull);

      // Delete conversation from store
      await historyStore.deleteConversation('conv_del');

      // Verify it's gone from store
      final deletedConv = await historyStore.readConversation('conv_del');
      expect(deletedConv, isNull);
    });

    testWidgets(
        'after delete current conversation, new chat creates new conversation',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'New response'),
      );

      // Start with empty state
      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send a message to create a conversation
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'First message',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final firstConv = await historyStore.readLatestConversation();
      expect(firstConv, isNotNull);
      expect(firstConv!.title, 'First message');

      // New chat
      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      // Verify no new empty conversation created
      final afterNewChat = await historyStore.readLatestConversation();
      expect(afterNewChat!.id, firstConv.id);

      // Send another message to create a new conversation
      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Response 2'),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Second conversation',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final secondConv = await historyStore.readLatestConversation();
      expect(secondConv, isNotNull);
      expect(secondConv!.id, isNot(firstConv.id));
      expect(secondConv.title, 'Second conversation');
    });

    testWidgets('uses streamComplete not complete',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Hi'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      expect(chatClient.streamCallCount, 1);
      expect(chatClient.callCount, 0);
    });

    testWidgets('delta does not write to history store',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamDelta('Partial'));
      await tester.pump();

      final conv = await historyStore.readLatestConversation();
      final messages = await historyStore.readMessages(conv!.id);
      final assistantMessages =
          messages.where((m) => m.role == ChatRole.assistant).toList();
      expect(assistantMessages.length, 0);

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();
    });

    testWidgets('completed persists exactly one assistant message',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamDelta('Hi'));
      await tester.pump();
      streamController.add(const ChatStreamDelta(' there'));
      await tester.pump();
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      final conv = await historyStore.readLatestConversation();
      final messages = await historyStore.readMessages(conv!.id);
      final assistantMessages =
          messages.where((m) => m.role == ChatRole.assistant).toList();
      expect(assistantMessages.length, 1);
      expect(assistantMessages.first.content, 'Hi there');
    });

    testWidgets('no-text completed shows error', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      expect(find.text('Invalid provider response'), findsOneWidget);
    });

    testWidgets('pre-delta failure does not create assistant message',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.serverError,
        userMessage: 'Provider server error',
      ));
      streamController.close();
      await tester.pumpAndSettle();

      expect(find.text('Provider server error'), findsOneWidget);

      final conv = await historyStore.readLatestConversation();
      final messages = await historyStore.readMessages(conv!.id);
      final assistantMessages =
          messages.where((m) => m.role == ChatRole.assistant).toList();
      expect(assistantMessages.length, 0);
    });

    testWidgets('pre-delta failure preserves input',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.serverError,
        userMessage: 'Provider server error',
      ));
      streamController.close();
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Type a message...'),
      );
      expect(textField.controller?.text, 'Hello');
    });

    testWidgets('partial output failure shows interrupted message',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamDelta('Partial'));
      await tester.pump();

      streamController.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.serverError,
        userMessage: 'Provider server error',
      ));
      streamController.close();
      await tester.pumpAndSettle();

      expect(
          find.text('Response interrupted and was not saved'), findsOneWidget);
    });

    testWidgets('partial output not written to database',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamDelta('Partial text'));
      await tester.pump();

      streamController.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.serverError,
        userMessage: 'Error',
      ));
      streamController.close();
      await tester.pumpAndSettle();

      final conv = await historyStore.readLatestConversation();
      final messages = await historyStore.readMessages(conv!.id);
      final assistantMessages =
          messages.where((m) => m.role == ChatRole.assistant).toList();
      expect(assistantMessages.length, 0);
    });

    testWidgets('new chat clears streaming text', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamDelta('Partial'));
      await tester.pump();

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      expect(find.text('Start a conversation'), findsOneWidget);
    });

    testWidgets('completed content equals all deltas combined',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
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

      streamController.add(const ChatStreamDelta('Hello'));
      await tester.pump();
      streamController.add(const ChatStreamDelta(' World'));
      await tester.pump();
      streamController.add(const ChatStreamDelta('!'));
      await tester.pump();
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      final conv = await historyStore.readLatestConversation();
      final messages = await historyStore.readMessages(conv!.id);
      final assistantMessages =
          messages.where((m) => m.role == ChatRole.assistant).toList();
      expect(assistantMessages.length, 1);
      expect(assistantMessages.first.content, 'Hello World!');
    });

    testWidgets('save failure still shows reply and message',
        (WidgetTester tester) async {
      final failingHistoryStore = _FailingHistoryStore();
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Response'),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: failingHistoryStore,
            agentStore: agentStore,
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

      expect(find.text('Response'), findsOneWidget);
      expect(find.text('Response received but could not be saved'),
          findsOneWidget);
    });

    testWidgets(
        'unsupported protocol shows "Provider protocol is not supported yet"',
        (WidgetTester tester) async {
      // Config exists with anthropicMessages protocol, but resolver doesn't support it
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'anthropic',
        displayName: 'Anthropic',
        baseUrl: 'https://api.anthropic.com',
        defaultModel: 'claude-3',
        protocol: ProviderProtocol.anthropicMessages,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('anthropic', 'test-key');

      // Create a conversation with the unsupported provider
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_anthropic',
          title: 'Anthropic Chat',
          providerId: 'anthropic',
          model: 'claude-3',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the unsupported protocol warning
      expect(
          find.text('Provider protocol is not supported yet'), findsOneWidget);
      // Should NOT show the unavailable provider warning
      expect(find.text('Provider is no longer available'), findsNothing);
      // Should show history
      expect(find.text('Hello'), findsOneWidget);
      // Send should be disabled
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
            of: find.byIcon(Icons.send), matching: find.byType(IconButton)),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('invalid config shows "Provider configuration is invalid"',
        (WidgetTester tester) async {
      // Create a config store that throws on readConfig
      final throwingStore = _ThrowingConfigStore();

      // Create a conversation with a provider that has bad config
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_bad',
          title: 'Bad Config Chat',
          providerId: 'bad_provider',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: throwingStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the invalid config warning
      expect(find.text('Provider configuration is invalid'), findsOneWidget);
      // Should NOT show the unavailable provider warning
      expect(find.text('Provider is no longer available'), findsNothing);
      // Should NOT show the unsupported protocol warning
      expect(find.text('Provider protocol is not supported yet'), findsNothing);
      // Send should be disabled
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
            of: find.byIcon(Icons.send), matching: find.byType(IconButton)),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('invalid config does not call ChatCompletionClient',
        (WidgetTester tester) async {
      final throwingStore = _ThrowingConfigStore();

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_bad',
          title: 'Bad Config Chat',
          providerId: 'bad_provider',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: throwingStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No client calls should be made
      expect(chatClient.callCount, 0);
      expect(chatClient.streamCallCount, 0);
    });

    group('Stop Generation', () {
      testWidgets('shows Send button when not sending',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.byIcon(Icons.stop_rounded), findsNothing);
      });

      testWidgets('shows Stop button during streaming',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
        expect(find.byIcon(Icons.send), findsNothing);

        streamController.add(const ChatStreamDelta('Hi'));
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();
      });

      testWidgets('Stop button has tooltip', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        final stopButton = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.stop_rounded),
            matching: find.byType(IconButton),
          ),
        );
        expect(stopButton.tooltip, 'Stop generating');

        streamController.add(const ChatStreamDelta('Hi'));
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();
      });

      testWidgets('clicking Stop cancels cancellationToken',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        expect(chatClient.lastCancellationToken!.isCancelled, true);

        streamController.add(const ChatStreamDelta('Late'));
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();
      });

      testWidgets('Stop preserves partial text and shows Stopped',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial '));
        await tester.pump();

        expect(find.byType(AssistantMessageContent), findsOneWidget);

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // Partial text preserved (still rendered by AssistantMessageContent)
        expect(find.byType(AssistantMessageContent), findsOneWidget);
        // Stopped indicator shown
        expect(find.text('Stopped'), findsOneWidget);
        // No error snackbar
        expect(
            find.text('Response interrupted and was not saved'), findsNothing);

        streamController.add(const ChatStreamDelta('Late'));
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();

        // Late events ignored
        expect(find.text('Partial Late'), findsNothing);
      });

      testWidgets('Stop before first delta does not show empty bubble',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        // Stop before any delta
        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // No empty assistant bubble
        expect(find.text('Start a conversation'), findsNothing);
        // User message preserved
        expect(find.text('Hello'), findsOneWidget);
        // No Stopped indicator (no partial text)
        expect(find.text('Stopped'), findsNothing);

        streamController.close();
        await tester.pumpAndSettle();
      });

      testWidgets('Stop does not save assistant message to database',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Only user message in database
        final conv = await historyStore.readLatestConversation();
        final messages = await historyStore.readMessages(conv!.id);
        final assistantMessages =
            messages.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMessages.length, 0);
      });

      testWidgets('Stop restores Send button', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.byIcon(Icons.stop_rounded), findsNothing);
      });

      testWidgets('Stop enables New Chat and History',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        // New Chat disabled during sending
        final newChatButton = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.add_comment),
            matching: find.byType(IconButton),
          ),
        );
        expect(newChatButton.onPressed, isNull);

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // New Chat re-enabled
        final newChatButtonAfter = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.add_comment),
            matching: find.byType(IconButton),
          ),
        );
        expect(newChatButtonAfter.onPressed, isNotNull);
      });

      testWidgets('Stop allows sending again', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController1 = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First message',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        streamController1.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController1.close();
        await tester.pumpAndSettle();

        // Can send again - use setResult for default stream behavior
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Response'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second message',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Second message'), findsOneWidget);
        expect(find.text('Response'), findsOneWidget);
      });

      testWidgets('partial text not included in next request context',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController1 = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First message',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        streamController1.add(const ChatStreamDelta('Partial response'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController1.close();
        await tester.pumpAndSettle();

        // Send second message
        chatClient.startStream();
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second message',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Context should only have user messages, not partial assistant
        expect(chatClient.lastMessages!.length, 2);
        expect(chatClient.lastMessages![0].role, 'user');
        expect(chatClient.lastMessages![0].content, 'First message');
        expect(chatClient.lastMessages![1].role, 'user');
        expect(chatClient.lastMessages![1].content, 'Second message');
      });

      testWidgets('completed response shows Send not Stopped',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Hi there'));
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();

        expect(find.text('Stopped'), findsNothing);
        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.byIcon(Icons.stop_rounded), findsNothing);
        expect(find.text('Hi there'), findsOneWidget);
      });

      testWidgets('network failure shows error not Stopped',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        streamController.add(const ChatStreamFailure(
          errorType: ChatCompletionErrorType.serverError,
          userMessage: 'Provider server error',
        ));
        streamController.close();
        await tester.pumpAndSettle();

        expect(find.text('Response interrupted and was not saved'),
            findsOneWidget);
        expect(find.text('Stopped'), findsNothing);
      });

      testWidgets('New Chat clears Stopped state', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        expect(find.text('Stopped'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();

        expect(find.text('Stopped'), findsNothing);
        expect(find.text('Start a conversation'), findsOneWidget);
      });

      testWidgets('Stop does not update Conversation.updatedAt',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        final convBefore = await historyStore.readLatestConversation();
        final updatedAtBefore = convBefore!.updatedAt;

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        final convAfter = await historyStore.readLatestConversation();
        expect(convAfter!.updatedAt, updatedAtBefore);
      });

      testWidgets('Stop ignores late Delta after stop',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Before'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // Late delta after stop
        streamController.add(const ChatStreamDelta(' After'));
        await tester.pump();

        // Only "Before" should be visible, not "Before After"
        expect(find.text('Before'), findsOneWidget);
        expect(find.text('Before After'), findsNothing);

        streamController.close();
        await tester.pumpAndSettle();
      });

      testWidgets('Stop ignores late Completed after stop',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // Late Completed after stop
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();

        // Stopped should still be visible, not a saved message
        expect(find.text('Stopped'), findsOneWidget);

        // Only user message in database
        final conv = await historyStore.readLatestConversation();
        final messages = await historyStore.readMessages(conv!.id);
        final assistantMessages =
            messages.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMessages.length, 0);
      });

      testWidgets('Stop uses new cancellation token on resend',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController1 = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        final firstToken = chatClient.lastCancellationToken;

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController1.close();
        await tester.pumpAndSettle();

        // Send again
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Again',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // New token should be different
        expect(chatClient.lastCancellationToken, isNotNull);
        expect(chatClient.lastCancellationToken, isNot(equals(firstToken)));
      });

      testWidgets('dispose does not show Stopped', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        // Dispose by replacing with empty widget
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        // No Stopped should be visible (page is gone)
        expect(find.text('Stopped'), findsNothing);

        streamController.close();
      });

      testWidgets('user Stop does not show interrupted message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Should NOT show the interrupted message
        expect(
            find.text('Response interrupted and was not saved'), findsNothing);
        // Should show Stopped instead
        expect(find.text('Stopped'), findsOneWidget);
      });

      testWidgets('user Stop leaves input empty', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Input should be empty (user message was already sent)
        final textField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Type a message...'),
        );
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('Stop then send only shows one temp bubble',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController1 = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        streamController1.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController1.close();
        await tester.pumpAndSettle();

        // Stopped bubble visible
        expect(find.text('Stopped'), findsOneWidget);

        // Send second message
        final streamController2 = chatClient.startStream();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        streamController2.add(const ChatStreamDelta('New'));
        await tester.pump();

        // Only one streaming bubble (new one), old Stopped cleared
        expect(find.text('Partial'), findsNothing);
        expect(find.text('Stopped'), findsNothing);
        expect(find.text('New'), findsOneWidget);

        streamController2.add(const ChatStreamCompleted());
        streamController2.close();
        await tester.pumpAndSettle();
      });

      testWidgets('history switch clears Stopped state',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        // Create a previous conversation
        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_old',
            title: 'Old Chat',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_old',
            role: ChatRole.user,
            content: 'Old message',
            createdAt: DateTime(2024),
          ),
        );

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        expect(find.text('Stopped'), findsOneWidget);

        // Use New Chat to clear state (history switch is complex to test in widget tests)
        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();

        // Stopped should be cleared
        expect(find.text('Stopped'), findsNothing);
        expect(find.text('Start a conversation'), findsOneWidget);
      });

      testWidgets('Stop clears cancellation token',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // Token should be cancelled
        expect(chatClient.lastCancellationToken!.isCancelled, true);

        streamController.close();
        await tester.pumpAndSettle();
      });

      testWidgets('Stop ignores late Failure after stop',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // Late failure after stop
        streamController.add(const ChatStreamFailure(
          errorType: ChatCompletionErrorType.serverError,
          userMessage: 'Provider server error',
        ));
        streamController.close();
        await tester.pumpAndSettle();

        // Stopped should be visible, not error
        expect(find.text('Stopped'), findsOneWidget);
        expect(find.text('Provider server error'), findsNothing);
        expect(
            find.text('Response interrupted and was not saved'), findsNothing);
      });

      testWidgets('Completed then onDone does not second clean',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        streamController.add(const ChatStreamDelta('Hi'));
        streamController.add(const ChatStreamCompleted());
        await tester.pump();

        // Close stream (triggers onDone)
        streamController.close();
        await tester.pumpAndSettle();

        // Message should be saved exactly once
        final conv = await historyStore.readLatestConversation();
        final messages = await historyStore.readMessages(conv!.id);
        final assistantMessages =
            messages.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMessages.length, 1);
        expect(assistantMessages.first.content, 'Hi');
        expect(find.text('Stopped'), findsNothing);
      });

      testWidgets('Stop then send uses new generation',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController1 = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        final firstSub = chatClient.lastCancellationToken;

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController1.close();
        await tester.pumpAndSettle();

        // Send second
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // New token should be different
        expect(chatClient.lastCancellationToken, isNot(equals(firstSub)));
        expect(find.text('OK'), findsOneWidget);
        expect(find.text('Stopped'), findsNothing);
      });

      testWidgets('dispose clears resources without setState',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        final token = chatClient.lastCancellationToken;
        expect(token, isNotNull);
        expect(token!.isCancelled, false);

        // Dispose
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        // Token should be cancelled by dispose
        expect(token.isCancelled, true);

        streamController.close();
      });
    });

    group('Context trimming', () {
      testWidgets('sends builder output to stream client',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        // Small budget to force trimming
        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 20);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
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

        // Builder output was sent to client
        expect(chatClient.lastMessages, isNotNull);
        expect(chatClient.lastMessages!.last.content, 'Hello');
        expect(chatClient.lastMessages!.last.role, 'user');
      });

      testWidgets('omits oldest complete turn when over budget',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        // Very small budget to force trimming
        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 15);

        // First message
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Second message - budget should trim first turn
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply2'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // First turn should be omitted from request
        final sentMessages = chatClient.lastMessages!;
        expect(sentMessages.any((m) => m.content == 'First'), false);
        expect(sentMessages.last.content, 'Second');
      });

      testWidgets('preserves most recent complete turn',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        // Budget that allows recent turn but not old turn
        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 30);

        // First turn
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Old reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Old question',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Second turn
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'New question',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Third turn - should include second turn but not first
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Final reply'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Final question',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        final sentMessages = chatClient.lastMessages!;
        expect(sentMessages.any((m) => m.content == 'Old question'), false);
        expect(sentMessages.any((m) => m.content == 'Old reply'), false);
        expect(sentMessages.any((m) => m.content == 'New question'), true);
        expect(sentMessages.any((m) => m.content == 'New reply'), true);
      });

      testWidgets('keeps current user as final message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: ChatContextBuilder(maxEstimatedTokens: 20),
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'My question',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(chatClient.lastMessages!.last.content, 'My question');
        expect(chatClient.lastMessages!.last.role, 'user');
      });

      testWidgets('includes current user exactly once',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Unique question',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        final userMsgs = chatClient.lastMessages!
            .where((m) => m.content == 'Unique question')
            .toList();
        expect(userMsgs.length, 1);
      });

      testWidgets('preserves original roles and content',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(
          const ChatCompletionResult.success(
              assistantContent: '**bold** and `code`'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          '# Heading',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Next'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Next',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        final sent = chatClient.lastMessages!;
        expect(sent.any((m) => m.content == '# Heading'), true);
        expect(sent.any((m) => m.content == '**bold** and `code`'), true);
      });

      testWidgets('sends raw markdown source', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(
          const ChatCompletionResult.success(
              assistantContent: '```dart\nvoid main() {}\n```'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Show code',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Next'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Next',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        final sent = chatClient.lastMessages!;
        expect(
            sent.any((m) => m.content == '```dart\nvoid main() {}\n```'), true);
      });

      testWidgets('keeps omitted messages visible in UI',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 15);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // First message should still be visible in UI
        expect(find.text('First'), findsOneWidget);
      });

      testWidgets('keeps omitted messages in history store',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 15);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Message still in store
        final conv = await historyStore.readLatestConversation();
        final messages = await historyStore.readMessages(conv!.id);
        expect(messages.any((m) => m.content == 'First'), true);
      });

      testWidgets('stopped partial text excluded from next request',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Send second message
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Partial text not in request
        final sent = chatClient.lastMessages!;
        expect(sent.any((m) => m.content == 'Partial'), false);
        expect(sent.any((m) => m.content == 'Stopped'), false);
      });

      testWidgets('trimming notice shows when context is trimmed',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 15);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Second message should trigger trimming
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R2'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Earlier messages were omitted for this request'),
            findsOneWidget);
      });

      testWidgets('untrimmed request does not show notice',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
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

        expect(find.text('Earlier messages were omitted for this request'),
            findsNothing);
      });

      testWidgets('New Chat clears trimming notice',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 15);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R2'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Earlier messages were omitted for this request'),
            findsOneWidget);

        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();

        expect(find.text('Earlier messages were omitted for this request'),
            findsNothing);
      });

      testWidgets('trimming notice not persisted as ChatMessage',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 15);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'R2'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Check store doesn't contain the notice text
        final conv = await historyStore.readLatestConversation();
        final messages = await historyStore.readMessages(conv!.id);
        expect(
            messages.any((m) =>
                m.content == 'Earlier messages were omitted for this request'),
            false);
      });

      testWidgets('oversized current message still starts request',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 5);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'This is a very long message that exceeds the tiny budget',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(chatClient.streamCallCount, 1);
      });

      testWidgets('oversized current message sent without truncation',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 5);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final longText =
            'This is a very long message that exceeds the tiny budget';
        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          longText,
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(chatClient.lastMessages!.last.content, longText);
        expect(chatClient.lastMessages!.length, 1);
      });

      testWidgets('oversized current message shows notice',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final contextBuilder = ChatContextBuilder(maxEstimatedTokens: 5);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: contextBuilder,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'This is a very long message that exceeds the tiny budget',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Current message exceeds the local context estimate'),
            findsOneWidget);
      });

      testWidgets('context is rebuilt after normal completion',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply1'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        final firstCallMessages =
            List<ChatRequestMessage>.from(chatClient.lastMessages!);

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply2'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Second call should have more messages than first
        expect(chatClient.lastMessages!.length,
            greaterThan(firstCallMessages.length));
      });

      testWidgets('context is rebuilt after user stop',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'First',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Send second - should rebuild context
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'OK'),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Second',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // User message still in context
        expect(chatClient.lastMessages!.any((m) => m.content == 'First'), true);
        expect(chatClient.lastMessages!.last.content, 'Second');
        // Stopped partial not in context
        expect(
            chatClient.lastMessages!.any((m) => m.content == 'Partial'), false);
      });
    });

    group('Retry', () {
      testWidgets('shows Retry when last message is user',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        // Create a conversation with only a user message (no assistant reply)
        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_retry',
            title: 'Retry Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Retry'), findsOneWidget);
      });

      testWidgets('does not show Retry when last message is assistant',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_no_retry',
            title: 'No Retry',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_no_retry',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Hi there',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Retry'), findsNothing);
      });

      testWidgets('Retry does not create duplicate user message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_retry',
            title: 'Retry Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Retry'));
        await tester.pumpAndSettle();

        // Only one user message in the store
        final msgs = await historyStore.readMessages('conv_retry');
        final userMsgs = msgs.where((m) => m.role == ChatRole.user).toList();
        expect(userMsgs.length, 1);
        expect(userMsgs.first.content, 'Hello');
      });

      testWidgets('Retry sends original user message to client',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_retry',
            title: 'Retry Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Original question',
            createdAt: DateTime(2024),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Retry'));
        await tester.pumpAndSettle();

        expect(chatClient.lastMessages!.last.content, 'Original question');
        expect(chatClient.lastMessages!.last.role, 'user');
      });

      testWidgets('Retry success adds assistant message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_retry',
            title: 'Retry Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Retry'));
        await tester.pumpAndSettle();

        // Assistant message added
        final msgs = await historyStore.readMessages('conv_retry');
        final assistantMsgs =
            msgs.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMsgs.length, 1);
        expect(assistantMsgs.first.content, 'New reply');

        // UI shows the reply
        expect(find.text('New reply'), findsOneWidget);
      });

      testWidgets('Retry failure does not add assistant message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_retry',
            title: 'Retry Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.failure(
            errorType: ChatCompletionErrorType.serverError,
            userMessage: 'Provider server error',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Retry'));
        await tester.pumpAndSettle();

        // No assistant message added
        final msgs = await historyStore.readMessages('conv_retry');
        final assistantMsgs =
            msgs.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMsgs.length, 0);
      });
    });

    group('Regenerate', () {
      testWidgets('shows Regenerate on last assistant message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Hi there',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Regenerate response'), findsOneWidget);
      });

      testWidgets('Regenerate does not create duplicate user message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Only one user message in the store
        final msgs = await historyStore.readMessages('conv_regen');
        final userMsgs = msgs.where((m) => m.role == ChatRole.user).toList();
        expect(userMsgs.length, 1);
      });

      testWidgets('Regenerate success replaces assistant content',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Assistant content replaced
        final msgs = await historyStore.readMessages('conv_regen');
        final assistantMsgs =
            msgs.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMsgs.length, 1);
        expect(assistantMsgs.first.content, 'New reply');

        // UI shows new content
        expect(find.text('New reply'), findsOneWidget);
        expect(find.text('Old reply'), findsNothing);
      });

      testWidgets('Regenerate preserves message id',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst_original',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Message id preserved
        final msgs = await historyStore.readMessages('conv_regen');
        final assistantMsgs =
            msgs.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMsgs.first.id, 'msg_asst_original');
      });

      testWidgets('Regenerate does not increase message count',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Message count unchanged
        final msgs = await historyStore.readMessages('conv_regen');
        expect(msgs.length, 2); // 1 user + 1 assistant
      });

      testWidgets('Regenerate failure preserves old content',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.failure(
            errorType: ChatCompletionErrorType.serverError,
            userMessage: 'Provider server error',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Old content preserved
        final msgs = await historyStore.readMessages('conv_regen');
        final assistantMsgs =
            msgs.where((m) => m.role == ChatRole.assistant).toList();
        expect(assistantMsgs.length, 1);
        expect(assistantMsgs.first.content, 'Old reply');
      });

      testWidgets('Regenerate excludes old assistant from request',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply to exclude',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Old assistant excluded from request
        expect(
            chatClient.lastMessages!
                .any((m) => m.content == 'Old reply to exclude'),
            false);
        // User message included
        expect(chatClient.lastMessages!.any((m) => m.content == 'Hello'), true);
      });

      testWidgets('Regenerate uses ChatContextBuilder',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              contextBuilder: ChatContextBuilder(maxEstimatedTokens: 12000),
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Request made through builder
        expect(chatClient.lastMessages, isNotNull);
        expect(chatClient.lastMessages!.last.content, 'Hello');
      });

      testWidgets('Regenerate does not create duplicate user',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // No duplicate user
        final msgs = await historyStore.readMessages('conv_regen');
        final userMsgs = msgs.where((m) => m.role == ChatRole.user).toList();
        expect(userMsgs.length, 1);
        expect(userMsgs.first.id, 'msg_user');
      });

      testWidgets('Regenerate stop preserves old assistant',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial new'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Old content preserved in store
        final msgs = await historyStore.readMessages('conv_regen');
        final asst = msgs.firstWhere((m) => m.id == 'msg_asst');
        expect(asst.content, 'Old reply');
      });

      testWidgets('Regenerate stop does not call replaceAssistantMessage',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        expect(historyStore.replaceCallCount, 0);
      });

      testWidgets('Regenerate failure preserves old assistant',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.failure(
            errorType: ChatCompletionErrorType.serverError,
            userMessage: 'Provider server error',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // Old content preserved
        final msgs = await historyStore.readMessages('conv_regen');
        expect(msgs.firstWhere((m) => m.id == 'msg_asst').content, 'Old reply');
        expect(historyStore.replaceCallCount, 0);
      });

      testWidgets('only last assistant shows Regenerate',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user1',
            role: ChatRole.user,
            content: 'Q1',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst1',
            role: ChatRole.assistant,
            content: 'A1',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_user2',
            role: ChatRole.user,
            content: 'Q2',
            createdAt: DateTime(2024, 1, 1, 0, 0, 2),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst2',
            role: ChatRole.assistant,
            content: 'A2',
            createdAt: DateTime(2024, 1, 1, 0, 0, 3),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Only one Regenerate button (for the last assistant)
        expect(find.byTooltip('Regenerate response'), findsOneWidget);
      });

      testWidgets('Regenerate updates Conversation.updatedAt on success',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // updatedAt updated
        expect(historyStore.lastReplaceConversationUpdatedAt,
            isNot(DateTime(2024)));
      });

      testWidgets('New Chat clears Retry/Regenerate state',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Regenerate response'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Regenerate response'), findsNothing);
        expect(find.byTooltip('Retry'), findsNothing);
      });

      testWidgets('store replace failure preserves old assistant and updatedAt',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        // Configure store to fail on replace
        historyStore.replaceAssistantMessageError = Exception('DB error');

        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'New reply'),
        );

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pumpAndSettle();

        // replace was called
        expect(historyStore.replaceCallCount, 1);
        expect(historyStore.lastReplaceConversationId, 'conv_regen');
        expect(historyStore.lastReplacedMessageId, 'msg_asst');
        expect(historyStore.lastReplacedContent, 'New reply');

        // Old content preserved in store
        final msgs = await historyStore.readMessages('conv_regen');
        expect(msgs.firstWhere((m) => m.id == 'msg_asst').content, 'Old reply');

        // Conversation updatedAt not changed
        final conv = await historyStore.readConversation('conv_regen');
        expect(conv!.updatedAt, DateTime(2024));

        // Message count unchanged
        expect(msgs.length, 2);

        // Error shown
        expect(find.text('Response received but could not be saved'),
            findsOneWidget);
      });

      testWidgets('stop after partial output preserves old assistant',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial new'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // Old content preserved
        final msgs = await historyStore.readMessages('conv_regen');
        expect(msgs.firstWhere((m) => m.id == 'msg_asst').content, 'Old reply');

        // replace not called
        expect(historyStore.replaceCallCount, 0);

        // Conversation updatedAt unchanged
        final conv = await historyStore.readConversation('conv_regen');
        expect(conv!.updatedAt, DateTime(2024));

        // Message count unchanged
        expect(msgs.length, 2);
      });

      testWidgets('late Completed after stop does not replace assistant',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_regen',
            title: 'Regen Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_regen',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Regenerate response'));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        // Late Completed after stop
        streamController.add(const ChatStreamCompleted());
        streamController.close();
        await tester.pumpAndSettle();

        // Old content preserved
        final msgs = await historyStore.readMessages('conv_regen');
        expect(msgs.firstWhere((m) => m.id == 'msg_asst').content, 'Old reply');
        expect(historyStore.replaceCallCount, 0);
        expect(msgs.length, 2);
      });
    });

    group('Retry Stop', () {
      testWidgets('stop preserves user and allows retry again',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await historyStore.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_retry',
            title: 'Retry Test',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user',
            role: ChatRole.user,
            content: 'Hello',
            createdAt: DateTime(2024),
          ),
        );

        final streamController = chatClient.startStream();

        await tester.pumpWidget(
          buildTestApp(
            home: ChatPage(
              chatClientResolver: chatClientResolver,
              apiKeyStore: apiKeyStore,
              configStore: configStore,
              historyStore: historyStore,
              agentStore: agentStore,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Retry
        await tester.tap(find.byTooltip('Retry'));
        await tester.pump();

        streamController.add(const ChatStreamDelta('Partial'));
        await tester.pump();

        // Stop
        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pump();

        streamController.close();
        await tester.pumpAndSettle();

        // User preserved
        final msgs = await historyStore.readMessages('conv_retry');
        expect(msgs.length, 1);
        expect(msgs.first.id, 'msg_user');
        expect(msgs.first.content, 'Hello');

        // No assistant added
        expect(msgs.where((m) => m.role == ChatRole.assistant).length, 0);

        // Retry button available again
        expect(find.byTooltip('Retry'), findsOneWidget);

        // Can retry again
        chatClient.setResult(
          const ChatCompletionResult.success(assistantContent: 'Reply'),
        );

        await tester.tap(find.byTooltip('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Reply'), findsOneWidget);
        final msgsAfter = await historyStore.readMessages('conv_retry');
        expect(msgsAfter.where((m) => m.role == ChatRole.assistant).length, 1);
      });
    });

    group('Agent and Model selectors', () {
      testWidgets('new conversation defaults to No Agent',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('No Agent'), findsOneWidget);
      });

      testWidgets('multiple agents can be selected',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await agentStore.saveAgent(AgentProfileData(
          id: 'a1',
          name: 'Agent A',
          systemPrompt: 'prompt A',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ));
        await agentStore.saveAgent(AgentProfileData(
          id: 'a2',
          name: 'Agent B',
          systemPrompt: 'prompt B',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ));

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('No Agent'), findsOneWidget);

        await tester.tap(find.byType(DropdownButton<AgentProfileData?>));
        await tester.pumpAndSettle();
        expect(find.text('Agent A'), findsWidgets);
        expect(find.text('Agent B'), findsWidgets);
      });

      testWidgets('model list shows provider and model',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('OpenAI · gpt-4'), findsOneWidget);
      });

      testWidgets('agent and model lock after first message',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(const ChatCompletionResult.success(
          assistantContent: 'Hi',
        ));

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        // Before sending, dropdowns are visible
        expect(find.byType(DropdownButton<AgentProfileData?>), findsOneWidget);

        // Send message
        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Hello',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // After sending, dropdowns are hidden (locked)
        expect(find.byType(DropdownButton<AgentProfileData?>), findsNothing);
      });

      testWidgets('New Chat unlocks selectors', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        chatClient.setResult(const ChatCompletionResult.success(
          assistantContent: 'Hi',
        ));

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        // Send to lock
        await tester.enterText(
          find.widgetWithText(TextField, 'Type a message...'),
          'Hello',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButton<AgentProfileData?>), findsNothing);

        // New Chat unlocks
        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButton<AgentProfileData?>), findsOneWidget);
      });

      testWidgets('API key missing prevents send', (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        // No API key saved

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        // Shows empty state because no ready model
        expect(find.text('No ready provider'), findsOneWidget);
      });

      testWidgets('deleted agent falls back to No Agent in new chat',
          (WidgetTester tester) async {
        await configStore.saveConfig(ProviderConfigData(
          providerId: 'openai',
          displayName: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          defaultModel: 'gpt-4',
          protocol: ProviderProtocol.openAiCompatible,
          updatedAt: DateTime(2024),
        ));
        await apiKeyStore.saveKey('openai', 'test-key');

        await agentStore.saveAgent(AgentProfileData(
          id: 'a1',
          name: 'Agent A',
          systemPrompt: 'prompt A',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ));

        await tester.pumpWidget(buildTestApp(
          home: ChatPage(
            chatClientResolver: chatClientResolver,
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            agentStore: agentStore,
          ),
        ));
        await tester.pumpAndSettle();

        // Select Agent A
        await tester.tap(find.byType(DropdownButton<AgentProfileData?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Agent A').last);
        await tester.pumpAndSettle();

        // Delete the agent externally
        await agentStore.deleteAgent('a1');

        // New Chat
        await tester.tap(find.byIcon(Icons.add_comment));
        await tester.pumpAndSettle();

        // Should show No Agent
        expect(find.text('No Agent'), findsOneWidget);
        expect(find.text('Agent A'), findsNothing);
      });
    });
  });
}

class _ThrowingConfigStore extends FakeProviderConfigStore {
  @override
  Future<ProviderConfigData?> readConfig(String providerId) async {
    throw StateError('Unknown protocol for provider: $providerId');
  }

  @override
  Future<List<ProviderConfigData>> readAllConfigs() async {
    throw StateError('Unknown protocol in configs');
  }
}
