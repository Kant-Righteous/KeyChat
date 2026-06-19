import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
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

  const ChatPage({
    super.key,
    required this.chatClient,
    required this.apiKeyStore,
    required this.configStore,
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
  CancelToken? _cancelToken;
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
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

    if (mounted) {
      setState(() {
        _readyProviders.clear();
        _readyProviders.addAll(ready);
        _selectedProvider = ready.isNotEmpty ? ready.first : null;
        _loading = false;
      });
    }
  }

  String _nextId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_selectedProvider == null) return;
    if (_sending) return;

    setState(() {
      _sending = true;
      _messages.add(ChatMessage(
        id: _nextId(),
        role: ChatRole.user,
        content: text,
        createdAt: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    _cancelToken = CancelToken();

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
        cancelToken: _cancelToken,
      );

      if (!mounted) return;

      if (result.success && result.assistantContent != null) {
        setState(() {
          _messages.add(ChatMessage(
            id: _nextId(),
            role: ChatRole.assistant,
            content: result.assistantContent!,
            createdAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
      } else if (result.errorType != ChatCompletionErrorType.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.userMessage ?? 'Unable to get response')),
        );
      }
    } catch (_) {
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
    _cancelToken?.cancel();
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
          if (_selectedProvider != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _readyProviders.length > 1
                  ? DropdownButton<_ReadyProvider>(
                      value: _selectedProvider,
                      underline: const SizedBox(),
                      onChanged: (provider) {
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
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedProvider == null
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
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _sending ? null : _send,
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
