import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/openai_sse_parser.dart';

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

  @override
  Stream<ChatStreamEvent> streamComplete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) {
    final controller = StreamController<ChatStreamEvent>();

    _runStream(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      messages: messages,
      cancellationToken: cancellationToken,
      controller: controller,
    );

    return controller.stream;
  }

  Future<void> _runStream({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
    required StreamController<ChatStreamEvent> controller,
  }) async {
    final trimmedUrl = baseUrl.trim();
    if (trimmedUrl.isEmpty) {
      controller.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.invalidUrl,
        userMessage: 'Invalid Base URL',
      ));
      controller.close();
      return;
    }

    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      controller.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.apiKeyRequired,
        userMessage: 'API key required',
      ));
      controller.close();
      return;
    }

    final trimmedModel = model.trim();
    if (trimmedModel.isEmpty) {
      controller.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.modelRequired,
        userMessage: 'Model required',
      ));
      controller.close();
      return;
    }

    if (messages.isEmpty) {
      controller.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.emptyMessage,
        userMessage: 'Message cannot be empty',
      ));
      controller.close();
      return;
    }

    final url = buildChatUrl(trimmedUrl);
    final dioCancelToken = CancelToken();
    void Function()? removeListener;

    if (cancellationToken != null) {
      removeListener = cancellationToken.addCancelListener(() {
        dioCancelToken.cancel('Cancelled by user');
      });
    }

    bool terminated = false;

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: {
          'model': trimmedModel,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $trimmedKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
        ),
        cancelToken: dioCancelToken,
      );

      if (response.statusCode != 200) {
        _terminate(controller, terminated, () {
          controller.add(ChatStreamFailure(
            errorType: _mapStatusCodeToError(response.statusCode),
            userMessage: _mapStatusCodeToMessage(response.statusCode),
          ));
        });
        terminated = true;
        controller.close();
        removeListener?.call();
        return;
      }

      final parser = OpenAiSseParser();
      bool hasContent = false;
      bool gotDone = false;

      parser.stream.listen(
        (sseEvent) {
          if (terminated) return;

          if (sseEvent.data == '[DONE]') {
            gotDone = true;
            controller.add(const ChatStreamCompleted());
            terminated = true;
            return;
          }

          if (sseEvent.data == null) return;

          try {
            final parsed = _parseDelta(sseEvent.data!);
            if (parsed != null && parsed.isNotEmpty) {
              hasContent = true;
              controller.add(ChatStreamDelta(parsed));
            }
          } on FormatException {
            if (!terminated) {
              terminated = true;
              controller.add(const ChatStreamFailure(
                errorType: ChatCompletionErrorType.invalidResponse,
                userMessage: 'Invalid provider response',
              ));
            }
          }
        },
        onDone: () {
          if (terminated) return;

          if (!gotDone) {
            if (hasContent) {
              controller.add(const ChatStreamCompleted());
            } else {
              controller.add(const ChatStreamFailure(
                errorType: ChatCompletionErrorType.invalidResponse,
                userMessage: 'Invalid provider response',
              ));
            }
          }
          controller.close();
          removeListener?.call();
        },
        onError: (error) {
          if (terminated) return;
          controller.add(const ChatStreamFailure(
            errorType: ChatCompletionErrorType.unknown,
            userMessage: 'Unable to get response',
          ));
          terminated = true;
          controller.close();
          removeListener?.call();
        },
      );

      response.data!.stream.listen(
        (data) {
          parser.addBytes(data);
        },
        onDone: () {
          parser.close();
        },
        onError: (error) {
          parser.close();
        },
        cancelOnError: true,
      );
    } on DioException catch (e) {
      if (terminated) {
        removeListener?.call();
        return;
      }
      terminated = true;
      if (CancelToken.isCancel(e)) {
        controller.add(const ChatStreamFailure(
          errorType: ChatCompletionErrorType.cancelled,
          userMessage: 'Request cancelled',
        ));
      } else {
        controller.add(_mapDioErrorToStream(e));
      }
      controller.close();
      removeListener?.call();
    } catch (_) {
      if (terminated) {
        removeListener?.call();
        return;
      }
      terminated = true;
      controller.add(const ChatStreamFailure(
        errorType: ChatCompletionErrorType.unknown,
        userMessage: 'Unable to get response',
      ));
      controller.close();
      removeListener?.call();
    }
  }

  void _terminate(
    StreamController<ChatStreamEvent> controller,
    bool terminated,
    void Function() action,
  ) {
    if (!terminated) {
      action();
    }
  }

  static String? _parseDelta(String data) {
    final json = jsonDecode(data);
    if (json is! Map<String, dynamic>) return null;

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return null;

    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;

    final delta = first['delta'];
    if (delta is! Map<String, dynamic>) return null;

    final content = delta['content'];
    if (content is String && content.isNotEmpty) {
      return content;
    }

    return null;
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

  ChatCompletionErrorType _mapStatusCodeToError(int? statusCode) {
    switch (statusCode) {
      case 401:
        return ChatCompletionErrorType.unauthorized;
      case 403:
        return ChatCompletionErrorType.forbidden;
      case 429:
        return ChatCompletionErrorType.rateLimited;
      default:
        if (statusCode != null && statusCode >= 500) {
          return ChatCompletionErrorType.serverError;
        }
        return ChatCompletionErrorType.invalidResponse;
    }
  }

  String _mapStatusCodeToMessage(int? statusCode) {
    switch (statusCode) {
      case 401:
        return 'Invalid API key';
      case 403:
        return 'Access forbidden';
      case 429:
        return 'Rate limit exceeded';
      default:
        if (statusCode != null && statusCode >= 500) {
          return 'Provider server error';
        }
        return 'Invalid provider response';
    }
  }

  ChatStreamFailure _mapDioErrorToStream(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ChatStreamFailure(
          errorType: ChatCompletionErrorType.timeout,
          userMessage: 'Request timed out',
        );
      case DioExceptionType.connectionError:
        return const ChatStreamFailure(
          errorType: ChatCompletionErrorType.networkUnavailable,
          userMessage: 'Network unavailable',
        );
      case DioExceptionType.badResponse:
        return ChatStreamFailure(
          errorType: _mapStatusCodeToError(e.response?.statusCode),
          userMessage: _mapStatusCodeToMessage(e.response?.statusCode),
        );
      default:
        return const ChatStreamFailure(
          errorType: ChatCompletionErrorType.unknown,
          userMessage: 'Unable to get response',
        );
    }
  }
}
