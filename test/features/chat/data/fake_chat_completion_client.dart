import 'dart:async';

import 'package:keychat/features/chat/data/chat_completion_client.dart';

class FakeChatCompletionClient implements ChatCompletionClient {
  int completeCallCount = 0;
  int streamCallCount = 0;

  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) async {
    completeCallCount++;
    return const ChatCompletionResult.failure(
      errorType: ChatCompletionErrorType.unknown,
      userMessage: 'Fake client',
    );
  }

  @override
  Stream<ChatStreamEvent> streamComplete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) {
    streamCallCount++;
    return Stream.fromIterable([
      const ChatStreamFailure(
        errorType: ChatCompletionErrorType.unknown,
        userMessage: 'Fake client',
      ),
    ]);
  }
}
