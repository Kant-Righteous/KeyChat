import 'package:keychat/features/chat/data/chat_completion_client.dart';

final class ChatContextBuildResult {
  const ChatContextBuildResult({
    required this.messages,
    required this.estimatedTokens,
    required this.omittedMessageCount,
    required this.omittedTurnCount,
    required this.currentMessageExceedsBudget,
  });

  final List<ChatRequestMessage> messages;
  final int estimatedTokens;
  final int omittedMessageCount;
  final int omittedTurnCount;
  final bool currentMessageExceedsBudget;

  bool get wasTrimmed => omittedMessageCount > 0;
}

int estimateTokens(String text) {
  if (text.isEmpty) return 0;
  int asciiCount = 0;
  int nonAsciiCount = 0;
  for (final rune in text.runes) {
    if (rune < 128) {
      asciiCount++;
    } else {
      nonAsciiCount++;
    }
  }
  return (asciiCount / 4).ceil() + nonAsciiCount;
}

int estimateMessageTokens(ChatRequestMessage message) {
  return estimateTokens(message.content) + 4;
}

final class _Turn {
  final List<ChatRequestMessage> messages;
  final int tokenEstimate;

  _Turn({required this.messages, required this.tokenEstimate});
}

final class ChatContextBuilder {
  const ChatContextBuilder({
    this.maxEstimatedTokens = 12000,
  });

  final int maxEstimatedTokens;

  ChatContextBuildResult build({
    required List<ChatRequestMessage> history,
    required ChatRequestMessage currentUserMessage,
  }) {
    final currentTokens = estimateMessageTokens(currentUserMessage);
    final currentExceeds = currentTokens > maxEstimatedTokens;

    if (currentExceeds) {
      return ChatContextBuildResult(
        messages: [currentUserMessage],
        estimatedTokens: currentTokens,
        omittedMessageCount: history.length,
        omittedTurnCount: _countTurns(history),
        currentMessageExceedsBudget: true,
      );
    }

    if (history.isEmpty) {
      return ChatContextBuildResult(
        messages: [currentUserMessage],
        estimatedTokens: currentTokens,
        omittedMessageCount: 0,
        omittedTurnCount: 0,
        currentMessageExceedsBudget: false,
      );
    }

    final turns = _buildTurns(history);
    final selectedTurns = <_Turn>[];
    int usedTokens = currentTokens;

    for (int i = turns.length - 1; i >= 0; i--) {
      final turn = turns[i];
      if (usedTokens + turn.tokenEstimate <= maxEstimatedTokens) {
        selectedTurns.insert(0, turn);
        usedTokens += turn.tokenEstimate;
      } else {
        break;
      }
    }

    final resultMessages = <ChatRequestMessage>[];
    for (final turn in selectedTurns) {
      resultMessages.addAll(turn.messages);
    }
    resultMessages.add(currentUserMessage);

    int omittedMessages = 0;
    int omittedTurns = 0;
    for (final turn in turns) {
      if (!selectedTurns.contains(turn)) {
        omittedMessages += turn.messages.length;
        omittedTurns++;
      }
    }

    return ChatContextBuildResult(
      messages: resultMessages,
      estimatedTokens: usedTokens,
      omittedMessageCount: omittedMessages,
      omittedTurnCount: omittedTurns,
      currentMessageExceedsBudget: false,
    );
  }

  List<_Turn> _buildTurns(List<ChatRequestMessage> messages) {
    final turns = <_Turn>[];
    List<ChatRequestMessage> currentTurn = [];
    int currentTokens = 0;

    for (final msg in messages) {
      if (msg.role == 'user') {
        if (currentTurn.isNotEmpty) {
          turns.add(_Turn(
            messages: List.unmodifiable(currentTurn),
            tokenEstimate: currentTokens,
          ));
        }
        currentTurn = [msg];
        currentTokens = estimateMessageTokens(msg);
      } else if (msg.role == 'assistant') {
        if (currentTurn.isEmpty) {
          continue;
        }
        currentTurn.add(msg);
        currentTokens += estimateMessageTokens(msg);
      } else {
        continue;
      }
    }

    if (currentTurn.isNotEmpty) {
      turns.add(_Turn(
        messages: List.unmodifiable(currentTurn),
        tokenEstimate: currentTokens,
      ));
    }

    return turns;
  }

  int _countTurns(List<ChatRequestMessage> messages) {
    int count = 0;
    for (final msg in messages) {
      if (msg.role == 'user') count++;
    }
    return count;
  }
}
