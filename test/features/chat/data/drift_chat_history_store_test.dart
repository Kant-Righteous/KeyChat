import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart'
    as domain;
import 'package:keychat/features/chat/data/drift_chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

void main() {
  group('DriftChatHistoryStore.replaceAssistantMessage', () {
    late AppDatabase db;
    late DriftChatHistoryStore store;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');
      store = DriftChatHistoryStore(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedBasicData() async {
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Test',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: domain.ChatMessage(
          id: 'msg_user',
          role: domain.ChatRole.user,
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      );
      await store.appendMessage(
        conversationId: 'conv_1',
        message: domain.ChatMessage(
          id: 'msg_asst',
          role: domain.ChatRole.assistant,
          content: 'Old reply',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );
    }

    test('updates assistant content', () async {
      await seedBasicData();

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

    test('persists provider and model snapshots without endpoint secrets',
        () async {
      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_snapshot',
          title: 'Snapshot',
          providerId: 'openai',
          model: 'gpt-4.1',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: domain.ChatMessage(
          id: 'msg_snapshot_user',
          role: domain.ChatRole.user,
          content: 'Hello',
          providerIdSnapshot: 'openai',
          providerNameSnapshot: 'OpenAI at send time',
          modelIdSnapshot: 'gpt-4.1',
          createdAt: DateTime(2024),
        ),
      );
      await store.appendMessage(
        conversationId: 'conv_snapshot',
        message: domain.ChatMessage(
          id: 'msg_snapshot_assistant',
          role: domain.ChatRole.assistant,
          content: 'Hi',
          providerIdSnapshot: 'openai',
          providerNameSnapshot: 'OpenAI at send time',
          modelIdSnapshot: 'gpt-4.1',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      final messages = await store.readMessages('conv_snapshot');
      expect(messages, hasLength(2));
      expect(messages.first.providerIdSnapshot, 'openai');
      expect(messages.first.providerNameSnapshot, 'OpenAI at send time');
      expect(messages.first.modelIdSnapshot, 'gpt-4.1');
      expect(messages.last.providerIdSnapshot, 'openai');
      expect(messages.last.providerNameSnapshot, 'OpenAI at send time');
      expect(messages.last.modelIdSnapshot, 'gpt-4.1');

      final columns = db.chatMessages.$columns.map((column) => column.name);
      expect(columns, isNot(contains('api_key')));
      expect(columns, isNot(contains('base_url')));
      expect(columns, isNot(contains('authorization')));
    });

    test('legacy rows read with null model snapshots', () async {
      await seedBasicData();

      final messages = await store.readMessages('conv_1');
      final assistant = messages.firstWhere(
        (message) => message.role == domain.ChatRole.assistant,
      );

      expect(assistant.providerIdSnapshot, isNull);
      expect(assistant.providerNameSnapshot, isNull);
      expect(assistant.modelIdSnapshot, isNull);
    });

    test('regenerate replacement stores the model snapshot it used', () async {
      await seedBasicData();

      await store.replaceAssistantMessage(
        conversationId: 'conv_1',
        messageId: 'msg_asst',
        content: 'Regenerated reply',
        providerIdSnapshot: 'deepseek',
        providerNameSnapshot: 'DeepSeek',
        modelIdSnapshot: 'deepseek-chat',
        conversationUpdatedAt: DateTime(2024, 2),
      );

      final messages = await store.readMessages('conv_1');
      final assistant = messages.firstWhere((message) =>
          message.id == 'msg_asst' &&
          message.role == domain.ChatRole.assistant);
      expect(assistant.providerIdSnapshot, 'deepseek');
      expect(assistant.providerNameSnapshot, 'DeepSeek');
      expect(assistant.modelIdSnapshot, 'deepseek-chat');
    });

    test('preserves message id', () async {
      await seedBasicData();

      await store.replaceAssistantMessage(
        conversationId: 'conv_1',
        messageId: 'msg_asst',
        content: 'New reply',
        conversationUpdatedAt: DateTime(2024, 2),
      );

      final msgs = await store.readMessages('conv_1');
      expect(msgs.any((m) => m.id == 'msg_asst'), true);
    });

    test('does not increase message count', () async {
      await seedBasicData();

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
      await seedBasicData();

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
      await seedBasicData();

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
      await seedBasicData();

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
      await seedBasicData();

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
      await seedBasicData();

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
      await seedBasicData();

      await store.createConversationWithFirstMessage(
        conversation: ChatConversation(
          id: 'conv_2',
          title: 'Conv 2',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        firstMessage: domain.ChatMessage(
          id: 'msg_user2',
          role: domain.ChatRole.user,
          content: 'Hello 2',
          createdAt: DateTime(2024),
        ),
      );
      await store.appendMessage(
        conversationId: 'conv_2',
        message: domain.ChatMessage(
          id: 'msg_asst2',
          role: domain.ChatRole.assistant,
          content: 'Reply 2',
          createdAt: DateTime(2024, 1, 1, 0, 0, 1),
        ),
      );

      await store.replaceAssistantMessage(
        conversationId: 'conv_1',
        messageId: 'msg_asst',
        content: 'New Reply 1',
        conversationUpdatedAt: DateTime(2024, 2),
      );

      final msgs2 = await store.readMessages('conv_2');
      expect(msgs2.firstWhere((m) => m.id == 'msg_asst2').content, 'Reply 2');
      expect(msgs2.length, 2);
    });

    test('persists after database reopen', () async {
      await seedBasicData();

      await store.replaceAssistantMessage(
        conversationId: 'conv_1',
        messageId: 'msg_asst',
        content: 'Persisted reply',
        conversationUpdatedAt: DateTime(2024, 2),
      );

      // Reopen with new store
      final store2 = DriftChatHistoryStore(db);
      final msgs = await store2.readMessages('conv_1');
      expect(msgs.firstWhere((m) => m.id == 'msg_asst').content,
          'Persisted reply');
    });

    test('error message does not contain message content', () async {
      await seedBasicData();

      try {
        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'nonexistent',
          content: 'secret content here',
          conversationUpdatedAt: DateTime(2024, 2),
        );
        fail('Expected StateError');
      } on StateError catch (e) {
        expect(e.message, isNot(contains('secret content here')));
      }
    });

    test('error message does not contain API key', () async {
      await seedBasicData();

      try {
        await store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'nonexistent',
          content: 'reply',
          conversationUpdatedAt: DateTime(2024, 2),
        );
        fail('Expected StateError');
      } on StateError catch (e) {
        expect(e.message, isNot(contains('sk-')));
      }
    });

    test('rolls back message update when conversation update fails', () async {
      await seedBasicData();

      // Record original state
      final msgsBefore = await store.readMessages('conv_1');
      final asstBefore = msgsBefore.firstWhere((m) => m.id == 'msg_asst');
      final convBefore = await store.readConversation('conv_1');

      // Create trigger that aborts conversation updates
      await db.customStatement(
        "CREATE TRIGGER prevent_conv_update "
        "BEFORE UPDATE ON conversations "
        "WHEN old.id = 'conv_1' "
        "BEGIN SELECT RAISE(ABORT, 'test: conversation update blocked'); END",
      );

      expect(
        () => store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'Should not persist',
          conversationUpdatedAt: DateTime(2024, 9),
        ),
        throwsA(isA<Exception>()),
      );

      // Clean up trigger
      await db.customStatement('DROP TRIGGER IF EXISTS prevent_conv_update');

      // Verify rollback: assistant content unchanged
      final msgsAfter = await store.readMessages('conv_1');
      final asstAfter = msgsAfter.firstWhere((m) => m.id == 'msg_asst');
      expect(asstAfter.content, asstBefore.content);
      expect(asstAfter.id, asstBefore.id);

      // Verify rollback: conversation unchanged
      final convAfter = await store.readConversation('conv_1');
      expect(convAfter!.updatedAt, convBefore!.updatedAt);

      // Verify rollback: message count unchanged
      expect(msgsAfter.length, msgsBefore.length);

      // Verify rollback: user message unchanged
      final userAfter = msgsAfter.firstWhere((m) => m.id == 'msg_user');
      expect(userAfter.content, 'Hello');
    });

    test('preserves conversation when message update fails', () async {
      await seedBasicData();

      // Record original state
      final msgsBefore = await store.readMessages('conv_1');
      final convBefore = await store.readConversation('conv_1');

      // Create trigger that aborts message updates
      await db.customStatement(
        "CREATE TRIGGER prevent_msg_update "
        "BEFORE UPDATE ON chat_messages "
        "WHEN old.id = 'msg_asst' "
        "BEGIN SELECT RAISE(ABORT, 'test: message update blocked'); END",
      );

      expect(
        () => store.replaceAssistantMessage(
          conversationId: 'conv_1',
          messageId: 'msg_asst',
          content: 'Should not persist',
          conversationUpdatedAt: DateTime(2024, 9),
        ),
        throwsA(isA<Exception>()),
      );

      // Clean up trigger
      await db.customStatement('DROP TRIGGER IF EXISTS prevent_msg_update');

      // Verify: assistant content unchanged
      final msgsAfter = await store.readMessages('conv_1');
      final asstAfter = msgsAfter.firstWhere((m) => m.id == 'msg_asst');
      expect(asstAfter.content, 'Old reply');

      // Verify: conversation updatedAt unchanged
      final convAfter = await store.readConversation('conv_1');
      expect(convAfter!.updatedAt, convBefore!.updatedAt);

      // Verify: message count unchanged
      expect(msgsAfter.length, msgsBefore.length);

      // Verify: user message unchanged
      final userAfter = msgsAfter.firstWhere((m) => m.id == 'msg_user');
      expect(userAfter.content, 'Hello');
    });
  });
}
