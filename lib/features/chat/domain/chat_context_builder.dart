import 'package:keychat/features/chat/data/chat_completion_client.dart';

final class ChatContextBuildResult {
  ChatContextBuildResult({
    required List<ChatRequestMessage> messages,
    required this.estimatedTokens,
    required this.omittedMessageCount,
    required this.omittedTurnCount,
    required this.currentMessageExceedsBudget,
    this.systemPromptExceedsBudget = false,
  }) : messages = List.unmodifiable(messages);

  final List<ChatRequestMessage> messages;
  final int estimatedTokens;
  final int omittedMessageCount;
  final int omittedTurnCount;
  final bool currentMessageExceedsBudget;
  final bool systemPromptExceedsBudget;

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

// omittedMessageCount: total history messages not included in the result.
// Includes messages from omitted turns, orphan assistant messages, and
// messages with unknown roles.
// omittedTurnCount: number of complete user-started turns omitted.
// Orphan assistant and unknown role messages are excluded from turns
// and counted only in omittedMessageCount.

final class ChatContextBuilder {
  ChatContextBuilder({
    this.maxEstimatedTokens = 12000,
  }) {
    if (maxEstimatedTokens <= 0) {
      throw ArgumentError.value(
        maxEstimatedTokens,
        'maxEstimatedTokens',
        'must be greater than zero',
      );
    }
  }

  final int maxEstimatedTokens;

  ChatContextBuildResult build({
    required List<ChatRequestMessage> history,
    required ChatRequestMessage currentUserMessage,
    ChatRequestMessage? systemMessage,
  }) {
    if (currentUserMessage.role != 'user') {
      throw ArgumentError(
        'currentUserMessage.role must be "user", got "${currentUserMessage.role}"',
      );
    }

    final currentTokens = estimateMessageTokens(currentUserMessage);
    final systemTokens =
        systemMessage != null ? estimateMessageTokens(systemMessage) : 0;
    final currentExceeds = currentTokens > maxEstimatedTokens;

    if (currentExceeds) {
      final messages = <ChatRequestMessage>[
        if (systemMessage != null) systemMessage,
        currentUserMessage,
      ];
      return ChatContextBuildResult(
        messages: messages,
        estimatedTokens: currentTokens + systemTokens,
        omittedMessageCount: history.length,
        omittedTurnCount: _countTurns(history),
        currentMessageExceedsBudget: true,
      );
    }

    // Check if system + current exceeds budget
    if (systemTokens + currentTokens > maxEstimatedTokens) {
      final messages = <ChatRequestMessage>[
        if (systemMessage != null) systemMessage,
        currentUserMessage,
      ];
      return ChatContextBuildResult(
        messages: messages,
        estimatedTokens: systemTokens + currentTokens,
        omittedMessageCount: history.length,
        omittedTurnCount: _countTurns(history),
        currentMessageExceedsBudget: false,
        systemPromptExceedsBudget: true,
      );
    }

    if (history.isEmpty) {
      final messages = <ChatRequestMessage>[
        if (systemMessage != null) systemMessage,
        currentUserMessage,
      ];
      return ChatContextBuildResult(
        messages: messages,
        estimatedTokens: systemTokens + currentTokens,
        omittedMessageCount: 0,
        omittedTurnCount: 0,
        currentMessageExceedsBudget: false,
      );
    }

    final turns = _buildTurns(history);
    final selectedTurns = <_Turn>[];
    int usedTokens = currentTokens + systemTokens;

    for (int i = turns.length - 1; i >= 0; i--) {
      final turn = turns[i];
      if (usedTokens + turn.tokenEstimate <= maxEstimatedTokens) {
        selectedTurns.insert(0, turn);
        usedTokens += turn.tokenEstimate;
      } else {
        break;
      }
    }

    final resultMessages = <ChatRequestMessage>[
      if (systemMessage != null) systemMessage,
    ];
    for (final turn in selectedTurns) {
      resultMessages.addAll(turn.messages);
    }
    resultMessages.add(currentUserMessage);

    // Count messages that were part of turns but not selected
    int omittedMessages = 0;
    int omittedTurns = 0;
    for (final turn in turns) {
      if (!selectedTurns.contains(turn)) {
        omittedMessages += turn.messages.length;
        omittedTurns++;
      }
    }
    // Add orphan/unknown messages excluded from turns
    final turnMessageCount =
        turns.fold<int>(0, (sum, t) => sum + t.messages.length);
    omittedMessages += history.length - turnMessageCount;

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
          // orphan assistant - excluded from turns
          continue;
        }
        currentTurn.add(msg);
        currentTokens += estimateMessageTokens(msg);
      } else {
        // unknown role - excluded from turns
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
