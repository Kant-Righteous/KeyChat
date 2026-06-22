import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';

abstract interface class ChatHistoryStore {
  Future<ChatConversation?> readLatestConversation();
  Future<List<ChatConversation>> readConversations();
  Future<ChatConversation?> readConversation(String conversationId);
  Future<List<ChatMessage>> readMessages(String conversationId);
  Future<void> createConversationWithFirstMessage({
    required ChatConversation conversation,
    required ChatMessage firstMessage,
  });
  Future<void> appendMessage({
    required String conversationId,
    required ChatMessage message,
  });
  Future<void> updateConversationActivity({
    required String conversationId,
    required DateTime updatedAt,
  });
  Future<bool> renameConversation({
    required String conversationId,
    required String title,
  });
  Future<bool> deleteConversation(String conversationId);
  Future<void> replaceAssistantMessage({
    required String conversationId,
    required String messageId,
    required String content,
    required DateTime conversationUpdatedAt,
  });
}
