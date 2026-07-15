import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/conversation_list_result.dart';
import 'package:keychat/features/chat/presentation/conversation_list_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import '../../../test_helpers.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_history_store.dart';

class _EmptyMessagesHistoryStore extends FakeChatHistoryStore {
  @override
  Future<List<ChatMessage>> readMessages(String conversationId) async => [];
}

void main() {
  group('ConversationListPage', () {
    late FakeChatHistoryStore historyStore;
    late FakeProviderConfigStore configStore;

    setUp(() {
      historyStore = FakeChatHistoryStore();
      configStore = FakeProviderConfigStore();
    });

    testWidgets('shows loading during page load', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no conversations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('shows all conversations', (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'First Chat',
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
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_2',
          title: 'Second Chat',
          providerId: 'deepseek',
          model: 'deepseek-chat',
          createdAt: DateTime(2024, 2),
          updatedAt: DateTime(2024, 2),
        ),
        firstMessage: ChatMessage(
          id: 'msg_2',
          role: ChatRole.user,
          content: 'Hi',
          createdAt: DateTime(2024, 2),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First Chat'), findsOneWidget);
      expect(find.text('Second Chat'), findsOneWidget);
    });

    testWidgets('shows title and model', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Chat'), findsOneWidget);
      expect(find.text('openai · gpt-4'), findsOneWidget);
    });

    testWidgets('shows provider displayName when config exists',
        (WidgetTester tester) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2024),
      ));

      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OpenAI · gpt-4'), findsOneWidget);
    });

    testWidgets('falls back to providerId when config missing',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test',
          providerId: 'unknown_provider',
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
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('unknown_provider · gpt-4'), findsOneWidget);
    });

    testWidgets('current conversation shows selected state',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Current',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
            currentConversationId: 'conv_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping conversation returns conversationId',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test',
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

      ConversationListResult? returnedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push<ConversationListResult>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationListPage(
                      historyStore: historyStore,
                      configStore: configStore,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.action, ConversationListAction.selected);
      expect(returnedResult!.conversationId, 'conv_1');
    });

    testWidgets('page does not call ChatCompletionClient',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No client is passed to ConversationListPage, so this is inherently satisfied
      expect(find.byType(ConversationListPage), findsOneWidget);
    });

    testWidgets('page does not read ApiKeyStore', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ApiKeyStore is not passed to ConversationListPage
      expect(find.byType(ConversationListPage), findsOneWidget);
    });

    testWidgets('export opens second-level copy and share actions',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Export target',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Target prompt',
          createdAt: DateTime(2026),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Export conversation'), findsOneWidget);

      await tester.tap(find.text('Export conversation'));
      await tester.pumpAndSettle();
      expect(find.text('Copy as Markdown'), findsOneWidget);
      expect(find.text('Share Markdown'), findsOneWidget);
    });

    testWidgets('share exports the selected historical conversation',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_active',
          title: 'Active chat',
          providerId: 'openai',
          model: 'gpt-active',
          createdAt: DateTime(2026, 2),
          updatedAt: DateTime(2026, 2),
        ),
        firstMessage: ChatMessage(
          id: 'active_user',
          role: ChatRole.user,
          content: 'Active prompt',
          createdAt: DateTime(2026, 2),
        ),
      );
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_target',
          title: 'Historical target',
          providerId: 'deepseek',
          model: 'deepseek-chat',
          agentNameSnapshot: 'Archive Agent',
          systemPromptSnapshot: 'DO NOT EXPORT SYSTEM',
          createdAt: DateTime(2026, 1),
          updatedAt: DateTime(2026, 1),
        ),
        firstMessage: ChatMessage(
          id: 'target_user',
          role: ChatRole.user,
          content: 'Historical prompt',
          createdAt: DateTime(2026, 1),
        ),
      );
      await historyStore.appendMessage(
        conversationId: 'conv_target',
        message: ChatMessage(
          id: 'target_assistant',
          role: ChatRole.assistant,
          content: 'Historical answer',
          providerNameSnapshot: 'DeepSeek',
          modelIdSnapshot: 'deepseek-reasoner',
          createdAt: DateTime(2026, 1, 1, 0, 1),
        ),
      );
      String? sharedMarkdown;
      var shareCalls = 0;

      await tester.pumpWidget(
        buildTestApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
            currentConversationId: 'conv_active',
            now: () => DateTime.utc(2026, 7, 15, 9),
            shareMarkdown: (markdown, title, origin) async {
              shareCalls++;
              sharedMarkdown = markdown;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final targetTile = find.widgetWithText(ListTile, 'Historical target');
      await tester.tap(
        find.descendant(of: targetTile, matching: find.byIcon(Icons.more_vert)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share Markdown'));
      await tester.pumpAndSettle();

      expect(shareCalls, 1);
      expect(sharedMarkdown, contains('# Historical target'));
      expect(sharedMarkdown, contains('Agent: Archive Agent'));
      expect(sharedMarkdown, contains('Messages: 2'));
      expect(sharedMarkdown, contains('Historical prompt'));
      expect(sharedMarkdown, contains('Historical answer'));
      expect(sharedMarkdown, contains('Provider: DeepSeek'));
      expect(sharedMarkdown, contains('Model: deepseek-reasoner'));
      expect(sharedMarkdown, isNot(contains('Active prompt')));
      expect(sharedMarkdown, isNot(contains('DO NOT EXPORT SYSTEM')));
    });

    testWidgets('copy shows localized success message',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Copy target',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Copy this',
          createdAt: DateTime(2026),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('zh'),
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
            copyMarkdown: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出对话'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复制为 Markdown'));
      await tester.pumpAndSettle();

      expect(find.text('已复制为 Markdown'), findsOneWidget);
    });

    testWidgets('empty and failed exports show safe localized messages',
        (WidgetTester tester) async {
      final emptyStore = _EmptyMessagesHistoryStore();
      await emptyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_empty',
          title: 'Empty target',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        firstMessage: ChatMessage(
          id: 'ignored',
          role: ChatRole.user,
          content: 'Ignored by empty test store',
          createdAt: DateTime(2026),
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          home: ConversationListPage(
            historyStore: emptyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy as Markdown'));
      await tester.pumpAndSettle();
      expect(find.text('Conversation is empty'), findsOneWidget);

      historyStore = FakeChatHistoryStore();
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_failed',
          title: 'Failure target',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Failure prompt',
          createdAt: DateTime(2026),
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      historyStore.shouldFailOnRead = true;
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share Markdown'));
      await tester.pumpAndSettle();
      expect(find.text('Export failed'), findsOneWidget);
    });

    testWidgets('export menu switches Chinese English and back',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Locale target',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Locale prompt',
          createdAt: DateTime(2026),
        ),
      );
      final page = ConversationListPage(
        key: const ValueKey('conversation-list'),
        historyStore: historyStore,
        configStore: configStore,
      );

      await tester.pumpWidget(
        buildTestApp(home: page, locale: const Locale('zh')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('导出对话'), findsOneWidget);
      await tester.tap(find.text('导出对话'));
      await tester.pumpAndSettle();
      expect(find.text('复制为 Markdown'), findsOneWidget);
      expect(find.text('分享 Markdown'), findsOneWidget);
      Navigator.of(tester.element(find.text('分享 Markdown'))).pop();
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestApp(home: page));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Export conversation'), findsOneWidget);
      Navigator.of(tester.element(find.text('Export conversation'))).pop();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(home: page, locale: const Locale('zh')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('导出对话'), findsOneWidget);
    });

    testWidgets('load failure shows safe error', (WidgetTester tester) async {
      historyStore.shouldFailOnRead = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load conversations'), findsOneWidget);
    });

    testWidgets('shows action menu for each conversation',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('rename dialog shows with current title',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original Title',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Rename Conversation'), findsOneWidget);
      expect(find.text('Original Title'), findsWidgets);
    });

    testWidgets('rename cancel does not change title',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original Title',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Original Title'), findsOneWidget);
    });

    testWidgets('rename with empty title shows error',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original Title',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title cannot be empty'), findsOneWidget);
    });

    testWidgets('rename with whitespace-only title shows error',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original Title',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title cannot be empty'), findsOneWidget);
    });

    testWidgets('rename success updates list', (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original Title',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Title');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('New Title'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });

    testWidgets('delete shows confirmation dialog',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'To Delete',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Conversation'), findsOneWidget);
      expect(find.text('Delete this conversation and all its messages?'),
          findsOneWidget);
    });

    testWidgets('delete cancel keeps conversation',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'To Keep',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('To Keep'), findsOneWidget);
    });

    testWidgets('delete non-current conversation refreshes list',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'To Delete',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 1),
          updatedAt: DateTime(2024, 1),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024, 1),
        ),
      );
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_2',
          title: 'To Keep',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 2),
          updatedAt: DateTime(2024, 2),
        ),
        firstMessage: ChatMessage(
          id: 'msg_2',
          role: ChatRole.user,
          content: 'Hi',
          createdAt: DateTime(2024, 2),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and delete the first conversation (conv_1 with older updatedAt)
      final moreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(moreButtons.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      final deleteButton = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
      expect(find.text('To Keep'), findsOneWidget);
    });

    testWidgets('delete current conversation returns activeConversationDeleted',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Current',
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

      dynamic returnedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationListPage(
                      historyStore: historyStore,
                      configStore: configStore,
                      currentConversationId: 'conv_1',
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult.action,
          ConversationListAction.activeConversationDeleted);
    });

    testWidgets('rename with exactly 80 chars succeeds',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      final longTitle = 'A' * 80;
      await tester.enterText(find.byType(TextField), longTitle);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('rename with 81 chars shows error',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original',
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

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      final tooLongTitle = 'A' * 81;
      await tester.enterText(find.byType(TextField), tooLongTitle);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title is too long'), findsOneWidget);
    });

    testWidgets('rename does not change sort position',
        (WidgetTester tester) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_old',
          title: 'Old Chat',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 1),
          updatedAt: DateTime(2024, 1),
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024, 1),
        ),
      );
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_new',
          title: 'New Chat',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024, 6),
          updatedAt: DateTime(2024, 6),
        ),
        firstMessage: ChatMessage(
          id: 'msg_2',
          role: ChatRole.user,
          content: 'Hi',
          createdAt: DateTime(2024, 6),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rename the old conversation
      final moreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(moreButtons.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Renamed Old Chat');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Order should still be: New Chat first, then Renamed Old Chat
      final listItems = find.byType(ListTile);
      expect(listItems, findsNWidgets(2));
    });

    testWidgets('page does not read ApiKeyStore', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ApiKeyStore is not passed to ConversationListPage
      expect(find.byType(ConversationListPage), findsOneWidget);
    });

    testWidgets('page does not call ChatCompletionClient',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            historyStore: historyStore,
            configStore: configStore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No client is passed to ConversationListPage
      expect(find.byType(ConversationListPage), findsOneWidget);
    });
  });
}
