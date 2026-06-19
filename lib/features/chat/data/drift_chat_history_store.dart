import 'package:drift/drift.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart'
    as domain;
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

class DriftChatHistoryStore implements ChatHistoryStore {
  final AppDatabase _db;

  DriftChatHistoryStore(this._db);

  @override
  Future<ChatConversation?> readLatestConversation() async {
    final query = _db.select(_db.conversations)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toConversation(row);
  }

  @override
  Future<List<domain.ChatMessage>> readMessages(String conversationId) async {
    final query = _db.select(_db.chatMessages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    final rows = await query.get();
    return rows.map(_toMessage).toList();
  }

  @override
  Future<void> createConversationWithFirstMessage({
    required ChatConversation conversation,
    required domain.ChatMessage firstMessage,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.conversations).insert(
            ConversationsCompanion(
              id: Value(conversation.id),
              title: Value(conversation.title),
              providerId: Value(conversation.providerId),
              model: Value(conversation.model),
              createdAt: Value(conversation.createdAt),
              updatedAt: Value(conversation.updatedAt),
            ),
          );
      await _db.into(_db.chatMessages).insert(
            ChatMessagesCompanion(
              id: Value(firstMessage.id),
              conversationId: Value(conversation.id),
              role: Value(
                  firstMessage.role == domain.ChatRole.user ? 'user' : 'assistant'),
              content: Value(firstMessage.content),
              createdAt: Value(firstMessage.createdAt),
            ),
          );
    });
  }

  @override
  Future<void> appendMessage({
    required String conversationId,
    required domain.ChatMessage message,
  }) async {
    await _db.into(_db.chatMessages).insert(
          ChatMessagesCompanion(
            id: Value(message.id),
            conversationId: Value(conversationId),
            role:
                Value(message.role == domain.ChatRole.user ? 'user' : 'assistant'),
            content: Value(message.content),
            createdAt: Value(message.createdAt),
          ),
        );
  }

  @override
  Future<void> updateConversationActivity({
    required String conversationId,
    required DateTime updatedAt,
  }) async {
    await (_db.update(_db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationsCompanion(
      updatedAt: Value(updatedAt),
    ));
  }

  ChatConversation _toConversation(Conversation row) {
    return ChatConversation(
      id: row.id,
      title: row.title,
      providerId: row.providerId,
      model: row.model,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  domain.ChatMessage _toMessage(ChatMessage row) {
    return domain.ChatMessage(
      id: row.id,
      role: row.role == 'user' ? domain.ChatRole.user : domain.ChatRole.assistant,
      content: row.content,
      createdAt: row.createdAt,
    );
  }
}
