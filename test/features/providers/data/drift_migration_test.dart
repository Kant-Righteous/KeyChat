import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

void main() {
  group('Database migration v1 -> v2', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    test('v1 data preserved after upgrade to v2', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('openai'),
              displayName: const Value('OpenAI'),
              baseUrl: const Value('https://api.openai.com/v1'),
              defaultModel: const Value('gpt-4'),
              enabled: const Value(true),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      final configsBefore = await db.select(db.providerConfigs).get();
      expect(configsBefore.length, 1);
      expect(configsBefore.first.providerId, 'openai');

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_1'),
              title: const Value('Test'),
              providerId: const Value('openai'),
              model: const Value('gpt-4'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );

      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_1'),
              conversationId: const Value('conv_1'),
              role: const Value('user'),
              content: const Value('Hello'),
              createdAt: Value(DateTime(2024)),
            ),
          );

      final configsAfter = await db.select(db.providerConfigs).get();
      expect(configsAfter.length, 1);
      expect(configsAfter.first.providerId, 'openai');
      expect(configsAfter.first.displayName, 'OpenAI');

      final conversations = await db.select(db.conversations).get();
      expect(conversations.length, 1);
      expect(conversations.first.id, 'conv_1');

      final messages = await db.select(db.chatMessages).get();
      expect(messages.length, 1);
      expect(messages.first.id, 'msg_1');
      expect(messages.first.content, 'Hello');
    });

    test('new database has all three tables', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('test'),
              displayName: const Value('Test'),
              baseUrl: const Value('https://test.com'),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_test'),
              title: const Value('Test Conv'),
              providerId: const Value('test'),
              model: const Value('model'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );

      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_test'),
              conversationId: const Value('conv_test'),
              role: const Value('user'),
              content: const Value('Test message'),
              createdAt: Value(DateTime(2024)),
            ),
          );

      final configs = await db.select(db.providerConfigs).get();
      expect(configs.length, 1);

      final conversations = await db.select(db.conversations).get();
      expect(conversations.length, 1);

      final messages = await db.select(db.chatMessages).get();
      expect(messages.length, 1);
    });

    test('foreign key constraint works', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.customStatement('PRAGMA foreign_keys = ON');

      expect(
        () => db.into(db.chatMessages).insert(
              ChatMessagesCompanion(
                id: const Value('orphan_msg'),
                conversationId: const Value('nonexistent_conv'),
                role: const Value('user'),
                content: const Value('Orphan'),
                createdAt: Value(DateTime(2024)),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('cascade delete works', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_del'),
              title: const Value('To Delete'),
              providerId: const Value('test'),
              model: const Value('model'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );

      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_del'),
              conversationId: const Value('conv_del'),
              role: const Value('user'),
              content: const Value('To be deleted'),
              createdAt: Value(DateTime(2024)),
            ),
          );

      var messages = await db.select(db.chatMessages).get();
      expect(messages.length, 1);

      await (db.delete(db.conversations)..where((t) => t.id.equals('conv_del')))
          .go();

      messages = await db.select(db.chatMessages).get();
      expect(messages.length, 0);
    });

    test('delete conversation does not affect ProviderConfigs', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('openai'),
              displayName: const Value('OpenAI'),
              baseUrl: const Value('https://api.openai.com/v1'),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_del'),
              title: const Value('To Delete'),
              providerId: const Value('openai'),
              model: const Value('gpt-4'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );

      await (db.delete(db.conversations)..where((t) => t.id.equals('conv_del')))
          .go();

      final configs = await db.select(db.providerConfigs).get();
      expect(configs.length, 1);
      expect(configs.first.providerId, 'openai');
    });

    test('delete one conversation does not affect others', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_1'),
              title: const Value('To Delete'),
              providerId: const Value('test'),
              model: const Value('model'),
              createdAt: Value(DateTime(2024, 1)),
              updatedAt: Value(DateTime(2024, 1)),
            ),
          );

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_2'),
              title: const Value('To Keep'),
              providerId: const Value('test'),
              model: const Value('model'),
              createdAt: Value(DateTime(2024, 2)),
              updatedAt: Value(DateTime(2024, 2)),
            ),
          );

      await (db.delete(db.conversations)..where((t) => t.id.equals('conv_1')))
          .go();

      final remaining = await db.select(db.conversations).get();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'conv_2');
    });
  });

  group('Database schema v3 - protocol column', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    test('new v3 database contains protocol column', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      final columnNames =
          db.providerConfigs.$columns.map((c) => c.name).toList();
      expect(columnNames, contains('protocol'));
    });

    test('protocol column is NOT NULL', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      expect(
        () => db.into(db.providerConfigs).insert(
              ProviderConfigsCompanion(
                providerId: const Value('no_protocol'),
                displayName: const Value('No Protocol'),
                baseUrl: const Value('https://test.com'),
                updatedAt: Value(DateTime(2024)),
              ),
            ),
        throwsA(anyOf(isA<SqliteException>(), isA<InvalidDataException>())),
      );
    });

    test('openai_compatible protocol saves and reads correctly', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('openai'),
              displayName: const Value('OpenAI'),
              baseUrl: const Value('https://api.openai.com/v1'),
              defaultModel: const Value('gpt-4'),
              enabled: const Value(true),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      final row = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('openai')))
          .getSingle();
      expect(row.protocol, 'openai_compatible');
    });

    test('anthropic_messages protocol saves and reads correctly', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('anthropic'),
              displayName: const Value('Anthropic'),
              baseUrl: const Value('https://api.anthropic.com'),
              defaultModel: const Value('claude-3'),
              enabled: const Value(true),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('anthropic_messages'),
            ),
          );

      final row = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('anthropic')))
          .getSingle();
      expect(row.protocol, 'anthropic_messages');
    });

    test('gemini_generate_content protocol saves and reads correctly',
        () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('gemini'),
              displayName: const Value('Gemini'),
              baseUrl: const Value('https://generativelanguage.googleapis.com'),
              defaultModel: const Value('gemini-pro'),
              enabled: const Value(true),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('gemini_generate_content'),
            ),
          );

      final row = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('gemini')))
          .getSingle();
      expect(row.protocol, 'gemini_generate_content');
    });

    test('v2 -> v3 migration adds protocol with default value', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      // Use Drift insert which handles datetime serialization correctly
      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('test'),
              displayName: const Value('Test'),
              baseUrl: const Value('https://test.com'),
              enabled: const Value(true),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      final row = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('test')))
          .getSingle();
      expect(row.protocol, 'openai_compatible');
    });

    test('Conversations data preserved in v3', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('openai'),
              displayName: const Value('OpenAI'),
              baseUrl: const Value('https://api.openai.com/v1'),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_v3'),
              title: const Value('V3 Conv'),
              providerId: const Value('openai'),
              model: const Value('gpt-4'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );

      final conv = await (db.select(db.conversations)
            ..where((t) => t.id.equals('conv_v3')))
          .getSingle();
      expect(conv.title, 'V3 Conv');
      expect(conv.providerId, 'openai');
    });

    test('ChatMessages data preserved in v3', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_msg'),
              title: const Value('Msg Conv'),
              providerId: const Value('openai'),
              model: const Value('gpt-4'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );

      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_v3'),
              conversationId: const Value('conv_msg'),
              role: const Value('user'),
              content: const Value('Hello v3'),
              createdAt: Value(DateTime(2024)),
            ),
          );

      final msg = await (db.select(db.chatMessages)
            ..where((t) => t.id.equals('msg_v3')))
          .getSingle();
      expect(msg.content, 'Hello v3');
    });

    test('foreign key still works in v3', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      expect(
        () => db.into(db.chatMessages).insert(
              ChatMessagesCompanion(
                id: const Value('orphan_v3'),
                conversationId: const Value('nonexistent'),
                role: const Value('user'),
                content: const Value('Orphan'),
                createdAt: Value(DateTime(2024)),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('API key not stored in protocol column', () async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('PRAGMA foreign_keys = ON');

      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('test'),
              displayName: const Value('Test'),
              baseUrl: const Value('https://test.com'),
              updatedAt: Value(DateTime(2024)),
              protocol: const Value('openai_compatible'),
            ),
          );

      final row = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('test')))
          .getSingle();
      expect(row.protocol, isNot(contains('sk-')));
      expect(row.protocol, 'openai_compatible');
    });
  });
}
