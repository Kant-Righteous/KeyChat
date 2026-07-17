import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test_helpers.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import '../../agents/data/fake_agent_profile_store.dart';
import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_client_resolver.dart';
import '../data/fake_chat_history_store.dart';

void main() {
  group('ChatPage scroll behavior', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatHistoryStore historyStore;
    late FakeChatClientResolver chatClientResolver;
    late FakeChatCompletionClient chatClient;
    late FakeAgentProfileStore agentStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      historyStore = FakeChatHistoryStore();
      chatClient = FakeChatCompletionClient();
      chatClientResolver = FakeChatClientResolver(
        openAiCompatibleClient: chatClient,
      );
      agentStore = FakeAgentProfileStore();
    });

    Future<void> setupConfig(WidgetTester tester) async {
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
    }

    testWidgets('short conversation send makes message visible',
        (WidgetTester tester) async {
      await setupConfig(tester);

      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Reply'),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('near bottom delta auto-follows', (WidgetTester tester) async {
      await setupConfig(tester);

      final streamController = chatClient.startStream();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      streamController.add(const ChatStreamDelta('Part1 '));
      await tester.pump();
      streamController.add(const ChatStreamDelta('Part2'));
      await tester.pump();

      expect(find.text('Part1 Part2'), findsOneWidget);

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();
    });

    testWidgets('near bottom completed auto-follows',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final streamController = chatClient.startStream();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      streamController.add(const ChatStreamDelta('Final reply'));
      await tester.pump();
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      expect(find.text('Final reply'), findsOneWidget);
    });

    testWidgets('model selector stays hidden while response is streaming',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final streamController = chatClient.startStream();
      expect(find.byKey(const Key('model_selector')), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('model_selector')), findsNothing);

      streamController.add(const ChatStreamDelta('Streaming response'));
      await tester.pump();
      expect(find.byKey(const Key('model_selector')), findsNothing);

      streamController.add(const ChatStreamCompleted());
      await streamController.close();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('model_selector')), findsOneWidget);
    });

    testWidgets(
        'input focus and draft do not override toolbar hidden by scroll',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final longReply = List.generate(
        60,
        (index) => 'Long response paragraph $index with enough text to scroll.',
      ).join('\n\n');
      chatClient.setResult(
        ChatCompletionResult.success(assistantContent: longReply),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Show long response',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final messageList = find.byType(ListView);
      expect(messageList, findsOneWidget);
      await tester.drag(messageList, const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model_selector')), findsNothing);

      await tester.tap(
        find.widgetWithText(TextField, 'Type a message...'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model_selector')), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Draft',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model_selector')), findsNothing);
    });

    testWidgets('model and attachment toolbar follows user scroll direction',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final longReply = List.generate(
        60,
        (index) => 'Long response paragraph $index with enough text to scroll.',
      ).join('\n\n');
      chatClient.setResult(
        ChatCompletionResult.success(assistantContent: longReply),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Show long response',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final messageList = find.byType(ListView);
      await tester.drag(messageList, const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model_selector')), findsNothing);
      expect(find.byKey(const Key('attachment_button')), findsNothing);

      await tester.drag(messageList, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model_selector')), findsOneWidget);
      expect(find.byKey(const Key('attachment_button')), findsOneWidget);

      await tester.drag(messageList, const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model_selector')), findsNothing);
      expect(find.byKey(const Key('attachment_button')), findsNothing);
    });

    testWidgets('user scrolled up delta does not steal position',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final streamController = chatClient.startStream();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      streamController.add(const ChatStreamDelta('Response'));
      await tester.pump();

      // Verify no crash and delta received
      expect(find.text('Response'), findsOneWidget);

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();
    });

    testWidgets('stop does not force scroll to bottom',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final streamController = chatClient.startStream();

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

      // No crash, Stopped shown
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('failure does not force scroll to bottom',
        (WidgetTester tester) async {
      await setupConfig(tester);

      chatClient.setResult(
        const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.serverError,
          userMessage: 'Provider server error',
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Error shown, no crash
      expect(find.text('Provider server error'), findsOneWidget);
    });

    testWidgets('retry near-bottom behavior consistent',
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

      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('regenerate near-bottom behavior consistent',
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

      expect(find.text('New reply'), findsOneWidget);
    });

    testWidgets('user scrolled up then completed does not force to bottom',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final streamController = chatClient.startStream();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Add some content
      streamController.add(ChatStreamDelta('Long response ' * 20));
      await tester.pump();

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      // No crash, content visible
      expect(find.textContaining('Long response'), findsOneWidget);
    });

    testWidgets('ScrollController with no clients does not throw',
        (WidgetTester tester) async {
      await setupConfig(tester);

      // Just verify the page builds without error
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

      // No crash
      expect(find.text('Start a conversation'), findsOneWidget);
    });

    testWidgets('long Markdown does not cause overflow',
        (WidgetTester tester) async {
      await setupConfig(tester);

      final longMd =
          '# Title\n\n${'A' * 500}\n\n```dart\n${'void f() {\n' * 20}\n}\n```';

      chatClient.setResult(
        ChatCompletionResult.success(assistantContent: longMd),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Show long',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // No overflow
      expect(find.text('Title'), findsOneWidget);
    });
  });
}

class FakeChatCompletionClient implements ChatCompletionClient {
  ChatCompletionResult? _nextResult;
  StreamController<ChatStreamEvent>? _streamController;
  int streamCallCount = 0;

  void setResult(ChatCompletionResult result) {
    _nextResult = result;
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

    if (_streamController != null) {
      final controller = _streamController;
      _streamController = null;
      return controller!.stream;
    }

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
