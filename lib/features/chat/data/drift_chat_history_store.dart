import 'package:drift/drift.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart'
    as domain;
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart' as domain;
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
  Future<List<ChatConversation>> readConversations() async {
    final query = _db.select(_db.conversations)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    final rows = await query.get();
    return rows.map(_toConversation).toList();
  }

  @override
  Future<ChatConversation?> readConversation(String conversationId) async {
    final query = _db.select(_db.conversations)
      ..where((t) => t.id.equals(conversationId))
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
    final attachmentQuery = _db.select(_db.chatAttachments)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    final attachmentRows = await attachmentQuery.get();
    final attachmentsByMessage = <String, List<domain.ChatAttachment>>{};
    for (final row in attachmentRows) {
      attachmentsByMessage
          .putIfAbsent(row.messageId, () => [])
          .add(_toAttachment(row));
    }
    return rows
        .map((row) => _toMessage(
              row,
              attachmentsByMessage[row.id] ?? const [],
            ))
        .toList();
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
              agentId: Value(conversation.agentId),
              agentNameSnapshot: Value(conversation.agentNameSnapshot),
              systemPromptSnapshot: Value(conversation.systemPromptSnapshot),
              createdAt: Value(conversation.createdAt),
              updatedAt: Value(conversation.updatedAt),
            ),
          );
      await _db.into(_db.chatMessages).insert(
            ChatMessagesCompanion(
              id: Value(firstMessage.id),
              conversationId: Value(conversation.id),
              role: Value(firstMessage.role == domain.ChatRole.user
                  ? 'user'
                  : 'assistant'),
              content: Value(firstMessage.content),
              providerIdSnapshot: Value(firstMessage.providerIdSnapshot),
              providerNameSnapshot: Value(firstMessage.providerNameSnapshot),
              modelIdSnapshot: Value(firstMessage.modelIdSnapshot),
              createdAt: Value(firstMessage.createdAt),
            ),
          );
      await _insertAttachments(firstMessage.attachments);
    });
  }

  @override
  Future<void> appendMessage({
    required String conversationId,
    required domain.ChatMessage message,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.chatMessages).insert(
            ChatMessagesCompanion(
              id: Value(message.id),
              conversationId: Value(conversationId),
              role: Value(
                  message.role == domain.ChatRole.user ? 'user' : 'assistant'),
              content: Value(message.content),
              providerIdSnapshot: Value(message.providerIdSnapshot),
              providerNameSnapshot: Value(message.providerNameSnapshot),
              modelIdSnapshot: Value(message.modelIdSnapshot),
              createdAt: Value(message.createdAt),
            ),
          );
      await _insertAttachments(message.attachments);
    });
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

  @override
  Future<bool> renameConversation({
    required String conversationId,
    required String title,
  }) async {
    final trimmed = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 80) return false;

    final existing = await readConversation(conversationId);
    if (existing == null) return false;

    await (_db.update(_db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationsCompanion(
      title: Value(trimmed),
    ));
    return true;
  }

  @override
  Future<bool> deleteConversation(String conversationId) async {
    final existing = await readConversation(conversationId);
    if (existing == null) return false;

    await (_db.delete(_db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .go();
    return true;
  }

  @override
  Future<void> replaceAssistantMessage({
    required String conversationId,
    required String messageId,
    required String content,
    String? providerIdSnapshot,
    String? providerNameSnapshot,
    String? modelIdSnapshot,
    required DateTime conversationUpdatedAt,
  }) async {
    await _db.transaction(() async {
      // Verify message exists and belongs to conversation
      final query = _db.select(_db.chatMessages)
        ..where((t) => t.id.equals(messageId))
        ..where((t) => t.conversationId.equals(conversationId))
        ..limit(1);
      final row = await query.getSingleOrNull();
      if (row == null) {
        throw StateError(
            'Message $messageId not found in conversation $conversationId');
      }
      if (row.role != 'assistant') {
        throw StateError('Message $messageId is not an assistant message');
      }

      // Update message content
      await (_db.update(_db.chatMessages)..where((t) => t.id.equals(messageId)))
          .write(ChatMessagesCompanion(
        content: Value(content),
        providerIdSnapshot: providerIdSnapshot == null
            ? const Value.absent()
            : Value(providerIdSnapshot),
        providerNameSnapshot: providerNameSnapshot == null
            ? const Value.absent()
            : Value(providerNameSnapshot),
        modelIdSnapshot: modelIdSnapshot == null
            ? const Value.absent()
            : Value(modelIdSnapshot),
      ));

      // Update conversation timestamp
      await (_db.update(_db.conversations)
            ..where((t) => t.id.equals(conversationId)))
          .write(ConversationsCompanion(
        updatedAt: Value(conversationUpdatedAt),
      ));
    });
  }

  ChatConversation _toConversation(Conversation row) {
    return ChatConversation(
      id: row.id,
      title: row.title,
      providerId: row.providerId,
      model: row.model,
      agentId: row.agentId,
      agentNameSnapshot: row.agentNameSnapshot,
      systemPromptSnapshot: row.systemPromptSnapshot,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  domain.ChatMessage _toMessage(
    ChatMessage row,
    List<domain.ChatAttachment> attachments,
  ) {
    return domain.ChatMessage(
      id: row.id,
      role:
          row.role == 'user' ? domain.ChatRole.user : domain.ChatRole.assistant,
      content: row.content,
      providerIdSnapshot: row.providerIdSnapshot,
      providerNameSnapshot: row.providerNameSnapshot,
      modelIdSnapshot: row.modelIdSnapshot,
      attachments: attachments,
      createdAt: row.createdAt,
    );
  }

  Future<void> _insertAttachments(
    List<domain.ChatAttachment> attachments,
  ) async {
    for (final attachment in attachments) {
      await _db.into(_db.chatAttachments).insert(
            ChatAttachmentsCompanion(
              id: Value(attachment.id),
              fileName: Value(attachment.fileName),
              mimeType: Value(attachment.mimeType),
              fileSize: Value(attachment.fileSize),
              localPath: Value(attachment.localPath),
              kind: Value(attachment.kind.storageValue),
              messageId: Value(attachment.messageId),
              conversationId: Value(attachment.conversationId),
            ),
          );
    }
  }

  domain.ChatAttachment _toAttachment(ChatAttachment row) {
    return domain.ChatAttachment(
      id: row.id,
      fileName: row.fileName,
      mimeType: row.mimeType,
      fileSize: row.fileSize,
      localPath: row.localPath,
      kind: domain.ChatAttachmentKind.fromStorageValue(row.kind),
      messageId: row.messageId,
      conversationId: row.conversationId,
    );
  }
}
