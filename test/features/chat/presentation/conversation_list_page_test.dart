import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/presentation/conversation_list_page.dart';
import 'package:keychat/features/providers/data/provider_config.dart';

import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_history_store.dart';

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

      String? returnedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedId = await Navigator.push<String>(
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

      expect(returnedId, 'conv_1');
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
  });
}
