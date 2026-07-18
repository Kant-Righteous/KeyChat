import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';

class FakeAgentProfileStore implements AgentProfileStore {
  final List<AgentProfileData> _agents = [];

  @override
  Future<List<AgentProfileData>> readAgents() async {
    return List.unmodifiable(_agents);
  }

  @override
  Future<AgentProfileData?> readAgent(String id) async {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAgent(AgentProfileData agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
  }

  @override
  Future<bool> deleteAgent(String id) async {
    final index = _agents.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _agents.removeAt(index);
      return true;
    }
    return false;
  }
}
