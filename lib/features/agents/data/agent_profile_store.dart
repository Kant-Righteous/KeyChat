import 'package:keychat/features/agents/domain/agent_profile.dart';

abstract interface class AgentProfileStore {
  Future<List<AgentProfileData>> readAgents();
  Future<AgentProfileData?> readAgent(String id);
  Future<void> saveAgent(AgentProfileData agent);
  Future<bool> deleteAgent(String id);
}
