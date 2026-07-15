enum ChatRole {
  user,
  assistant,
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final String? reasoningContent;
  final String? providerIdSnapshot;
  final String? providerNameSnapshot;
  final String? modelIdSnapshot;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.reasoningContent,
    this.providerIdSnapshot,
    this.providerNameSnapshot,
    this.modelIdSnapshot,
    required this.createdAt,
  });
}

class ChatRequestMessage {
  final String role;
  final String content;

  const ChatRequestMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

enum ChatCompletionErrorType {
  invalidUrl,
  apiKeyRequired,
  modelRequired,
  emptyMessage,
  unauthorized,
  forbidden,
  rateLimited,
  timeout,
  networkUnavailable,
  serverError,
  invalidResponse,
  cancelled,
  unknown,
}

class ChatCompletionResult {
  final bool success;
  final String? assistantContent;
  final ChatCompletionErrorType? errorType;
  final String? userMessage;

  const ChatCompletionResult.success({
    required this.assistantContent,
  })  : success = true,
        errorType = null,
        userMessage = null;

  const ChatCompletionResult.failure({
    required this.errorType,
    required this.userMessage,
  })  : success = false,
        assistantContent = null;
}

final class ChatCancellationToken {
  bool _isCancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }

  void Function() addCancelListener(void Function() listener) {
    if (_isCancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }
}

abstract interface class ChatCompletionClient {
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  });

  Stream<ChatStreamEvent> streamComplete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  });
}

sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

final class ChatStreamDelta extends ChatStreamEvent {
  const ChatStreamDelta(this.content);

  final String content;
}

final class ChatStreamReasoningDelta extends ChatStreamEvent {
  const ChatStreamReasoningDelta(this.content);

  final String content;
}

final class ChatStreamCompleted extends ChatStreamEvent {
  const ChatStreamCompleted();
}

final class ChatStreamFailure extends ChatStreamEvent {
  const ChatStreamFailure({
    required this.errorType,
    required this.userMessage,
  });

  final ChatCompletionErrorType errorType;
  final String userMessage;
}
