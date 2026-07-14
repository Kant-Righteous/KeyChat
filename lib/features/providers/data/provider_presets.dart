import 'package:keychat/features/providers/domain/provider_protocol.dart';

class ProviderPreset {
  final String id;
  final String name;
  final String description;
  final String defaultBaseUrl;
  final bool isCustom;
  final ProviderProtocol protocol;

  const ProviderPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultBaseUrl,
    required this.protocol,
    this.isCustom = false,
  });
}

class ProviderEndpointPreset {
  final String id;
  final String defaultBaseUrl;
  final String? apiKeyPrefix;
  final bool isPlan;

  const ProviderEndpointPreset({
    required this.id,
    required this.defaultBaseUrl,
    this.apiKeyPrefix,
    this.isPlan = false,
  });
}

class ProviderTemplatePreset {
  final String id;
  final String name;
  final List<ProviderEndpointPreset> endpoints;

  const ProviderTemplatePreset({
    required this.id,
    required this.name,
    required this.endpoints,
  });
}

const providerPresets = [
  ProviderPreset(
    id: 'openai',
    name: 'OpenAI',
    description: 'GPT-4, GPT-3.5 Turbo, and other OpenAI models',
    defaultBaseUrl: 'https://api.openai.com/v1',
    protocol: ProviderProtocol.openAiCompatible,
  ),
  ProviderPreset(
    id: 'deepseek',
    name: 'DeepSeek',
    description: 'DeepSeek Chat and Coder models',
    defaultBaseUrl: 'https://api.deepseek.com/v1',
    protocol: ProviderProtocol.openAiCompatible,
  ),
  ProviderPreset(
    id: 'openrouter',
    name: 'OpenRouter',
    description: 'Access multiple AI providers through one API',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
    protocol: ProviderProtocol.openAiCompatible,
  ),
  ProviderPreset(
    id: 'custom',
    name: 'Custom Provider',
    description: 'Any OpenAI-compatible provider',
    defaultBaseUrl: '',
    isCustom: true,
    protocol: ProviderProtocol.openAiCompatible,
  ),
];

const providerTemplatePresets = [
  ProviderTemplatePreset(
    id: 'custom',
    name: 'Custom Provider',
    endpoints: [],
  ),
  ProviderTemplatePreset(
    id: 'openai',
    name: 'OpenAI',
    endpoints: [
      ProviderEndpointPreset(
        id: 'openai_default',
        defaultBaseUrl: 'https://api.openai.com/v1',
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'deepseek',
    name: 'DeepSeek',
    endpoints: [
      ProviderEndpointPreset(
        id: 'deepseek_default',
        defaultBaseUrl: 'https://api.deepseek.com/v1',
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'openrouter',
    name: 'OpenRouter',
    endpoints: [
      ProviderEndpointPreset(
        id: 'openrouter_default',
        defaultBaseUrl: 'https://openrouter.ai/api/v1',
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'kimi',
    name: 'Kimi',
    endpoints: [
      ProviderEndpointPreset(
        id: 'kimi_china',
        defaultBaseUrl: 'https://api.moonshot.cn/v1',
      ),
      ProviderEndpointPreset(
        id: 'kimi_global',
        defaultBaseUrl: 'https://api.moonshot.ai/v1',
      ),
      ProviderEndpointPreset(
        id: 'kimi_code',
        defaultBaseUrl: 'https://api.kimi.com/coding/v1',
        isPlan: true,
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'mimo',
    name: 'MiMo',
    endpoints: [
      ProviderEndpointPreset(
        id: 'mimo_pay_as_you_go',
        defaultBaseUrl: 'https://api.xiaomimimo.com/v1',
        apiKeyPrefix: 'sk-',
      ),
      ProviderEndpointPreset(
        id: 'mimo_token_china',
        defaultBaseUrl: 'https://token-plan-cn.xiaomimimo.com/v1',
        apiKeyPrefix: 'tp-',
        isPlan: true,
      ),
      ProviderEndpointPreset(
        id: 'mimo_token_singapore',
        defaultBaseUrl: 'https://token-plan-sgp.xiaomimimo.com/v1',
        apiKeyPrefix: 'tp-',
        isPlan: true,
      ),
      ProviderEndpointPreset(
        id: 'mimo_token_europe',
        defaultBaseUrl: 'https://token-plan-ams.xiaomimimo.com/v1',
        apiKeyPrefix: 'tp-',
        isPlan: true,
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'glm',
    name: 'GLM',
    endpoints: [
      ProviderEndpointPreset(
        id: 'glm_china_general',
        defaultBaseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      ),
      ProviderEndpointPreset(
        id: 'glm_global_general',
        defaultBaseUrl: 'https://api.z.ai/api/paas/v4',
      ),
      ProviderEndpointPreset(
        id: 'glm_china_coding',
        defaultBaseUrl: 'https://open.bigmodel.cn/api/coding/paas/v4',
        isPlan: true,
      ),
      ProviderEndpointPreset(
        id: 'glm_global_coding',
        defaultBaseUrl: 'https://api.z.ai/api/coding/paas/v4',
        isPlan: true,
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'gemini',
    name: 'Gemini',
    endpoints: [
      ProviderEndpointPreset(
        id: 'gemini_default',
        defaultBaseUrl:
            'https://generativelanguage.googleapis.com/v1beta/openai',
      ),
    ],
  ),
  ProviderTemplatePreset(
    id: 'qwen',
    name: 'Qwen',
    endpoints: [
      ProviderEndpointPreset(
        id: 'qwen_pay_as_you_go_beijing',
        defaultBaseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        apiKeyPrefix: 'sk-',
      ),
      ProviderEndpointPreset(
        id: 'qwen_pay_as_you_go_singapore',
        defaultBaseUrl:
            'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
        apiKeyPrefix: 'sk-',
      ),
      ProviderEndpointPreset(
        id: 'qwen_pay_as_you_go_us',
        defaultBaseUrl: 'https://dashscope-us.aliyuncs.com/compatible-mode/v1',
        apiKeyPrefix: 'sk-',
      ),
      ProviderEndpointPreset(
        id: 'qwen_token_beijing',
        defaultBaseUrl:
            'https://token-plan.cn-beijing.maas.aliyuncs.com/compatible-mode/v1',
        apiKeyPrefix: 'sk-sp-',
        isPlan: true,
      ),
      ProviderEndpointPreset(
        id: 'qwen_coding_beijing',
        defaultBaseUrl: 'https://coding.dashscope.aliyuncs.com/v1',
        apiKeyPrefix: 'sk-sp-',
        isPlan: true,
      ),
    ],
  ),
];
