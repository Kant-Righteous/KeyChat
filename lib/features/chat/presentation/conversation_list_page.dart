import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keychat/l10n/generated/app_localizations.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/conversation_markdown_exporter.dart';
import 'package:keychat/features/chat/domain/conversation_list_result.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:share_plus/share_plus.dart';

typedef ConversationMarkdownShare = Future<void> Function(
  String markdown,
  String title,
  Rect sharePositionOrigin,
);
typedef ConversationMarkdownCopy = Future<void> Function(String markdown);

class ConversationListPage extends StatefulWidget {
  final ChatHistoryStore historyStore;
  final ProviderConfigStore configStore;
  final String? currentConversationId;
  final ConversationMarkdownShare? shareMarkdown;
  final ConversationMarkdownCopy? copyMarkdown;
  final DateTime Function() now;

  const ConversationListPage({
    super.key,
    required this.historyStore,
    required this.configStore,
    this.currentConversationId,
    this.shareMarkdown,
    this.copyMarkdown,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  List<ChatConversation> _conversations = [];
  Map<String, String> _providerNames = {};
  bool _loading = true;
  String? _error;
  static const _markdownExporter = ConversationMarkdownExporter();

  _ConversationListStrings get _strings =>
      _ConversationListStrings(AppLocalizations.of(context));

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
    final localDateTime = dt.toLocal();
    final now = widget.now().toLocal();
    if (localDateTime.year == now.year &&
        localDateTime.month == now.month &&
        localDateTime.day == now.day) {
      return '${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showRenameDialog(ChatConversation conv) async {
    final strings = _strings;
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
              title: Text(strings.renameConversation),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: strings.enterTitle,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.pop(context, false),
                  child: Text(strings.cancel),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final title = controller.text.trim();
                          if (title.isEmpty) {
                            setDialogState(() {
                              errorText = strings.titleRequired;
                            });
                            return;
                          }
                          if (title.length > 80) {
                            setDialogState(() {
                              errorText = strings.titleTooLong;
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
                                errorText = strings.renameConversationFailed;
                              });
                            }
                          } catch (_) {
                            setDialogState(() {
                              saving = false;
                              errorText = strings.renameConversationFailed;
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.save),
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
    final strings = _strings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteConversation),
          content: Text(strings.deleteConversationConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(strings.delete),
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
            SnackBar(content: Text(_strings.deleteConversationFailed)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_strings.deleteConversationFailed)),
        );
      }
    }
  }

  Future<String?> _exportMarkdown(ChatConversation selectedConversation) async {
    try {
      final conversation =
          await widget.historyStore.readConversation(selectedConversation.id);
      if (conversation == null) throw StateError('Conversation not found');

      final messages =
          await widget.historyStore.readMessages(selectedConversation.id);
      if (messages.isEmpty) {
        if (mounted) _showSnackBar(_strings.conversationEmpty);
        return null;
      }

      return _markdownExporter.export(
        conversation: conversation,
        messages: messages,
        exportedAt: widget.now(),
      );
    } catch (_) {
      if (mounted) _showSnackBar(_strings.exportFailed);
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyAsMarkdown(ChatConversation conversation) async {
    final markdown = await _exportMarkdown(conversation);
    if (markdown == null || !mounted) return;

    try {
      final copy = widget.copyMarkdown ?? _copyWithPlatform;
      await copy(markdown);
      if (mounted) _showSnackBar(_strings.copiedAsMarkdown);
    } catch (_) {
      if (mounted) _showSnackBar(_strings.exportFailed);
    }
  }

  static Future<void> _copyWithPlatform(String markdown) {
    return Clipboard.setData(ClipboardData(text: markdown));
  }

  Future<void> _shareAsMarkdown(
    ChatConversation conversation,
    Rect sharePositionOrigin,
  ) async {
    final markdown = await _exportMarkdown(conversation);
    if (markdown == null || !mounted) return;

    try {
      final share = widget.shareMarkdown ?? _shareWithPlatform;
      await share(markdown, conversation.title, sharePositionOrigin);
    } catch (_) {
      if (mounted) _showSnackBar(_strings.exportFailed);
    }
  }

  static Future<void> _shareWithPlatform(
    String markdown,
    String title,
    Rect sharePositionOrigin,
  ) async {
    await Share.share(
      markdown,
      subject: title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Rect _sharePositionOrigin(BuildContext anchorContext) {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const Rect.fromLTWH(0, 0, 1, 1);
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _showExportMenu(ChatConversation conversation) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final strings = _ConversationListStrings(
          AppLocalizations.of(sheetContext),
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.exportConversation,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              ListTile(
                key: const Key('copy_conversation_markdown'),
                leading: const Icon(Icons.copy_all_outlined),
                title: Text(strings.copyAsMarkdown),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyAsMarkdown(conversation);
                },
              ),
              Builder(
                builder: (anchorContext) => ListTile(
                  key: const Key('share_conversation_markdown'),
                  leading: const Icon(Icons.share_outlined),
                  title: Text(strings.shareMarkdown),
                  onTap: () {
                    final origin = _sharePositionOrigin(anchorContext);
                    Navigator.pop(sheetContext);
                    _shareAsMarkdown(conversation, origin);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.conversations),
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
                  ? Center(
                      child: Text(
                        strings.noConversations,
                        style: TextStyle(color: Colors.grey.shade700),
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
                                  } else if (value == 'export') {
                                    _showExportMenu(conv);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text(strings.rename),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(strings.delete),
                                  ),
                                  PopupMenuItem(
                                    value: 'export',
                                    child: Text(strings.exportConversation),
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

class _ConversationListStrings {
  const _ConversationListStrings(this.l10n);

  final AppLocalizations? l10n;

  String get conversations => l10n?.conversations ?? 'Conversations';
  String get noConversations => l10n?.noConversations ?? 'No conversations yet';
  String get rename => l10n?.rename ?? 'Rename';
  String get renameConversation =>
      l10n?.renameConversation ?? 'Rename Conversation';
  String get enterTitle => l10n?.enterTitle ?? 'Enter title';
  String get titleRequired => l10n?.titleRequired ?? 'Title cannot be empty';
  String get titleTooLong => l10n?.titleTooLong ?? 'Title is too long';
  String get renameConversationFailed =>
      l10n?.renameConversationFailed ?? 'Failed to rename conversation';
  String get deleteConversation =>
      l10n?.deleteConversation ?? 'Delete Conversation';
  String get deleteConversationConfirm =>
      l10n?.deleteConversationConfirm ??
      'Delete this conversation and all its messages?';
  String get deleteConversationFailed =>
      l10n?.deleteConversationFailed ?? 'Failed to delete conversation';
  String get exportConversation =>
      l10n?.exportConversation ?? 'Export conversation';
  String get copyAsMarkdown => l10n?.copyAsMarkdown ?? 'Copy as Markdown';
  String get shareMarkdown => l10n?.shareMarkdown ?? 'Share Markdown';
  String get copiedAsMarkdown => l10n?.copiedAsMarkdown ?? 'Copied as Markdown';
  String get conversationEmpty =>
      l10n?.conversationEmpty ?? 'Conversation is empty';
  String get exportFailed => l10n?.exportFailed ?? 'Export failed';
  String get save => l10n?.save ?? 'Save';
  String get cancel => l10n?.cancel ?? 'Cancel';
  String get delete => l10n?.delete ?? 'Delete';
}
