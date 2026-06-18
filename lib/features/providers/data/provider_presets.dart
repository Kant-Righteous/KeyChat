class ProviderPreset {
  final String id;
  final String name;
  final String description;
  final String defaultBaseUrl;
  final bool isCustom;

  const ProviderPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultBaseUrl,
    this.isCustom = false,
  });
}

const providerPresets = [
  ProviderPreset(
    id: 'openai',
    name: 'OpenAI',
    description: 'GPT-4, GPT-3.5 Turbo, and other OpenAI models',
    defaultBaseUrl: 'https://api.openai.com/v1',
  ),
  ProviderPreset(
    id: 'deepseek',
    name: 'DeepSeek',
    description: 'DeepSeek Chat and Coder models',
    defaultBaseUrl: 'https://api.deepseek.com/v1',
  ),
  ProviderPreset(
    id: 'openrouter',
    name: 'OpenRouter',
    description: 'Access multiple AI providers through one API',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
  ),
  ProviderPreset(
    id: 'custom',
    name: 'Custom Provider',
    description: 'Any OpenAI-compatible provider',
    defaultBaseUrl: '',
    isCustom: true,
  ),
];
