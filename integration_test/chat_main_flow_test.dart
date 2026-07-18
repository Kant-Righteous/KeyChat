import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../test/features/agents/data/fake_agent_profile_store.dart';
import '../test/features/chat/data/fake_chat_client_resolver.dart';
import '../test/features/chat/data/fake_chat_history_store.dart';
import '../test/features/providers/data/fake_api_key_store.dart';
import '../test/features/providers/data/fake_connection_tester_resolver.dart';
import '../test/features/providers/data/fake_provider_config_store.dart';
import '../test/features/providers/data/fake_provider_connection_tester.dart';
import 'support/test_app.dart';

class _LocaleTestApp extends StatefulWidget {
  final Widget Function(Locale?, void Function(Locale)) buildShell;

  const _LocaleTestApp({required this.buildShell});

  @override
  State<_LocaleTestApp> createState() => _LocaleTestAppState();
}

class _LocaleTestAppState extends State<_LocaleTestApp> {
  Locale? _locale = const Locale('zh');

  void _onLocaleChanged(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget.buildShell(_locale, _onLocaleChanged),
    );
  }
}

class _FakeChatCompletionClient implements ChatCompletionClient {
  StreamController<ChatStreamEvent>? _streamController;
  ChatCompletionResult? _nextResult;
  int streamCallCount = 0;
  List<ChatRequestMessage>? lastMessages;

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
    lastMessages = messages;

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
        userMessage: 'No stream configured',
      ),
    ]);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Main Flow', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatHistoryStore historyStore;
    late _FakeChatCompletionClient chatClient;
    late FakeChatClientResolver chatClientResolver;
    late FakeConnectionTesterResolver connectionTesterResolver;
    late FakeAgentProfileStore agentStore;

    setUp(() {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      historyStore = FakeChatHistoryStore();
      chatClient = _FakeChatCompletionClient();
      chatClientResolver = FakeChatClientResolver(
        openAiCompatibleClient: chatClient,
      );
      connectionTesterResolver = FakeConnectionTesterResolver(
        openAiCompatibleTester: FakeProviderConnectionTester(),
      );
      agentStore = FakeAgentProfileStore();
    });

    Locale? currentLocale;

    Widget buildApp() {
      return MaterialApp(
        locale: currentLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TestAppShell(
          apiKeyStore: apiKeyStore,
          configStore: configStore,
          historyStore: historyStore,
          chatClientResolver: chatClientResolver,
          connectionTesterResolver: connectionTesterResolver,
          agentStore: agentStore,
          onLocaleChanged: (locale) {
            currentLocale = locale;
          },
        ),
      );
    }

    testWidgets('Flow A: First chat - send, stream, complete, save',
        (WidgetTester tester) async {
      // Setup provider
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

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Send message
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello AI',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Stream deltas
      streamController.add(const ChatStreamDelta('Hello '));
      await tester.pump();
      streamController.add(const ChatStreamDelta('human!'));
      await tester.pump();

      // Complete
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      // Verify user saved once
      final conv = await historyStore.readLatestConversation();
      expect(conv, isNotNull);
      final msgs = await historyStore.readMessages(conv!.id);
      final userMsgs = msgs.where((m) => m.role == ChatRole.user).toList();
      expect(userMsgs.length, 1);
      expect(userMsgs.first.content, 'Hello AI');

      // Verify assistant saved once
      final asstMsgs = msgs.where((m) => m.role == ChatRole.assistant).toList();
      expect(asstMsgs.length, 1);
      expect(asstMsgs.first.content, 'Hello human!');

      // Verify UI shows both
      expect(find.text('Hello AI'), findsOneWidget);
      expect(find.text('Hello human!'), findsOneWidget);

      // Verify Send restored
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Flow B: Stop and Retry', (WidgetTester tester) async {
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

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Send message
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Tell me a story',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Partial response
      streamController.add(const ChatStreamDelta('Once upon'));
      await tester.pump();

      // Stop
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();

      streamController.close();
      await tester.pumpAndSettle();

      // Verify partial text shown with Stopped
      expect(find.text('Once upon'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);

      // Verify no assistant saved
      final conv = await historyStore.readLatestConversation();
      final msgs = await historyStore.readMessages(conv!.id);
      expect(msgs.where((m) => m.role == ChatRole.assistant).length, 0);

      // Retry
      chatClient.setResult(
        const ChatCompletionResult.success(assistantContent: 'Full story'),
      );

      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();

      // Verify assistant saved
      final msgsAfter = await historyStore.readMessages(conv.id);
      expect(msgsAfter.where((m) => m.role == ChatRole.assistant).length, 1);
      expect(msgsAfter.last.content, 'Full story');

      // Verify Regenerate appears
      expect(find.byTooltip('Regenerate response'), findsOneWidget);
    });

    testWidgets('Flow C: Regenerate success', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      // Pre-populate conversation
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

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Click Regenerate
      await tester.tap(find.byTooltip('Regenerate response'));
      await tester.pump();

      // Stream new response
      streamController.add(const ChatStreamDelta('New '));
      await tester.pump();
      streamController.add(const ChatStreamDelta('reply'));
      await tester.pump();
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      // Verify content replaced
      final msgs = await historyStore.readMessages('conv_regen');
      final asstMsgs = msgs.where((m) => m.role == ChatRole.assistant).toList();
      expect(asstMsgs.length, 1);
      expect(asstMsgs.first.content, 'New reply');
      expect(asstMsgs.first.id, 'msg_asst'); // Same ID

      // Verify message count unchanged
      expect(msgs.length, 2);
    });

    testWidgets('Flow D: Regenerate failure preserves old assistant',
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
          id: 'conv_regen_fail',
          title: 'Regen Fail',
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
        conversationId: 'conv_regen_fail',
        message: ChatMessage(
          id: 'msg_asst',
          role: ChatRole.assistant,
          content: 'Old reply',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      // Configure store to fail
      historyStore.replaceAssistantMessageError = Exception('DB error');

      final streamController = chatClient.startStream();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Regenerate response'));
      await tester.pump();

      streamController.add(const ChatStreamDelta('New content'));
      await tester.pump();
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      // Old content preserved
      final msgs = await historyStore.readMessages('conv_regen_fail');
      expect(msgs.firstWhere((m) => m.id == 'msg_asst').content, 'Old reply');
      expect(msgs.length, 2);
    });

    testWidgets('Flow E: History switch isolates conversations',
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
          id: 'msg_a',
          role: ChatRole.user,
          content: 'Message A',
          createdAt: DateTime(2024, 1),
        ),
      );

      // Create conversation B (newer)
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_b',
          title: 'Conversation B',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 2),
          updatedAt: DateTime(2024, 2),
        ),
        firstMessage: ChatMessage(
          id: 'msg_b',
          role: ChatRole.user,
          content: 'Message B',
          createdAt: DateTime(2024, 2),
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Should show conversation B (newest)
      expect(find.text('Message B'), findsOneWidget);

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Select conversation A
      await tester.tap(find.text('Conversation A'));
      await tester.pumpAndSettle();

      // Should show conversation A
      expect(find.text('Message A'), findsOneWidget);
      expect(find.text('Message B'), findsNothing);
    });

    testWidgets('Flow F: New Chat clears state', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      // Create existing conversation
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

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Should show old message
      expect(find.text('Old message'), findsOneWidget);

      // New Chat
      await tester.tap(find.byIcon(Icons.add_comment));
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('Start a conversation'), findsOneWidget);
      expect(find.text('Old message'), findsNothing);

      // Old conversation still exists
      final oldConv = await historyStore.readConversation('conv_old');
      expect(oldConv, isNotNull);
    });

    testWidgets('Flow G: Agent system prompt', (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');

      // Create an agent
      await agentStore.saveAgent(AgentProfileData(
        id: 'agent_1',
        name: 'Test Agent',
        description: 'A test agent',
        systemPrompt: 'You are a helpful assistant.',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));

      final streamController = chatClient.startStream();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Select the agent
      await tester.tap(find.byType(DropdownButton<AgentProfileData?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Agent').last);
      await tester.pumpAndSettle();

      // Send message
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message...'),
        'Hello',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify system message is first
      expect(chatClient.lastMessages, isNotNull);
      expect(chatClient.lastMessages!.first.role, 'system');
      expect(chatClient.lastMessages!.first.content,
          'You are a helpful assistant.');

      // Stream response
      streamController.add(const ChatStreamDelta('Hi there!'));
      streamController.add(const ChatStreamCompleted());
      streamController.close();
      await tester.pumpAndSettle();

      // Verify conversation saved with agent snapshot
      final conv = await historyStore.readLatestConversation();
      expect(conv, isNotNull);
      expect(conv!.agentId, 'agent_1');
      expect(conv.agentNameSnapshot, 'Test Agent');
      expect(conv.systemPromptSnapshot, 'You are a helpful assistant.');

      // Edit agent - should not affect old conversation
      await agentStore.saveAgent(AgentProfileData(
        id: 'agent_1',
        name: 'Updated Agent',
        description: 'Updated',
        systemPrompt: 'New prompt',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2025),
      ));

      // Old conversation still has old snapshot
      final oldConv = await historyStore.readConversation(conv.id);
      expect(oldConv!.systemPromptSnapshot, 'You are a helpful assistant.');
    });

    testWidgets('Flow H: Language switch', (WidgetTester tester) async {
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
        _LocaleTestApp(
          buildShell: (locale, onLocaleChanged) => TestAppShell(
            apiKeyStore: apiKeyStore,
            configStore: configStore,
            historyStore: historyStore,
            chatClientResolver: chatClientResolver,
            connectionTesterResolver: connectionTesterResolver,
            agentStore: agentStore,
            onLocaleChanged: onLocaleChanged,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is Chinese
      expect(find.text('聊天'), findsOneWidget);
      expect(find.text('提供商'), findsOneWidget);
      expect(find.text('智能体'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      // No Appearance or Privacy
      expect(find.text('Appearance'), findsNothing);
      expect(find.text('Privacy'), findsNothing);

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Tap language
      await tester.tap(find.text('语言'));
      await tester.pumpAndSettle();

      // Chinese should be selected by default
      final chineseRadio = find.byType(RadioListTile<String>);
      expect(chineseRadio, findsWidgets);

      // Select English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Go back from Language page
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Go back to chat from Settings
      await tester.tap(find.byIcon(Icons.chat_outlined));
      await tester.pumpAndSettle();

      // Should be in English
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Providers'), findsOneWidget);
      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify provider data not lost
      final configs = await configStore.readAllConfigs();
      expect(configs.length, 1);
      expect(configs.first.providerId, 'openai');

      // Verify agent data not lost
      final agents = await agentStore.readAgents();
      expect(agents.length, 0);

      // Go to About and check English text
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About KeyChat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('local-first BYOK'), findsOneWidget);

      // Go back and switch to Chinese
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();

      // Go back from Language page
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Go back to chat from Settings
      await tester.tap(find.byIcon(Icons.chat_outlined));
      await tester.pumpAndSettle();

      // Should be back in Chinese
      expect(find.text('聊天'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });
  });
}
