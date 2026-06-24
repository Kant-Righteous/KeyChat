import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';
import 'features/providers/data/fake_api_key_store.dart';
import 'features/providers/data/fake_provider_config_store.dart';

class _FakeChatClient implements ChatCompletionClient {
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
      userMessage: 'Not implemented',
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
    return Stream.fromIterable([
      const ChatStreamFailure(
        errorType: ChatCompletionErrorType.unknown,
        userMessage: 'Not implemented',
      ),
    ]);
  }
}

class _FakeHistoryStore implements ChatHistoryStore {
  @override
  Future<ChatConversation?> readLatestConversation() async => null;

  @override
  Future<List<ChatConversation>> readConversations() async => [];

  @override
  Future<ChatConversation?> readConversation(String conversationId) async =>
      null;

  @override
  Future<List<ChatMessage>> readMessages(String conversationId) async => [];

  @override
  Future<void> createConversationWithFirstMessage({
    required ChatConversation conversation,
    required ChatMessage firstMessage,
  }) async {}

  @override
  Future<void> appendMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {}

  @override
  Future<void> updateConversationActivity({
    required String conversationId,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<bool> renameConversation({
    required String conversationId,
    required String title,
  }) async =>
      false;

  @override
  Future<bool> deleteConversation(String conversationId) async => false;

  @override
  Future<void> replaceAssistantMessage({
    required String conversationId,
    required String messageId,
    required String content,
    required DateTime conversationUpdatedAt,
  }) async {}
}

class _FakeAgentProfileStore implements AgentProfileStore {
  @override
  Future<List<AgentProfileData>> readAgents() async => [];

  @override
  Future<AgentProfileData?> readAgent(String id) async => null;

  @override
  Future<void> saveAgent(AgentProfileData agent) async {}

  @override
  Future<bool> deleteAgent(String id) async => false;
}

void main() {
  testWidgets('ChatPage shows empty state when no provider',
      (WidgetTester tester) async {
    final chatClient = _FakeChatClient();
    await tester.pumpWidget(
      buildTestApp(
        home: ChatPage(
          chatClientResolver: DefaultChatClientResolver(
            openAiCompatibleClient: chatClient,
          ),
          apiKeyStore: FakeApiKeyStore(),
          configStore: FakeProviderConfigStore(),
          historyStore: _FakeHistoryStore(),
          agentStore: _FakeAgentProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KeyChat'), findsOneWidget);
    expect(find.text('No ready provider'), findsOneWidget);
  });

  testWidgets('ProvidersPage shows presets', (WidgetTester tester) async {
    final apiKeyStore = FakeApiKeyStore();
    final configStore = FakeProviderConfigStore();
    await tester.pumpWidget(
      buildTestApp(
        home: ProvidersPage(
          apiKeyStore: apiKeyStore,
          configStore: configStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('DeepSeek'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    expect(find.text('Custom Provider'), findsOneWidget);
  });

  testWidgets('SettingsPage shows setting items', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(home: SettingsPage(onLocaleChanged: (locale) {})),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('About KeyChat'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Privacy'), findsNothing);
  });
}
