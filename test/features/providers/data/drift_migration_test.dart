import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3_lib;

void main() {
  group('Real v1 → v3 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('keychat_v1_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('triggers formal onUpgrade from v1 to v3', () async {
      final dbFile = File('${tempDir.path}/v1_test.sqlite');

      // Step 1: Create a real v1 database using raw sqlite3
      final rawDb = sqlite3_lib.sqlite3.open(dbFile.path);

      // v1 only has ProviderConfigs (no Conversations, no ChatMessages, no protocol)
      rawDb.execute('''
        CREATE TABLE provider_configs (
          provider_id TEXT NOT NULL PRIMARY KEY,
          display_name TEXT NOT NULL,
          base_url TEXT NOT NULL,
          default_model TEXT,
          enabled INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER NOT NULL
        )
      ''');

      rawDb.execute('PRAGMA user_version = 1');

      // Insert v1 data
      rawDb.execute(
        "INSERT INTO provider_configs (provider_id, display_name, base_url, default_model, enabled, updated_at) "
        "VALUES ('openai', 'OpenAI', 'https://api.openai.com/v1', 'gpt-4', 1, 1704067200000)",
      );
      rawDb.execute(
        "INSERT INTO provider_configs (provider_id, display_name, base_url, enabled, updated_at) "
        "VALUES ('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1', 1, 1704067200000)",
      );

      rawDb.dispose();

      // Step 2: Open with current AppDatabase - this triggers migration
      final db = AppDatabase.forTesting(
        NativeDatabase(File(dbFile.path)),
      );

      // Step 3: Verify migration results

      // schemaVersion should be 5
      expect(db.schemaVersion, 5);

      // ProviderConfigs data preserved
      final configs = await db.select(db.providerConfigs).get();
      expect(configs.length, 2);

      final openai = configs.firstWhere((c) => c.providerId == 'openai');
      expect(openai.displayName, 'OpenAI');
      expect(openai.baseUrl, 'https://api.openai.com/v1');
      expect(openai.defaultModel, 'gpt-4');
      expect(openai.enabled, true);
      expect(openai.protocol, 'openai_compatible');

      final deepseek = configs.firstWhere((c) => c.providerId == 'deepseek');
      expect(deepseek.displayName, 'DeepSeek');
      expect(deepseek.baseUrl, 'https://api.deepseek.com/v1');
      expect(deepseek.defaultModel, equals(null));
      expect(deepseek.enabled, true);
      expect(deepseek.protocol, 'openai_compatible');

      // Conversations table created by migration
      final convs = await db.select(db.conversations).get();
      expect(convs, isEmpty);

      // ChatMessages table created by migration
      final msgs = await db.select(db.chatMessages).get();
      expect(msgs, isEmpty);

      // Can insert new conversation
      await db.into(db.conversations).insert(
            ConversationsCompanion(
              id: const Value('conv_new'),
              title: const Value('New Conv'),
              providerId: const Value('openai'),
              model: const Value('gpt-4'),
              createdAt: Value(DateTime(2024)),
              updatedAt: Value(DateTime(2024)),
            ),
          );
      final newConv = await (db.select(db.conversations)
            ..where((t) => t.id.equals('conv_new')))
          .getSingle();
      expect(newConv.title, 'New Conv');

      // Can insert new chat message
      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_new'),
              conversationId: const Value('conv_new'),
              role: const Value('user'),
              content: const Value('Hello'),
              createdAt: Value(DateTime(2024)),
            ),
          );
      final newMsg = await (db.select(db.chatMessages)
            ..where((t) => t.id.equals('msg_new')))
          .getSingle();
      expect(newMsg.content, 'Hello');

      // Foreign key works
      expect(
        () => db.into(db.chatMessages).insert(
              ChatMessagesCompanion(
                id: const Value('orphan'),
                conversationId: const Value('nonexistent'),
                role: const Value('user'),
                content: const Value('Orphan'),
                createdAt: Value(DateTime(2024)),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // Cascade delete works
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
      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_del'),
              conversationId: const Value('conv_del'),
              role: const Value('user'),
              content: const Value('Delete me'),
              createdAt: Value(DateTime(2024)),
            ),
          );

      await (db.delete(db.conversations)..where((t) => t.id.equals('conv_del')))
          .go();
      final deletedMsgs = await (db.select(db.chatMessages)
            ..where((t) => t.id.equals('msg_del')))
          .get();
      expect(deletedMsgs, isEmpty);

      // Protocol column is NOT NULL with SQL DEFAULT
      final pragmaResult =
          await db.customSelect("PRAGMA table_info(provider_configs)").get();
      final protocolCol = pragmaResult.firstWhere(
        (row) => row.data['name'] == 'protocol',
      );
      expect(protocolCol.data['type'], 'TEXT');
      expect(protocolCol.data['notnull'], 1);
      expect(protocolCol.data['dflt_value'], "'openai_compatible'");

      // API key column does not exist
      final colNames = db.providerConfigs.$columns.map((c) => c.name).toList();
      expect(colNames, isNot(contains('api_key')));

      // Database can be closed and reopened
      await db.close();
      final db2 = AppDatabase.forTesting(
        NativeDatabase(File(dbFile.path)),
      );
      final configs2 = await db2.select(db2.providerConfigs).get();
      expect(configs2.length, 2);
      expect(configs2.firstWhere((c) => c.providerId == 'openai').protocol,
          'openai_compatible');
      await db2.close();
    });
  });

  group('Real v2 → v3 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('keychat_v2_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('triggers formal onUpgrade from v2 to v3 with data', () async {
      final dbFile = File('${tempDir.path}/v2_test.sqlite');

      // Step 1: Create a real v2 database
      final rawDb = sqlite3_lib.sqlite3.open(dbFile.path);

      // v2 has ProviderConfigs (no protocol), Conversations, ChatMessages
      rawDb.execute('''
        CREATE TABLE provider_configs (
          provider_id TEXT NOT NULL PRIMARY KEY,
          display_name TEXT NOT NULL,
          base_url TEXT NOT NULL,
          default_model TEXT,
          enabled INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER NOT NULL
        )
      ''');

      rawDb.execute('''
        CREATE TABLE conversations (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          model TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      rawDb.execute('''
        CREATE TABLE chat_messages (
          id TEXT NOT NULL PRIMARY KEY,
          conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      rawDb.execute('PRAGMA user_version = 2');

      // Insert v2 data
      rawDb.execute(
        "INSERT INTO provider_configs (provider_id, display_name, base_url, default_model, enabled, updated_at) "
        "VALUES ('openai', 'OpenAI', 'https://api.openai.com/v1', 'gpt-4', 1, 1704067200000)",
      );
      rawDb.execute(
        "INSERT INTO provider_configs (provider_id, display_name, base_url, enabled, updated_at) "
        "VALUES ('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1', 1, 1704067200000)",
      );
      rawDb.execute(
        "INSERT INTO conversations (id, title, provider_id, model, created_at, updated_at) "
        "VALUES ('conv_1', 'Test Conv', 'openai', 'gpt-4', 1704067200000, 1704067200000)",
      );
      rawDb.execute(
        "INSERT INTO chat_messages (id, conversation_id, role, content, created_at) "
        "VALUES ('msg_1', 'conv_1', 'user', 'Hello', 1704067200000)",
      );
      rawDb.execute(
        "INSERT INTO chat_messages (id, conversation_id, role, content, created_at) "
        "VALUES ('msg_2', 'conv_1', 'assistant', 'Hi there', 1704067201000)",
      );

      rawDb.dispose();

      // Step 2: Open with current AppDatabase - triggers v2→v3 migration
      final db = AppDatabase.forTesting(
        NativeDatabase(File(dbFile.path)),
      );

      // Step 3: Verify migration results

      // ProviderConfigs preserved with protocol
      final configs = await db.select(db.providerConfigs).get();
      expect(configs.length, 2);

      final openai = configs.firstWhere((c) => c.providerId == 'openai');
      expect(openai.displayName, 'OpenAI');
      expect(openai.baseUrl, 'https://api.openai.com/v1');
      expect(openai.defaultModel, 'gpt-4');
      expect(openai.enabled, true);
      expect(openai.protocol, 'openai_compatible');

      final deepseek = configs.firstWhere((c) => c.providerId == 'deepseek');
      expect(deepseek.displayName, 'DeepSeek');
      expect(deepseek.protocol, 'openai_compatible');

      // Conversations preserved
      final convs = await db.select(db.conversations).get();
      expect(convs.length, 1);
      expect(convs.first.id, 'conv_1');
      expect(convs.first.title, 'Test Conv');
      expect(convs.first.providerId, 'openai');
      expect(convs.first.model, 'gpt-4');

      // ChatMessages preserved in order
      final msgs = await (db.select(db.chatMessages)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
      expect(msgs.length, 2);
      expect(msgs[0].id, 'msg_1');
      expect(msgs[0].role, 'user');
      expect(msgs[0].content, 'Hello');
      expect(msgs[1].id, 'msg_2');
      expect(msgs[1].role, 'assistant');
      expect(msgs[1].content, 'Hi there');

      // Protocol column properties
      final pragmaResult =
          await db.customSelect("PRAGMA table_info(provider_configs)").get();
      final protocolCol = pragmaResult.firstWhere(
        (row) => row.data['name'] == 'protocol',
      );
      expect(protocolCol.data['type'], 'TEXT');
      expect(protocolCol.data['notnull'], 1);
      expect(protocolCol.data['dflt_value'], "'openai_compatible'");

      // Foreign key works
      expect(
        () => db.into(db.chatMessages).insert(
              ChatMessagesCompanion(
                id: const Value('orphan'),
                conversationId: const Value('nonexistent'),
                role: const Value('user'),
                content: const Value('Orphan'),
                createdAt: Value(DateTime(2024)),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // Cascade delete works
      await (db.delete(db.conversations)..where((t) => t.id.equals('conv_1')))
          .go();
      final remainingMsgs = await db.select(db.chatMessages).get();
      expect(remainingMsgs, isEmpty);

      // Can read and write after migration
      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('new_provider'),
              displayName: const Value('New'),
              baseUrl: const Value('https://new.example.com'),
              updatedAt: Value(DateTime(2024)),
            ),
          );
      final newConfig = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('new_provider')))
          .getSingle();
      expect(newConfig.protocol, 'openai_compatible');

      // Database can be closed and reopened
      await db.close();
      final db2 = AppDatabase.forTesting(
        NativeDatabase(File(dbFile.path)),
      );
      final configs2 = await db2.select(db2.providerConfigs).get();
      expect(configs2.length, 3);
      await db2.close();
    });

    test('migrates v4 messages with null model snapshots', () async {
      final dbFile = File('${tempDir.path}/v4_test.sqlite');
      final rawDb = sqlite3_lib.sqlite3.open(dbFile.path);

      rawDb.execute('''
        CREATE TABLE provider_configs (
          provider_id TEXT NOT NULL PRIMARY KEY,
          display_name TEXT NOT NULL,
          base_url TEXT NOT NULL,
          default_model TEXT,
          enabled INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER NOT NULL,
          protocol TEXT NOT NULL DEFAULT 'openai_compatible'
        )
      ''');
      rawDb.execute('''
        CREATE TABLE agent_profiles (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          system_prompt TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE conversations (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          model TEXT NOT NULL,
          agent_id TEXT,
          agent_name_snapshot TEXT,
          system_prompt_snapshot TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE chat_messages (
          id TEXT NOT NULL PRIMARY KEY,
          conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      rawDb.execute('PRAGMA user_version = 4');
      rawDb.execute(
        "INSERT INTO conversations (id, title, provider_id, model, created_at, updated_at) "
        "VALUES ('conv_legacy', 'Legacy', 'openai', 'gpt-4', 1704067200000, 1704067200000)",
      );
      rawDb.execute(
        "INSERT INTO chat_messages (id, conversation_id, role, content, created_at) "
        "VALUES ('msg_legacy', 'conv_legacy', 'assistant', 'Old reply', 1704067201000)",
      );
      rawDb.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(File(dbFile.path)));
      final message = await db.select(db.chatMessages).getSingle();

      expect(db.schemaVersion, 5);
      expect(message.content, 'Old reply');
      expect(message.providerIdSnapshot, equals(null));
      expect(message.providerNameSnapshot, equals(null));
      expect(message.modelIdSnapshot, equals(null));

      await db.close();
    });
  });

  group('Fresh current database schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 5', () {
      expect(db.schemaVersion, 5);
    });

    test('protocol column is TEXT NOT NULL with SQL DEFAULT', () async {
      final result =
          await db.customSelect("PRAGMA table_info(provider_configs)").get();
      final protocolCol = result.firstWhere(
        (row) => row.data['name'] == 'protocol',
      );
      expect(protocolCol.data['type'], 'TEXT');
      expect(protocolCol.data['notnull'], 1);
      expect(protocolCol.data['dflt_value'], "'openai_compatible'");
    });

    test('protocol uses default when not specified', () async {
      await db.into(db.providerConfigs).insert(
            ProviderConfigsCompanion(
              providerId: const Value('test'),
              displayName: const Value('Test'),
              baseUrl: const Value('https://test.com'),
              updatedAt: Value(DateTime(2024)),
            ),
          );
      final row = await (db.select(db.providerConfigs)
            ..where((t) => t.providerId.equals('test')))
          .getSingle();
      expect(row.protocol, 'openai_compatible');
    });

    test('Conversations structure unchanged', () {
      final cols = db.conversations.$columns.map((c) => c.name).toList();
      expect(cols, contains('id'));
      expect(cols, contains('title'));
      expect(cols, contains('provider_id'));
      expect(cols, contains('model'));
      expect(cols, contains('agent_id'));
      expect(cols, contains('agent_name_snapshot'));
      expect(cols, contains('system_prompt_snapshot'));
      expect(cols, contains('created_at'));
      expect(cols, contains('updated_at'));
      expect(cols.length, 9);
    });

    test('ChatMessages contains nullable model snapshot columns', () {
      final cols = db.chatMessages.$columns.map((c) => c.name).toList();
      expect(cols, contains('id'));
      expect(cols, contains('conversation_id'));
      expect(cols, contains('role'));
      expect(cols, contains('content'));
      expect(cols, contains('provider_id_snapshot'));
      expect(cols, contains('provider_name_snapshot'));
      expect(cols, contains('model_id_snapshot'));
      expect(cols, contains('created_at'));
      expect(cols.length, 8);
    });

    test('chat message snapshot excludes secrets and endpoint', () {
      final cols = db.chatMessages.$columns.map((c) => c.name).toList();
      expect(cols, isNot(contains('api_key')));
      expect(cols, isNot(contains('secret')));
      expect(cols, isNot(contains('base_url')));
      expect(cols, isNot(contains('authorization')));
    });

    test('AgentProfiles table exists', () {
      final cols = db.agentProfiles.$columns.map((c) => c.name).toList();
      expect(cols, contains('id'));
      expect(cols, contains('name'));
      expect(cols, contains('description'));
      expect(cols, contains('system_prompt'));
      expect(cols, contains('created_at'));
      expect(cols, contains('updated_at'));
      expect(cols.length, 6);
    });

    test('foreign key enabled', () async {
      expect(
        () => db.into(db.chatMessages).insert(
              ChatMessagesCompanion(
                id: const Value('orphan'),
                conversationId: const Value('nonexistent'),
                role: const Value('user'),
                content: const Value('Orphan'),
                createdAt: Value(DateTime(2024)),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('cascade delete works', () async {
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
      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion(
              id: const Value('msg_del'),
              conversationId: const Value('conv_del'),
              role: const Value('user'),
              content: const Value('Delete me'),
              createdAt: Value(DateTime(2024)),
            ),
          );

      await (db.delete(db.conversations)..where((t) => t.id.equals('conv_del')))
          .go();

      final msgs = await db.select(db.chatMessages).get();
      expect(msgs, isEmpty);
    });
  });
}
