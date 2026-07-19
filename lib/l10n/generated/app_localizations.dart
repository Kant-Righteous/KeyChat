import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KeyChat'**
  String get appTitle;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @aboutKeyChat.
  ///
  /// In en, this message translates to:
  /// **'About KeyChat'**
  String get aboutKeyChat;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'KeyChat is a local-first BYOK AI chat client.\nUsers can configure their own AI API Key and chat directly with compatible large language models.\n\nCurrent version is a test version.'**
  String get aboutDescription;

  /// No description provided for @noAgent.
  ///
  /// In en, this message translates to:
  /// **'No Agent'**
  String get noAgent;

  /// No description provided for @selectAgent.
  ///
  /// In en, this message translates to:
  /// **'Select agent'**
  String get selectAgent;

  /// No description provided for @noModelAvailable.
  ///
  /// In en, this message translates to:
  /// **'No model available'**
  String get noModelAvailable;

  /// No description provided for @configureProviderFirst.
  ///
  /// In en, this message translates to:
  /// **'Please configure a provider and model first'**
  String get configureProviderFirst;

  /// No description provided for @providerModel.
  ///
  /// In en, this message translates to:
  /// **'{provider} · {model}'**
  String providerModel(String provider, String model);

  /// No description provided for @legacyModel.
  ///
  /// In en, this message translates to:
  /// **'Legacy model'**
  String get legacyModel;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @conversationOutline.
  ///
  /// In en, this message translates to:
  /// **'Conversation outline'**
  String get conversationOutline;

  /// No description provided for @noOutline.
  ///
  /// In en, this message translates to:
  /// **'No outline'**
  String get noOutline;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameConversation.
  ///
  /// In en, this message translates to:
  /// **'Rename Conversation'**
  String get renameConversation;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get titleRequired;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title is too long'**
  String get titleTooLong;

  /// No description provided for @renameConversationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename conversation'**
  String get renameConversationFailed;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation and all its messages?'**
  String get deleteConversationConfirm;

  /// No description provided for @deleteConversationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete conversation'**
  String get deleteConversationFailed;

  /// No description provided for @exportConversation.
  ///
  /// In en, this message translates to:
  /// **'Export conversation'**
  String get exportConversation;

  /// No description provided for @copyAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy as Markdown'**
  String get copyAsMarkdown;

  /// No description provided for @shareMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Share Markdown'**
  String get shareMarkdown;

  /// No description provided for @copiedAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copied as Markdown'**
  String get copiedAsMarkdown;

  /// No description provided for @conversationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Conversation is empty'**
  String get conversationEmpty;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stopGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get stopGenerating;

  /// No description provided for @waitingForResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response'**
  String get waitingForResponse;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinking;

  /// No description provided for @generatingResponse.
  ///
  /// In en, this message translates to:
  /// **'Generating response'**
  String get generatingResponse;

  /// No description provided for @thinkingProcess.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get thinkingProcess;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @regenerateResponse.
  ///
  /// In en, this message translates to:
  /// **'Regenerate response'**
  String get regenerateResponse;

  /// No description provided for @copyResponse.
  ///
  /// In en, this message translates to:
  /// **'Copy response'**
  String get copyResponse;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @noReadyProvider.
  ///
  /// In en, this message translates to:
  /// **'No ready provider'**
  String get noReadyProvider;

  /// No description provided for @configureProviderApiKey.
  ///
  /// In en, this message translates to:
  /// **'Configure a provider with API key and default model'**
  String get configureProviderApiKey;

  /// No description provided for @providerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Provider is no longer available'**
  String get providerNotAvailable;

  /// No description provided for @protocolNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Provider protocol is not supported yet'**
  String get protocolNotSupported;

  /// No description provided for @failedToSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save message'**
  String get failedToSaveMessage;

  /// No description provided for @failedToLoadConversation.
  ///
  /// In en, this message translates to:
  /// **'Failed to load conversation'**
  String get failedToLoadConversation;

  /// No description provided for @responseNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Response interrupted and was not saved'**
  String get responseNotSaved;

  /// No description provided for @invalidProviderResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid provider response'**
  String get invalidProviderResponse;

  /// No description provided for @unableToGetResponse.
  ///
  /// In en, this message translates to:
  /// **'Unable to get response'**
  String get unableToGetResponse;

  /// No description provided for @responseSavedButNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Response received but could not be saved'**
  String get responseSavedButNotSaved;

  /// No description provided for @contextTrimmed.
  ///
  /// In en, this message translates to:
  /// **'Earlier messages were omitted for this request'**
  String get contextTrimmed;

  /// No description provided for @currentMessageExceedsBudget.
  ///
  /// In en, this message translates to:
  /// **'Current message exceeds the local context estimate'**
  String get currentMessageExceedsBudget;

  /// No description provided for @systemPromptExceedsBudget.
  ///
  /// In en, this message translates to:
  /// **'System prompt and current message exceed the local context estimate'**
  String get systemPromptExceedsBudget;

  /// No description provided for @agentName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get agentName;

  /// No description provided for @agentDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get agentDescription;

  /// No description provided for @agentSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get agentSystemPrompt;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @createAgent.
  ///
  /// In en, this message translates to:
  /// **'Create Agent'**
  String get createAgent;

  /// No description provided for @editAgent.
  ///
  /// In en, this message translates to:
  /// **'Edit Agent'**
  String get editAgent;

  /// No description provided for @deleteAgent.
  ///
  /// In en, this message translates to:
  /// **'Delete Agent'**
  String get deleteAgent;

  /// No description provided for @deleteAgentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this agent?'**
  String get deleteAgentConfirm;

  /// No description provided for @deleteAgentDescription.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone, but historical conversations will be preserved.'**
  String get deleteAgentDescription;

  /// No description provided for @agentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get agentNameRequired;

  /// No description provided for @agentNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 50 characters'**
  String get agentNameTooLong;

  /// No description provided for @agentSystemPromptRequired.
  ///
  /// In en, this message translates to:
  /// **'System prompt cannot be empty'**
  String get agentSystemPromptRequired;

  /// No description provided for @agentSystemPromptTooLong.
  ///
  /// In en, this message translates to:
  /// **'System prompt cannot exceed 20000 characters'**
  String get agentSystemPromptTooLong;

  /// No description provided for @agentSaved.
  ///
  /// In en, this message translates to:
  /// **'Agent saved'**
  String get agentSaved;

  /// No description provided for @agentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Agent deleted'**
  String get agentDeleted;

  /// No description provided for @agentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get agentSaveFailed;

  /// No description provided for @agentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get agentDeleteFailed;

  /// No description provided for @noAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents yet'**
  String get noAgents;

  /// No description provided for @createAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new agent'**
  String get createAgentHint;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @apiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please configure API Key first'**
  String get apiKeyRequired;

  /// No description provided for @modelRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a model first'**
  String get modelRequired;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModel;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @noProvider.
  ///
  /// In en, this message translates to:
  /// **'No provider'**
  String get noProvider;

  /// No description provided for @systemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPrompt;

  /// No description provided for @agentDeletedFromSelector.
  ///
  /// In en, this message translates to:
  /// **'Agent deleted, reverted to No Agent'**
  String get agentDeletedFromSelector;

  /// No description provided for @failedToSaveLanguage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save language settings'**
  String get failedToSaveLanguage;

  /// No description provided for @invalidLocale.
  ///
  /// In en, this message translates to:
  /// **'Invalid locale'**
  String get invalidLocale;

  /// No description provided for @httpsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only HTTPS URLs are supported to protect your API key and messages'**
  String get httpsOnly;

  /// No description provided for @customProvider.
  ///
  /// In en, this message translates to:
  /// **'Custom Provider'**
  String get customProvider;

  /// No description provided for @customProviderDescription.
  ///
  /// In en, this message translates to:
  /// **'Any OpenAI-compatible provider'**
  String get customProviderDescription;

  /// No description provided for @addCustomProvider.
  ///
  /// In en, this message translates to:
  /// **'Custom Provider'**
  String get addCustomProvider;

  /// No description provided for @providerPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider preset'**
  String get providerPresetLabel;

  /// No description provided for @manualProviderPreset.
  ///
  /// In en, this message translates to:
  /// **'Other (manual)'**
  String get manualProviderPreset;

  /// No description provided for @accessOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Access option / region'**
  String get accessOptionLabel;

  /// No description provided for @providerEndpointKeyHint.
  ///
  /// In en, this message translates to:
  /// **'The API key must belong to the selected access option and region.'**
  String get providerEndpointKeyHint;

  /// No description provided for @apiKeyPrefixHint.
  ///
  /// In en, this message translates to:
  /// **'The API key for this option usually starts with {prefix}.'**
  String apiKeyPrefixHint(String prefix);

  /// No description provided for @planEndpointWarning.
  ///
  /// In en, this message translates to:
  /// **'The plan endpoint must be paired with its plan-specific API key and used within the provider\'s permitted scope.'**
  String get planEndpointWarning;

  /// No description provided for @visitOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit official website'**
  String get visitOfficialWebsite;

  /// No description provided for @unableToOpenOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the official website. Please try again.'**
  String get unableToOpenOfficialWebsite;

  /// No description provided for @chinaApiOption.
  ///
  /// In en, this message translates to:
  /// **'China API'**
  String get chinaApiOption;

  /// No description provided for @globalApiOption.
  ///
  /// In en, this message translates to:
  /// **'Global API'**
  String get globalApiOption;

  /// No description provided for @kimiCodeOption.
  ///
  /// In en, this message translates to:
  /// **'Kimi Code'**
  String get kimiCodeOption;

  /// No description provided for @payAsYouGoApiOption.
  ///
  /// In en, this message translates to:
  /// **'Pay-as-you-go API'**
  String get payAsYouGoApiOption;

  /// No description provided for @tokenPlanChinaOption.
  ///
  /// In en, this message translates to:
  /// **'Token Plan · China'**
  String get tokenPlanChinaOption;

  /// No description provided for @tokenPlanSingaporeOption.
  ///
  /// In en, this message translates to:
  /// **'Token Plan · Singapore'**
  String get tokenPlanSingaporeOption;

  /// No description provided for @tokenPlanEuropeOption.
  ///
  /// In en, this message translates to:
  /// **'Token Plan · Europe'**
  String get tokenPlanEuropeOption;

  /// No description provided for @chinaGeneralApiOption.
  ///
  /// In en, this message translates to:
  /// **'China general API'**
  String get chinaGeneralApiOption;

  /// No description provided for @globalGeneralApiOption.
  ///
  /// In en, this message translates to:
  /// **'Global general API'**
  String get globalGeneralApiOption;

  /// No description provided for @chinaCodingPlanOption.
  ///
  /// In en, this message translates to:
  /// **'China Coding Plan'**
  String get chinaCodingPlanOption;

  /// No description provided for @globalCodingPlanOption.
  ///
  /// In en, this message translates to:
  /// **'Global Coding Plan'**
  String get globalCodingPlanOption;

  /// No description provided for @payAsYouGoBeijingOption.
  ///
  /// In en, this message translates to:
  /// **'Pay-as-you-go · Beijing'**
  String get payAsYouGoBeijingOption;

  /// No description provided for @payAsYouGoSingaporeOption.
  ///
  /// In en, this message translates to:
  /// **'Pay-as-you-go · Singapore'**
  String get payAsYouGoSingaporeOption;

  /// No description provided for @payAsYouGoUsOption.
  ///
  /// In en, this message translates to:
  /// **'Pay-as-you-go · US'**
  String get payAsYouGoUsOption;

  /// No description provided for @tokenPlanBeijingOption.
  ///
  /// In en, this message translates to:
  /// **'Token Plan · Beijing'**
  String get tokenPlanBeijingOption;

  /// No description provided for @codingPlanBeijingOption.
  ///
  /// In en, this message translates to:
  /// **'Coding Plan · Beijing'**
  String get codingPlanBeijingOption;

  /// No description provided for @openAiDescription.
  ///
  /// In en, this message translates to:
  /// **'OpenAI compatible official API'**
  String get openAiDescription;

  /// No description provided for @deepSeekDescription.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek official API'**
  String get deepSeekDescription;

  /// No description provided for @openRouterDescription.
  ///
  /// In en, this message translates to:
  /// **'Access multiple AI providers through one API'**
  String get openRouterDescription;

  /// No description provided for @providerConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get providerConfigured;

  /// No description provided for @providerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get providerNotConfigured;

  /// No description provided for @httpsUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update to HTTPS required'**
  String get httpsUpdateRequired;

  /// No description provided for @configureProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure Provider'**
  String get configureProviderTitle;

  /// No description provided for @providerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider Name'**
  String get providerNameLabel;

  /// No description provided for @baseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrlLabel;

  /// No description provided for @baseUrlExampleLabel.
  ///
  /// In en, this message translates to:
  /// **'China Region Example'**
  String get baseUrlExampleLabel;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @defaultModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Model'**
  String get defaultModelLabel;

  /// No description provided for @apiKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'API key is already configured'**
  String get apiKeyConfigured;

  /// No description provided for @newApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'New API Key (leave blank to keep)'**
  String get newApiKeyLabel;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @testConnectionButton.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnectionButton;

  /// No description provided for @removeApiKeyButton.
  ///
  /// In en, this message translates to:
  /// **'Remove API Key'**
  String get removeApiKeyButton;

  /// No description provided for @removeApiKeyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the API key?'**
  String get removeApiKeyConfirmation;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @apiKeyRemoved.
  ///
  /// In en, this message translates to:
  /// **'API key removed'**
  String get apiKeyRemoved;

  /// No description provided for @providerConfiguredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Provider configured'**
  String get providerConfiguredSuccess;

  /// No description provided for @failedToSaveProvider.
  ///
  /// In en, this message translates to:
  /// **'Failed to save configuration'**
  String get failedToSaveProvider;

  /// No description provided for @failedToRemoveApiKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove API key'**
  String get failedToRemoveApiKey;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionSuccessful;

  /// No description provided for @modelsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} models found'**
  String modelsFound(int count);

  /// No description provided for @connectionTestUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Connection test is not supported for this protocol'**
  String get connectionTestUnsupported;

  /// No description provided for @invalidApiKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key'**
  String get invalidApiKey;

  /// No description provided for @accessForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden'**
  String get accessForbidden;

  /// No description provided for @rateLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded'**
  String get rateLimitExceeded;

  /// No description provided for @connectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out'**
  String get connectionTimedOut;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable'**
  String get networkUnavailable;

  /// No description provided for @providerServerError.
  ///
  /// In en, this message translates to:
  /// **'Provider server error'**
  String get providerServerError;

  /// No description provided for @invalidBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid Base URL'**
  String get invalidBaseUrl;

  /// No description provided for @unableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get unableToConnect;

  /// No description provided for @providerConfigInvalid.
  ///
  /// In en, this message translates to:
  /// **'Provider configuration is invalid'**
  String get providerConfigInvalid;

  /// No description provided for @configLoadError.
  ///
  /// In en, this message translates to:
  /// **'The saved configuration could not be loaded.'**
  String get configLoadError;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing…'**
  String get initializing;

  /// No description provided for @usageGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get usageGuide;

  /// No description provided for @usageGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get usageGuideTitle;

  /// No description provided for @configurationMethod.
  ///
  /// In en, this message translates to:
  /// **'Configuration Method'**
  String get configurationMethod;

  /// No description provided for @builtInProvider.
  ///
  /// In en, this message translates to:
  /// **'Built-in Provider'**
  String get builtInProvider;

  /// No description provided for @quickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStartTitle;

  /// No description provided for @quickStartContent.
  ///
  /// In en, this message translates to:
  /// **'1. Open Providers, then select a built-in provider or add a custom provider.\n2. Enter the API Key and model ID, test the connection, then save.\n3. Return to Chat, select the model, and start a conversation.'**
  String get quickStartContent;

  /// No description provided for @providerFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure a Provider'**
  String get providerFieldsTitle;

  /// No description provided for @providerSetupSummary.
  ///
  /// In en, this message translates to:
  /// **'The Providers page includes built-in entries for OpenAI, DeepSeek, and OpenRouter. For other services, select Add Custom Provider and use a preset for Kimi, MiMo, GLM, Gemini, or Qwen, or manually configure a service compatible with OpenAI Chat Completions.\n\nConfiguration fields:\n• Provider Name: Identifies the service in KeyChat and does not affect requests.\n• Base URL: Must use HTTPS. Selecting a preset and access option fills it automatically. For manual configuration, keep the API version path but do not append /chat/completions.\n• Default Model: Enter the model ID provided by the supplier, not its display name.\n• API Key: Get it from the supplier\'s console. When using a region-specific or plan-specific endpoint, the Base URL and API Key must belong to the same endpoint.\n\nAfter entering the fields, select Test Connection. Choose a model if a list is returned. If the supplier does not support the model-list endpoint, enter the model ID manually. Testing the connection does not save the configuration, so select Save when everything is correct.'**
  String get providerSetupSummary;

  /// No description provided for @providerNameGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Name'**
  String get providerNameGuideTitle;

  /// No description provided for @providerNameGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Used to distinguish different services. Built-in providers like OpenAI, DeepSeek, and OpenRouter have fixed names. Custom Provider can be named Xiaomi MiMo, company internal model, etc. The name does not affect actual API requests.'**
  String get providerNameGuideContent;

  /// No description provided for @baseUrlGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrlGuideTitle;

  /// No description provided for @baseUrlGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Must be the OpenAI-compatible base URL provided by the supplier, and must use HTTPS.\n\nDo not append /chat/completions manually, as KeyChat will add it automatically.\n\nCorrect example:\nhttps://api.example.com/v1\n\nWrong examples:\nhttp://api.example.com/v1\nhttps://api.example.com/v1/chat/completions'**
  String get baseUrlGuideContent;

  /// No description provided for @apiKeyGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyGuideTitle;

  /// No description provided for @apiKeyGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Created from the corresponding supplier\'s console. Keys from different suppliers or plans cannot be mixed.\n\nThe key is stored only in the device\'s secure storage. Do not share the full key with others, and do not include it in screenshots, recordings, or bug reports.\n\nIt is recommended to use a test key with limited quota.'**
  String get apiKeyGuideContent;

  /// No description provided for @defaultModelGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Default Model'**
  String get defaultModelGuideTitle;

  /// No description provided for @defaultModelGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Fill in the model ID actually supported by the supplier. The display name and model ID may differ. Prefer copying the model ID from the supplier\'s console or official documentation.\n\nIf the connection test does not return a model list, you can manually enter the model ID. Requests will fail if the model does not exist or your account lacks permission.'**
  String get defaultModelGuideContent;

  /// No description provided for @deepSeekExampleTitle.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek Configuration Example'**
  String get deepSeekExampleTitle;

  /// No description provided for @deepSeekApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in the API Key created on DeepSeek Open Platform'**
  String get deepSeekApiKeyHint;

  /// No description provided for @modelNameMayChange.
  ///
  /// In en, this message translates to:
  /// **'Model names may change with supplier updates. Please refer to the supplier\'s console and official documentation.'**
  String get modelNameMayChange;

  /// No description provided for @doNotAppendChatCompletions.
  ///
  /// In en, this message translates to:
  /// **'Do not append /chat/completions to the base URL. KeyChat will automatically append the request path.'**
  String get doNotAppendChatCompletions;

  /// No description provided for @mimoExampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi MiMo Configuration Example'**
  String get mimoExampleTitle;

  /// No description provided for @mimoRequiresCustomProvider.
  ///
  /// In en, this message translates to:
  /// **'The current version does not include a dedicated Xiaomi MiMo provider. Configure it through Custom Provider on the Providers page.'**
  String get mimoRequiresCustomProvider;

  /// No description provided for @mimoPayAsYouGoTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay-as-you-go API'**
  String get mimoPayAsYouGoTitle;

  /// No description provided for @mimoApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in the pay-as-you-go API Key created on Xiaomi MiMo Open Platform'**
  String get mimoApiKeyHint;

  /// No description provided for @mimoPayAsYouGoKeyWarning.
  ///
  /// In en, this message translates to:
  /// **'Pay-as-you-go API Key and Token Plan API Key cannot be mixed.'**
  String get mimoPayAsYouGoKeyWarning;

  /// No description provided for @mimoTokenPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Token Plan'**
  String get mimoTokenPlanTitle;

  /// No description provided for @mimoTokenPlanUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Copy the OpenAI-compatible Base URL from Token Plan console'**
  String get mimoTokenPlanUrlHint;

  /// No description provided for @mimoTokenPlanApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in the dedicated API Key provided by the Token Plan page'**
  String get mimoTokenPlanApiKeyHint;

  /// No description provided for @mimoTokenPlanWarning.
  ///
  /// In en, this message translates to:
  /// **'The base URL and API Key for Token Plan are different from pay-as-you-go API. You must use the address and Key pair provided by the same plan page.'**
  String get mimoTokenPlanWarning;

  /// No description provided for @mimoTokenPlanRegionHint.
  ///
  /// In en, this message translates to:
  /// **'Different regions may have different Token Plan base URLs. Prefer copying the actual address shown in the console.'**
  String get mimoTokenPlanRegionHint;

  /// No description provided for @mimoOpenAiCompatibleAddressHint.
  ///
  /// In en, this message translates to:
  /// **'In KeyChat, select the OpenAI-compatible address. Do not use the Anthropic-compatible address.'**
  String get mimoOpenAiCompatibleAddressHint;

  /// No description provided for @mimoCustomProviderNote.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi MiMo currently works through Custom Provider. The name you fill in does not affect the request. What actually determines the connection method is the Base URL, API Key, and Model ID.'**
  String get mimoCustomProviderNote;

  /// No description provided for @customProviderGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Provider'**
  String get customProviderGuideTitle;

  /// No description provided for @customProviderGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Custom Provider is suitable for:\n- Xiaomi MiMo\n- Other services compatible with OpenAI Chat Completions\n- User\'s own HTTPS API gateway\n\nConfiguration requirements:\n- HTTPS Base URL\n- Bearer API Key\n- Model ID\n- Compatible with OpenAI Chat Completions'**
  String get customProviderGuideContent;

  /// No description provided for @customProviderCompatibilityWarning.
  ///
  /// In en, this message translates to:
  /// **'Different suppliers may vary in model lists, authentication methods, streaming responses, and extended parameters. Being labeled as OpenAI-compatible does not mean all advanced features are fully compatible.'**
  String get customProviderCompatibilityWarning;

  /// No description provided for @agentGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat and Agents'**
  String get agentGuideTitle;

  /// No description provided for @chatAndAgentsContent.
  ///
  /// In en, this message translates to:
  /// **'On the Chat page, you can switch between configured models. Models that support attachments can receive images or files.\n\nAgents store reusable system prompts and can be selected when starting a new conversation. Conversations are stored locally and can be exported as Markdown.'**
  String get chatAndAgentsContent;

  /// No description provided for @agentGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Agent is a set of system prompts that can be saved and reused.\n\nWhen creating an Agent, you can fill in:\n- Name\n- Brief description\n- System prompt'**
  String get agentGuideContent;

  /// No description provided for @agentGuideExample.
  ///
  /// In en, this message translates to:
  /// **'For example:\n\nName: French Learning Assistant\nSystem prompt: You are a patient French teacher. Please explain grammar in Chinese and provide French examples for each knowledge point.\n\nAfter creation, you can select this Agent when starting a new session. Selecting \"No Agent\" will not send additional system prompts.'**
  String get agentGuideExample;

  /// No description provided for @agentGuideNote.
  ///
  /// In en, this message translates to:
  /// **'Agent does not save API Keys and cannot automatically call external tools.'**
  String get agentGuideNote;

  /// No description provided for @frequentlyAskedQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestionsTitle;

  /// No description provided for @noAvailableModelsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why are there no available models?'**
  String get noAvailableModelsQuestion;

  /// No description provided for @noAvailableModelsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please check:\n- Is the Provider enabled?\n- Has the API Key been saved?\n- Is the default model filled in?\n- Is the Base URL HTTPS?\n- Is the model ID correct?\n- Is the protocol supported by KeyChat?'**
  String get noAvailableModelsAnswer;

  /// No description provided for @connectionTestFailedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why did the connection test fail?'**
  String get connectionTestFailedQuestion;

  /// No description provided for @connectionTestFailedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please check:\n- Is the network working?\n- Is the Base URL correct?\n- Does the API Key belong to the current supplier?\n- Has the Key expired?\n- Does the Key match the plan address?\n- Does the supplier support the model list endpoint?\n\nSome compatible services may not provide a model list endpoint. In this case, you can manually enter the model ID, save the configuration, and verify with an actual request.'**
  String get connectionTestFailedAnswer;

  /// No description provided for @invalidApiKeyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does it say the API Key is invalid?'**
  String get invalidApiKeyQuestion;

  /// No description provided for @invalidApiKeyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Possible reasons:\n- Key entered incorrectly\n- Key has expired\n- Using a Key from the wrong supplier\n- Mixing regular API Key with subscription plan Key\n- Base URL and Key type mismatch'**
  String get invalidApiKeyAnswer;

  /// No description provided for @modelAccessDeniedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does it say I don\'t have access to the model?'**
  String get modelAccessDeniedQuestion;

  /// No description provided for @modelAccessDeniedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Possible reasons:\n- Model ID may be incorrect\n- Your account doesn\'t have permission for this model\n- Your plan doesn\'t include this model\n- The model has been deprecated or renamed'**
  String get modelAccessDeniedAnswer;

  /// No description provided for @rateLimitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does it say the request rate is too high?'**
  String get rateLimitQuestion;

  /// No description provided for @rateLimitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your account has triggered the supplier\'s rate limit. Please wait and try again, and check your balance, plan, and concurrency limits.'**
  String get rateLimitAnswer;

  /// No description provided for @httpsRequiredQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why must HTTPS be used?'**
  String get httpsRequiredQuestion;

  /// No description provided for @httpsRequiredAnswer.
  ///
  /// In en, this message translates to:
  /// **'API Keys and message content are sensitive data. HTTPS reduces the risk of data being intercepted or tampered with during transmission, so KeyChat does not allow plain HTTP addresses.'**
  String get httpsRequiredAnswer;

  /// No description provided for @mimoConnectionFailedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why can\'t I connect after configuring Xiaomi MiMo?'**
  String get mimoConnectionFailedQuestion;

  /// No description provided for @mimoConnectionFailedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please check:\n- Did you select \"Custom Provider\"?\n- Is the Base URL an OpenAI-compatible address?\n- Did you incorrectly append /chat/completions?\n- Are you mixing pay-as-you-go Key with Token Plan Key?\n- Do the Base URL and API Key belong to the same plan?\n- Is the model ID correct?\n- Can your current network access the supplier\'s service?'**
  String get mimoConnectionFailedAnswer;

  /// No description provided for @mimoNoDedicatedProviderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why is there no dedicated Xiaomi MiMo Provider in settings?'**
  String get mimoNoDedicatedProviderQuestion;

  /// No description provided for @mimoNoDedicatedProviderAnswer.
  ///
  /// In en, this message translates to:
  /// **'The current version does not include a built-in Xiaomi MiMo Provider. MiMo provides an OpenAI-compatible API, so it can be configured through \"Custom Provider\". Whether to add a dedicated entry in the future will depend on actual compatibility and testing results.'**
  String get mimoNoDedicatedProviderAnswer;

  /// No description provided for @securityTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Tips'**
  String get securityTipsTitle;

  /// No description provided for @securityTipsContent.
  ///
  /// In en, this message translates to:
  /// **'API Keys are stored only in secure storage on your device. Do not include a full Key in screenshots or bug reports. You can remove a saved Key from the provider configuration when it is no longer needed.\n\nIf a connection fails, check the network, Base URL, API Key, model ID, and account access in that order.'**
  String get securityTipsContent;

  /// No description provided for @supportsImageInput.
  ///
  /// In en, this message translates to:
  /// **'Supports image input'**
  String get supportsImageInput;

  /// No description provided for @supportsImageInputDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how the default model handles image attachments.'**
  String get supportsImageInputDescription;

  /// No description provided for @supportsFileInput.
  ///
  /// In en, this message translates to:
  /// **'Supports file input'**
  String get supportsFileInput;

  /// No description provided for @supportsFileInputDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how the default model handles ordinary file attachments.'**
  String get supportsFileInputDescription;

  /// No description provided for @attachmentCapabilityAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get attachmentCapabilityAutomatic;

  /// No description provided for @attachmentCapabilitySupported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get attachmentCapabilitySupported;

  /// No description provided for @attachmentCapabilityUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get attachmentCapabilityUnsupported;

  /// No description provided for @attachmentCapabilityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get attachmentCapabilityUnknown;

  /// No description provided for @attachmentCapabilityEffectiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Effective status'**
  String get attachmentCapabilityEffectiveStatus;

  /// No description provided for @attachmentCapabilityAutomaticDescription.
  ///
  /// In en, this message translates to:
  /// **'Attachments are tried first. KeyChat learns from explicit provider rejection or a successful response.'**
  String get attachmentCapabilityAutomaticDescription;

  /// No description provided for @attachmentCapabilityResetDetected.
  ///
  /// In en, this message translates to:
  /// **'Reset detected capabilities'**
  String get attachmentCapabilityResetDetected;

  /// No description provided for @attachmentCapabilityResetDone.
  ///
  /// In en, this message translates to:
  /// **'Detected attachment capabilities were reset.'**
  String get attachmentCapabilityResetDone;

  /// No description provided for @attachmentCapabilityResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset detected attachment capabilities.'**
  String get attachmentCapabilityResetFailed;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The attachment must be 10 MiB or smaller.'**
  String get attachmentTooLarge;

  /// No description provided for @attachmentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected file is unavailable.'**
  String get attachmentUnavailable;

  /// No description provided for @attachmentPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to select the attachment.'**
  String get attachmentPickFailed;

  /// No description provided for @attachmentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the attachment locally.'**
  String get attachmentSaveFailed;

  /// No description provided for @attachmentLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to 5 files per message.'**
  String get attachmentLimitReached;

  /// No description provided for @unsupportedAttachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment may not be supported'**
  String get unsupportedAttachmentTitle;

  /// No description provided for @unsupportedAttachmentMessage.
  ///
  /// In en, this message translates to:
  /// **'The current model may not be able to read this attachment. Only the text will be sent, while the attachment remains in local chat history.'**
  String get unsupportedAttachmentMessage;

  /// No description provided for @sendTextOnly.
  ///
  /// In en, this message translates to:
  /// **'Send text only'**
  String get sendTextOnly;

  /// No description provided for @attachmentRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider rejected the attachment'**
  String get attachmentRejectedTitle;

  /// No description provided for @attachmentRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'The provider explicitly rejected this attachment input. Retry the same message with text only? The attachment will remain in local chat history.'**
  String get attachmentRejectedMessage;

  /// No description provided for @retryWithoutAttachments.
  ///
  /// In en, this message translates to:
  /// **'Retry with text only'**
  String get retryWithoutAttachments;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
