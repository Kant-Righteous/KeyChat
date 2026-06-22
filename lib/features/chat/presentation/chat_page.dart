import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/chat_context_builder.dart';
import 'package:keychat/features/chat/domain/conversation_list_result.dart';
import 'package:keychat/features/chat/presentation/conversation_list_page.dart';
import 'package:keychat/features/chat/presentation/widgets/assistant_message_content.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';

class _ReadyProvider {
  final ProviderConfigData config;
  final String apiKey;
  final ChatCompletionClient client;

  const _ReadyProvider({
    required this.config,
    required this.apiKey,
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
  final ChatContextBuilder contextBuilder;

  ChatPage({
    super.key,
    required this.chatClientResolver,
    required this.apiKeyStore,
    required this.configStore,
    required this.historyStore,
    ChatContextBuilder? contextBuilder,
  }) : contextBuilder = contextBuilder ?? ChatContextBuilder();

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  final List<_ReadyProvider> _readyProviders = [];
  _ReadyProvider? _selectedProvider;
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
    final ready = <_ReadyProvider>[];

    for (final config in configs) {
      if (!config.enabled) continue;
      if (config.baseUrl.trim().isEmpty) continue;
      if (config.defaultModel == null || config.defaultModel!.trim().isEmpty) {
        continue;
      }
      final hasKey = await widget.apiKeyStore.hasKey(config.providerId);
      if (!hasKey) continue;
      final apiKey = await widget.apiKeyStore.readKey(config.providerId);
      if (apiKey == null || apiKey.trim().isEmpty) continue;

      final client = widget.chatClientResolver.resolve(config.protocol);
      if (client == null) continue;

      ready.add(_ReadyProvider(config: config, apiKey: apiKey, client: client));
    }

    final conversation = await widget.historyStore.readLatestConversation();
    List<ChatMessage> historyMessages = [];
    String? restoredProviderId;

    if (conversation != null) {
      historyMessages = await widget.historyStore.readMessages(conversation.id);
      restoredProviderId = conversation.providerId;
    }

    _ReadyProvider? selectedProvider;
    if (restoredProviderId != null) {
      try {
        selectedProvider = ready.firstWhere(
          (p) => p.config.providerId == restoredProviderId,
        );
      } catch (_) {
        selectedProvider = null;
      }
    }

    if (selectedProvider == null && ready.isNotEmpty) {
      selectedProvider = ready.first;
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
        _readyProviders.addAll(ready);
        _selectedProvider = selectedProvider;
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
    }
  }

  bool get _isProviderLocked => _activeConversationId != null;

  bool get _canSend {
    if (_sending) return false;
    if (_selectedProvider == null) return false;
    if (_persistWarning != null) return false;
    if (_protocolWarning != null) return false;
    return true;
  }

  bool get _canStop => _sending && _activeGenerationId != null;

  bool get _canRetry {
    if (_sending) return false;
    if (_selectedProvider == null) return false;
    if (_persistWarning != null) return false;
    if (_protocolWarning != null) return false;
    if (_activeConversationId == null) return false;
    if (_messages.isEmpty) return false;
    final last = _messages.last;
    return last.role == ChatRole.user;
  }

  bool get _canRegenerate {
    if (_sending) return false;
    if (_selectedProvider == null) return false;
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
    _userStopped = false;
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

    if (reason == _GenerationEndReason.disposed) return;

    if (mounted) {
      setState(() {
        _sending = false;
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

  Future<void> _newChat() async {
    if (_sending) return;
    setState(() {
      _messages.clear();
      _activeConversationId = null;
      _persistWarning = null;
      _protocolWarning = null;
      _selectedProvider =
          _readyProviders.isNotEmpty ? _readyProviders.first : null;
      _messageController.clear();
      _clearStoppedState();
    });
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
      setState(() {
        _messages.clear();
        _activeConversationId = null;
        _persistWarning = null;
        _protocolWarning = null;
        _selectedProvider =
            _readyProviders.isNotEmpty ? _readyProviders.first : null;
        _messageController.clear();
        _clearStoppedState();
      });
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
          (p) => p.config.providerId == conversation.providerId,
        );
      } catch (_) {
        selectedProvider = null;
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
        providerId: _selectedProvider!.config.providerId,
        model: _selectedProvider!.config.defaultModel!,
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

  Future<void> _runGeneration(_GenerationTarget target) async {
    setState(() {
      _sending = true;
      _userStopped = false;
      _streamingAssistantText = '';
    });

    _scrollToBottom();
    _cancellationToken = ChatCancellationToken();
    final genId = ++_generationCounter;
    _activeGenerationId = genId;
    _terminalHandled = false;
    _streamingAssistantText = '';

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

      final contextResult = widget.contextBuilder.build(
        history: historyMessages,
        currentUserMessage: currentUserRequest,
      );

      if (contextResult.wasTrimmed) {
        setState(() {
          _trimWarning = 'Earlier messages were omitted for this request';
        });
      } else if (contextResult.currentMessageExceedsBudget) {
        setState(() {
          _trimWarning = 'Current message exceeds the local context estimate';
        });
      } else {
        setState(() {
          _trimWarning = null;
        });
      }

      final stream = _selectedProvider!.client.streamComplete(
        baseUrl: _selectedProvider!.config.baseUrl,
        apiKey: _selectedProvider!.apiKey,
        model: _selectedProvider!.config.defaultModel!,
        messages: contextResult.messages,
        cancellationToken: localToken,
      );

      bool hasContent = false;

      _streamSubscription = stream.listen(
        (event) {
          if (!_isGenerationActive(genId)) return;

          if (event is ChatStreamDelta) {
            hasContent = true;
            setState(() {
              _streamingAssistantText += event.content;
            });
            _scrollToBottom();
          } else if (event is ChatStreamCompleted) {
            _handleStreamCompleted(hasContent, genId, target);
          } else if (event is ChatStreamFailure) {
            _handleStreamFailure(event, hasContent, genId, target);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid provider response')),
        );
      }
      return;
    }

    final now = DateTime.now();

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
                createdAt: target.replacedAssistantMessage!.createdAt,
              );
            }
            _streamingAssistantText = '';
          });
          _scrollToBottom();
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
          });
        }
      }
    } else {
      // Normal or Retry: append new assistant message
      final assistantMessage = ChatMessage(
        id: _nextId(),
        role: ChatRole.assistant,
        content: _streamingAssistantText,
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
          _streamingAssistantText = '';
        });
        _scrollToBottom();
      }
    }
  }

  void _handleStreamFailure(ChatStreamFailure event, bool hasContent, int genId,
      _GenerationTarget target) {
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
    }
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
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get response')),
        );
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyChat'),
        actions: [
          if (!_isProviderLocked && _selectedProvider != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _readyProviders.length > 1
                  ? Semantics(
                      label: 'Select provider',
                      child: DropdownButton<_ReadyProvider>(
                        value: _selectedProvider,
                        underline: const SizedBox(),
                        onChanged: _isProviderLocked
                            ? null
                            : (provider) {
                                if (provider != null) {
                                  setState(
                                      () => _selectedProvider = provider);
                                }
                              },
                        items: _readyProviders.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.config.displayName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : Center(
                      child: Text(
                        _selectedProvider!.config.displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
            ),
          if (_isProviderLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _selectedProvider?.config.displayName ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            onPressed: _sending ? null : _openConversationList,
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          IconButton(
            onPressed: _sending ? null : _newChat,
            icon: const Icon(Icons.add_comment),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedProvider == null &&
                  !_isProviderLocked &&
                  _persistWarning == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No ready provider',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Configure a provider with API key and default model',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
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
                      child: _messages.isEmpty &&
                              _streamingAssistantText.isEmpty
                          ? const Center(
                              child: Text(
                                'Start a conversation',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length +
                                  (_streamingAssistantText.isNotEmpty ? 1 : 0),
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

                                return Column(
                                  crossAxisAlignment: isUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75,
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
                                            : AssistantMessageContent(
                                                source: content,
                                                key: ValueKey(
                                                    'msg_${isStreaming ? 'streaming' : _messages[index].id}'),
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
                                              label: 'Copy response',
                                              child: IconButton(
                                                icon: const Icon(Icons.copy,
                                                    size: 16),
                                                tooltip: 'Copy response',
                                                onPressed: () async {
                                                  final messenger =
                                                      ScaffoldMessenger.of(
                                                          context);
                                                  await Clipboard.setData(
                                                    ClipboardData(text: content),
                                                  );
                                                  if (mounted) {
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Copied'),
                                                        duration:
                                                            Duration(seconds: 1),
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
                                                label: 'Regenerate response',
                                                child: IconButton(
                                                  icon: const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 16),
                                                  tooltip:
                                                      'Regenerate response',
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
                                          'Stopped',
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
                                label: 'Retry',
                                child: IconButton(
                                  onPressed: _retryLastTurn,
                                  icon: const Icon(Icons.refresh, size: 20),
                                  tooltip: 'Retry',
                                ),
                              ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
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
                                label: 'Stop generating',
                                child: IconButton(
                                  onPressed: _stopGeneration,
                                  icon: const Icon(Icons.stop_rounded),
                                  tooltip: 'Stop generating',
                                ),
                              )
                            else
                              Semantics(
                                label: 'Send message',
                                child: IconButton(
                                  onPressed: _canSend ? _send : null,
                                  tooltip: 'Send',
                                  icon: _sending
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
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
}
