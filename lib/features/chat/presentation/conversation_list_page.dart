import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/conversation_list_result.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';

class ConversationListPage extends StatefulWidget {
  final ChatHistoryStore historyStore;
  final ProviderConfigStore configStore;
  final String? currentConversationId;

  const ConversationListPage({
    super.key,
    required this.historyStore,
    required this.configStore,
    this.currentConversationId,
  });

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  List<ChatConversation> _conversations = [];
  Map<String, String> _providerNames = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final conversations = await widget.historyStore.readConversations();
      final configs = await widget.configStore.readAllConfigs();
      final providerNames = <String, String>{};
      for (final config in configs) {
        providerNames[config.providerId] = config.displayName;
      }

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _providerNames = providerNames;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load conversations';
        });
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showRenameDialog(ChatConversation conv) async {
    final controller = TextEditingController(text: conv.title);
    String? errorText;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rename Conversation'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter title',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 80,
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final title = controller.text.trim();
                          if (title.isEmpty) {
                            setDialogState(() {
                              errorText = 'Title cannot be empty';
                            });
                            return;
                          }
                          if (title.length > 80) {
                            setDialogState(() {
                              errorText = 'Title is too long';
                            });
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            final success =
                                await widget.historyStore.renameConversation(
                              conversationId: conv.id,
                              title: title,
                            );
                            if (success && context.mounted) {
                              Navigator.pop(context, true);
                            } else if (!success) {
                              setDialogState(() {
                                saving = false;
                                errorText = 'Failed to rename conversation';
                              });
                            }
                          } catch (_) {
                            setDialogState(() {
                              saving = false;
                              errorText = 'Failed to rename conversation';
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _showDeleteDialog(ChatConversation conv) async {
    final isActive = conv.id == widget.currentConversationId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text('Delete this conversation and all its messages?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = await widget.historyStore.deleteConversation(conv.id);
      if (!mounted) return;

      if (success) {
        if (isActive) {
          Navigator.pop(
            context,
            const ConversationListResult.activeConversationDeleted(),
          );
        } else {
          await _loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete conversation')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete conversation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final isSelected =
                            conv.id == widget.currentConversationId;
                        final providerName =
                            _providerNames[conv.providerId] ?? conv.providerId;

                        return ListTile(
                          selected: isSelected,
                          leading: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '$providerName · ${conv.model}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(conv.updatedAt),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showRenameDialog(conv);
                                  } else if (value == 'delete') {
                                    _showDeleteDialog(conv);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(
                              context,
                              ConversationListResult.selected(conv.id),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
