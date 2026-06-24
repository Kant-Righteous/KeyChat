import 'package:flutter/material.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AgentEditPage extends StatefulWidget {
  final AgentProfileData? agent;

  const AgentEditPage({super.key, this.agent});

  @override
  State<AgentEditPage> createState() => _AgentEditPageState();
}

class _AgentEditPageState extends State<AgentEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.agent != null) {
      _nameController.text = widget.agent!.name;
      _descriptionController.text = widget.agent!.description ?? '';
      _systemPromptController.text = widget.agent!.systemPrompt;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final agent = AgentProfileData(
      id: widget.agent?.id ?? 'agent_${now.microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      systemPrompt: _systemPromptController.text.trim(),
      createdAt: widget.agent?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, agent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.agent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editAgent : l10n.createAgent),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.agentName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final error = AgentProfileData.validateName(value ?? '');
                if (error != null) {
                  return _getValidationMessage(l10n, error);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.agentDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _systemPromptController,
              decoration: InputDecoration(
                labelText: l10n.agentSystemPrompt,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (value) {
                final error =
                    AgentProfileData.validateSystemPrompt(value ?? '');
                if (error != null) {
                  return _getValidationMessage(l10n, error);
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getValidationMessage(AppLocalizations l10n, String errorKey) {
    switch (errorKey) {
      case 'agentNameRequired':
        return l10n.agentNameRequired;
      case 'agentNameTooLong':
        return l10n.agentNameTooLong;
      case 'agentSystemPromptRequired':
        return l10n.agentSystemPromptRequired;
      case 'agentSystemPromptTooLong':
        return l10n.agentSystemPromptTooLong;
      default:
        return errorKey;
    }
  }
}
