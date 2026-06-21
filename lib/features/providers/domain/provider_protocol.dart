enum ProviderProtocol {
  openAiCompatible,
  anthropicMessages,
  geminiGenerateContent;

  String get storageValue {
    switch (this) {
      case ProviderProtocol.openAiCompatible:
        return 'openai_compatible';
      case ProviderProtocol.anthropicMessages:
        return 'anthropic_messages';
      case ProviderProtocol.geminiGenerateContent:
        return 'gemini_generate_content';
    }
  }

  static ProviderProtocol? tryParse(String value) {
    switch (value) {
      case 'openai_compatible':
        return ProviderProtocol.openAiCompatible;
      case 'anthropic_messages':
        return ProviderProtocol.anthropicMessages;
      case 'gemini_generate_content':
        return ProviderProtocol.geminiGenerateContent;
      default:
        return null;
    }
  }
}
