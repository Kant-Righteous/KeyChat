import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';

class FakeChatHistoryStore implements ChatHistoryStore {
  final Map<String, ChatConversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  String? latestConversationId;
  bool shouldFailOnAppend = false;
  bool shouldFailOnCreate = false;
  bool shouldFailOnRead = false;
  bool shouldFailOnReplace = false;
  Object? replaceAssistantMessageError;

  int replaceCallCount = 0;
  String? lastReplaceConversationId;
  String? lastReplacedMessageId;
  String? lastReplacedContent;
  DateTime? lastReplaceConversationUpdatedAt;

  void reset() {
    _conversations.clear();
    _messages.clear();
    latestConversationId = null;
    shouldFailOnAppend = false;
    shouldFailOnCreate = false;
    shouldFailOnRead = false;
    shouldFailOnReplace = false;
    replaceAssistantMessageError = null;
    replaceCallCount = 0;
    lastReplaceConversationId = null;
    lastReplacedMessageId = null;
    lastReplacedContent = null;
    lastReplaceConversationUpdatedAt = null;
  }

  @override
  Future<ChatConversation?> readLatestConversation() async {
    if (latestConversationId == null) return null;
    return _conversations[latestConversationId];
  }

  @override
  Future<List<ChatConversation>> readConversations() async {
    if (shouldFailOnRead) {
      throw Exception('Database failure');
    }
    final list = _conversations.values.toList();
    list.sort((a, b) {
      final cmp = b.updatedAt.compareTo(a.updatedAt);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });
    return list;
  }

  @override
  Future<ChatConversation?> readConversation(String conversationId) async {
    if (shouldFailOnRead) {
      throw Exception('Database failure');
    }
    return _conversations[conversationId];
  }

  @override
  Future<List<ChatMessage>> readMessages(String conversationId) async {
    if (shouldFailOnRead) {
      throw Exception('Database failure');
    }
    return _messages[conversationId] ?? [];
  }

  @override
  Future<void> createConversationWithFirstMessage({
    required ChatConversation conversation,
    required ChatMessage firstMessage,
  }) async {
    if (shouldFailOnCreate) {
      throw Exception('Database failure');
    }
    _conversations[conversation.id] = conversation;
    _messages[conversation.id] = [firstMessage];
    latestConversationId = conversation.id;
  }

  @override
  Future<void> appendMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {
    if (shouldFailOnAppend) {
      throw Exception('Database failure');
    }
    _messages[conversationId] ??= [];
    _messages[conversationId]!.add(message);
  }

  @override
  Future<void> updateConversationActivity({
    required String conversationId,
    required DateTime updatedAt,
  }) async {
    final conv = _conversations[conversationId];
    if (conv != null) {
      _conversations[conversationId] = ChatConversation(
        id: conv.id,
        title: conv.title,
        providerId: conv.providerId,
        model: conv.model,
        createdAt: conv.createdAt,
        updatedAt: updatedAt,
      );
      latestConversationId = conversationId;
    }
  }

  @override
  Future<bool> renameConversation({
    required String conversationId,
    required String title,
  }) async {
    final trimmed = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 80) return false;

    final conv = _conversations[conversationId];
    if (conv == null) return false;

    _conversations[conversationId] = ChatConversation(
      id: conv.id,
      title: trimmed,
      providerId: conv.providerId,
      model: conv.model,
      createdAt: conv.createdAt,
      updatedAt: conv.updatedAt,
    );
    return true;
  }

  @override
  Future<bool> deleteConversation(String conversationId) async {
    if (!_conversations.containsKey(conversationId)) return false;
    _conversations.remove(conversationId);
    _messages.remove(conversationId);
    if (latestConversationId == conversationId) {
      latestConversationId = null;
    }
    return true;
  }

  @override
  Future<void> replaceAssistantMessage({
    required String conversationId,
    required String messageId,
    required String content,
    required DateTime conversationUpdatedAt,
  }) async {
    // Record call parameters before any failure
    replaceCallCount++;
    lastReplaceConversationId = conversationId;
    lastReplacedMessageId = messageId;
    lastReplacedContent = content;
    lastReplaceConversationUpdatedAt = conversationUpdatedAt;

    if (replaceAssistantMessageError != null) {
      throw replaceAssistantMessageError!;
    }
    if (shouldFailOnReplace) {
      throw Exception('Replace failure');
    }

    final msgs = _messages[conversationId];
    if (msgs == null) {
      throw StateError('Conversation $conversationId not found');
    }

    final index = msgs.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      throw StateError('Message $messageId not found');
    }
    if (msgs[index].role != ChatRole.assistant) {
      throw StateError('Message $messageId is not assistant');
    }

    msgs[index] = ChatMessage(
      id: messageId,
      role: ChatRole.assistant,
      content: content,
      createdAt: msgs[index].createdAt,
    );

    final conv = _conversations[conversationId];
    if (conv != null) {
      _conversations[conversationId] = ChatConversation(
        id: conv.id,
        title: conv.title,
        providerId: conv.providerId,
        model: conv.model,
        createdAt: conv.createdAt,
        updatedAt: conversationUpdatedAt,
      );
    }
  }
}
