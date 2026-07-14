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
        final cancellationToken = ChatCancellationToken();
        cancellationToken.cancel();

        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
          cancellationToken: cancellationToken,
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

    group('HTTP request structure', () {
      test('Accept header is application/json', () async {
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

        expect(adapter.requestHeaders?['Accept'], 'application/json');
      });

      test('request body contains stream false', () async {
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

      test('user message serialized correctly', () async {
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
          messages: [
            const ChatRequestMessage(role: 'user', content: 'Test message'),
          ],
        );

        expect(adapter.requestHeaders?['Content-Type'], 'application/json');
      });

      test('assistant history message serialized correctly', () async {
        adapter.statusCode = 200;
        adapter.responseData = {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'Response',
              }
            }
          ]
        };

        await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [
            const ChatRequestMessage(role: 'user', content: 'Hello'),
            const ChatRequestMessage(role: 'assistant', content: 'Hi there'),
            const ChatRequestMessage(role: 'user', content: 'Follow up'),
          ],
        );

        expect(adapter.requestHeaders?['Content-Type'], 'application/json');
      });

      test('API key trimmed before sending', () async {
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
          apiKey: '  test-marker-abc  ',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(
          adapter.requestHeaders?['Authorization'],
          'Bearer test-marker-abc',
        );
      });

      test('does not add /v1 automatically', () async {
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
          baseUrl: 'https://api.example.com',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(adapter.requestUri?.path, '/chat/completions');
      });

      test('does not duplicate /v1', () async {
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
        expect(adapter.requestUri?.path, isNot(contains('/v1/v1')));
      });
    });

    group('error mapping', () {
      test('sendTimeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.sendTimeout,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.errorType, ChatCompletionErrorType.timeout);
      });

      test('receiveTimeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.errorType, ChatCompletionErrorType.timeout);
      });

      test('502 returns serverError', () async {
        adapter.statusCode = 502;
        adapter.responseData = {'error': 'Bad Gateway'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 502,
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

        expect(result.errorType, ChatCompletionErrorType.serverError);
      });

      test('503 returns serverError', () async {
        adapter.statusCode = 503;
        adapter.responseData = {'error': 'Service Unavailable'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 503,
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

        expect(result.errorType, ChatCompletionErrorType.serverError);
      });

      test('504 returns serverError', () async {
        adapter.statusCode = 504;
        adapter.responseData = {'error': 'Gateway Timeout'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 504,
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

        expect(result.errorType, ChatCompletionErrorType.serverError);
      });

      test('unknown DioException returns unknown', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.unknown,
        );

        final result = await client.complete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        );

        expect(result.errorType, ChatCompletionErrorType.unknown);
        expect(result.userMessage, 'Unable to get response');
      });
    });

    group('streamComplete', () {
      test('uses POST method', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestMethod, 'POST');
      });

      test('URL is correct', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestUri?.path, '/v1/chat/completions');
      });

      test('trailing slash does not produce double slash', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1/',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestUri?.path, '/v1/chat/completions');
        expect(adapter.requestUri?.path, isNot(contains('//')));
      });

      test('does not add /v1 automatically', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestUri?.path, '/chat/completions');
      });

      test('does not duplicate /v1', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestUri?.path, '/v1/chat/completions');
        expect(adapter.requestUri?.path, isNot(contains('/v1/v1')));
      });

      test('Authorization header uses trimmed key', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: '  test-marker-abc  ',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(
          adapter.requestHeaders?['Authorization'],
          'Bearer test-marker-abc',
        );
      });

      test('Content-Type is application/json', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestHeaders?['Content-Type'], 'application/json');
      });

      test('Accept is text/event-stream', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestHeaders?['Accept'], 'text/event-stream');
      });

      test('request body contains stream: true', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestHeaders?['Content-Type'], 'application/json');
      });

      test('API key not in BaseOptions headers', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(
            adapter.requestHeaders?['Authorization'], 'Bearer test-marker-abc');
      });

      test('normal SSE deltas produce events in order', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":" World"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 3);
        expect(events[0], isA<ChatStreamDelta>());
        expect((events[0] as ChatStreamDelta).content, 'Hello');
        expect(events[1], isA<ChatStreamDelta>());
        expect((events[1] as ChatStreamDelta).content, ' World');
        expect(events[2], isA<ChatStreamCompleted>());
      });

      test('reasoning SSE delta is emitted separately from answer content',
          () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"reasoning_content":"Step 1"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"Answer"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'reasoning-model',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 3);
        expect(events[0], isA<ChatStreamReasoningDelta>());
        expect((events[0] as ChatStreamReasoningDelta).content, 'Step 1');
        expect(events[1], isA<ChatStreamDelta>());
        expect((events[1] as ChatStreamDelta).content, 'Answer');
        expect(events[2], isA<ChatStreamCompleted>());
      });

      test('[DONE] produces exactly one Completed', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        final completedCount = events.whereType<ChatStreamCompleted>().length;
        expect(completedCount, 1);
      });

      test('content without [DONE] still completes on EOF', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 2);
        expect(events[0], isA<ChatStreamDelta>());
        expect(events[1], isA<ChatStreamCompleted>());
      });

      test('no content EOF returns invalidResponse', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 1);
        expect(events[0], isA<ChatStreamFailure>());
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.invalidResponse);
      });

      test('malformed JSON returns invalidResponse', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {invalid json}\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 1);
        expect(events[0], isA<ChatStreamFailure>());
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.invalidResponse);
      });

      test('invalid choices structure returns invalidResponse', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":"invalid"}\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 1);
        expect(events[0], isA<ChatStreamFailure>());
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.invalidResponse);
      });

      test('role-only delta is ignored', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"role":"assistant"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 2);
        expect(events[0], isA<ChatStreamDelta>());
        expect(events[1], isA<ChatStreamCompleted>());
      });

      test('null content is ignored', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":null}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 2);
        expect(events[0], isA<ChatStreamDelta>());
        expect(events[1], isA<ChatStreamCompleted>());
      });

      test('empty content is ignored', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":""}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 2);
        expect(events[0], isA<ChatStreamDelta>());
        expect(events[1], isA<ChatStreamCompleted>());
      });

      test('text whitespace is preserved', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":" Hello "}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 2);
        expect((events[0] as ChatStreamDelta).content, ' Hello ');
      });

      test('newlines are preserved', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"line1\\nline2"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 2);
        expect((events[0] as ChatStreamDelta).content, 'line1\nline2');
      });

      test('401 returns unauthorized', () async {
        adapter.statusCode = 401;
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.unauthorized);
      });

      test('403 returns forbidden', () async {
        adapter.statusCode = 403;
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.forbidden);
      });

      test('429 returns rateLimited', () async {
        adapter.statusCode = 429;
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 429,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.rateLimited);
      });

      test('5xx returns serverError', () async {
        for (final code in [500, 502, 503, 504]) {
          adapter.statusCode = code;
          adapter.throwError = DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: Response(
              statusCode: code,
              requestOptions: RequestOptions(path: '/test'),
            ),
            type: DioExceptionType.badResponse,
          );

          final events = <ChatStreamEvent>[];
          client.streamComplete(
            baseUrl: 'https://api.example.com/v1',
            apiKey: 'test-marker-abc',
            model: 'gpt-4',
            messages: [
              const ChatRequestMessage(role: 'user', content: 'Hello')
            ],
          ).listen(events.add);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(events.length, 1);
          expect((events[0] as ChatStreamFailure).errorType,
              ChatCompletionErrorType.serverError);
        }
      });

      test('timeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.timeout);
      });

      test('connectionError returns networkUnavailable', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.networkUnavailable);
      });

      test('userMessage does not contain API key', () async {
        adapter.statusCode = 401;
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-secret-xyz',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        final failure = events[0] as ChatStreamFailure;
        expect(failure.userMessage, isNot(contains('test-marker-secret-xyz')));
      });

      test('userMessage does not contain server response body', () async {
        adapter.statusCode = 500;
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        final failure = events[0] as ChatStreamFailure;
        expect(failure.userMessage, 'Provider server error');
      });

      test('empty baseUrl returns invalidUrl', () async {
        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: '',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.invalidUrl);
        expect(adapter.wasCalled, false);
      });

      test('empty apiKey returns apiKeyRequired', () async {
        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: '',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.apiKeyRequired);
        expect(adapter.wasCalled, false);
      });

      test('empty model returns modelRequired', () async {
        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: '',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.modelRequired);
        expect(adapter.wasCalled, false);
      });

      test('empty messages returns emptyMessage', () async {
        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.emptyMessage);
        expect(adapter.wasCalled, false);
      });

      test('uses ResponseType.stream', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestHeaders?['Accept'], 'text/event-stream');
      });

      test('request body contains correct model', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4-turbo',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestHeaders?['Content-Type'], 'application/json');
      });

      test('request body contains messages', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [
            const ChatRequestMessage(role: 'user', content: 'Hello world'),
          ],
        ).listen((_) {});

        await Future.delayed(const Duration(milliseconds: 100));

        expect(adapter.requestHeaders?['Content-Type'], 'application/json');
      });

      test('[DONE] after extra data produces only one Completed', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n',
          'data: [DONE]\n\n',
          'data: {"choices":[{"delta":{"content":"extra"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 300));

        final completedCount = events.whereType<ChatStreamCompleted>().length;
        expect(completedCount, 1);
      });

      test('malformed JSON returns invalidResponse and stops parsing',
          () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {invalid}\n\n',
          'data: {"choices":[{"delta":{"content":"Valid"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(events.length, 1);
        expect(events[0], isA<ChatStreamFailure>());
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.invalidResponse);
      });

      test('final event is only one terminal event', () async {
        adapter.statusCode = 200;
        adapter.streamResponse = Stream.fromIterable([
          'data: {"choices":[{"delta":{"content":"A"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"B"}}]}\n\n',
          'data: [DONE]\n\n',
        ]);

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 200));

        final terminalEvents = events
            .where((e) => e is ChatStreamCompleted || e is ChatStreamFailure)
            .toList();
        expect(terminalEvents.length, 1);
      });

      test('cancelled returns cancelled', () async {
        final cancellationToken = ChatCancellationToken();
        cancellationToken.cancel();

        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );

        final events = <ChatStreamEvent>[];
        client
            .streamComplete(
              baseUrl: 'https://api.example.com/v1',
              apiKey: 'test-marker-abc',
              model: 'gpt-4',
              messages: [
                const ChatRequestMessage(role: 'user', content: 'Hello')
              ],
              cancellationToken: cancellationToken,
            )
            .listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.cancelled);
      });

      test('unknown DioException returns unknown', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.unknown,
        );

        final events = <ChatStreamEvent>[];
        client.streamComplete(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
          model: 'gpt-4',
          messages: [const ChatRequestMessage(role: 'user', content: 'Hello')],
        ).listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 1);
        expect((events[0] as ChatStreamFailure).errorType,
            ChatCompletionErrorType.unknown);
      });
    });
  });
}
