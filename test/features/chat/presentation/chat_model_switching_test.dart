import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import '../../../test_helpers.dart';
import '../../agents/data/fake_agent_profile_store.dart';
import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_client_resolver.dart';
import '../data/fake_chat_history_store.dart';

final class _RecordingChatClient implements ChatCompletionClient {
  final requests = <({String baseUrl, String model})>[];
  String response = 'Assistant reply';
  StreamController<ChatStreamEvent>? pendingStream;

  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<ChatStreamEvent> streamComplete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) {
    requests.add((baseUrl: baseUrl, model: model));
    final pending = pendingStream;
    if (pending != null) {
      pendingStream = null;
      return pending.stream;
    }
    return Stream.fromIterable([
      ChatStreamDelta(response),
      const ChatStreamCompleted(),
    ]);
  }
}

void main() {
  group('Chat model switching', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatHistoryStore historyStore;
    late FakeAgentProfileStore agentStore;
    late _RecordingChatClient chatClient;
    late FakeChatClientResolver resolver;

    setUp(() async {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      historyStore = FakeChatHistoryStore();
      agentStore = FakeAgentProfileStore();
      chatClient = _RecordingChatClient();
      resolver = FakeChatClientResolver(
        openAiCompatibleClient: chatClient,
      );

      await _saveProvider(
        configStore,
        apiKeyStore,
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4.1',
      );
      await _saveProvider(
        configStore,
        apiKeyStore,
        providerId: 'deepseek',
        displayName: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
      );
    });

    Future<void> pumpChat(WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        home: ChatPage(
          chatClientResolver: resolver,
          apiKeyStore: apiKeyStore,
          configStore: configStore,
          historyStore: historyStore,
          agentStore: agentStore,
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> selectDeepSeek(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('model_selector')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('model_option_deepseek_deepseek-chat')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('input model picker groups models by provider', (tester) async {
      await pumpChat(tester);

      expect(find.text('OpenAI · gpt-4.1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('model_selector')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('model_provider_group_openai')), findsOneWidget);
      expect(find.byKey(const Key('model_provider_group_deepseek')),
          findsOneWidget);
      expect(find.text('gpt-4.1'), findsOneWidget);
      expect(find.text('deepseek-chat'), findsOneWidget);
    });

    testWidgets('model selector fills the composer width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpChat(tester);

      final pageWidth = tester.getSize(find.byType(Scaffold)).width;
      final selectorWidth =
          tester.getSize(find.byKey(const Key('model_selector'))).width;

      expect(selectorWidth, closeTo(pageWidth - 16, 0.1));
    });

    testWidgets('one conversation sends different turns with different models',
        (tester) async {
      await pumpChat(tester);

      await _send(tester, 'First question');
      await selectDeepSeek(tester);
      chatClient.response = 'DeepSeek reply';
      await _send(tester, 'Second question');

      expect(chatClient.requests, [
        (
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4.1',
        ),
        (
          baseUrl: 'https://api.deepseek.com/v1',
          model: 'deepseek-chat',
        ),
      ]);

      final conversation = await historyStore.readLatestConversation();
      final messages = await historyStore.readMessages(conversation!.id);
      expect(messages, hasLength(4));
      expect(messages[0].providerNameSnapshot, 'OpenAI');
      expect(messages[0].modelIdSnapshot, 'gpt-4.1');
      expect(messages[1].providerNameSnapshot, 'OpenAI');
      expect(messages[1].modelIdSnapshot, 'gpt-4.1');
      expect(messages[2].providerNameSnapshot, 'DeepSeek');
      expect(messages[2].modelIdSnapshot, 'deepseek-chat');
      expect(messages[3].providerNameSnapshot, 'DeepSeek');
      expect(messages[3].modelIdSnapshot, 'deepseek-chat');

      expect(
        find.byKey(ValueKey('assistant_model_label_${messages[1].id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('assistant_model_label_${messages[3].id}')),
        findsOneWidget,
      );
    });

    testWidgets('Retry uses the original user message model', (tester) async {
      await _seedConversation(
        historyStore,
        userSnapshot: const _Snapshot('openai', 'OpenAI', 'gpt-4.1'),
      );
      await pumpChat(tester);
      await selectDeepSeek(tester);

      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();

      expect(chatClient.requests.single.baseUrl, 'https://api.openai.com/v1');
      expect(chatClient.requests.single.model, 'gpt-4.1');
    });

    testWidgets('Regenerate uses the original assistant message model',
        (tester) async {
      await _seedConversation(
        historyStore,
        userSnapshot: const _Snapshot('deepseek', 'DeepSeek', 'deepseek-chat'),
        assistantSnapshot: const _Snapshot('openai', 'OpenAI', 'gpt-4.1'),
      );
      await pumpChat(tester);
      await selectDeepSeek(tester);

      await tester.tap(find.byTooltip('Regenerate response'));
      await tester.pumpAndSettle();

      expect(chatClient.requests.single.baseUrl, 'https://api.openai.com/v1');
      expect(chatClient.requests.single.model, 'gpt-4.1');
      final messages = await historyStore.readMessages('conversation_seed');
      expect(messages.last.providerNameSnapshot, 'OpenAI');
      expect(messages.last.modelIdSnapshot, 'gpt-4.1');
    });

    testWidgets('assistant without snapshot shows Legacy model',
        (tester) async {
      await _seedConversation(
        historyStore,
        userSnapshot: null,
        assistantSnapshot: null,
      );
      await pumpChat(tester);

      expect(find.text('Legacy model'), findsOneWidget);
    });

    testWidgets('renamed provider does not change historical assistant label',
        (tester) async {
      await _seedConversation(
        historyStore,
        userSnapshot: const _Snapshot('openai', 'Original OpenAI', 'gpt-4.1'),
        assistantSnapshot:
            const _Snapshot('openai', 'Original OpenAI', 'gpt-4.1'),
      );
      await _saveProvider(
        configStore,
        apiKeyStore,
        providerId: 'openai',
        displayName: 'Renamed OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4.1',
      );

      await pumpChat(tester);

      expect(find.text('Original OpenAI · gpt-4.1'), findsOneWidget);
      expect(find.text('Renamed OpenAI · gpt-4.1'), findsOneWidget);
    });

    testWidgets('deleted provider does not remove historical assistant label',
        (tester) async {
      await _seedConversation(
        historyStore,
        userSnapshot: const _Snapshot('openai', 'Deleted OpenAI', 'gpt-4.1'),
        assistantSnapshot:
            const _Snapshot('openai', 'Deleted OpenAI', 'gpt-4.1'),
      );
      await configStore.deleteConfig('openai');

      await pumpChat(tester);

      expect(find.text('Deleted OpenAI · gpt-4.1'), findsOneWidget);
      expect(find.text('DeepSeek · deepseek-chat'), findsOneWidget);
    });

    testWidgets('copy response excludes provider and model label',
        (tester) async {
      String? copiedText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await _seedConversation(
        historyStore,
        userSnapshot: const _Snapshot('openai', 'OpenAI', 'gpt-4.1'),
        assistantSnapshot: const _Snapshot('openai', 'OpenAI', 'gpt-4.1'),
      );
      await pumpChat(tester);

      await tester.tap(find.byTooltip('Copy response'));
      await tester.pumpAndSettle();

      expect(copiedText, 'Original answer');
    });

    testWidgets('HTTP provider does not appear in model picker',
        (tester) async {
      await _saveProvider(
        configStore,
        apiKeyStore,
        providerId: 'http_provider',
        displayName: 'HTTP Provider',
        baseUrl: 'http://unsafe.example.com/v1',
        model: 'unsafe-model',
      );
      await pumpChat(tester);

      await tester.tap(find.byKey(const Key('model_selector')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('model_provider_group_http_provider')),
          findsNothing);
      expect(find.text('HTTP Provider'), findsNothing);
      expect(find.text('unsafe-model'), findsNothing);
    });

    testWidgets('model selector is hidden while generating', (tester) async {
      final stream = StreamController<ChatStreamEvent>();
      chatClient.pendingStream = stream;
      addTearDown(stream.close);
      await pumpChat(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Wait',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('model_selector')), findsNothing);
    });

    testWidgets('no available model disables sending and shows empty state',
        (tester) async {
      configStore = FakeProviderConfigStore();
      apiKeyStore = FakeApiKeyStore();
      await _saveProvider(
        configStore,
        apiKeyStore,
        providerId: 'http_only',
        displayName: 'HTTP only',
        baseUrl: 'http://unsafe.example.com/v1',
        model: 'unsafe-model',
      );
      await pumpChat(tester);

      expect(find.byKey(const Key('no_models_empty_state')), findsOneWidget);
      expect(find.text('No model available'), findsWidgets);
      expect(find.widgetWithIcon(IconButton, Icons.send), findsNothing);
    });
  });
}

Future<void> _saveProvider(
  FakeProviderConfigStore configStore,
  FakeApiKeyStore apiKeyStore, {
  required String providerId,
  required String displayName,
  required String baseUrl,
  required String model,
}) async {
  await configStore.saveConfig(ProviderConfigData(
    providerId: providerId,
    displayName: displayName,
    baseUrl: baseUrl,
    defaultModel: model,
    protocol: ProviderProtocol.openAiCompatible,
    updatedAt: DateTime(2024),
  ));
  await apiKeyStore.saveKey(providerId, '$providerId-key');
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Type a message...'),
    text,
  );
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

final class _Snapshot {
  const _Snapshot(this.providerId, this.providerName, this.modelId);

  final String providerId;
  final String providerName;
  final String modelId;
}

Future<void> _seedConversation(
  FakeChatHistoryStore historyStore, {
  required _Snapshot? userSnapshot,
  _Snapshot? assistantSnapshot,
}) async {
  final now = DateTime(2024);
  await historyStore.createConversationWithFirstMessage(
    conversation: ChatConversation(
      id: 'conversation_seed',
      title: 'Seed',
      providerId: 'openai',
      model: 'gpt-4.1',
      createdAt: now,
      updatedAt: now,
    ),
    firstMessage: ChatMessage(
      id: 'user_seed',
      role: ChatRole.user,
      content: 'Original question',
      providerIdSnapshot: userSnapshot?.providerId,
      providerNameSnapshot: userSnapshot?.providerName,
      modelIdSnapshot: userSnapshot?.modelId,
      createdAt: now,
    ),
  );
  if (assistantSnapshot != null || userSnapshot == null) {
    await historyStore.appendMessage(
      conversationId: 'conversation_seed',
      message: ChatMessage(
        id: 'assistant_seed',
        role: ChatRole.assistant,
        content: 'Original answer',
        providerIdSnapshot: assistantSnapshot?.providerId,
        providerNameSnapshot: assistantSnapshot?.providerName,
        modelIdSnapshot: assistantSnapshot?.modelId,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    );
  }
}
