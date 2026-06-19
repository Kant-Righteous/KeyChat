import 'package:dio/dio.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';

class DioChatCompletionClient implements ChatCompletionClient {
  final Dio _dio;

  DioChatCompletionClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ));

  static String buildChatUrl(String baseUrl) {
    var url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return '$url/chat/completions';
  }

  static String? parseAssistantContent(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;

    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;

    final message = first['message'];
    if (message is! Map<String, dynamic>) return null;

    final content = message['content'];
    if (content is! String) return null;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    return trimmed;
  }

  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) async {
    final trimmedUrl = baseUrl.trim();
    if (trimmedUrl.isEmpty) {
      return const ChatCompletionResult.failure(
        errorType: ChatCompletionErrorType.invalidUrl,
        userMessage: 'Invalid Base URL',
      );
    }

    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      return const ChatCompletionResult.failure(
        errorType: ChatCompletionErrorType.apiKeyRequired,
        userMessage: 'API key required',
      );
    }

    final trimmedModel = model.trim();
    if (trimmedModel.isEmpty) {
      return const ChatCompletionResult.failure(
        errorType: ChatCompletionErrorType.modelRequired,
        userMessage: 'Model required',
      );
    }

    if (messages.isEmpty) {
      return const ChatCompletionResult.failure(
        errorType: ChatCompletionErrorType.emptyMessage,
        userMessage: 'Message cannot be empty',
      );
    }

    final url = buildChatUrl(trimmedUrl);
    final dioCancelToken = CancelToken();
    void Function()? removeListener;

    if (cancellationToken != null) {
      removeListener = cancellationToken.addCancelListener(() {
        dioCancelToken.cancel('Cancelled by user');
      });
    }

    try {
      final response = await _dio.post(
        url,
        data: {
          'model': trimmedModel,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $trimmedKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        cancelToken: dioCancelToken,
      );

      if (response.statusCode == 200) {
        final content = parseAssistantContent(response.data);
        if (content == null) {
          return const ChatCompletionResult.failure(
            errorType: ChatCompletionErrorType.invalidResponse,
            userMessage: 'Invalid provider response',
          );
        }
        return ChatCompletionResult.success(assistantContent: content);
      }

      return const ChatCompletionResult.failure(
        errorType: ChatCompletionErrorType.invalidResponse,
        userMessage: 'Invalid provider response',
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.cancelled,
          userMessage: 'Request cancelled',
        );
      }
      return _mapDioError(e);
    } catch (_) {
      return const ChatCompletionResult.failure(
        errorType: ChatCompletionErrorType.unknown,
        userMessage: 'Unable to get response',
      );
    } finally {
      removeListener?.call();
    }
  }

  ChatCompletionResult _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.timeout,
          userMessage: 'Request timed out',
        );
      case DioExceptionType.connectionError:
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.networkUnavailable,
          userMessage: 'Network unavailable',
        );
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode);
      default:
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.unknown,
          userMessage: 'Unable to get response',
        );
    }
  }

  ChatCompletionResult _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 401:
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.unauthorized,
          userMessage: 'Invalid API key',
        );
      case 403:
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.forbidden,
          userMessage: 'Access forbidden',
        );
      case 429:
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.rateLimited,
          userMessage: 'Rate limit exceeded',
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const ChatCompletionResult.failure(
            errorType: ChatCompletionErrorType.serverError,
            userMessage: 'Provider server error',
          );
        }
        return const ChatCompletionResult.failure(
          errorType: ChatCompletionErrorType.invalidResponse,
          userMessage: 'Invalid provider response',
        );
    }
  }
}
