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

  @override
  Set<Column> get primaryKey => {providerId};
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
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
    tables: [ProviderConfigs, AgentProfiles, Conversations, ChatMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

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
