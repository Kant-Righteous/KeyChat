import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/dio_chat_completion_client.dart';

import '../../providers/data/test_http_adapter.dart';

void main() {
  group('buildChatUrl', () {
    test('appends /chat/completions without trailing slash', () {
      expect(
        DioChatCompletionClient.buildChatUrl('https://api.openai.com/v1'),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('does not produce double slash with trailing slash', () {
      expect(
        DioChatCompletionClient.buildChatUrl('https://api.openai.com/v1/'),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('handles base URL without path', () {
      expect(
        DioChatCompletionClient.buildChatUrl('https://api.openai.com'),
        'https://api.openai.com/chat/completions',
      );
    });

    test('trims whitespace', () {
      expect(
        DioChatCompletionClient.buildChatUrl('  https://api.openai.com/v1  '),
        'https://api.openai.com/v1/chat/completions',
      );
    });
  });

  group('parseAssistantContent', () {
    test('parses valid response', () {
      final data = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hello world',
            }
          }
        ]
      };
      expect(
          DioChatCompletionClient.parseAssistantContent(data), 'Hello world');
    });

    test('trims whitespace from content', () {
      final data = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': '  Hello world  ',
            }
          }
        ]
      };
      expect(
          DioChatCompletionClient.parseAssistantContent(data), 'Hello world');
    });

    test('returns null for non-map input', () {
      expect(DioChatCompletionClient.parseAssistantContent('invalid'), isNull);
    });

    test('returns null for missing choices', () {
      expect(DioChatCompletionClient.parseAssistantContent({'other': 'value'}),
          isNull);
    });

    test('returns null for empty choices', () {
      expect(DioChatCompletionClient.parseAssistantContent({'choices': []}),
          isNull);
    });

    test('returns null for non-list choices', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({'choices': 'invalid'}),
          isNull);
    });

    test('returns null for invalid first choice', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({
            'choices': ['invalid']
          }),
          isNull);
    });

    test('returns null for missing message', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({
            'choices': [
              {'other': 'value'}
            ]
          }),
          isNull);
    });

    test('returns null for non-map message', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({
            'choices': [
              {'message': 'invalid'}
            ]
          }),
          isNull);
    });

    test('returns null for non-string content', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({
            'choices': [
              {
                'message': {'content': 123}
              }
            ]
          }),
          isNull);
    });

    test('returns null for empty content', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({
            'choices': [
              {
                'message': {'content': ''}
              }
            ]
          }),
          isNull);
    });

    test('returns null for whitespace-only content', () {
      expect(
          DioChatCompletionClient.parseAssistantContent({
            'choices': [
              {
                'message': {'content': '   '}
              }
            ]
          }),
          isNull);
    });
  });

  group('complete HTTP behavior', () {
    late TestHttpAdapter adapter;
    late Dio dio;
    late DioChatCompletionClient client;

    setUp(() {
      adapter = TestHttpAdapter();
      dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));
      dio.httpClientAdapter = adapter;
      client = DioChatCompletionClient(dio: dio);
    });

    tearDown(() {
      dio.close();
    });

    test('uses POST method', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hi',
            }
          }
        ]
      };

      await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(adapter.requestMethod, 'POST');
    });

    test('URL is correct', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hi',
            }
          }
        ]
      };

      await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(adapter.requestUri?.path, '/v1/chat/completions');
    });

    test('trailing slash does not produce double slash', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hi',
            }
          }
        ]
      };

      await client.complete(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(adapter.requestUri?.path, '/v1/chat/completions');
      expect(adapter.requestUri?.path, isNot(contains('//')));
    });

    test('Authorization header uses Bearer format', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hi',
            }
          }
        ]
      };

      await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(
        adapter.requestHeaders?['Authorization'],
        'Bearer test-marker-abc',
      );
    });

    test('Content-Type is application/json', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hi',
            }
          }
        ]
      };

      await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(adapter.requestHeaders?['Content-Type'], 'application/json');
    });

    test('request body contains correct model', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hi',
            }
          }
        ]
      };

      await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4-turbo',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(adapter.requestHeaders?['Content-Type'], 'application/json');
    });

    test('successful response returns assistant content', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Hello! How can I help?',
            }
          }
        ]
      };

      final result = await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(result.success, true);
      expect(result.assistantContent, 'Hello! How can I help?');
      expect(result.errorType, isNull);
    });

    test('invalid response structure returns invalidResponse', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'unexpected': 'structure'};

      final result = await client.complete(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
        model: 'gpt-4',
        messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
      );

      expect(result.success, false);
      expect(result.errorType, ChatCompletionErrorType.invalidResponse);
    });

    group('input validation', () {
      test('empty base URL returns invalidUrl', () async {
        final result = await client.complete(
          baseUrl: '',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.success, false);
        expect(result.errorType, ChatCompletionErrorType.invalidUrl);
        expect(adapter.wasCalled, false);
      });

      test('empty API key returns apiKeyRequired', () async {
        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: '',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.success, false);
        expect(result.errorType, ChatCompletionErrorType.apiKeyRequired);
        expect(adapter.wasCalled, false);
      });

      test('empty model returns modelRequired', () async {
        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: '',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.success, false);
        expect(result.errorType, ChatCompletionErrorType.modelRequired);
        expect(adapter.wasCalled, false);
      });

      test('empty messages returns emptyMessage', () async {
        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [],
        );

        expect(result.success, false);
        expect(result.errorType, ChatCompletionErrorType.emptyMessage);
        expect(adapter.wasCalled, false);
      });
    });

    group('HTTP status code mapping', () {
      Future<ChatCompletionResult> testStatusCode(int code) async {
        adapter.statusCode = code;
        adapter.responseData = {'error': 'test'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: code,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        return await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );
      }

      test('401 returns unauthorized', () async {
        final result = await testStatusCode(401);
        expect(result.errorType, ChatCompletionErrorType.unauthorized);
        expect(result.userMessage, 'Invalid API key');
      });

      test('403 returns forbidden', () async {
        final result = await testStatusCode(403);
        expect(result.errorType, ChatCompletionErrorType.forbidden);
      });

      test('429 returns rateLimited', () async {
        final result = await testStatusCode(429);
        expect(result.errorType, ChatCompletionErrorType.rateLimited);
      });

      test('500 returns serverError', () async {
        final result = await testStatusCode(500);
        expect(result.errorType, ChatCompletionErrorType.serverError);
      });
    });

    group('DioException type mapping', () {
      test('connectionTimeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.errorType, ChatCompletionErrorType.timeout);
      });

      test('connectionError returns networkUnavailable', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.errorType, ChatCompletionErrorType.networkUnavailable);
      });

      test('cancelled returns cancelled', () async {
        final cancelToken = CancelToken();
        cancelToken.cancel();

        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
          cancelToken: cancelToken,
        );

        expect(result.errorType, ChatCompletionErrorType.cancelled);
      });
    });

    group('security', () {
      test('userMessage does not contain test key', () async {
        adapter.statusCode = 401;
        adapter.responseData = {'error': 'unauthorized'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-secret-xyz',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.userMessage, isNot(contains('test-marker-secret-xyz')));
      });

      test('server response body does not appear in userMessage', () async {
        adapter.statusCode = 500;
        adapter.responseData = {'error': 'Internal: key=abc123'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.userMessage, 'Provider server error');
        expect(result.userMessage, isNot(contains('key=abc123')));
      });
    });
  });
}
