import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

void main() {
  group('ProviderConfigs table schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('table contains expected columns including protocol', () {
      final table = db.providerConfigs;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, contains('provider_id'));
      expect(columnNames, contains('display_name'));
      expect(columnNames, contains('base_url'));
      expect(columnNames, contains('default_model'));
      expect(columnNames, contains('enabled'));
      expect(columnNames, contains('updated_at'));
      expect(columnNames, contains('protocol'));
      expect(columnNames, contains('supports_image_input'));
      expect(columnNames, contains('supports_file_input'));
      expect(columnNames.length, 9);
    });

    test('table does not contain API key column', () {
      final table = db.providerConfigs;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, isNot(contains('api_key')));
      expect(columnNames, isNot(contains('apiKey')));
      expect(columnNames, isNot(contains('key')));
      expect(columnNames, isNot(contains('secret')));
      expect(columnNames, isNot(contains('token')));
    });

    test('provider_id is primary key', () {
      final table = db.providerConfigs;
      final primaryKey = table.primaryKey;

      expect(primaryKey.length, 1);
      expect(primaryKey.first.name, 'provider_id');
    });

    test('protocol column is TEXT NOT NULL via PRAGMA', () async {
      await db.customStatement('PRAGMA foreign_keys = ON');

      final result = await db
          .customSelect(
            "PRAGMA table_info(provider_configs)",
          )
          .get();

      final protocolCol = result.firstWhere(
        (row) => row.data['name'] == 'protocol',
      );

      expect(protocolCol.data['type'], 'TEXT');
      expect(protocolCol.data['notnull'], 1);
    });

    test('protocol column has SQL default value via PRAGMA', () async {
      await db.customStatement('PRAGMA foreign_keys = ON');

      final result = await db
          .customSelect(
            "PRAGMA table_info(provider_configs)",
          )
          .get();

      final protocolCol = result.firstWhere(
        (row) => row.data['name'] == 'protocol',
      );

      // The default value should be 'openai_compatible'
      expect(protocolCol.data['dflt_value'], "'openai_compatible'");
    });

    test('schemaVersion is 8', () {
      expect(db.schemaVersion, 8);
    });
  });

  group('Conversations table schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('table contains expected columns', () {
      final table = db.conversations;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('title'));
      expect(columnNames, contains('provider_id'));
      expect(columnNames, contains('model'));
      expect(columnNames, contains('agent_id'));
      expect(columnNames, contains('agent_name_snapshot'));
      expect(columnNames, contains('system_prompt_snapshot'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
      expect(columnNames.length, 9);
    });

    test('table does not contain API key column', () {
      final table = db.conversations;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, isNot(contains('api_key')));
      expect(columnNames, isNot(contains('apiKey')));
      expect(columnNames, isNot(contains('secret')));
    });
  });

  group('ChatMessages table schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('table contains expected columns', () {
      final table = db.chatMessages;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('conversation_id'));
      expect(columnNames, contains('role'));
      expect(columnNames, contains('content'));
      expect(columnNames, contains('provider_id_snapshot'));
      expect(columnNames, contains('provider_name_snapshot'));
      expect(columnNames, contains('model_id_snapshot'));
      expect(columnNames, contains('created_at'));
      expect(columnNames.length, 8);
    });

    test('table does not contain credentials or endpoint columns', () {
      final table = db.chatMessages;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, isNot(contains('api_key')));
      expect(columnNames, isNot(contains('apiKey')));
      expect(columnNames, isNot(contains('secret')));
      expect(columnNames, isNot(contains('base_url')));
      expect(columnNames, isNot(contains('authorization')));
      expect(columnNames, isNot(contains('authorization_header')));
    });
  });

  group('ChatAttachments table schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('contains attachment metadata but no content or secrets', () {
      final names = db.chatAttachments.$columns.map((c) => c.name).toList();

      expect(
          names,
          containsAll([
            'id',
            'file_name',
            'mime_type',
            'file_size',
            'local_path',
            'kind',
            'message_id',
            'conversation_id',
          ]));
      expect(names, isNot(contains('content')));
      expect(names, isNot(contains('api_key')));
      expect(names, isNot(contains('base_url')));
      expect(names, isNot(contains('authorization')));
      expect(names, isNot(contains('request_body')));
      expect(names, isNot(contains('response_body')));
    });
  });

  group('ModelAttachmentCapabilities table schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('contains only model capability metadata', () {
      final names =
          db.modelAttachmentCapabilities.$columns.map((c) => c.name).toList();

      expect(
        names,
        containsAll([
          'provider_id',
          'model_id',
          'modality',
          'status',
          'source',
          'updated_at',
        ]),
      );
      expect(names, hasLength(6));
      expect(names, isNot(contains('api_key')));
      expect(names, isNot(contains('base_url')));
      expect(names, isNot(contains('authorization')));
      expect(names, isNot(contains('request_body')));
      expect(names, isNot(contains('response_body')));
    });

    test('primary key includes provider model modality and source', () {
      final primaryKey =
          db.modelAttachmentCapabilities.primaryKey.map((c) => c.name).toSet();

      expect(
        primaryKey,
        {'provider_id', 'model_id', 'modality', 'source'},
      );
    });
  });

  group('AttachmentDeliveryStates table schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('contains only per-attachment delivery metadata', () {
      final table = db.attachmentDeliveryStates;
      final names = table.$columns.map((column) => column.name).toList();

      expect(
        names,
        containsAll([
          'attachment_id',
          'provider_id',
          'model_id',
          'status',
          'updated_at',
        ]),
      );
      expect(names, hasLength(5));
      expect(names, isNot(contains('api_key')));
      expect(names, isNot(contains('base_url')));
      expect(names, isNot(contains('request_body')));
      expect(names, isNot(contains('response_body')));
    });

    test('primary key isolates an attachment per provider and model', () {
      final primaryKey = db.attachmentDeliveryStates.primaryKey
          .map((column) => column.name)
          .toSet();

      expect(primaryKey, {'attachment_id', 'provider_id', 'model_id'});
    });
  });
}
