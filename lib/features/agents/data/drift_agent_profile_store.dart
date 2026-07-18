import 'package:drift/drift.dart';
import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

class DriftAgentProfileStore implements AgentProfileStore {
  final AppDatabase _db;

  DriftAgentProfileStore(this._db);

  @override
  Future<List<AgentProfileData>> readAgents() async {
    final query = _db.select(_db.agentProfiles)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    final rows = await query.get();
    return rows.map(_toAgentProfile).toList();
  }

  @override
  Future<AgentProfileData?> readAgent(String id) async {
    final query = _db.select(_db.agentProfiles)
      ..where((t) => t.id.equals(id))
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toAgentProfile(row);
  }

  @override
  Future<void> saveAgent(AgentProfileData agent) async {
    await _db.into(_db.agentProfiles).insertOnConflictUpdate(
          AgentProfilesCompanion(
            id: Value(agent.id),
            name: Value(agent.name),
            description: Value(agent.description),
            systemPrompt: Value(agent.systemPrompt),
            createdAt: Value(agent.createdAt),
            updatedAt: Value(agent.updatedAt),
          ),
        );
  }

  @override
  Future<bool> deleteAgent(String id) async {
    final existing = await readAgent(id);
    if (existing == null) return false;

    await (_db.delete(_db.agentProfiles)..where((t) => t.id.equals(id))).go();
    return true;
  }

  AgentProfileData _toAgentProfile(AgentProfile row) {
    return AgentProfileData(
      id: row.id,
      name: row.name,
      description: row.description,
      systemPrompt: row.systemPrompt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
