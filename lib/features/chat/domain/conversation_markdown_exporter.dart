import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';

class ConversationMarkdownExporter {
  const ConversationMarkdownExporter();

  String export({
    required ChatConversation conversation,
    required List<ChatMessage> messages,
    required DateTime exportedAt,
  }) {
    final exportableMessages = messages
        .where((message) =>
            message.role == ChatRole.user || message.role == ChatRole.assistant)
        .toList(growable: false);
    final buffer = StringBuffer()
      ..writeln(
        '# ${_escapeHeading(_redactSensitiveContent(conversation.title))}',
      )
      ..writeln()
      ..writeln('- Exported at: ${exportedAt.toIso8601String()}')
      ..writeln('- Agent: ${_agentName(conversation)}')
      ..writeln('- Messages: ${exportableMessages.length}');

    for (final message in exportableMessages) {
      buffer
        ..writeln()
        ..writeln(message.role == ChatRole.user ? '## User' : '## Assistant')
        ..writeln();

      if (message.role == ChatRole.assistant) {
        final provider = _firstNonEmpty([
          message.providerNameSnapshot,
          message.providerIdSnapshot,
          conversation.providerId,
        ]);
        final model = _firstNonEmpty([
          message.modelIdSnapshot,
          conversation.model,
        ]);
        buffer
          ..writeln('- Provider: $provider')
          ..writeln('- Model: $model')
          ..writeln();
      }

      buffer.writeln(_redactSensitiveContent(message.content));
    }

    return buffer.toString().trimRight();
  }

  String _agentName(ChatConversation conversation) {
    final name = conversation.agentNameSnapshot?.trim();
    return name == null || name.isEmpty
        ? 'No Agent'
        : _redactSensitiveContent(name);
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return _redactSensitiveContent(trimmed);
      }
    }
    return 'Unknown';
  }

  String _escapeHeading(String value) {
    final title = value.trim().isEmpty ? 'Untitled conversation' : value.trim();
    return title.replaceAll(RegExp(r'([\\`*_{}\[\]()#+.!|>-])'), r'\$1');
  }

  String _redactSensitiveContent(String value) {
    var redacted = value.replaceAll(
      RegExp(
        r'^[ \t]*(?:api[ _-]?key|base[ _-]?url|authorization)[ \t]*[:=][^\r\n]*',
        caseSensitive: false,
        multiLine: true,
      ),
      '[Sensitive data removed]',
    );
    redacted = redacted.replaceAll(
      RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]{8,}', caseSensitive: false),
      'Bearer [Sensitive data removed]',
    );
    redacted = redacted.replaceAll(
      RegExp(r'\bsk-[A-Za-z0-9_-]{8,}\b', caseSensitive: false),
      '[Sensitive data removed]',
    );
    return redacted;
  }
}
