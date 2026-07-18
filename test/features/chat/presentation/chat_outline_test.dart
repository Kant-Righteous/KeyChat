import 'package:flutter/material.dart';
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
import '../data/fake_chat_completion_client.dart';
import '../data/fake_chat_history_store.dart';

void main() {
  group('ChatPage conversation outline', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late FakeChatHistoryStore historyStore;
    late FakeAgentProfileStore agentStore;
    late FakeChatClientResolver chatClientResolver;

    setUp(() async {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      historyStore = FakeChatHistoryStore();
      agentStore = FakeAgentProfileStore();
      chatClientResolver = FakeChatClientResolver(
        openAiCompatibleClient: FakeChatCompletionClient(),
      );
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4',
        protocol: ProviderProtocol.openAiCompatible,
        updatedAt: DateTime(2026),
      ));
      await apiKeyStore.saveKey('openai', 'test-key');
    });

    ChatPage page() => ChatPage(
          key: const ValueKey('chat-page'),
          chatClientResolver: chatClientResolver,
          apiKeyStore: apiKeyStore,
          configStore: configStore,
          historyStore: historyStore,
          agentStore: agentStore,
        );

    Future<void> createConversation({
      required String id,
      required String title,
      required String firstPrompt,
      required DateTime updatedAt,
    }) async {
      await historyStore.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: id,
          title: title,
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: updatedAt,
          updatedAt: updatedAt,
        ),
        firstMessage: ChatMessage(
          id: '${id}_user_1',
          role: ChatRole.user,
          content: firstPrompt,
          createdAt: updatedAt,
        ),
      );
    }

    testWidgets('entry tooltip and empty state follow locale', (tester) async {
      final chatPage = page();
      await tester.pumpWidget(buildTestApp(home: chatPage));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Conversation outline'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Conversation outline'), findsOneWidget);
      semantics.dispose();
      await tester.tap(find.byTooltip('Conversation outline'));
      await tester.pumpAndSettle();
      expect(find.text('No outline'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(home: chatPage, locale: const Locale('zh')),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('对话目录'), findsOneWidget);
      await tester.tap(find.byTooltip('对话目录'));
      await tester.pumpAndSettle();
      expect(find.text('对话目录'), findsOneWidget);
      expect(find.text('暂无目录'), findsOneWidget);
      Navigator.of(tester.element(find.text('暂无目录'))).pop();
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestApp(home: chatPage));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Conversation outline'), findsOneWidget);
    });

    testWidgets('contains only user messages and long title does not overflow',
        (tester) async {
      final longPrompt = List.filled(30, 'A very long prompt').join(' ');
      await createConversation(
        id: 'conv_1',
        title: 'Outline',
        firstPrompt: longPrompt,
        updatedAt: DateTime(2026),
      );
      await historyStore.appendMessage(
        conversationId: 'conv_1',
        message: ChatMessage(
          id: 'assistant_1',
          role: ChatRole.assistant,
          content: 'Assistant content must not appear in the outline',
          createdAt: DateTime(2026, 1, 1, 0, 1),
        ),
      );
      await historyStore.appendMessage(
        conversationId: 'conv_1',
        message: ChatMessage(
          id: 'user_2',
          role: ChatRole.user,
          content: 'Second user prompt',
          createdAt: DateTime(2026, 1, 1, 0, 2),
        ),
      );

      await tester.pumpWidget(buildTestApp(home: page()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Conversation outline'));
      await tester.pumpAndSettle();

      final longOutlineText = find.descendant(
        of: find.byKey(const Key('outline_item_conv_1_user_1')),
        matching: find.text(longPrompt),
      );
      expect(longOutlineText, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('outline_item_user_2')),
          matching: find.text('Second user prompt'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('outline_item_assistant_1')), findsNothing);
      expect(
          find.byKey(const Key('outline_item_conv_1_user_1')), findsOneWidget);
      expect(find.byKey(const Key('outline_item_user_2')), findsOneWidget);
      final longTitle = tester.widget<Text>(longOutlineText);
      expect(longTitle.maxLines, 2);
      expect(longTitle.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping item closes sheet, jumps and highlights message',
        (tester) async {
      await createConversation(
        id: 'conv_1',
        title: 'Outline',
        firstPrompt: 'First prompt',
        updatedAt: DateTime(2026),
      );
      for (var index = 0; index < 8; index++) {
        await historyStore.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'assistant_$index',
            role: ChatRole.assistant,
            content: List.filled(8, 'Long answer $index').join(' '),
            providerNameSnapshot: 'OpenAI',
            modelIdSnapshot: 'gpt-4',
            createdAt: DateTime(2026, 1, 1, 0, index + 1),
          ),
        );
        await historyStore.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'user_$index',
            role: ChatRole.user,
            content: index == 7 ? 'Jump target prompt' : 'Prompt $index',
            createdAt: DateTime(2026, 1, 1, 1, index + 1),
          ),
        );
      }

      await tester.pumpWidget(buildTestApp(home: page()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Conversation outline'));
      await tester.pumpAndSettle();
      final targetItem = find.byKey(const Key('outline_item_user_7'));
      await tester.dragUntilVisible(
        targetItem,
        find.byType(ListView).last,
        const Offset(0, -300),
      );
      await tester.tap(targetItem);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Conversation outline'), findsNothing);
      expect(
          find.byKey(const Key('highlighted_message_user_7')), findsOneWidget);
      expect(find.text('Jump target prompt'), findsOneWidget);
    });

    testWidgets(
        'switching conversation refreshes outline and New Chat clears it',
        (tester) async {
      await createConversation(
        id: 'conv_old',
        title: 'Old conversation',
        firstPrompt: 'Old outline prompt',
        updatedAt: DateTime(2026, 1),
      );
      await createConversation(
        id: 'conv_new',
        title: 'New conversation',
        firstPrompt: 'New outline prompt',
        updatedAt: DateTime(2026, 2),
      );

      await tester.pumpWidget(buildTestApp(home: page()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Conversation outline'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('outline_item_conv_new_user_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('outline_item_conv_old_user_1')),
        findsNothing,
      );
      Navigator.of(
        tester.element(find.byKey(const Key('outline_item_conv_new_user_1'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Old conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Conversation outline'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('outline_item_conv_old_user_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('outline_item_conv_new_user_1')),
        findsNothing,
      );
      Navigator.of(
        tester.element(find.byKey(const Key('outline_item_conv_old_user_1'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('New Chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Conversation outline'));
      await tester.pumpAndSettle();
      expect(find.text('No outline'), findsOneWidget);
    });
  });
}
