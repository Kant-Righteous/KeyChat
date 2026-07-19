// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KeyChat';

  @override
  String get chat => 'Chat';

  @override
  String get providers => 'Providers';

  @override
  String get agents => 'Agents';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get aboutKeyChat => 'About KeyChat';

  @override
  String get aboutDescription =>
      'KeyChat is a local-first BYOK AI chat client.\nUsers can configure their own AI API Key and chat directly with compatible large language models.\n\nCurrent version is a test version.';

  @override
  String get noAgent => 'No Agent';

  @override
  String get selectAgent => 'Select agent';

  @override
  String get noModelAvailable => 'No model available';

  @override
  String get configureProviderFirst =>
      'Please configure a provider and model first';

  @override
  String providerModel(String provider, String model) {
    return '$provider · $model';
  }

  @override
  String get legacyModel => 'Legacy model';

  @override
  String get newChat => 'New Chat';

  @override
  String get history => 'History';

  @override
  String get conversationOutline => 'Conversation outline';

  @override
  String get noOutline => 'No outline';

  @override
  String get conversations => 'Conversations';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get rename => 'Rename';

  @override
  String get renameConversation => 'Rename Conversation';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get titleRequired => 'Title cannot be empty';

  @override
  String get titleTooLong => 'Title is too long';

  @override
  String get renameConversationFailed => 'Failed to rename conversation';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String get deleteConversationConfirm =>
      'Delete this conversation and all its messages?';

  @override
  String get deleteConversationFailed => 'Failed to delete conversation';

  @override
  String get exportConversation => 'Export conversation';

  @override
  String get copyAsMarkdown => 'Copy as Markdown';

  @override
  String get shareMarkdown => 'Share Markdown';

  @override
  String get copiedAsMarkdown => 'Copied as Markdown';

  @override
  String get conversationEmpty => 'Conversation is empty';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get stopGenerating => 'Stop generating';

  @override
  String get waitingForResponse => 'Waiting for response';

  @override
  String get thinking => 'Thinking';

  @override
  String get generatingResponse => 'Generating response';

  @override
  String get thinkingProcess => 'Reasoning';

  @override
  String get retry => 'Retry';

  @override
  String get regenerateResponse => 'Regenerate response';

  @override
  String get copyResponse => 'Copy response';

  @override
  String get copied => 'Copied';

  @override
  String get stopped => 'Stopped';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get noReadyProvider => 'No ready provider';

  @override
  String get configureProviderApiKey =>
      'Configure a provider with API key and default model';

  @override
  String get providerNotAvailable => 'Provider is no longer available';

  @override
  String get protocolNotSupported => 'Provider protocol is not supported yet';

  @override
  String get failedToSaveMessage => 'Failed to save message';

  @override
  String get failedToLoadConversation => 'Failed to load conversation';

  @override
  String get responseNotSaved => 'Response interrupted and was not saved';

  @override
  String get invalidProviderResponse => 'Invalid provider response';

  @override
  String get unableToGetResponse => 'Unable to get response';

  @override
  String get responseSavedButNotSaved =>
      'Response received but could not be saved';

  @override
  String get contextTrimmed => 'Earlier messages were omitted for this request';

  @override
  String get currentMessageExceedsBudget =>
      'Current message exceeds the local context estimate';

  @override
  String get systemPromptExceedsBudget =>
      'System prompt and current message exceed the local context estimate';

  @override
  String get agentName => 'Name';

  @override
  String get agentDescription => 'Description (optional)';

  @override
  String get agentSystemPrompt => 'System Prompt';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get createAgent => 'Create Agent';

  @override
  String get editAgent => 'Edit Agent';

  @override
  String get deleteAgent => 'Delete Agent';

  @override
  String get deleteAgentConfirm =>
      'Are you sure you want to delete this agent?';

  @override
  String get deleteAgentDescription =>
      'This cannot be undone, but historical conversations will be preserved.';

  @override
  String get agentNameRequired => 'Name cannot be empty';

  @override
  String get agentNameTooLong => 'Name cannot exceed 50 characters';

  @override
  String get agentSystemPromptRequired => 'System prompt cannot be empty';

  @override
  String get agentSystemPromptTooLong =>
      'System prompt cannot exceed 20000 characters';

  @override
  String get agentSaved => 'Agent saved';

  @override
  String get agentDeleted => 'Agent deleted';

  @override
  String get agentSaveFailed => 'Failed to save';

  @override
  String get agentDeleteFailed => 'Failed to delete';

  @override
  String get noAgents => 'No agents yet';

  @override
  String get createAgentHint => 'Tap + to create a new agent';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get privacy => 'Privacy';

  @override
  String get apiKeyRequired => 'Please configure API Key first';

  @override
  String get modelRequired => 'Please select a model first';

  @override
  String get agent => 'Agent';

  @override
  String get model => 'Model';

  @override
  String get selectModel => 'Select model';

  @override
  String get provider => 'Provider';

  @override
  String get noProvider => 'No provider';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get agentDeletedFromSelector => 'Agent deleted, reverted to No Agent';

  @override
  String get failedToSaveLanguage => 'Failed to save language settings';

  @override
  String get invalidLocale => 'Invalid locale';

  @override
  String get httpsOnly =>
      'Only HTTPS URLs are supported to protect your API key and messages';

  @override
  String get customProvider => 'Custom Provider';

  @override
  String get customProviderDescription => 'Any OpenAI-compatible provider';

  @override
  String get addCustomProvider => 'Custom Provider';

  @override
  String get providerPresetLabel => 'Provider preset';

  @override
  String get manualProviderPreset => 'Other (manual)';

  @override
  String get accessOptionLabel => 'Access option / region';

  @override
  String get providerEndpointKeyHint =>
      'The API key must belong to the selected access option and region.';

  @override
  String apiKeyPrefixHint(String prefix) {
    return 'The API key for this option usually starts with $prefix.';
  }

  @override
  String get planEndpointWarning =>
      'The plan endpoint must be paired with its plan-specific API key and used within the provider\'s permitted scope.';

  @override
  String get visitOfficialWebsite => 'Visit official website';

  @override
  String get unableToOpenOfficialWebsite =>
      'Unable to open the official website. Please try again.';

  @override
  String get chinaApiOption => 'China API';

  @override
  String get globalApiOption => 'Global API';

  @override
  String get kimiCodeOption => 'Kimi Code';

  @override
  String get payAsYouGoApiOption => 'Pay-as-you-go API';

  @override
  String get tokenPlanChinaOption => 'Token Plan · China';

  @override
  String get tokenPlanSingaporeOption => 'Token Plan · Singapore';

  @override
  String get tokenPlanEuropeOption => 'Token Plan · Europe';

  @override
  String get chinaGeneralApiOption => 'China general API';

  @override
  String get globalGeneralApiOption => 'Global general API';

  @override
  String get chinaCodingPlanOption => 'China Coding Plan';

  @override
  String get globalCodingPlanOption => 'Global Coding Plan';

  @override
  String get payAsYouGoBeijingOption => 'Pay-as-you-go · Beijing';

  @override
  String get payAsYouGoSingaporeOption => 'Pay-as-you-go · Singapore';

  @override
  String get payAsYouGoUsOption => 'Pay-as-you-go · US';

  @override
  String get tokenPlanBeijingOption => 'Token Plan · Beijing';

  @override
  String get codingPlanBeijingOption => 'Coding Plan · Beijing';

  @override
  String get openAiDescription => 'OpenAI compatible official API';

  @override
  String get deepSeekDescription => 'DeepSeek official API';

  @override
  String get openRouterDescription =>
      'Access multiple AI providers through one API';

  @override
  String get providerConfigured => 'Configured';

  @override
  String get providerNotConfigured => 'Not configured';

  @override
  String get httpsUpdateRequired => 'Update to HTTPS required';

  @override
  String get configureProviderTitle => 'Configure Provider';

  @override
  String get providerNameLabel => 'Provider Name';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlExampleLabel => 'China Region Example';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get defaultModelLabel => 'Default Model';

  @override
  String get apiKeyConfigured => 'API key is already configured';

  @override
  String get newApiKeyLabel => 'New API Key (leave blank to keep)';

  @override
  String get saveButton => 'Save';

  @override
  String get testConnectionButton => 'Test Connection';

  @override
  String get removeApiKeyButton => 'Remove API Key';

  @override
  String get removeApiKeyConfirmation =>
      'Are you sure you want to remove the API key?';

  @override
  String get remove => 'Remove';

  @override
  String get apiKeyRemoved => 'API key removed';

  @override
  String get providerConfiguredSuccess => 'Provider configured';

  @override
  String get failedToSaveProvider => 'Failed to save configuration';

  @override
  String get failedToRemoveApiKey => 'Failed to remove API key';

  @override
  String get connectionSuccessful => 'Connected';

  @override
  String modelsFound(int count) {
    return '$count models found';
  }

  @override
  String get connectionTestUnsupported =>
      'Connection test is not supported for this protocol';

  @override
  String get invalidApiKey => 'Invalid API key';

  @override
  String get accessForbidden => 'Access forbidden';

  @override
  String get rateLimitExceeded => 'Rate limit exceeded';

  @override
  String get connectionTimedOut => 'Connection timed out';

  @override
  String get networkUnavailable => 'Network unavailable';

  @override
  String get providerServerError => 'Provider server error';

  @override
  String get invalidBaseUrl => 'Invalid Base URL';

  @override
  String get unableToConnect => 'Unable to connect';

  @override
  String get providerConfigInvalid => 'Provider configuration is invalid';

  @override
  String get configLoadError => 'The saved configuration could not be loaded.';

  @override
  String get goBack => 'Go Back';

  @override
  String get loading => 'Loading...';

  @override
  String get initializing => 'Initializing…';

  @override
  String get usageGuide => 'User Guide';

  @override
  String get usageGuideTitle => 'User Guide';

  @override
  String get configurationMethod => 'Configuration Method';

  @override
  String get builtInProvider => 'Built-in Provider';

  @override
  String get quickStartTitle => 'Quick Start';

  @override
  String get quickStartContent =>
      '1. Open Providers, then select a built-in provider or add a custom provider.\n2. Enter the API Key and model ID, test the connection, then save.\n3. Return to Chat, select the model, and start a conversation.';

  @override
  String get providerFieldsTitle => 'Configure a Provider';

  @override
  String get providerSetupSummary =>
      'The Providers page includes built-in entries for OpenAI, DeepSeek, and OpenRouter. For other services, select Add Custom Provider and use a preset for Kimi, MiMo, GLM, Gemini, or Qwen, or manually configure a service compatible with OpenAI Chat Completions.\n\nConfiguration fields:\n• Provider Name: Identifies the service in KeyChat and does not affect requests.\n• Base URL: Must use HTTPS. Selecting a preset and access option fills it automatically. For manual configuration, keep the API version path but do not append /chat/completions.\n• Default Model: Enter the model ID provided by the supplier, not its display name.\n• API Key: Get it from the supplier\'s console. When using a region-specific or plan-specific endpoint, the Base URL and API Key must belong to the same endpoint.\n\nAfter entering the fields, select Test Connection. Choose a model if a list is returned. If the supplier does not support the model-list endpoint, enter the model ID manually. Testing the connection does not save the configuration, so select Save when everything is correct.';

  @override
  String get providerNameGuideTitle => 'Provider Name';

  @override
  String get providerNameGuideContent =>
      'Used to distinguish different services. Built-in providers like OpenAI, DeepSeek, and OpenRouter have fixed names. Custom Provider can be named Xiaomi MiMo, company internal model, etc. The name does not affect actual API requests.';

  @override
  String get baseUrlGuideTitle => 'Base URL';

  @override
  String get baseUrlGuideContent =>
      'Must be the OpenAI-compatible base URL provided by the supplier, and must use HTTPS.\n\nDo not append /chat/completions manually, as KeyChat will add it automatically.\n\nCorrect example:\nhttps://api.example.com/v1\n\nWrong examples:\nhttp://api.example.com/v1\nhttps://api.example.com/v1/chat/completions';

  @override
  String get apiKeyGuideTitle => 'API Key';

  @override
  String get apiKeyGuideContent =>
      'Created from the corresponding supplier\'s console. Keys from different suppliers or plans cannot be mixed.\n\nThe key is stored only in the device\'s secure storage. Do not share the full key with others, and do not include it in screenshots, recordings, or bug reports.\n\nIt is recommended to use a test key with limited quota.';

  @override
  String get defaultModelGuideTitle => 'Default Model';

  @override
  String get defaultModelGuideContent =>
      'Fill in the model ID actually supported by the supplier. The display name and model ID may differ. Prefer copying the model ID from the supplier\'s console or official documentation.\n\nIf the connection test does not return a model list, you can manually enter the model ID. Requests will fail if the model does not exist or your account lacks permission.';

  @override
  String get deepSeekExampleTitle => 'DeepSeek Configuration Example';

  @override
  String get deepSeekApiKeyHint =>
      'Fill in the API Key created on DeepSeek Open Platform';

  @override
  String get modelNameMayChange =>
      'Model names may change with supplier updates. Please refer to the supplier\'s console and official documentation.';

  @override
  String get doNotAppendChatCompletions =>
      'Do not append /chat/completions to the base URL. KeyChat will automatically append the request path.';

  @override
  String get mimoExampleTitle => 'Xiaomi MiMo Configuration Example';

  @override
  String get mimoRequiresCustomProvider =>
      'The current version does not include a dedicated Xiaomi MiMo provider. Configure it through Custom Provider on the Providers page.';

  @override
  String get mimoPayAsYouGoTitle => 'Pay-as-you-go API';

  @override
  String get mimoApiKeyHint =>
      'Fill in the pay-as-you-go API Key created on Xiaomi MiMo Open Platform';

  @override
  String get mimoPayAsYouGoKeyWarning =>
      'Pay-as-you-go API Key and Token Plan API Key cannot be mixed.';

  @override
  String get mimoTokenPlanTitle => 'Token Plan';

  @override
  String get mimoTokenPlanUrlHint =>
      'Copy the OpenAI-compatible Base URL from Token Plan console';

  @override
  String get mimoTokenPlanApiKeyHint =>
      'Fill in the dedicated API Key provided by the Token Plan page';

  @override
  String get mimoTokenPlanWarning =>
      'The base URL and API Key for Token Plan are different from pay-as-you-go API. You must use the address and Key pair provided by the same plan page.';

  @override
  String get mimoTokenPlanRegionHint =>
      'Different regions may have different Token Plan base URLs. Prefer copying the actual address shown in the console.';

  @override
  String get mimoOpenAiCompatibleAddressHint =>
      'In KeyChat, select the OpenAI-compatible address. Do not use the Anthropic-compatible address.';

  @override
  String get mimoCustomProviderNote =>
      'Xiaomi MiMo currently works through Custom Provider. The name you fill in does not affect the request. What actually determines the connection method is the Base URL, API Key, and Model ID.';

  @override
  String get customProviderGuideTitle => 'Custom Provider';

  @override
  String get customProviderGuideContent =>
      'Custom Provider is suitable for:\n- Xiaomi MiMo\n- Other services compatible with OpenAI Chat Completions\n- User\'s own HTTPS API gateway\n\nConfiguration requirements:\n- HTTPS Base URL\n- Bearer API Key\n- Model ID\n- Compatible with OpenAI Chat Completions';

  @override
  String get customProviderCompatibilityWarning =>
      'Different suppliers may vary in model lists, authentication methods, streaming responses, and extended parameters. Being labeled as OpenAI-compatible does not mean all advanced features are fully compatible.';

  @override
  String get agentGuideTitle => 'Chat and Agents';

  @override
  String get chatAndAgentsContent =>
      'On the Chat page, you can switch between configured models. Models that support attachments can receive images or files.\n\nAgents store reusable system prompts and can be selected when starting a new conversation. Conversations are stored locally and can be exported as Markdown.';

  @override
  String get agentGuideContent =>
      'Agent is a set of system prompts that can be saved and reused.\n\nWhen creating an Agent, you can fill in:\n- Name\n- Brief description\n- System prompt';

  @override
  String get agentGuideExample =>
      'For example:\n\nName: French Learning Assistant\nSystem prompt: You are a patient French teacher. Please explain grammar in Chinese and provide French examples for each knowledge point.\n\nAfter creation, you can select this Agent when starting a new session. Selecting \"No Agent\" will not send additional system prompts.';

  @override
  String get agentGuideNote =>
      'Agent does not save API Keys and cannot automatically call external tools.';

  @override
  String get frequentlyAskedQuestionsTitle => 'Frequently Asked Questions';

  @override
  String get noAvailableModelsQuestion => 'Why are there no available models?';

  @override
  String get noAvailableModelsAnswer =>
      'Please check:\n- Is the Provider enabled?\n- Has the API Key been saved?\n- Is the default model filled in?\n- Is the Base URL HTTPS?\n- Is the model ID correct?\n- Is the protocol supported by KeyChat?';

  @override
  String get connectionTestFailedQuestion =>
      'Why did the connection test fail?';

  @override
  String get connectionTestFailedAnswer =>
      'Please check:\n- Is the network working?\n- Is the Base URL correct?\n- Does the API Key belong to the current supplier?\n- Has the Key expired?\n- Does the Key match the plan address?\n- Does the supplier support the model list endpoint?\n\nSome compatible services may not provide a model list endpoint. In this case, you can manually enter the model ID, save the configuration, and verify with an actual request.';

  @override
  String get invalidApiKeyQuestion => 'Why does it say the API Key is invalid?';

  @override
  String get invalidApiKeyAnswer =>
      'Possible reasons:\n- Key entered incorrectly\n- Key has expired\n- Using a Key from the wrong supplier\n- Mixing regular API Key with subscription plan Key\n- Base URL and Key type mismatch';

  @override
  String get modelAccessDeniedQuestion =>
      'Why does it say I don\'t have access to the model?';

  @override
  String get modelAccessDeniedAnswer =>
      'Possible reasons:\n- Model ID may be incorrect\n- Your account doesn\'t have permission for this model\n- Your plan doesn\'t include this model\n- The model has been deprecated or renamed';

  @override
  String get rateLimitQuestion =>
      'Why does it say the request rate is too high?';

  @override
  String get rateLimitAnswer =>
      'Your account has triggered the supplier\'s rate limit. Please wait and try again, and check your balance, plan, and concurrency limits.';

  @override
  String get httpsRequiredQuestion => 'Why must HTTPS be used?';

  @override
  String get httpsRequiredAnswer =>
      'API Keys and message content are sensitive data. HTTPS reduces the risk of data being intercepted or tampered with during transmission, so KeyChat does not allow plain HTTP addresses.';

  @override
  String get mimoConnectionFailedQuestion =>
      'Why can\'t I connect after configuring Xiaomi MiMo?';

  @override
  String get mimoConnectionFailedAnswer =>
      'Please check:\n- Did you select \"Custom Provider\"?\n- Is the Base URL an OpenAI-compatible address?\n- Did you incorrectly append /chat/completions?\n- Are you mixing pay-as-you-go Key with Token Plan Key?\n- Do the Base URL and API Key belong to the same plan?\n- Is the model ID correct?\n- Can your current network access the supplier\'s service?';

  @override
  String get mimoNoDedicatedProviderQuestion =>
      'Why is there no dedicated Xiaomi MiMo Provider in settings?';

  @override
  String get mimoNoDedicatedProviderAnswer =>
      'The current version does not include a built-in Xiaomi MiMo Provider. MiMo provides an OpenAI-compatible API, so it can be configured through \"Custom Provider\". Whether to add a dedicated entry in the future will depend on actual compatibility and testing results.';

  @override
  String get securityTipsTitle => 'Security Tips';

  @override
  String get securityTipsContent =>
      'API Keys are stored only in secure storage on your device. Do not include a full Key in screenshots or bug reports. You can remove a saved Key from the provider configuration when it is no longer needed.\n\nIf a connection fails, check the network, Base URL, API Key, model ID, and account access in that order.';

  @override
  String get supportsImageInput => 'Supports image input';

  @override
  String get supportsImageInputDescription =>
      'Choose how the default model handles image attachments.';

  @override
  String get supportsFileInput => 'Supports file input';

  @override
  String get supportsFileInputDescription =>
      'Choose how the default model handles ordinary file attachments.';

  @override
  String get attachmentCapabilityAutomatic => 'Automatic';

  @override
  String get attachmentCapabilitySupported => 'Supported';

  @override
  String get attachmentCapabilityUnsupported => 'Unsupported';

  @override
  String get attachmentCapabilityUnknown => 'Unknown';

  @override
  String get attachmentCapabilityEffectiveStatus => 'Effective status';

  @override
  String get attachmentCapabilityAutomaticDescription =>
      'Attachments are tried first. KeyChat learns from explicit provider rejection or a successful response.';

  @override
  String get attachmentCapabilityResetDetected => 'Reset detected capabilities';

  @override
  String get attachmentCapabilityResetDone =>
      'Detected attachment capabilities were reset.';

  @override
  String get attachmentCapabilityResetFailed =>
      'Unable to reset detected attachment capabilities.';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get attachmentTooLarge => 'The attachment must be 10 MiB or smaller.';

  @override
  String get attachmentUnavailable => 'The selected file is unavailable.';

  @override
  String get attachmentPickFailed => 'Unable to select the attachment.';

  @override
  String get attachmentSaveFailed => 'Unable to save the attachment locally.';

  @override
  String get attachmentLimitReached =>
      'You can attach up to 5 files per message.';

  @override
  String get unsupportedAttachmentTitle => 'Attachment may not be supported';

  @override
  String get unsupportedAttachmentMessage =>
      'The current model may not be able to read this attachment. Only the text will be sent, while the attachment remains in local chat history.';

  @override
  String get sendTextOnly => 'Send text only';

  @override
  String get attachmentRejectedTitle => 'Provider rejected the attachment';

  @override
  String get attachmentRejectedMessage =>
      'The provider explicitly rejected this attachment input. Retry the same message with text only? The attachment will remain in local chat history.';

  @override
  String get retryWithoutAttachments => 'Retry with text only';
}
