import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/conversation_markdown_exporter.dart';

void main() {
  group('ConversationMarkdownExporter', () {
    test('exports required conversation metadata and message content', () {
      final markdown = const ConversationMarkdownExporter().export(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'Planning session',
          providerId: 'openai',
          model: 'gpt-4o-mini',
          agentId: 'agent_1',
          agentNameSnapshot: 'Researcher',
          systemPromptSnapshot: 'PRIVATE SYSTEM PROMPT',
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15, 1),
        ),
        messages: [
          ChatMessage(
            id: 'user_1',
            role: ChatRole.user,
            content: 'Summarize this topic.',
            createdAt: DateTime.utc(2026, 7, 15),
          ),
          ChatMessage(
            id: 'assistant_1',
            role: ChatRole.assistant,
            content: 'Here is the summary.',
            reasoningContent: 'PRIVATE REASONING',
            providerIdSnapshot: 'openai',
            providerNameSnapshot: 'OpenAI',
            modelIdSnapshot: 'gpt-4.1',
            createdAt: DateTime.utc(2026, 7, 15, 0, 1),
          ),
        ],
        exportedAt: DateTime.utc(2026, 7, 15, 8, 30),
      );

      expect(markdown, contains('# Planning session'));
      expect(markdown, contains('2026-07-15T08:30:00.000Z'));
      expect(markdown, contains('Agent: Researcher'));
      expect(markdown, contains('Messages: 2'));
      expect(markdown, contains('## User'));
      expect(markdown, contains('Summarize this topic.'));
      expect(markdown, contains('## Assistant'));
      expect(markdown, contains('Provider: OpenAI'));
      expect(markdown, contains('Model: gpt-4.1'));
      expect(markdown, contains('Here is the summary.'));
      expect(markdown, isNot(contains('PRIVATE SYSTEM PROMPT')));
      expect(markdown, isNot(contains('PRIVATE REASONING')));
    });

    test('redacts sensitive configuration-like content', () {
      final markdown = const ConversationMarkdownExporter().export(
        conversation: ChatConversation(
          id: 'conv_1',
          title: 'API Key: sk-title-secret-123456',
          providerId: 'openai',
          model: 'gpt-4',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        messages: [
          ChatMessage(
            id: 'user_1',
            role: ChatRole.user,
            content: 'API Key: sk-secret-value-123456\n'
                'Base URL: https://private.example/v1\n'
                'Authorization: Bearer hidden-token-value\n'
                'Keep this safe sentence.',
            createdAt: DateTime.utc(2026),
          ),
        ],
        exportedAt: DateTime.utc(2026),
      );

      expect(markdown, isNot(contains('sk-secret-value-123456')));
      expect(markdown, isNot(contains('sk-title-secret-123456')));
      expect(markdown, isNot(contains('https://private.example/v1')));
      expect(markdown, isNot(contains('hidden-token-value')));
      expect(markdown, contains('[Sensitive data removed]'));
      expect(markdown, contains('Keep this safe sentence.'));
    });
  });
}
