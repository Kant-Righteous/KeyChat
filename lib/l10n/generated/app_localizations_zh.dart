// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'KeyChat';

  @override
  String get chat => '聊天';

  @override
  String get providers => '提供商';

  @override
  String get agents => '智能体';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get aboutKeyChat => '关于 KeyChat';

  @override
  String get aboutDescription =>
      'KeyChat 是一个本地优先的 BYOK AI 对话客户端。\n用户可以配置自己的 AI API Key，并直接与兼容的大语言模型对话。\n\n当前版本为测试版本。';

  @override
  String get noAgent => '无 Agent';

  @override
  String get selectAgent => '选择智能体';

  @override
  String get noModelAvailable => '没有可用模型';

  @override
  String get configureProviderFirst => '请先配置提供商和模型';

  @override
  String providerModel(String provider, String model) {
    return '$provider · $model';
  }

  @override
  String get legacyModel => '历史模型';

  @override
  String get newChat => '新对话';

  @override
  String get history => '历史';

  @override
  String get conversationOutline => '对话目录';

  @override
  String get noOutline => '暂无目录';

  @override
  String get conversations => '历史对话';

  @override
  String get noConversations => '暂无历史对话';

  @override
  String get rename => '重命名';

  @override
  String get renameConversation => '重命名对话';

  @override
  String get enterTitle => '输入标题';

  @override
  String get titleRequired => '标题不能为空';

  @override
  String get titleTooLong => '标题过长';

  @override
  String get renameConversationFailed => '重命名对话失败';

  @override
  String get deleteConversation => '删除对话';

  @override
  String get deleteConversationConfirm => '删除此对话及其全部消息？';

  @override
  String get deleteConversationFailed => '删除对话失败';

  @override
  String get exportConversation => '导出对话';

  @override
  String get copyAsMarkdown => '复制为 Markdown';

  @override
  String get shareMarkdown => '分享 Markdown';

  @override
  String get copiedAsMarkdown => '已复制为 Markdown';

  @override
  String get conversationEmpty => '当前会话为空';

  @override
  String get exportFailed => '导出失败';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get send => '发送';

  @override
  String get stopGenerating => '停止生成';

  @override
  String get waitingForResponse => '正在等待响应';

  @override
  String get thinking => '正在思考';

  @override
  String get generatingResponse => '正在生成回答';

  @override
  String get thinkingProcess => '思考过程';

  @override
  String get retry => '重试';

  @override
  String get regenerateResponse => '重新生成';

  @override
  String get copyResponse => '复制回复';

  @override
  String get copied => '已复制';

  @override
  String get stopped => '已停止';

  @override
  String get startConversation => '开始对话';

  @override
  String get noReadyProvider => '没有可用的提供商';

  @override
  String get configureProviderApiKey => '请配置提供商、API Key 和默认模型';

  @override
  String get providerNotAvailable => '提供商不可用';

  @override
  String get protocolNotSupported => '提供商协议暂不支持';

  @override
  String get failedToSaveMessage => '消息保存失败';

  @override
  String get failedToLoadConversation => '加载对话失败';

  @override
  String get responseNotSaved => '响应已中断，未保存';

  @override
  String get invalidProviderResponse => '提供商响应无效';

  @override
  String get unableToGetResponse => '无法获取响应';

  @override
  String get responseSavedButNotSaved => '响应已收到但保存失败';

  @override
  String get contextTrimmed => '早期消息已为此请求省略';

  @override
  String get currentMessageExceedsBudget => '当前消息超过本地上下文估算';

  @override
  String get systemPromptExceedsBudget => '系统提示词和当前消息超过本地上下文估算';

  @override
  String get agentName => '名称';

  @override
  String get agentDescription => '描述（可选）';

  @override
  String get agentSystemPrompt => '系统提示词';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get createAgent => '创建智能体';

  @override
  String get editAgent => '编辑智能体';

  @override
  String get deleteAgent => '删除智能体';

  @override
  String get deleteAgentConfirm => '确定要删除这个智能体吗？';

  @override
  String get deleteAgentDescription => '删除后无法恢复，但历史对话仍会保留。';

  @override
  String get agentNameRequired => '名称不能为空';

  @override
  String get agentNameTooLong => '名称不能超过 50 个字符';

  @override
  String get agentSystemPromptRequired => '系统提示词不能为空';

  @override
  String get agentSystemPromptTooLong => '系统提示词不能超过 20000 个字符';

  @override
  String get agentSaved => '智能体已保存';

  @override
  String get agentDeleted => '智能体已删除';

  @override
  String get agentSaveFailed => '保存失败';

  @override
  String get agentDeleteFailed => '删除失败';

  @override
  String get noAgents => '还没有智能体';

  @override
  String get createAgentHint => '点击 + 创建一个新智能体';

  @override
  String get languageSettings => '语言设置';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get appearance => '外观';

  @override
  String get privacy => '隐私';

  @override
  String get apiKeyRequired => '请先配置 API Key';

  @override
  String get modelRequired => '请先选择模型';

  @override
  String get agent => '智能体';

  @override
  String get model => '模型';

  @override
  String get selectModel => '选择模型';

  @override
  String get provider => '提供商';

  @override
  String get noProvider => '无提供商';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get agentDeletedFromSelector => '智能体已删除，已回退到无 Agent';

  @override
  String get failedToSaveLanguage => '语言设置保存失败';

  @override
  String get invalidLocale => '无效的语言设置';

  @override
  String get httpsOnly => '仅支持 HTTPS 地址，以保护您的 API Key 和消息内容';

  @override
  String get customProvider => '自定义提供商';

  @override
  String get customProviderDescription => '配置任意兼容 OpenAI 协议的服务';

  @override
  String get addCustomProvider => '自定义提供商';

  @override
  String get providerPresetLabel => '提供商预设';

  @override
  String get manualProviderPreset => '其他（手动填写）';

  @override
  String get accessOptionLabel => '接入方案 / 地域';

  @override
  String get providerEndpointKeyHint => 'API Key 必须来自所选接入方案和地域。';

  @override
  String apiKeyPrefixHint(String prefix) {
    return '该方案的 API Key 通常以 $prefix 开头。';
  }

  @override
  String get planEndpointWarning => '套餐地址必须与套餐专用 API Key 配套使用，并遵守提供商的适用范围。';

  @override
  String get visitOfficialWebsite => '前往官网';

  @override
  String get unableToOpenOfficialWebsite => '无法打开官网，请稍后重试';

  @override
  String get chinaApiOption => '中国普通 API';

  @override
  String get globalApiOption => '国际普通 API';

  @override
  String get kimiCodeOption => 'Kimi Code';

  @override
  String get payAsYouGoApiOption => '普通按量 API';

  @override
  String get tokenPlanChinaOption => 'Token Plan · 中国';

  @override
  String get tokenPlanSingaporeOption => 'Token Plan · 新加坡';

  @override
  String get tokenPlanEuropeOption => 'Token Plan · 欧洲';

  @override
  String get chinaGeneralApiOption => '中国普通 API';

  @override
  String get globalGeneralApiOption => '国际普通 API';

  @override
  String get chinaCodingPlanOption => '中国 Coding Plan';

  @override
  String get globalCodingPlanOption => '国际 Coding Plan';

  @override
  String get payAsYouGoBeijingOption => '按量付费 · 北京';

  @override
  String get payAsYouGoSingaporeOption => '按量付费 · 新加坡';

  @override
  String get payAsYouGoUsOption => '按量付费 · 美国';

  @override
  String get tokenPlanBeijingOption => 'Token Plan · 北京';

  @override
  String get codingPlanBeijingOption => 'Coding Plan · 北京';

  @override
  String get openAiDescription => 'OpenAI 兼容的官方 API';

  @override
  String get deepSeekDescription => 'DeepSeek 官方 API';

  @override
  String get openRouterDescription => '通过统一接口访问多个模型';

  @override
  String get providerConfigured => '已配置';

  @override
  String get providerNotConfigured => '未配置';

  @override
  String get httpsUpdateRequired => '需要更新为 HTTPS';

  @override
  String get configureProviderTitle => '配置提供商';

  @override
  String get providerNameLabel => '提供商名称';

  @override
  String get baseUrlLabel => '基础地址';

  @override
  String get baseUrlExampleLabel => '中国区示例';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get defaultModelLabel => '默认模型';

  @override
  String get apiKeyConfigured => '已配置 API Key';

  @override
  String get newApiKeyLabel => '新 API Key（留空保留原有）';

  @override
  String get saveButton => '保存';

  @override
  String get testConnectionButton => '测试连接';

  @override
  String get removeApiKeyButton => '删除 API Key';

  @override
  String get removeApiKeyConfirmation => '确定要删除 API Key 吗？';

  @override
  String get remove => '删除';

  @override
  String get apiKeyRemoved => 'API Key 已删除';

  @override
  String get providerConfiguredSuccess => '提供商已配置';

  @override
  String get failedToSaveProvider => '配置保存失败';

  @override
  String get failedToRemoveApiKey => '删除 API Key 失败';

  @override
  String get connectionSuccessful => '连接成功';

  @override
  String modelsFound(int count) {
    return '找到 $count 个模型';
  }

  @override
  String get connectionTestUnsupported => '此协议暂不支持连接测试';

  @override
  String get invalidApiKey => 'API Key 无效';

  @override
  String get accessForbidden => '访问被拒绝';

  @override
  String get rateLimitExceeded => '请求频率超限';

  @override
  String get connectionTimedOut => '连接超时';

  @override
  String get networkUnavailable => '网络不可用';

  @override
  String get providerServerError => '提供商服务器错误';

  @override
  String get invalidBaseUrl => '无效的基础地址';

  @override
  String get unableToConnect => '无法连接';

  @override
  String get providerConfigInvalid => '提供商配置无效';

  @override
  String get configLoadError => '无法加载配置';

  @override
  String get goBack => '返回';

  @override
  String get loading => '加载中...';

  @override
  String get initializing => '正在初始化…';

  @override
  String get usageGuide => '使用说明';

  @override
  String get usageGuideTitle => '使用说明';

  @override
  String get configurationMethod => '配置方式';

  @override
  String get builtInProvider => '内置 Provider';

  @override
  String get quickStartTitle => '快速开始';

  @override
  String get quickStartContent =>
      '1. 打开「提供商」，选择内置提供商或添加自定义提供商。\n2. 填写 API Key 和模型 ID，测试连接后保存。\n3. 返回「聊天」，选择模型后开始对话。';

  @override
  String get providerFieldsTitle => '配置提供商';

  @override
  String get providerSetupSummary =>
      '「提供商」页面提供 OpenAI、DeepSeek 和 OpenRouter 内置入口。其他服务可选择「添加自定义提供商」，使用 Kimi、MiMo、GLM、Gemini、Qwen 等预设，或手动配置兼容 OpenAI Chat Completions 的服务。\n\n配置字段：\n• 提供商名称：用于在 KeyChat 中区分服务，不影响实际请求。\n• Base URL：必须使用 HTTPS。选择预设和访问方式后会自动填写；手动填写时只需保留 API 版本路径，不要添加 /chat/completions。\n• 默认模型：填写供应商实际提供的模型 ID，而不是展示名称。\n• API Key：从对应供应商控制台获取。使用地区或套餐专用入口时，Base URL 和 API Key 必须属于同一入口。\n\n填写后点击「测试连接」。如果返回模型列表，可直接选择；如果供应商不支持模型列表接口，可手动填写模型 ID。测试连接不会自动保存配置，确认无误后还需点击「保存」。';

  @override
  String get providerNameGuideTitle => 'Provider 名称';

  @override
  String get providerNameGuideContent =>
      '用于区分不同服务。OpenAI、DeepSeek、OpenRouter 等内置提供商已有固定名称。自定义 Provider 可以填写 Xiaomi MiMo、公司内部模型等名称。名称不会影响实际 API 请求。';

  @override
  String get baseUrlGuideTitle => 'Base URL / 基础地址';

  @override
  String get baseUrlGuideContent =>
      '必须填写供应商提供的 OpenAI-compatible 基础地址，必须使用 HTTPS。\n\n不要填写完整的 /chat/completions 地址，KeyChat 会自动拼接。\n\n正确示例：\nhttps://api.example.com/v1\n\n错误示例：\nhttp://api.example.com/v1\nhttps://api.example.com/v1/chat/completions';

  @override
  String get apiKeyGuideTitle => 'API Key';

  @override
  String get apiKeyGuideContent =>
      '从对应供应商的控制台创建。不同供应商或不同套餐的 Key 不能混用。\n\nKey 只保存在设备安全存储中。不要把完整 Key 发给其他人，不要把完整 Key 放入截图、录屏或问题反馈。\n\n推荐使用有额度限制的测试 Key。';

  @override
  String get defaultModelGuideTitle => '默认模型';

  @override
  String get defaultModelGuideContent =>
      '填写供应商实际支持的模型 ID。模型显示名称和模型 ID 可能不同，应优先复制供应商控制台或官方文档中的模型 ID。\n\n如果连接测试没有返回模型列表，可以手动输入模型 ID。模型不存在或当前账号无权限时，请求会失败。';

  @override
  String get deepSeekExampleTitle => 'DeepSeek 配置示例';

  @override
  String get deepSeekApiKeyHint => '填写 DeepSeek 开放平台创建的 API Key';

  @override
  String get modelNameMayChange => '模型名称可能随供应商更新，请以供应商控制台和官方文档为准。';

  @override
  String get doNotAppendChatCompletions =>
      '不要在基础地址后添加 /chat/completions，KeyChat 会自动拼接请求路径。';

  @override
  String get mimoExampleTitle => 'Xiaomi MiMo 配置示例';

  @override
  String get mimoRequiresCustomProvider =>
      '当前版本没有单独的 Xiaomi MiMo Provider。请在「提供商」页面选择「自定义 Provider」进行配置。';

  @override
  String get mimoPayAsYouGoTitle => '按量付费 API';

  @override
  String get mimoApiKeyHint => '填写 Xiaomi MiMo 开放平台创建的按量 API Key';

  @override
  String get mimoPayAsYouGoKeyWarning =>
      '按量 API Key 与 Token Plan API Key 不可混用。';

  @override
  String get mimoTokenPlanTitle => 'Token Plan';

  @override
  String get mimoTokenPlanUrlHint =>
      '复制 Token Plan 控制台显示的 OpenAI-compatible Base URL';

  @override
  String get mimoTokenPlanApiKeyHint => '填写 Token Plan 页面提供的专属 API Key';

  @override
  String get mimoTokenPlanWarning =>
      'Token Plan 的基础地址和 API Key 与按量 API 不同，必须使用同一套餐页面提供的一组地址和 Key。';

  @override
  String get mimoTokenPlanRegionHint =>
      '不同地区的 Token Plan 基础地址可能不同，应优先复制控制台实际显示的地址。';

  @override
  String get mimoOpenAiCompatibleAddressHint =>
      '在 KeyChat 中应选择 OpenAI-compatible 地址，不要使用 Anthropic-compatible 地址。';

  @override
  String get mimoCustomProviderNote =>
      'Xiaomi MiMo 当前通过自定义 Provider 使用。填写名称不会影响请求，真正决定连接方式的是基础地址、API Key 和模型 ID。';

  @override
  String get customProviderGuideTitle => '自定义 Provider';

  @override
  String get customProviderGuideContent =>
      '自定义 Provider 适用于：\n- Xiaomi MiMo\n- 其他兼容 OpenAI Chat Completions 的服务\n- 用户自己的 HTTPS API 网关\n\n配置要求：\n- HTTPS Base URL\n- Bearer API Key\n- 模型 ID\n- 兼容 OpenAI Chat Completions';

  @override
  String get customProviderCompatibilityWarning =>
      '不同供应商可能在模型列表、认证方式、流式响应和扩展参数上存在差异。标称兼容 OpenAI 协议并不代表所有高级功能都完全兼容。';

  @override
  String get agentGuideTitle => '聊天与智能体';

  @override
  String get chatAndAgentsContent =>
      '聊天页可切换已配置的模型。支持的模型可接收图片或文件附件。\n\n「智能体」用于保存可重复使用的系统提示词，可在开始新对话时选择。对话记录保存在本机，并可导出为 Markdown。';

  @override
  String get agentGuideContent =>
      'Agent 是一组可以保存和重复使用的系统提示词。\n\n创建 Agent 时，可以填写：\n- 名称\n- 简短描述\n- 系统提示词';

  @override
  String get agentGuideExample =>
      '例如：\n\n名称：法语学习助手\n系统提示词：你是一名耐心的法语老师。请使用中文解释语法，并为每个知识点提供法语例句。\n\n创建后，可以在开始新会话时选择这个 Agent。选择「无 Agent」时，不会发送额外的系统提示词。';

  @override
  String get agentGuideNote => 'Agent 不保存 API Key，也不会自动调用外部工具。';

  @override
  String get frequentlyAskedQuestionsTitle => '常见问题';

  @override
  String get noAvailableModelsQuestion => '为什么没有可用模型？';

  @override
  String get noAvailableModelsAnswer =>
      '请检查：\n- Provider 是否启用\n- API Key 是否已经保存\n- 默认模型是否填写\n- Base URL 是否为 HTTPS\n- 模型 ID 是否正确\n- 当前协议是否受 KeyChat 支持';

  @override
  String get connectionTestFailedQuestion => '为什么测试连接失败？';

  @override
  String get connectionTestFailedAnswer =>
      '请检查：\n- 网络是否正常\n- Base URL 是否正确\n- API Key 是否属于当前供应商\n- Key 是否已过期\n- Key 与套餐地址是否匹配\n- 供应商是否支持模型列表接口\n\n部分兼容服务可能不提供模型列表接口。此时可以手动填写模型 ID，再保存配置并进行实际验证。';

  @override
  String get invalidApiKeyQuestion => '为什么提示 API Key 无效？';

  @override
  String get invalidApiKeyAnswer =>
      '可能原因：\n- Key 输入错误\n- Key 已失效\n- 使用了错误供应商的 Key\n- 普通 API Key 与订阅套餐 Key 混用\n- Base URL 与 Key 类型不匹配';

  @override
  String get modelAccessDeniedQuestion => '为什么提示无权访问模型？';

  @override
  String get modelAccessDeniedAnswer =>
      '可能原因：\n- 模型 ID 可能不正确\n- 当前账号没有该模型权限\n- 套餐不包含该模型\n- 模型已经下线或更名';

  @override
  String get rateLimitQuestion => '为什么提示请求频率过高？';

  @override
  String get rateLimitAnswer => '当前账号触发供应商速率限制。请等待后再试，并检查余额、套餐和并发限制。';

  @override
  String get httpsRequiredQuestion => '为什么必须使用 HTTPS？';

  @override
  String get httpsRequiredAnswer =>
      'API Key 和消息内容属于敏感数据。HTTPS 可以降低数据在传输过程中被窃取或篡改的风险，因此 KeyChat 不允许使用普通 HTTP 地址。';

  @override
  String get mimoConnectionFailedQuestion => '为什么 Xiaomi MiMo 配置后无法连接？';

  @override
  String get mimoConnectionFailedAnswer =>
      '请检查：\n- 是否选择了「自定义 Provider」\n- Base URL 是否为 OpenAI-compatible 地址\n- 是否错误添加了 /chat/completions\n- 按量 API Key 与 Token Plan Key 是否混用\n- Base URL 与 API Key 是否来自同一个套餐\n- 模型 ID 是否正确\n- 当前网络是否可访问供应商服务';

  @override
  String get mimoNoDedicatedProviderQuestion =>
      '为什么设置中没有 Xiaomi MiMo 专用 Provider？';

  @override
  String get mimoNoDedicatedProviderAnswer =>
      '当前版本暂未内置 Xiaomi MiMo Provider。MiMo 提供 OpenAI-compatible API，因此可以通过「自定义 Provider」配置使用。后续是否增加专用入口，将根据实际兼容性和测试结果决定。';

  @override
  String get securityTipsTitle => '安全提示';

  @override
  String get securityTipsContent =>
      'API Key 仅保存在设备安全存储中，请勿将完整 Key 放入截图或问题反馈。不再使用时，可在提供商配置中删除。\n\n连接失败时，请依次检查网络、Base URL、API Key、模型 ID 和账号权限。';

  @override
  String get supportsImageInput => '支持图片输入';

  @override
  String get supportsImageInputDescription => '选择默认模型处理图片附件的方式。';

  @override
  String get supportsFileInput => '支持文件输入';

  @override
  String get supportsFileInputDescription => '选择默认模型处理普通文件附件的方式。';

  @override
  String get attachmentCapabilityAutomatic => '自动检测';

  @override
  String get attachmentCapabilitySupported => '支持';

  @override
  String get attachmentCapabilityUnsupported => '不支持';

  @override
  String get attachmentCapabilityUnknown => '未知';

  @override
  String get attachmentCapabilityEffectiveStatus => '当前生效状态';

  @override
  String get attachmentCapabilityAutomaticDescription =>
      '优先尝试发送附件；供应商明确拒绝或请求成功后，KeyChat 会记住结果。';

  @override
  String get attachmentCapabilityResetDetected => '重置检测结果';

  @override
  String get attachmentCapabilityResetDone => '已重置附件能力检测结果。';

  @override
  String get attachmentCapabilityResetFailed => '无法重置附件能力检测结果。';

  @override
  String get addAttachment => '添加附件';

  @override
  String get chooseImage => '选择图片';

  @override
  String get chooseFile => '选择文件';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get attachmentTooLarge => '附件大小不能超过 10 MiB。';

  @override
  String get attachmentUnavailable => '无法访问所选文件。';

  @override
  String get attachmentPickFailed => '无法选择附件。';

  @override
  String get attachmentSaveFailed => '无法将附件保存到本地。';

  @override
  String get attachmentLimitReached => '每条消息最多添加 5 个附件。';

  @override
  String get unsupportedAttachmentTitle => '附件可能不受支持';

  @override
  String get unsupportedAttachmentMessage =>
      '当前模型可能无法读取此附件，将仅发送文字；附件仍会保留在本地聊天记录中。';

  @override
  String get sendTextOnly => '仅发送文字';

  @override
  String get attachmentRejectedTitle => '供应商拒绝了附件';

  @override
  String get attachmentRejectedMessage =>
      '供应商已明确拒绝此附件输入。是否使用同一条消息仅重试文字？附件仍会保留在本地聊天记录中。';

  @override
  String get retryWithoutAttachments => '仅用文字重试';
}
