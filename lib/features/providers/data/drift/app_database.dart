import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class ProviderConfigs extends Table {
  TextColumn get providerId => text()();
  TextColumn get displayName => text()();
  TextColumn get baseUrl => text()();
  TextColumn get defaultModel => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get protocol =>
      text().withDefault(const Constant('openai_compatible'))();
  BoolColumn get supportsImageInput =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get supportsFileInput =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {providerId};
}

@DataClassName('ModelAttachmentCapabilityRow')
class ModelAttachmentCapabilities extends Table {
  TextColumn get providerId => text().references(
        ProviderConfigs,
        #providerId,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get modelId => text()();
  TextColumn get modality => text()();
  TextColumn get status => text()();
  TextColumn get source => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {providerId, modelId, modality, source};
}

class AgentProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get systemPrompt => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get providerId => text()();
  TextColumn get model => text()();
  TextColumn get agentId => text().nullable()();
  TextColumn get agentNameSnapshot => text().nullable()();
  TextColumn get systemPromptSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get providerIdSnapshot => text().nullable()();
  TextColumn get providerNameSnapshot => text().nullable()();
  TextColumn get modelIdSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();
  TextColumn get localPath => text()();
  TextColumn get kind => text()();
  TextColumn get messageId =>
      text().references(ChatMessages, #id, onDelete: KeyAction.cascade)();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttachmentDeliveryStateRow')
class AttachmentDeliveryStates extends Table {
  TextColumn get attachmentId => text().references(
        ChatAttachments,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {attachmentId, providerId, modelId};
}

@DriftDatabase(
  tables: [
    ProviderConfigs,
    AgentProfiles,
    Conversations,
    ChatMessages,
    ChatAttachments,
    AttachmentDeliveryStates,
    ModelAttachmentCapabilities,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(conversations);
            await m.createTable(chatMessages);
          }
          if (from < 3) {
            await m.addColumn(providerConfigs, providerConfigs.protocol);
          }
          if (from >= 2 && from < 4) {
            await m.addColumn(conversations, conversations.agentId);
            await m.addColumn(conversations, conversations.agentNameSnapshot);
            await m.addColumn(
                conversations, conversations.systemPromptSnapshot);
          }
          if (from < 4) {
            await m.createTable(agentProfiles);
          }
          if (from >= 2 && from < 5) {
            await m.addColumn(chatMessages, chatMessages.providerIdSnapshot);
            await m.addColumn(chatMessages, chatMessages.providerNameSnapshot);
            await m.addColumn(chatMessages, chatMessages.modelIdSnapshot);
          }
          if (from < 6) {
            await m.addColumn(
              providerConfigs,
              providerConfigs.supportsImageInput,
            );
            await m.addColumn(
              providerConfigs,
              providerConfigs.supportsFileInput,
            );
            await m.createTable(chatAttachments);
          }
          if (from < 7) {
            await m.createTable(modelAttachmentCapabilities);
            await customStatement('''
              INSERT INTO model_attachment_capabilities (
                provider_id,
                model_id,
                modality,
                status,
                source,
                updated_at
              )
              SELECT
                provider_id,
                default_model,
                'image',
                'supported',
                'manual',
                updated_at
              FROM provider_configs
              WHERE default_model IS NOT NULL
                AND TRIM(default_model) <> ''
                AND supports_image_input = 1
            ''');
            await customStatement('''
              INSERT INTO model_attachment_capabilities (
                provider_id,
                model_id,
                modality,
                status,
                source,
                updated_at
              )
              SELECT
                provider_id,
                default_model,
                'file',
                'supported',
                'manual',
                updated_at
              FROM provider_configs
              WHERE default_model IS NOT NULL
                AND TRIM(default_model) <> ''
                AND supports_file_input = 1
            ''');
          }
          if (from < 8) {
            await m.createTable(attachmentDeliveryStates);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'keychat.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
