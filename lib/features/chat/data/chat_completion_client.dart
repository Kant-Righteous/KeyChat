enum ChatRole {
  user,
  assistant,
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
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

abstract interface class ChatCompletionClient {
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    dynamic cancelToken,
  });
}
