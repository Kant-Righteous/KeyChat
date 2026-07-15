import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/chat/application/generation_keep_alive.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/chat_context_builder.dart';
import 'package:keychat/features/chat/domain/conversation_list_result.dart';
import 'package:keychat/features/chat/presentation/conversation_list_page.dart';
import 'package:keychat/features/chat/presentation/widgets/assistant_message_content.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';
import 'package:keychat/features/providers/domain/provider_url_policy.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _ReadyProvider {
  final String providerId;
  final String providerDisplayName;
  final String baseUrl;
  final String defaultModelId;
  final String apiKey;
  final ProviderProtocol protocol;
  final ChatCompletionClient client;

  const _ReadyProvider({
    required this.providerId,
    required this.providerDisplayName,
    required this.baseUrl,
    required this.defaultModelId,
    required this.apiKey,
    required this.protocol,
    required this.client,
  });
}

enum _GenerationEndReason {
  completed,
  failed,
  userStopped,
  disposed,
}

enum _GenerationKind {
  normal,
  retry,
  regenerate,
}

enum _GenerationPhase {
  idle,
  waiting,
  reasoning,
  responding,
}

final class _GenerationTarget {
  const _GenerationTarget({
    required this.kind,
    required this.userMessage,
    this.replacedAssistantMessage,
  });

  final ChatMessage userMessage;
  final ChatMessage? replacedAssistantMessage;
  final _GenerationKind kind;
}

class ChatPage extends StatefulWidget {
  final ChatClientResolver chatClientResolver;
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ChatHistoryStore historyStore;
  final AgentProfileStore agentStore;
  final ConnectionTesterResolver? connectionTesterResolver;
  final ChatContextBuilder contextBuilder;
  final GenerationKeepAlive generationKeepAlive;

  ChatPage({
    super.key,
    required this.chatClientResolver,
    required this.apiKeyStore,
    required this.configStore,
    required this.historyStore,
    required this.agentStore,
    this.connectionTesterResolver,
    ChatContextBuilder? contextBuilder,
    GenerationKeepAlive? generationKeepAlive,
  })  : contextBuilder = contextBuilder ?? ChatContextBuilder(),
        generationKeepAlive =
            generationKeepAlive ?? const NoopGenerationKeepAlive();

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _streamingReasoningKey = 'streaming-reasoning';

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  final List<_ReadyProvider> _readyProviders = [];
  _ReadyProvider? _selectedProvider;
  final List<String> _availableModels = [];
  String? _selectedModelId;
  bool _loadingModels = false;
  int _modelLoadCounter = 0;
  final List<AgentProfileData> _agents = [];
  AgentProfileData? _selectedAgent;
  bool _loading = true;
  bool _sending = false;
  bool _userStopped = false;
  int _generationCounter = 0;
  int? _activeGenerationId;
  bool _terminalHandled = false;
  ChatCancellationToken? _cancellationToken;
  int _idCounter = 0;
  String? _activeConversationId;
  String? _persistWarning;
  String? _protocolWarning;
  String _streamingAssistantText = '';
  String _streamingReasoningText = '';
  final Set<String> _expandedReasoningKeys = {};
  _GenerationPhase _generationPhase = _GenerationPhase.idle;
  StreamSubscription<ChatStreamEvent>? _streamSubscription;
  String? _trimWarning;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<ProviderConfigData> configs;
    try {
      configs = await widget.configStore.readAllConfigs();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _persistWarning = 'Provider configuration is invalid';
        });
      }
      return;
    }

    final readyProviders = <_ReadyProvider>[];
    for (final config in configs) {
      if (!config.enabled) continue;
      if (config.baseUrl.trim().isEmpty) continue;
      // Only allow HTTPS
      if (!ProviderUrlPolicy.isAllowedForRequest(config.baseUrl)) continue;
      if (config.defaultModel == null || config.defaultModel!.trim().isEmpty) {
        continue;
      }
      final hasKey = await widget.apiKeyStore.hasKey(config.providerId);
      if (!hasKey) continue;
      final apiKey = await widget.apiKeyStore.readKey(config.providerId);
      if (apiKey == null || apiKey.trim().isEmpty) continue;

      final client = widget.chatClientResolver.resolve(config.protocol);
      if (client == null) continue;

      readyProviders.add(_ReadyProvider(
        providerId: config.providerId,
        providerDisplayName: config.displayName,
        baseUrl: config.baseUrl,
        defaultModelId: config.defaultModel!,
        apiKey: apiKey,
        protocol: config.protocol,
        client: client,
      ));
    }

    final agents = await widget.agentStore.readAgents();

    final conversation = await widget.historyStore.readLatestConversation();
    List<ChatMessage> historyMessages = [];
    String? restoredProviderId;
    String? restoredModelId;

    if (conversation != null) {
      historyMessages = await widget.historyStore.readMessages(conversation.id);
      restoredProviderId = conversation.providerId;
      restoredModelId = conversation.model;
    }

    _ReadyProvider? selectedProvider;
    if (restoredProviderId != null) {
      try {
        selectedProvider = readyProviders.firstWhere(
          (provider) => provider.providerId == restoredProviderId,
        );
      } catch (_) {
        selectedProvider = null;
      }
    }

    if (selectedProvider == null &&
        conversation == null &&
        readyProviders.isNotEmpty) {
      selectedProvider = readyProviders.first;
    }

    final selectedModelId = selectedProvider == null
        ? null
        : restoredModelId ?? selectedProvider.defaultModelId;

    AgentProfileData? selectedAgent;
    if (conversation?.agentId != null) {
      try {
        selectedAgent = agents.firstWhere((a) => a.id == conversation!.agentId);
      } catch (_) {
        selectedAgent = null;
      }
    }

    String? protocolWarning;
    if (conversation != null && selectedProvider == null) {
      try {
        final convConfig =
            await widget.configStore.readConfig(conversation.providerId);
        if (convConfig != null &&
            !widget.chatClientResolver.supports(convConfig.protocol)) {
          protocolWarning = 'Provider protocol is not supported yet';
        } else {
          _persistWarning = 'Provider is no longer available';
        }
      } catch (_) {
        _persistWarning = 'Provider configuration is invalid';
      }
    }

    if (mounted) {
      setState(() {
        _readyProviders.clear();
        _readyProviders.addAll(readyProviders);
        _selectedProvider = selectedProvider;
        _selectedModelId = selectedModelId;
        _availableModels.clear();
        if (selectedModelId != null) {
          _availableModels.add(selectedModelId);
        }
        _agents.clear();
        _agents.addAll(agents);
        _selectedAgent = selectedAgent;
        _messages.clear();
        _messages.addAll(historyMessages);
        _activeConversationId = conversation?.id;
        _loading = false;
        _protocolWarning = protocolWarning;

        if (conversation != null &&
            selectedProvider == null &&
            _persistWarning == null &&
            _protocolWarning == null) {
          _persistWarning = 'Provider is no longer available';
        }
      });

      if (conversation == null && selectedProvider != null) {
        unawaited(_loadModels(selectedProvider));
      }
    }
  }

  bool get _isSelectionLocked => _activeConversationId != null;

  bool get _canSend {
    if (_sending) return false;
    if (_selectedProvider == null || _selectedModelId == null) return false;
    if (_persistWarning != null) return false;
    if (_protocolWarning != null) return false;
    return true;
  }

  bool get _canStop => _sending && _activeGenerationId != null;

  bool get _hasTransientAssistant {
    return _sending ||
        _streamingAssistantText.isNotEmpty ||
        _streamingReasoningText.isNotEmpty;
  }

  bool get _canRetry {
    if (_sending) return false;
    if (_selectedProvider == null || _selectedModelId == null) return false;
    if (_persistWarning != null) return false;
    if (_protocolWarning != null) return false;
    if (_activeConversationId == null) return false;
    if (_messages.isEmpty) return false;
    final last = _messages.last;
    return last.role == ChatRole.user;
  }

  bool get _canRegenerate {
    if (_sending) return false;
    if (_selectedProvider == null || _selectedModelId == null) return false;
    if (_persistWarning != null) return false;
    if (_protocolWarning != null) return false;
    if (_activeConversationId == null) return false;
    if (_messages.length < 2) return false;
    final last = _messages.last;
    final secondLast = _messages[_messages.length - 2];
    return last.role == ChatRole.assistant && secondLast.role == ChatRole.user;
  }

  ChatMessage? get _lastUserMessage {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == ChatRole.user) return _messages[i];
    }
    return null;
  }

  ChatMessage? get _lastAssistantMessage {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == ChatRole.assistant) return _messages[i];
    }
    return null;
  }

  String _nextId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  void _clearStoppedState() {
    _streamingAssistantText = '';
    _streamingReasoningText = '';
    _expandedReasoningKeys.clear();
    _userStopped = false;
    _generationPhase = _GenerationPhase.idle;
    _trimWarning = null;
  }

  bool _isGenerationActive(int generationId) {
    return mounted && _activeGenerationId == generationId && !_terminalHandled;
  }

  void _finishGeneration({
    required int generationId,
    required _GenerationEndReason reason,
  }) {
    if (!_isGenerationActive(generationId)) return;

    _terminalHandled = true;

    final sub = _streamSubscription;
    _streamSubscription = null;
    final token = _cancellationToken;
    _cancellationToken = null;
    _activeGenerationId = null;

    _safeCancel(sub);
    _safeCancelToken(token);
    unawaited(widget.generationKeepAlive.stop());

    if (reason == _GenerationEndReason.disposed) return;

    if (mounted) {
      setState(() {
        _sending = false;
        _generationPhase = _GenerationPhase.idle;
      });
    }
  }

  void _safeCancel(StreamSubscription? sub) {
    if (sub == null) return;
    unawaited(sub.cancel().catchError((_) {}));
  }

  void _safeCancelToken(ChatCancellationToken? token) {
    if (token == null) return;
    try {
      token.cancel();
    } catch (_) {}
  }

  void _resetProviderSelection() {
    _modelLoadCounter++;
    _loadingModels = false;
    _selectedProvider =
        _readyProviders.isNotEmpty ? _readyProviders.first : null;
    _selectedModelId = _selectedProvider?.defaultModelId;
    _availableModels.clear();
    if (_selectedModelId != null) {
      _availableModels.add(_selectedModelId!);
    }
  }

  Future<void> _selectProvider(_ReadyProvider provider) async {
    setState(() {
      _modelLoadCounter++;
      _loadingModels = false;
      _selectedProvider = provider;
      _selectedModelId = provider.defaultModelId;
      _availableModels
        ..clear()
        ..add(provider.defaultModelId);
    });
    await _loadModels(provider);
  }

  Future<void> _loadModels(_ReadyProvider provider) async {
    final tester = widget.connectionTesterResolver?.resolve(provider.protocol);
    if (tester == null || _isSelectionLocked) return;

    final requestId = ++_modelLoadCounter;
    setState(() => _loadingModels = true);

    try {
      final result = await tester.testConnection(
        baseUrl: provider.baseUrl,
        apiKey: provider.apiKey,
      );
      if (!mounted ||
          requestId != _modelLoadCounter ||
          _selectedProvider?.providerId != provider.providerId) {
        return;
      }

      if (result.success) {
        final models = <String>{provider.defaultModelId};
        for (final modelId in result.modelIds) {
          final trimmedModelId = modelId.trim();
          if (trimmedModelId.isNotEmpty) {
            models.add(trimmedModelId);
          }
        }
        setState(() {
          _availableModels
            ..clear()
            ..addAll(models);
          if (!_availableModels.contains(_selectedModelId)) {
            _selectedModelId = provider.defaultModelId;
          }
        });
      }
    } catch (_) {
      // Keep the configured default model when the provider does not expose
      // a compatible models endpoint or the request fails.
    } finally {
      if (mounted &&
          requestId == _modelLoadCounter &&
          _selectedProvider?.providerId == provider.providerId) {
        setState(() => _loadingModels = false);
      }
    }
  }

  Future<void> _newChat() async {
    if (_sending) return;
    _ReadyProvider? provider;
    setState(() {
      _messages.clear();
      _activeConversationId = null;
      _persistWarning = null;
      _protocolWarning = null;
      _resetProviderSelection();
      provider = _selectedProvider;
      _selectedAgent = null;
      _messageController.clear();
      _clearStoppedState();
    });
    if (provider != null) {
      unawaited(_loadModels(provider!));
    }
  }

  Future<void> _openConversationList() async {
    if (_sending) return;

    final result = await Navigator.push<ConversationListResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationListPage(
          historyStore: widget.historyStore,
          configStore: widget.configStore,
          currentConversationId: _activeConversationId,
        ),
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    if (result.action == ConversationListAction.activeConversationDeleted) {
      _ReadyProvider? provider;
      setState(() {
        _messages.clear();
        _activeConversationId = null;
        _persistWarning = null;
        _protocolWarning = null;
        _resetProviderSelection();
        provider = _selectedProvider;
        _selectedAgent = null;
        _messageController.clear();
        _clearStoppedState();
      });
      if (provider != null) {
        unawaited(_loadModels(provider!));
      }
    } else if (result.action == ConversationListAction.selected &&
        result.conversationId != null &&
        result.conversationId != _activeConversationId) {
      await _switchConversation(result.conversationId!);
    }
  }

  Future<void> _switchConversation(String conversationId) async {
    setState(() => _loading = true);

    try {
      final conversation =
          await widget.historyStore.readConversation(conversationId);
      if (conversation == null) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load conversation')),
          );
        }
        return;
      }

      final messages = await widget.historyStore.readMessages(conversationId);

      _ReadyProvider? selectedProvider;
      try {
        selectedProvider = _readyProviders.firstWhere(
          (provider) => provider.providerId == conversation.providerId,
        );
      } catch (_) {
        selectedProvider = null;
      }

      AgentProfileData? selectedAgent;
      if (conversation.agentId != null) {
        try {
          selectedAgent =
              _agents.firstWhere((a) => a.id == conversation.agentId);
        } catch (_) {
          selectedAgent = null;
        }
      }

      String? protocolWarning;
      String? persistWarning;
      if (selectedProvider == null) {
        try {
          final convConfig =
              await widget.configStore.readConfig(conversation.providerId);
          if (convConfig != null &&
              !widget.chatClientResolver.supports(convConfig.protocol)) {
            protocolWarning = 'Provider protocol is not supported yet';
          } else {
            persistWarning = 'Provider is no longer available';
          }
        } catch (_) {
          persistWarning = 'Provider configuration is invalid';
        }
      }

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _activeConversationId = conversationId;
          _selectedProvider = selectedProvider;
          _selectedModelId =
              selectedProvider == null ? null : conversation.model;
          _availableModels.clear();
          if (_selectedModelId != null) {
            _availableModels.add(_selectedModelId!);
          }
          _selectedAgent = selectedAgent;
          _persistWarning = persistWarning;
          _protocolWarning = protocolWarning;
          _loading = false;
          _messageController.clear();
          _clearStoppedState();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load conversation')),
        );
      }
    }
  }

  void _stopGeneration() {
    if (!_canStop) return;
    final genId = _activeGenerationId!;

    setState(() {
      _userStopped = true;
    });

    _finishGeneration(
      generationId: genId,
      reason: _GenerationEndReason.userStopped,
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (!_canSend) return;

    final isFirstMessage = _activeConversationId == null;

    final userMessage = ChatMessage(
      id: _nextId(),
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    if (isFirstMessage) {
      final conversationId = 'conversation_${_nextId()}';
      final conversation = ChatConversation(
        id: conversationId,
        title: ChatConversation.generateTitle(text),
        providerId: _selectedProvider!.providerId,
        model: _selectedModelId!,
        agentId: _selectedAgent?.id,
        agentNameSnapshot: _selectedAgent?.name,
        systemPromptSnapshot: _selectedAgent?.systemPrompt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await widget.historyStore.createConversationWithFirstMessage(
          conversation: conversation,
          firstMessage: userMessage,
        );
        setState(() {
          _activeConversationId = conversationId;
          _messages.add(userMessage);
        });
        _messageController.clear();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save message')),
          );
        }
        return;
      }
    } else {
      try {
        await widget.historyStore.appendMessage(
          conversationId: _activeConversationId!,
          message: userMessage,
        );
        await widget.historyStore.updateConversationActivity(
          conversationId: _activeConversationId!,
          updatedAt: DateTime.now(),
        );
        setState(() {
          _messages.add(userMessage);
        });
        _messageController.clear();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save message')),
          );
        }
        return;
      }
    }

    final target = _GenerationTarget(
      kind: _GenerationKind.normal,
      userMessage: userMessage,
    );

    await _runGeneration(target);
  }

  Future<void> _retryLastTurn() async {
    if (!_canRetry) return;

    final userMsg = _lastUserMessage;
    if (userMsg == null) return;

    final target = _GenerationTarget(
      kind: _GenerationKind.retry,
      userMessage: userMsg,
    );

    await _runGeneration(target);
  }

  Future<void> _regenerateLastResponse() async {
    if (!_canRegenerate) return;

    final userMsg = _lastUserMessage;
    final assistantMsg = _lastAssistantMessage;
    if (userMsg == null || assistantMsg == null) return;

    final target = _GenerationTarget(
      kind: _GenerationKind.regenerate,
      userMessage: userMsg,
      replacedAssistantMessage: assistantMsg,
    );

    await _runGeneration(target);
  }

  Future<void> _runGeneration(
    _GenerationTarget target, {
    int automaticRetryAttempt = 0,
  }) async {
    setState(() {
      _sending = true;
      _userStopped = false;
      _streamingAssistantText = '';
      _streamingReasoningText = '';
      _expandedReasoningKeys.remove(_streamingReasoningKey);
      _generationPhase = _GenerationPhase.waiting;
    });

    _scrollToBottom();
    _cancellationToken = ChatCancellationToken();
    final genId = ++_generationCounter;
    _activeGenerationId = genId;
    _terminalHandled = false;
    _streamingAssistantText = '';
    _streamingReasoningText = '';

    await widget.generationKeepAlive.start();
    if (!_isGenerationActive(genId)) return;

    final localToken = _cancellationToken;

    try {
      // Build context: exclude the target user message from history
      final historyMessages = _messages
          .where((m) => m.id != target.userMessage.id)
          // For regenerate, also exclude the old assistant message
          .where((m) =>
              target.kind != _GenerationKind.regenerate ||
              m.id != target.replacedAssistantMessage?.id)
          .map((m) => ChatRequestMessage(
                role: m.role == ChatRole.user ? 'user' : 'assistant',
                content: m.content,
              ))
          .toList();

      final currentUserRequest = ChatRequestMessage(
        role: 'user',
        content: target.userMessage.content,
      );

      // Build system message from agent snapshot if available
      ChatRequestMessage? systemMessage;
      if (_activeConversationId != null) {
        final conversation =
            await widget.historyStore.readConversation(_activeConversationId!);
        if (conversation?.systemPromptSnapshot != null &&
            conversation!.systemPromptSnapshot!.isNotEmpty) {
          systemMessage = ChatRequestMessage(
            role: 'system',
            content: conversation.systemPromptSnapshot!,
          );
        }
      } else if (_selectedAgent != null &&
          _selectedAgent!.systemPrompt.isNotEmpty) {
        systemMessage = ChatRequestMessage(
          role: 'system',
          content: _selectedAgent!.systemPrompt,
        );
      }

      final contextResult = widget.contextBuilder.build(
        history: historyMessages,
        currentUserMessage: currentUserRequest,
        systemMessage: systemMessage,
      );

      if (contextResult.wasTrimmed) {
        setState(() {
          _trimWarning = 'Earlier messages were omitted for this request';
        });
      } else if (contextResult.currentMessageExceedsBudget) {
        setState(() {
          _trimWarning = 'Current message exceeds the local context estimate';
        });
      } else if (contextResult.systemPromptExceedsBudget) {
        setState(() {
          _trimWarning =
              'System prompt and current message exceed the local context estimate';
        });
      } else {
        setState(() {
          _trimWarning = null;
        });
      }

      final stream = _selectedProvider!.client.streamComplete(
        baseUrl: _selectedProvider!.baseUrl,
        apiKey: _selectedProvider!.apiKey,
        model: _selectedModelId!,
        messages: contextResult.messages,
        cancellationToken: localToken,
      );

      bool hasContent = false;

      _streamSubscription = stream.listen(
        (event) {
          if (!_isGenerationActive(genId)) return;

          if (event is ChatStreamReasoningDelta) {
            setState(() {
              _streamingReasoningText += event.content;
              if (_streamingAssistantText.isEmpty) {
                _generationPhase = _GenerationPhase.reasoning;
              }
            });
            _scrollIfNearBottom();
          } else if (event is ChatStreamDelta) {
            hasContent = true;
            setState(() {
              _streamingAssistantText += event.content;
              _generationPhase = _GenerationPhase.responding;
            });
            _scrollIfNearBottom();
          } else if (event is ChatStreamCompleted) {
            _handleStreamCompleted(hasContent, genId, target);
          } else if (event is ChatStreamFailure) {
            _handleStreamFailure(
              event,
              hasContent,
              genId,
              target,
              automaticRetryAttempt,
            );
          }
        },
        onError: (error) {
          if (!_isGenerationActive(genId)) return;
          _handleStreamError(hasContent, genId);
        },
        onDone: () {
          if (!_isGenerationActive(genId)) return;
          _finishGeneration(
            generationId: genId,
            reason: _GenerationEndReason.completed,
          );
        },
      );
    } catch (_) {
      if (mounted) {
        _finishGeneration(
          generationId: genId,
          reason: _GenerationEndReason.failed,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get response')),
        );
      }
    }
  }

  Future<void> _handleStreamCompleted(
      bool hasContent, int genId, _GenerationTarget target) async {
    if (!_isGenerationActive(genId)) return;

    if (!hasContent) {
      _finishGeneration(
        generationId: genId,
        reason: _GenerationEndReason.failed,
      );
      if (mounted) {
        setState(() {
          _streamingReasoningText = '';
          _expandedReasoningKeys.remove(_streamingReasoningKey);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid provider response')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final reasoningWasExpanded =
        _expandedReasoningKeys.contains(_streamingReasoningKey);
    final hasReasoning = _streamingReasoningText.isNotEmpty;

    if (target.kind == _GenerationKind.regenerate &&
        target.replacedAssistantMessage != null) {
      // Replace existing assistant message
      try {
        await widget.historyStore.replaceAssistantMessage(
          conversationId: _activeConversationId!,
          messageId: target.replacedAssistantMessage!.id,
          content: _streamingAssistantText,
          conversationUpdatedAt: now,
        );

        _finishGeneration(
          generationId: genId,
          reason: _GenerationEndReason.completed,
        );

        if (mounted) {
          setState(() {
            final idx = _messages
                .indexWhere((m) => m.id == target.replacedAssistantMessage!.id);
            if (idx != -1) {
              _messages[idx] = ChatMessage(
                id: target.replacedAssistantMessage!.id,
                role: ChatRole.assistant,
                content: _streamingAssistantText,
                reasoningContent: _streamingReasoningText.isEmpty
                    ? null
                    : _streamingReasoningText,
                createdAt: target.replacedAssistantMessage!.createdAt,
              );
            }
            _expandedReasoningKeys
              ..remove(_streamingReasoningKey)
              ..remove(target.replacedAssistantMessage!.id);
            if (reasoningWasExpanded && hasReasoning) {
              _expandedReasoningKeys.add(target.replacedAssistantMessage!.id);
            }
            _streamingAssistantText = '';
            _streamingReasoningText = '';
          });
          _scrollIfNearBottom();
        }
      } catch (_) {
        _finishGeneration(
          generationId: genId,
          reason: _GenerationEndReason.failed,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response received but could not be saved'),
            ),
          );
          setState(() {
            _streamingAssistantText = '';
            _streamingReasoningText = '';
            _expandedReasoningKeys.remove(_streamingReasoningKey);
          });
        }
      }
    } else {
      // Normal or Retry: append new assistant message
      final assistantMessage = ChatMessage(
        id: _nextId(),
        role: ChatRole.assistant,
        content: _streamingAssistantText,
        reasoningContent:
            _streamingReasoningText.isEmpty ? null : _streamingReasoningText,
        createdAt: now,
      );

      _finishGeneration(
        generationId: genId,
        reason: _GenerationEndReason.completed,
      );

      try {
        await widget.historyStore.appendMessage(
          conversationId: _activeConversationId!,
          message: assistantMessage,
        );
        await widget.historyStore.updateConversationActivity(
          conversationId: _activeConversationId!,
          updatedAt: now,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response received but could not be saved'),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _messages.add(assistantMessage);
          _expandedReasoningKeys.remove(_streamingReasoningKey);
          if (reasoningWasExpanded && hasReasoning) {
            _expandedReasoningKeys.add(assistantMessage.id);
          }
          _streamingAssistantText = '';
          _streamingReasoningText = '';
        });
        _scrollIfNearBottom();
      }
    }
  }

  void _handleStreamFailure(
    ChatStreamFailure event,
    bool hasContent,
    int genId,
    _GenerationTarget target,
    int automaticRetryAttempt,
  ) {
    if (!_isGenerationActive(genId)) return;

    if (_shouldAutomaticallyRetry(event, automaticRetryAttempt) &&
        _prepareAutomaticRetry(genId)) {
      unawaited(_runGeneration(
        target,
        automaticRetryAttempt: automaticRetryAttempt + 1,
      ));
      return;
    }

    _finishGeneration(
      generationId: genId,
      reason: _GenerationEndReason.failed,
    );

    if (hasContent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response interrupted and was not saved'),
          ),
        );
        setState(() {
          _streamingAssistantText = '';
          _streamingReasoningText = '';
          _expandedReasoningKeys.remove(_streamingReasoningKey);
        });
      }
    } else {
      if (target.kind == _GenerationKind.normal) {
        _messageController.text = target.userMessage.content;
      }
      if (mounted && event.errorType != ChatCompletionErrorType.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.userMessage)),
        );
      }
      if (mounted) {
        setState(() {
          _streamingReasoningText = '';
          _expandedReasoningKeys.remove(_streamingReasoningKey);
        });
      }
    }
  }

  bool _shouldAutomaticallyRetry(
    ChatStreamFailure event,
    int automaticRetryAttempt,
  ) {
    if (automaticRetryAttempt >= 1) return false;
    return event.errorType == ChatCompletionErrorType.networkUnavailable ||
        event.errorType == ChatCompletionErrorType.timeout;
  }

  bool _prepareAutomaticRetry(int generationId) {
    if (!_isGenerationActive(generationId)) return false;

    _terminalHandled = true;

    final sub = _streamSubscription;
    _streamSubscription = null;
    final token = _cancellationToken;
    _cancellationToken = null;
    _activeGenerationId = null;

    _safeCancel(sub);
    _safeCancelToken(token);

    setState(() {
      _streamingAssistantText = '';
      _streamingReasoningText = '';
      _expandedReasoningKeys.remove(_streamingReasoningKey);
      _generationPhase = _GenerationPhase.waiting;
    });
    return true;
  }

  void _handleStreamError(bool hasContent, int genId) {
    if (!_isGenerationActive(genId)) return;

    _finishGeneration(
      generationId: genId,
      reason: _GenerationEndReason.failed,
    );

    if (hasContent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response interrupted and was not saved'),
          ),
        );
        setState(() {
          _streamingAssistantText = '';
          _streamingReasoningText = '';
          _expandedReasoningKeys.remove(_streamingReasoningKey);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _streamingReasoningText = '';
          _expandedReasoningKeys.remove(_streamingReasoningKey);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get response')),
        );
      }
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    const threshold = 120.0;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= threshold;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollIfNearBottom() {
    if (!_isNearBottom()) return;
    _scrollToBottom();
  }

  Widget _buildGenerationStatus(AppLocalizations l10n) {
    final (label, icon) = switch (_generationPhase) {
      _GenerationPhase.waiting => (
          l10n.waitingForResponse,
          const Icon(Icons.hourglass_top_rounded, size: 18),
        ),
      _GenerationPhase.reasoning => (
          l10n.thinking,
          const Icon(Icons.psychology_outlined, size: 18),
        ),
      _GenerationPhase.responding => (
          l10n.generatingResponse,
          const Icon(Icons.edit_note_rounded, size: 18),
        ),
      _GenerationPhase.idle => ('', const SizedBox.shrink()),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      label: label,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Row(
          key: ValueKey(_generationPhase),
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningDisclosure(
    AppLocalizations l10n,
    String reasoning,
    String expansionKey,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = _expandedReasoningKeys.contains(expansionKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: isExpanded,
          label: l10n.thinkingProcess,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('reasoning-toggle-$expansionKey'),
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedReasoningKeys.remove(expansionKey);
                  } else {
                    _expandedReasoningKeys.add(expansionKey);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.thinkingProcess,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 3, bottom: 8),
            padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colorScheme.outlineVariant, width: 2),
              ),
            ),
            child: SelectableText(
              reasoning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssistantContent({
    required AppLocalizations l10n,
    required String content,
    required bool isStreaming,
    required Key contentKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isStreaming && _generationPhase != _GenerationPhase.idle) ...[
          _buildGenerationStatus(l10n),
          if (content.isNotEmpty) const SizedBox(height: 10),
        ],
        if (content.isNotEmpty)
          AssistantMessageContent(
            source: content,
            key: contentKey,
          ),
      ],
    );
  }

  @override
  void dispose() {
    final genId = _activeGenerationId;
    if (genId != null) {
      _finishGeneration(
        generationId: genId,
        reason: _GenerationEndReason.disposed,
      );
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyChat'),
        actions: [
          Semantics(
            label: l10n.history,
            child: IconButton(
              onPressed: _sending ? null : _openConversationList,
              icon: const Icon(Icons.history),
              tooltip: l10n.history,
            ),
          ),
          Semantics(
            label: l10n.newChat,
            child: IconButton(
              onPressed: _sending ? null : _newChat,
              icon: const Icon(Icons.add_comment),
              tooltip: l10n.newChat,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedProvider == null &&
                  !_isSelectionLocked &&
                  _persistWarning == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noReadyProvider,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.configureProviderApiKey,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (!_isSelectionLocked) _buildSelectors(l10n),
                    if (_persistWarning != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.orange.shade100,
                        child: Text(
                          _persistWarning!,
                          style: TextStyle(color: Colors.orange.shade900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_protocolWarning != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.orange.shade100,
                        child: Text(
                          _protocolWarning!,
                          style: TextStyle(color: Colors.orange.shade900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_trimWarning != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.shade50,
                        child: Text(
                          _trimWarning!,
                          style: TextStyle(
                              color: Colors.blue.shade900, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: _messages.isEmpty && !_hasTransientAssistant
                          ? Center(
                              child: Text(
                                l10n.startConversation,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length +
                                  (_hasTransientAssistant ? 1 : 0),
                              itemBuilder: (context, index) {
                                final isStreaming = index == _messages.length;
                                final isUser = !isStreaming &&
                                    _messages[index].role == ChatRole.user;
                                final isAssistant = !isStreaming &&
                                    _messages[index].role == ChatRole.assistant;
                                final isLastAssistant = isAssistant &&
                                    index == _messages.length - 1;
                                final content = isStreaming
                                    ? _streamingAssistantText
                                    : _messages[index].content;
                                final reasoning = isStreaming
                                    ? _streamingReasoningText
                                    : _messages[index].reasoningContent ?? '';
                                final reasoningExpansionKey = isStreaming
                                    ? _streamingReasoningKey
                                    : _messages[index].id;

                                return Column(
                                  crossAxisAlignment: isUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser && reasoning.isNotEmpty)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 3),
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.75,
                                          ),
                                          child: _buildReasoningDisclosure(
                                            l10n,
                                            reasoning,
                                            reasoningExpansionKey,
                                          ),
                                        ),
                                      ),
                                    Align(
                                      alignment: isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        key: ValueKey(
                                          '${isUser ? 'user' : 'assistant'}_message_bubble_$index',
                                        ),
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        width: isUser ? null : double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: isUser
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.75
                                              : double.infinity,
                                          minHeight: 44,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: isUser
                                            ? Text(content)
                                            : _buildAssistantContent(
                                                l10n: l10n,
                                                content: content,
                                                isStreaming: isStreaming,
                                                contentKey: ValueKey(
                                                  'msg_${isStreaming ? 'streaming' : _messages[index].id}',
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (isAssistant)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Semantics(
                                              label: l10n.copyResponse,
                                              child: IconButton(
                                                icon: const Icon(Icons.copy,
                                                    size: 16),
                                                tooltip: l10n.copyResponse,
                                                onPressed: () async {
                                                  final messenger =
                                                      ScaffoldMessenger.of(
                                                          context);
                                                  await Clipboard.setData(
                                                    ClipboardData(
                                                        text: content),
                                                  );
                                                  if (mounted) {
                                                    messenger.showSnackBar(
                                                      SnackBar(
                                                        content:
                                                            Text(l10n.copied),
                                                        duration:
                                                            const Duration(
                                                                seconds: 1),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            if (isLastAssistant &&
                                                _canRegenerate &&
                                                !_sending)
                                              Semantics(
                                                label: l10n.regenerateResponse,
                                                child: IconButton(
                                                  icon: const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 16),
                                                  tooltip:
                                                      l10n.regenerateResponse,
                                                  onPressed:
                                                      _regenerateLastResponse,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (isStreaming && _userStopped)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 12, bottom: 8),
                                        child: Text(
                                          l10n.stopped,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            if (_canRetry && !_sending)
                              Semantics(
                                label: l10n.retry,
                                child: IconButton(
                                  onPressed: _retryLastTurn,
                                  icon: const Icon(Icons.refresh, size: 20),
                                  tooltip: l10n.retry,
                                ),
                              ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: l10n.typeMessage,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                enabled: _canSend,
                                onSubmitted: _canSend ? (_) => _send() : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_canStop)
                              Semantics(
                                label: l10n.stopGenerating,
                                child: IconButton(
                                  onPressed: _stopGeneration,
                                  icon: const Icon(Icons.stop_rounded),
                                  tooltip: l10n.stopGenerating,
                                ),
                              )
                            else
                              Semantics(
                                label: l10n.send,
                                child: IconButton(
                                  onPressed: _canSend ? _send : null,
                                  tooltip: l10n.send,
                                  icon: _sending
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSelectors(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAgentSelector(l10n),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProviderSelector(l10n),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildModelSelector(l10n),
        ],
      ),
    );
  }

  Widget _buildAgentSelector(AppLocalizations l10n) {
    return DropdownButton<AgentProfileData?>(
      value: _selectedAgent,
      isExpanded: true,
      underline: const SizedBox(),
      items: [
        DropdownMenuItem<AgentProfileData?>(
          value: null,
          child: Text(
            l10n.noAgent,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ..._agents.map((agent) => DropdownMenuItem<AgentProfileData?>(
              value: agent,
              child: Text(
                agent.name,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: _isSelectionLocked
          ? null
          : (agent) {
              if (mounted) {
                setState(() => _selectedAgent = agent);
              }
            },
    );
  }

  Widget _buildProviderSelector(AppLocalizations l10n) {
    if (_readyProviders.isEmpty) {
      return Text(
        l10n.noProvider,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      );
    }

    return DropdownButton<_ReadyProvider>(
      key: const Key('provider_selector'),
      value: _selectedProvider,
      isExpanded: true,
      underline: const SizedBox(),
      items: _readyProviders
          .map((provider) => DropdownMenuItem<_ReadyProvider>(
                value: provider,
                child: Text(
                  provider.providerDisplayName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: _isSelectionLocked
          ? null
          : (provider) {
              if (provider != null) {
                unawaited(_selectProvider(provider));
              }
            },
    );
  }

  Widget _buildModelSelector(AppLocalizations l10n) {
    if (_availableModels.isEmpty) {
      return Text(
        l10n.noModelAvailable,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      );
    }

    return DropdownButtonFormField<String>(
      key: const Key('model_selector'),
      value: _selectedModelId,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: l10n.model,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: _loadingModels
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      selectedItemBuilder: (context) => _availableModels
          .map((modelId) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  modelId,
                  style: const TextStyle(fontSize: 14),
                  softWrap: true,
                ),
              ))
          .toList(),
      items: _availableModels
          .map((modelId) => DropdownMenuItem<String>(
                value: modelId,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    modelId,
                    style: const TextStyle(fontSize: 14),
                    softWrap: true,
                  ),
                ),
              ))
          .toList(),
      onChanged: _isSelectionLocked || _loadingModels
          ? null
          : (modelId) {
              if (modelId != null) {
                setState(() => _selectedModelId = modelId);
              }
            },
    );
  }
}
