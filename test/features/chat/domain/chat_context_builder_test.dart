import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_context_builder.dart';

void main() {
  group('estimateTokens', () {
    test('empty string returns 0', () {
      expect(estimateTokens(''), 0);
    });

    test('ASCII characters estimated at 4 chars per token', () {
      expect(estimateTokens('abcd'), 1);
      expect(estimateTokens('abcdefgh'), 2);
      expect(estimateTokens('abcde'), 2);
    });

    test('non-ASCII characters estimated at 1 token each', () {
      expect(estimateTokens('中文'), 2);
      expect(estimateTokens('你好世界'), 4);
    });

    test('emoji estimated by rune count', () {
      expect(estimateTokens('😀'), 1);
      expect(estimateTokens('😀😁'), 2);
    });

    test('mixed ASCII and non-ASCII', () {
      expect(estimateTokens('hi你好'), 1 + 2);
    });
  });

  group('estimateMessageTokens', () {
    test('adds 4 overhead per message', () {
      expect(
          estimateMessageTokens(
              const ChatRequestMessage(role: 'user', content: '')),
          4);
    });

    test('ASCII content plus overhead', () {
      expect(
          estimateMessageTokens(
              const ChatRequestMessage(role: 'user', content: 'abcd')),
          5);
    });

    test('Chinese content plus overhead', () {
      expect(
          estimateMessageTokens(
              const ChatRequestMessage(role: 'user', content: '你好')),
          6);
    });
  });

  group('ChatContextBuilder', () {
    test('empty history returns only current user message', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 100);
      const current = ChatRequestMessage(role: 'user', content: 'Hello');

      final result = builder.build(history: [], currentUserMessage: current);

      expect(result.messages.length, 1);
      expect(result.messages[0].content, 'Hello');
      expect(result.messages[0].role, 'user');
      expect(result.omittedMessageCount, 0);
      expect(result.omittedTurnCount, 0);
      expect(result.currentMessageExceedsBudget, false);
      expect(result.wasTrimmed, false);
    });

    test('current user is always last message', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q2');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.last.role, 'user');
      expect(result.messages.last.content, 'Q2');
    });

    test('current user not duplicated', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q2');

      final result =
          builder.build(history: history, currentUserMessage: current);

      final userMessages =
          result.messages.where((m) => m.role == 'user').toList();
      expect(userMessages.last.content, 'Q2');
      expect(userMessages.where((m) => m.content == 'Q2').length, 1);
    });

    test('all messages within budget are kept', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
        const ChatRequestMessage(role: 'user', content: 'Q2'),
        const ChatRequestMessage(role: 'assistant', content: 'A2'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q3');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.length, 5);
      expect(result.omittedMessageCount, 0);
      expect(result.wasTrimmed, false);
    });

    test('oldest turn removed when over budget', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 20);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Old question'),
        const ChatRequestMessage(role: 'assistant', content: 'Old answer'),
        const ChatRequestMessage(role: 'user', content: 'New question'),
        const ChatRequestMessage(role: 'assistant', content: 'New answer'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Current');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.first.content, 'New question');
      expect(result.omittedMessageCount, 2);
      expect(result.omittedTurnCount, 1);
      expect(result.wasTrimmed, true);
    });

    test('multiple turns removed when over budget', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 15);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
        const ChatRequestMessage(role: 'user', content: 'Q2'),
        const ChatRequestMessage(role: 'assistant', content: 'A2'),
        const ChatRequestMessage(role: 'user', content: 'Q3'),
        const ChatRequestMessage(role: 'assistant', content: 'A3'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.omittedMessageCount, greaterThanOrEqualTo(2));
      expect(result.wasTrimmed, true);
      expect(result.messages.last.content, 'Now');
    });

    test('most recent turn preserved', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 20);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Old'),
        const ChatRequestMessage(role: 'assistant', content: 'Old reply'),
        const ChatRequestMessage(role: 'user', content: 'Recent'),
        const ChatRequestMessage(role: 'assistant', content: 'Recent reply'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final result =
          builder.build(history: history, currentUserMessage: current);

      final contents = result.messages.map((m) => m.content).toList();
      expect(contents, contains('Recent'));
      expect(contents, contains('Recent reply'));
    });

    test('output in chronological order', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
        const ChatRequestMessage(role: 'user', content: 'Q2'),
        const ChatRequestMessage(role: 'assistant', content: 'A2'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q3');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages[0].content, 'Q1');
      expect(result.messages[1].content, 'A1');
      expect(result.messages[2].content, 'Q2');
      expect(result.messages[3].content, 'A2');
      expect(result.messages[4].content, 'Q3');
    });

    test('input list not modified', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 15);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Old'),
        const ChatRequestMessage(role: 'assistant', content: 'Old reply'),
        const ChatRequestMessage(role: 'user', content: 'New'),
        const ChatRequestMessage(role: 'assistant', content: 'New reply'),
      ];
      final originalLength = history.length;

      builder.build(
        history: history,
        currentUserMessage:
            const ChatRequestMessage(role: 'user', content: 'Now'),
      );

      expect(history.length, originalLength);
    });

    test('message content not modified', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Original'),
      ];

      builder.build(
        history: history,
        currentUserMessage:
            const ChatRequestMessage(role: 'user', content: 'Now'),
      );

      expect(history[0].content, 'Original');
    });

    test('long messages not truncated', () {
      const longContent =
          'This is a very long message that should not be truncated';
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q'),
        const ChatRequestMessage(role: 'assistant', content: longContent),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.any((m) => m.content == longContent), true);
    });

    test('no duplicate messages', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q2');

      final result =
          builder.build(history: history, currentUserMessage: current);

      final ids = result.messages.map((m) => '${m.role}:${m.content}').toList();
      expect(ids.toSet().length, ids.length);
    });

    test('user+assistant kept as complete turn', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q2');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages[0].role, 'user');
      expect(result.messages[0].content, 'Q1');
      expect(result.messages[1].role, 'assistant');
      expect(result.messages[1].content, 'A1');
    });

    test('assistant-only turn excluded', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'assistant', content: 'Orphan'),
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q2');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.any((m) => m.content == 'Orphan'), false);
    });

    test('consecutive user messages handled', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'user', content: 'Q2'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q3');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.length, 3);
    });

    test('unknown role excluded', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'system', content: 'Sys'),
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Q2');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.any((m) => m.role == 'system'), false);
    });

    test('current message exceeds budget still included', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 5);
      const current = ChatRequestMessage(
          role: 'user', content: 'This message is way too long for the budget');

      final result = builder.build(history: [], currentUserMessage: current);

      expect(result.messages.length, 1);
      expect(result.messages[0].content,
          'This message is way too long for the budget');
      expect(result.currentMessageExceedsBudget, true);
    });

    test('current message exceeds budget history all omitted', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 5);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q1'),
        const ChatRequestMessage(role: 'assistant', content: 'A1'),
      ];
      const current = ChatRequestMessage(
          role: 'user', content: 'This message is way too long for the budget');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.messages.length, 1);
      expect(result.omittedMessageCount, 2);
      expect(result.currentMessageExceedsBudget, true);
    });

    test('currentMessageExceedsBudget correct', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      const current = ChatRequestMessage(role: 'user', content: 'Short');

      final result = builder.build(history: [], currentUserMessage: current);

      expect(result.currentMessageExceedsBudget, false);
    });

    test('omittedMessageCount correct', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 20);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Old'),
        const ChatRequestMessage(role: 'assistant', content: 'Old reply'),
        const ChatRequestMessage(role: 'user', content: 'New'),
        const ChatRequestMessage(role: 'assistant', content: 'New reply'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.omittedMessageCount, 2);
    });

    test('omittedTurnCount correct', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 20);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Old'),
        const ChatRequestMessage(role: 'assistant', content: 'Old reply'),
        const ChatRequestMessage(role: 'user', content: 'New'),
        const ChatRequestMessage(role: 'assistant', content: 'New reply'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.omittedTurnCount, 1);
    });

    test('wasTrimmed correct', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q'),
        const ChatRequestMessage(role: 'assistant', content: 'A'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final result =
          builder.build(history: history, currentUserMessage: current);

      expect(result.wasTrimmed, false);
    });

    test('same input produces same result', () {
      const builder = ChatContextBuilder(maxEstimatedTokens: 10000);
      final history = [
        const ChatRequestMessage(role: 'user', content: 'Q'),
        const ChatRequestMessage(role: 'assistant', content: 'A'),
      ];
      const current = ChatRequestMessage(role: 'user', content: 'Now');

      final r1 = builder.build(history: history, currentUserMessage: current);
      final r2 = builder.build(history: history, currentUserMessage: current);

      expect(r1.messages.length, r2.messages.length);
      expect(r1.estimatedTokens, r2.estimatedTokens);
      expect(r1.omittedMessageCount, r2.omittedMessageCount);
    });
  });
}
