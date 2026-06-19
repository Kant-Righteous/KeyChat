import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/conversation_list_result.dart';
import 'package:keychat/features/chat/presentation/conversation_list_page.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';

class _ReadyProvider {
  final ProviderConfigData config;
  final String apiKey;

  const _ReadyProvider({required this.config, required this.apiKey});
}

class ChatPage extends StatefulWidget {
  final ChatCompletionClient chatClient;
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ChatHistoryStore historyStore;

  const ChatPage({
    super.key,
    required this.chatClient,
    required this.apiKeyStore,
    required this.configStore,
    required this.historyStore,
  });

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
  ChatCancellationToken? _cancellationToken;
  int _idCounter = 0;
  String? _activeConversationId;
  String? _persistWarning;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final configs = await widget.configStore.readAllConfigs();
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
      ready.add(_ReadyProvider(config: config, apiKey: apiKey));
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

    if (mounted) {
      setState(() {
        _readyProviders.clear();
        _readyProviders.addAll(ready);
        _selectedProvider = selectedProvider;
        _messages.clear();
        _messages.addAll(historyMessages);
        _activeConversationId = conversation?.id;
        _loading = false;

        if (conversation != null && selectedProvider == null) {
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
    return true;
  }

  String _nextId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  Future<void> _newChat() async {
    if (_sending) return;
    setState(() {
      _messages.clear();
      _activeConversationId = null;
      _persistWarning = null;
      _selectedProvider =
          _readyProviders.isNotEmpty ? _readyProviders.first : null;
      _messageController.clear();
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
        _selectedProvider =
            _readyProviders.isNotEmpty ? _readyProviders.first : null;
        _messageController.clear();
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

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _activeConversationId = conversationId;
          _selectedProvider = selectedProvider;
          _persistWarning = selectedProvider == null
              ? 'Provider is no longer available'
              : null;
          _loading = false;
          _messageController.clear();
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
          _sending = true;
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
          _sending = true;
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

    _scrollToBottom();
    _cancellationToken = ChatCancellationToken();

    try {
      final requestMessages = _messages
          .map((m) => ChatRequestMessage(
                role: m.role == ChatRole.user ? 'user' : 'assistant',
                content: m.content,
              ))
          .toList();

      final result = await widget.chatClient.complete(
        baseUrl: _selectedProvider!.config.baseUrl,
        apiKey: _selectedProvider!.apiKey,
        model: _selectedProvider!.config.defaultModel!,
        messages: requestMessages,
        cancellationToken: _cancellationToken,
      );

      if (!mounted) return;

      if (result.success && result.assistantContent != null) {
        final assistantMessage = ChatMessage(
          id: _nextId(),
          role: ChatRole.assistant,
          content: result.assistantContent!,
          createdAt: DateTime.now(),
        );

        try {
          await widget.historyStore.appendMessage(
            conversationId: _activeConversationId!,
            message: assistantMessage,
          );
          await widget.historyStore.updateConversationActivity(
            conversationId: _activeConversationId!,
            updatedAt: DateTime.now(),
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

        setState(() {
          _messages.add(assistantMessage);
        });
        _scrollToBottom();
      } else if (result.errorType != ChatCompletionErrorType.cancelled) {
        _messageController.text = text;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.userMessage ?? 'Unable to get response'),
            ),
          );
        }
      }
    } catch (_) {
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get response')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
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
    _cancellationToken?.cancel();
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
                  ? DropdownButton<_ReadyProvider>(
                      value: _selectedProvider,
                      underline: const SizedBox(),
                      onChanged: _isProviderLocked
                          ? null
                          : (provider) {
                              if (provider != null) {
                                setState(() => _selectedProvider = provider);
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
          : _selectedProvider == null && !_isProviderLocked
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
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Start a conversation',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isUser = msg.role == ChatRole.user;
                                return Align(
                                  alignment: isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(msg.content),
                                  ),
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
                            IconButton(
                              onPressed: _canSend ? _send : null,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
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
