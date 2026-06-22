import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';

import 'fake_chat_history_store.dart';

void main() {
  group('FakeChatHistoryStore', () {
    late FakeChatHistoryStore store;

    setUp(() {
      store = FakeChatHistoryStore();
    });

    test('readLatestConversation returns null when empty', () async {
      final result = await store.readLatestConversation();
      expect(result, isNull);
    });

    test('create and read conversation', () async {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Test',
        providerId: 'openai',
        model: 'gpt-4',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final message = ChatMessage(
        id: 'msg_1',
        role: ChatRole.user,
        content: 'Hello',
        createdAt: DateTime(2024),
      );

      await store.createConversationWithFirstMessage(
        conversation: conversation,
        firstMessage: message,
      );

      final result = await store.readLatestConversation();
      expect(result, isNotNull);
      expect(result!.id, 'conv_1');
      expect(result.title, 'Test');
    });

    test('createConversationWithFirstMessage is atomic', () async {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Test',
        providerId: 'openai',
        model: 'gpt-4',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final message = ChatMessage(
        id: 'msg_1',
        role: ChatRole.user,
        content: 'Hello',
        createdAt: DateTime(2024),
      );

      await store.createConversationWithFirstMessage(
        conversation: conversation,
        firstMessage: message,
      );

      final messages = await store.readMessages('conv_1');
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello');
    });

    test('readMessages returns messages in order', () async {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Test',
        providerId: 'openai',
        model: 'gpt-4',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final msg1 = ChatMessage(
        id: 'msg_1',
        role: ChatRole.user,
        content: 'Hello',
        createdAt: DateTime(2024),
      );

      await store.createConversationWithFirstMessage(
        conversation: conversation,
        firstMessage: msg1,
      );

      final msg2 = ChatMessage(
        id: 'msg_2',
        role: ChatRole.assistant,
        content: 'Hi there',
        createdAt: DateTime(2024, 1, 1, 0, 0, 1),
      );
      await store.appendMessage(conversationId: 'conv_1', message: msg2);

      final messages = await store.readMessages('conv_1');
      expect(messages.length, 2);
      expect(messages[0].role, ChatRole.user);
      expect(messages[1].role, ChatRole.assistant);
    });

    test('updateConversationActivity updates updatedAt', () async {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Test',
        providerId: 'openai',
        model: 'gpt-4',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final message = ChatMessage(
        id: 'msg_1',
        role: ChatRole.user,
        content: 'Hello',
        createdAt: DateTime(2024),
      );

      await store.createConversationWithFirstMessage(
        conversation: conversation,
        firstMessage: message,
      );

      final newTime = DateTime(2024, 6);
      await store.updateConversationActivity(
        conversationId: 'conv_1',
        updatedAt: newTime,
      );

      final result = await store.readLatestConversation();
      expect(result!.updatedAt, newTime);
    });

    test('ChatConversation.generateTitle truncates long messages', () {
      final longMessage = 'A' * 100;
      final title = ChatConversation.generateTitle(longMessage);
      expect(title.length, 43); // 40 + '...'
      expect(title.endsWith('...'), true);
    });

    test('ChatConversation.generateTitle compresses whitespace', () {
      final title = ChatConversation.generateTitle('Hello   world  test');
      expect(title, 'Hello world test');
    });

    test('role mapping is correct', () async {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Test',
        providerId: 'openai',
        model: 'gpt-4',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      await store.createConversationWithFirstMessage(
        conversation: conversation,
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      );
      await store.appendMessage(
        conversationId: 'conv_1',
        message: ChatMessage(
          id: 'msg_2',
          role: ChatRole.assistant,
          content: 'Hi',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      final messages = await store.readMessages('conv_1');
      expect(messages[0].role, ChatRole.user);
      expect(messages[1].role, ChatRole.assistant);
    });

    test('readConversations returns empty list when empty', () async {
      final result = await store.readConversations();
      expect(result, isEmpty);
    });

    test('readConversations returns all conversations', () async {
      await store.createConversationWithFirstMessage(
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
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      );
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_2',
          title: 'Second',
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

      final result = await store.readConversations();
      expect(result.length, 2);
    });

    test('readConversations sorts by updatedAt descending', () async {
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_old',
          title: 'Old',
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
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_new',
          title: 'New',
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

      final result = await store.readConversations();
      expect(result.first.id, 'conv_new');
      expect(result.last.id, 'conv_old');
    });

    test('readConversation returns specific conversation', () async {
      await store.createConversationWithFirstMessage(
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

      final result = await store.readConversation('conv_1');
      expect(result, isNotNull);
      expect(result!.id, 'conv_1');
    });

    test('readConversation returns null for nonexistent id', () async {
      final result = await store.readConversation('nonexistent');
      expect(result, isNull);
    });

    test('new message updates conversation position', () async {
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_old',
          title: 'Old',
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
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_new',
          title: 'New',
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

      await store.updateConversationActivity(
        conversationId: 'conv_old',
        updatedAt: DateTime(2024, 12),
      );

      final result = await store.readConversations();
      expect(result.first.id, 'conv_old');
    });

    test('readConversations sorts stably when updatedAt is equal', () async {
      final sameTime = DateTime(2024, 6);

      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_b',
          title: 'B',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: sameTime,
          updatedAt: sameTime,
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: sameTime,
        ),
      );
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_a',
          title: 'A',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: sameTime,
          updatedAt: sameTime,
        ),
        firstMessage: ChatMessage(
          id: 'msg_2',
          role: ChatRole.user,
          content: 'Hi',
          createdAt: sameTime,
        ),
      );

      final result = await store.readConversations();
      expect(result.length, 2);
      expect(result.first.id, 'conv_b');
      expect(result.last.id, 'conv_a');
    });

    test('renameConversation updates title', () async {
      await store.createConversationWithFirstMessage(
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

      final result = await store.renameConversation(
        conversationId: 'conv_1',
        title: 'New Title',
      );

      expect(result, true);
      final conv = await store.readConversation('conv_1');
      expect(conv!.title, 'New Title');
    });

    test('renameConversation does not modify updatedAt', () async {
      final originalTime = DateTime(2024, 1);
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Original',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: originalTime,
          updatedAt: originalTime,
        ),
        firstMessage: ChatMessage(
          id: 'msg_1',
          role: ChatRole.user,
          content: 'Hello',
          createdAt: originalTime,
        ),
      );

      await store.renameConversation(
        conversationId: 'conv_1',
        title: 'New Title',
      );

      final conv = await store.readConversation('conv_1');
      expect(conv!.updatedAt, originalTime);
    });

    test('renameConversation does not modify providerId and model', () async {
      await store.createConversationWithFirstMessage(
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

      await store.renameConversation(
        conversationId: 'conv_1',
        title: 'New Title',
      );

      final conv = await store.readConversation('conv_1');
      expect(conv!.providerId, 'openai');
      expect(conv.model, 'gpt-4');
    });

    test('renameConversation returns false for nonexistent conversation',
        () async {
      final result = await store.renameConversation(
        conversationId: 'nonexistent',
        title: 'New Title',
      );
      expect(result, false);
    });

    test('deleteConversation removes specified conversation', () async {
      await store.createConversationWithFirstMessage(
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

      final result = await store.deleteConversation('conv_1');
      expect(result, true);

      final conv = await store.readConversation('conv_1');
      expect(conv, isNull);
    });

    test('deleteConversation returns false for nonexistent conversation',
        () async {
      final result = await store.deleteConversation('nonexistent');
      expect(result, false);
    });

    test('deleteConversation cascades messages', () async {
      await store.createConversationWithFirstMessage(
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

      var messages = await store.readMessages('conv_1');
      expect(messages.length, 1);

      await store.deleteConversation('conv_1');

      messages = await store.readMessages('conv_1');
      expect(messages, isEmpty);
    });

    test('deleteConversation does not affect other conversations', () async {
      await store.createConversationWithFirstMessage(
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
      await store.createConversationWithFirstMessage(
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

      await store.deleteConversation('conv_1');

      final remaining = await store.readConversations();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'conv_2');

      final messages = await store.readMessages('conv_2');
      expect(messages.length, 1);
    });

    test('renameConversation normalizes title', () async {
      await store.createConversationWithFirstMessage(
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

      final result = await store.renameConversation(
        conversationId: 'conv_1',
        title: '  New   Title  ',
      );

      expect(result, true);
      final conv = await store.readConversation('conv_1');
      expect(conv!.title, 'New Title');
    });

    test('renameConversation rejects empty title', () async {
      await store.createConversationWithFirstMessage(
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

      final result = await store.renameConversation(
        conversationId: 'conv_1',
        title: '   ',
      );
      expect(result, false);
    });

    test('renameConversation rejects too long title', () async {
      await store.createConversationWithFirstMessage(
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

      final longTitle = 'A' * 81;
      final result = await store.renameConversation(
        conversationId: 'conv_1',
        title: longTitle,
      );
      expect(result, false);
    });

    group('replaceAssistantMessage', () {
      test('updates assistant content', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'New reply',
          conversationUpdatedAt: DateTime(2024, 2),
        );

        final msgs = await store.readMessages('conv_1');
        final asst = msgs.firstWhere((m) => m.id == 'msg_asst');
        expect(asst.content, 'New reply');
      });

      test('preserves message id', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst_original',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst_original',
          content: 'New reply',
          conversationUpdatedAt: DateTime(2024, 2),
        );

        final msgs = await store.readMessages('conv_1');
        expect(msgs.any((m) => m.id == 'msg_asst_original'), true);
      });

      test('does not increase message count', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'New reply',
          conversationUpdatedAt: DateTime(2024, 2),
        );

        final msgs = await store.readMessages('conv_1');
        expect(msgs.length, 2);
      });

      test('does not modify user message', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'New reply',
          conversationUpdatedAt: DateTime(2024, 2),
        );

        final msgs = await store.readMessages('conv_1');
        final user = msgs.firstWhere((m) => m.id == 'msg_user');
        expect(user.content, 'Hello');
      });

      test('updates conversation updatedAt', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Old reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        final newUpdatedAt = DateTime(2024, 6);
        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'New reply',
          conversationUpdatedAt: newUpdatedAt,
        );

        final conv = await store.readConversation('conv_1');
        expect(conv!.updatedAt, newUpdatedAt);
      });

      test('missing message throws StateError', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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

        expect(
          () => store.replaceAssistantMessage(
            conversationId: 'conv_1',
            messageId: 'nonexistent',
            content: 'New',
            conversationUpdatedAt: DateTime(2024, 2),
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('rejects mismatched conversationId', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        expect(
          () => store.replaceAssistantMessage(
            conversationId: 'conv_other',
            messageId: 'msg_asst',
            content: 'New',
            conversationUpdatedAt: DateTime(2024, 2),
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('rejects user role', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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

        expect(
          () => store.replaceAssistantMessage(
            conversationId: 'conv_1',
            messageId: 'msg_user',
            content: 'New',
            conversationUpdatedAt: DateTime(2024, 2),
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('does not affect another conversation', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Conv 1',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user1',
            role: ChatRole.user,
            content: 'Hello 1',
            createdAt: DateTime(2024),
          ),
        );
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst1',
            role: ChatRole.assistant,
            content: 'Reply 1',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_2',
            title: 'Conv 2',
            providerId: 'openai',
            model: 'gpt-4',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          firstMessage: ChatMessage(
            id: 'msg_user2',
            role: ChatRole.user,
            content: 'Hello 2',
            createdAt: DateTime(2024),
          ),
        );
        await store.appendMessage(
          conversationId: 'conv_2',
          message: ChatMessage(
            id: 'msg_asst2',
            role: ChatRole.assistant,
            content: 'Reply 2',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst1',
          content: 'New Reply 1',
          conversationUpdatedAt: DateTime(2024, 2),
        );

        // conv_2 unchanged
        final msgs2 = await store.readMessages('conv_2');
        expect(msgs2.firstWhere((m) => m.id == 'msg_asst2').content, 'Reply 2');
      });

      test('records replace call count', () async {
        await store.createConversationWithFirstMessage(
          conversation: ChatConversation(
            id: 'conv_1',
            title: 'Test',
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
        await store.appendMessage(
          conversationId: 'conv_1',
          message: ChatMessage(
            id: 'msg_asst',
            role: ChatRole.assistant,
            content: 'Reply',
            createdAt: DateTime(2024, 1, 1, 0, 0, 1),
          ),
        );

        expect(store.replaceCallCount, 0);

        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'New',
          conversationUpdatedAt: DateTime(2024, 2),
        );

        expect(store.replaceCallCount, 1);
        expect(store.lastReplacedMessageId, 'msg_asst');
        expect(store.lastReplacedContent, 'New');
      });
    });
  });
}
