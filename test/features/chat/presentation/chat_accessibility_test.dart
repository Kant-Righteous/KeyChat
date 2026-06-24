import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test_helpers.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/chat/presentation/conversation_list_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import '../../agents/data/fake_agent_profile_store.dart';
import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_client_resolver.dart';
import '../data/fake_chat_history_store.dart';

void main() {
  group('ChatPage accessibility', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatHistoryStore historyStore;
    late FakeChatClientResolver chatClientResolver;
    late _StreamChatClient chatClient;
    late FakeAgentProfileStore agentStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      historyStore = FakeChatHistoryStore();
      chatClient = _StreamChatClient();
      chatClientResolver = FakeChatClientResolver(
        openAiCompatibleClient: chatClient,
      );
      agentStore = FakeAgentProfileStore();
    });

    Future<void> setupConfig() async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');
    }

    Widget buildChatPage() {
      return buildTestApp(
        home: ChatPage(
          chatClientResolver: chatClientResolver,
          apiKeyStore: apiKeyStore,
          configStore: configStore,
          historyStore: historyStore,
          agentStore: agentStore,
        ),
      );
    }

    testWidgets('idle state meets all guidelines', (WidgetTester tester) async {
      await setupConfig();
      await tester.pumpWidget(buildChatPage());
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      semantics.dispose();
    });

    testWidgets('send ready state meets all guidelines',
        (WidgetTester tester) async {
      await setupConfig();
      await tester.pumpWidget(buildChatPage());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.pump();

      final semantics = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      semantics.dispose();
    });

    testWidgets('streaming stop state meets all guidelines',
        (WidgetTester tester) async {
      await setupConfig();
      final streamController = chatClient.startStream();

      await tester.pumpWidget(buildChatPage());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      streamController.add(const ChatStreamDelta('Partial'));
      await tester.pump();

      final semantics = tester.ensureSemantics();

      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      semantics.dispose();

      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();
    });

    testWidgets('completed assistant with actions meets all guidelines',
        (WidgetTester tester) async {
      await setupConfig();

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_a11y',
          title: 'A11y Test',
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
        conversationId: 'conv_a11y',
        message: ChatMessage(
          id: 'msg_asst',
          role: ChatRole.assistant,
          content: 'Hi there',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      await tester.pumpWidget(buildChatPage());
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();

      expect(find.byTooltip('Copy response'), findsOneWidget);
      expect(find.byTooltip('Regenerate response'), findsOneWidget);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      semantics.dispose();
    });

    testWidgets('retry state meets all guidelines',
        (WidgetTester tester) async {
      await setupConfig();

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

      await tester.pumpWidget(buildChatPage());
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();

      expect(find.byTooltip('Retry'), findsOneWidget);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      semantics.dispose();
    });

    testWidgets('stopped state meets all guidelines',
        (WidgetTester tester) async {
      await setupConfig();
      final streamController = chatClient.startStream();

      await tester.pumpWidget(buildChatPage());
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

      final semantics = tester.ensureSemantics();

      expect(find.text('Stopped'), findsOneWidget);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      semantics.dispose();
    });
  });

  group('ConversationListPage accessibility', () {
    late FakeChatHistoryStore historyStore;
    late FakeProviderConfigStore configStore;

    setUp(() {
      historyStore = FakeChatHistoryStore();
      configStore = FakeProviderConfigStore();
    });

    testWidgets('empty state meets all guidelines',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ConversationListPage(
          historyStore: historyStore,
          configStore: configStore,
        ),
      ));
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      semantics.dispose();
    });

    testWidgets('with conversations meets all guidelines',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test Chat',
          providerId: 'openai',
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

      await tester.pumpWidget(MaterialApp(
        home: ConversationListPage(
          historyStore: historyStore,
          configStore: configStore,
        ),
      ));
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      semantics.dispose();
    });
  });
}

class _StreamChatClient implements ChatCompletionClient {
  StreamController<ChatStreamEvent>? _streamController;

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
    return const ChatCompletionResult.failure(
      errorType: ChatCompletionErrorType.unknown,
      userMessage: 'No-op',
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
    if (_streamController != null) {
      final c = _streamController;
      _streamController = null;
      return c!.stream;
    }
    return Stream.fromIterable([
      const ChatStreamFailure(
        errorType: ChatCompletionErrorType.unknown,
        userMessage: 'No-op',
      ),
    ]);
  }
}
