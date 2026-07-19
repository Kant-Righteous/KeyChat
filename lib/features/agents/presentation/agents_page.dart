import 'package:flutter/material.dart';
import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/agents/presentation/agent_edit_page.dart';
import 'package:keychat/l10n/generated/app_localizations.dart';

class AgentsPage extends StatefulWidget {
  final AgentProfileStore agentStore;

  const AgentsPage({super.key, required this.agentStore});

  @override
  State<AgentsPage> createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  List<AgentProfileData> _agents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    final agents = await widget.agentStore.readAgents();
    if (mounted) {
      setState(() {
        _agents = agents;
        _loading = false;
      });
    }
  }

  Future<void> _createAgent() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.push<AgentProfileData>(
      context,
      MaterialPageRoute(
        builder: (context) => const AgentEditPage(),
      ),
    );
    if (result != null) {
      try {
        await widget.agentStore.saveAgent(result);
        await _loadAgents();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.agentSaveFailed)),
          );
        }
      }
    }
  }

  Future<void> _editAgent(AgentProfileData agent) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.push<AgentProfileData>(
      context,
      MaterialPageRoute(
        builder: (context) => AgentEditPage(agent: agent),
      ),
    );
    if (result != null) {
      try {
        await widget.agentStore.saveAgent(result);
        await _loadAgents();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.agentSaveFailed)),
          );
        }
      }
    }
  }

  Future<void> _deleteAgent(AgentProfileData agent) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAgent),
        content: Text(l10n.deleteAgentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.agentStore.deleteAgent(agent.id);
      if (success) {
        await _loadAgents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.agentDeleted)),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.agentDeleteFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agents),
        actions: [
          Semantics(
            label: l10n.createAgent,
            child: IconButton(
              onPressed: _createAgent,
              icon: const Icon(Icons.add),
              tooltip: l10n.createAgent,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _agents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined,
                          size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noAgents,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.createAgentHint,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _agents.length,
                  itemBuilder: (context, index) {
                    final agent = _agents[index];
                    return ListTile(
                      leading: const Icon(Icons.smart_toy_outlined),
                      title: Text(agent.name),
                      subtitle: Text(
                        agent.description ?? agent.systemPrompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: l10n.edit,
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editAgent(agent),
                              tooltip: l10n.edit,
                            ),
                          ),
                          Semantics(
                            label: l10n.delete,
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteAgent(agent),
                              tooltip: l10n.delete,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _editAgent(agent),
                    );
                  },
                ),
    );
  }
}
