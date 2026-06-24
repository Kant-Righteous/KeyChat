class AgentProfileData {
  final String id;
  final String name;
  final String? description;
  final String systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentProfileData({
    required this.id,
    required this.name,
    this.description,
    required this.systemPrompt,
    required this.createdAt,
    required this.updatedAt,
  });

  static String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'agentNameRequired';
    if (trimmed.length > 50) return 'agentNameTooLong';
    return null;
  }

  static String? validateSystemPrompt(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return 'agentSystemPromptRequired';
    if (trimmed.length > 20000) return 'agentSystemPromptTooLong';
    return null;
  }
}
