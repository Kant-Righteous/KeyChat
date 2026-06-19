import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';

class FakeChatHistoryStore implements ChatHistoryStore {
  final Map<String, ChatConversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  String? latestConversationId;
  bool shouldFailOnAppend = false;
  bool shouldFailOnCreate = false;

  void reset() {
    _conversations.clear();
    _messages.clear();
    latestConversationId = null;
    shouldFailOnAppend = false;
    shouldFailOnCreate = false;
  }

  @override
  Future<ChatConversation?> readLatestConversation() async {
    if (latestConversationId == null) return null;
    return _conversations[latestConversationId];
  }

  @override
  Future<List<ChatMessage>> readMessages(String conversationId) async {
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
    }
  }
}
