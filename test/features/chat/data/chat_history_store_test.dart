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
  });
}
