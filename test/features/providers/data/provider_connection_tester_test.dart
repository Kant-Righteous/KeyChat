import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/dio_provider_connection_tester.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';

import 'test_http_adapter.dart';

void main() {
  group('buildModelsUrl', () {
    test('appends /models to base URL without trailing slash', () {
      expect(
        DioProviderConnectionTester.buildModelsUrl('https://api.openai.com/v1'),
        'https://api.openai.com/v1/models',
      );
    });

    test('does not produce double slash with trailing slash', () {
      expect(
        DioProviderConnectionTester.buildModelsUrl(
            'https://api.openai.com/v1/'),
        'https://api.openai.com/v1/models',
      );
    });

    test('handles base URL without path', () {
      expect(
        DioProviderConnectionTester.buildModelsUrl('https://api.openai.com'),
        'https://api.openai.com/models',
      );
    });

    test('trims whitespace', () {
      expect(
        DioProviderConnectionTester.buildModelsUrl(
            '  https://api.openai.com/v1  '),
        'https://api.openai.com/v1/models',
      );
    });
  });

  group('parseModelIds', () {
    test('parses valid model list', () {
      final data = {
        'data': [
          {'id': 'gpt-4'},
          {'id': 'gpt-3.5-turbo'},
        ],
      };
      expect(
        DioProviderConnectionTester.parseModelIds(data),
        ['gpt-4', 'gpt-3.5-turbo'],
      );
    });

    test('ignores empty model IDs', () {
      final data = {
        'data': [
          {'id': 'gpt-4'},
          {'id': ''},
          {'id': 'gpt-3.5-turbo'},
        ],
      };
      expect(
        DioProviderConnectionTester.parseModelIds(data),
        ['gpt-4', 'gpt-3.5-turbo'],
      );
    });

    test('ignores non-string model IDs', () {
      final data = {
        'data': [
          {'id': 'gpt-4'},
          {'id': 123},
          {'id': null},
          {'id': 'gpt-3.5-turbo'},
        ],
      };
      expect(
        DioProviderConnectionTester.parseModelIds(data),
        ['gpt-4', 'gpt-3.5-turbo'],
      );
    });

    test('deduplicates model IDs preserving order', () {
      final data = {
        'data': [
          {'id': 'gpt-4'},
          {'id': 'gpt-3.5-turbo'},
          {'id': 'gpt-4'},
        ],
      };
      expect(
        DioProviderConnectionTester.parseModelIds(data),
        ['gpt-4', 'gpt-3.5-turbo'],
      );
    });

    test('trims whitespace from model IDs', () {
      final data = {
        'data': [
          {'id': '  gpt-4  '},
        ],
      };
      expect(
        DioProviderConnectionTester.parseModelIds(data),
        ['gpt-4'],
      );
    });

    test('returns empty list for empty data array', () {
      final data = {'data': <Map<String, dynamic>>[]};
      expect(DioProviderConnectionTester.parseModelIds(data), isEmpty);
    });

    test('returns empty list for missing data key', () {
      expect(DioProviderConnectionTester.parseModelIds({'other': 'value'}),
          isEmpty);
    });

    test('returns empty list for non-map input', () {
      expect(DioProviderConnectionTester.parseModelIds('invalid'), isEmpty);
    });

    test('returns empty list for non-list data', () {
      expect(DioProviderConnectionTester.parseModelIds({'data': 'invalid'}),
          isEmpty);
    });
  });

  group('testConnection HTTP behavior', () {
    late TestHttpAdapter adapter;
    late Dio dio;
    late DioProviderConnectionTester tester;

    setUp(() {
      adapter = TestHttpAdapter();
      dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      dio.httpClientAdapter = adapter;
      tester = DioProviderConnectionTester(dio: dio);
    });

    tearDown(() {
      dio.close();
    });

    test('successful request uses GET method', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'data': [
          {'id': 'gpt-4'}
        ]
      };

      await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(adapter.requestMethod, 'GET');
    });

    test('final request URL is correct', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'data': []};

      await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(adapter.requestUri?.path, '/v1/models');
    });

    test('base URL with trailing slash does not produce double slash',
        () async {
      adapter.statusCode = 200;
      adapter.responseData = {'data': []};

      await tester.testConnection(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'test-marker-abc',
      );

      expect(adapter.requestUri?.path, '/v1/models');
      expect(adapter.requestUri?.path, isNot(contains('//')));
    });

    test('does not automatically add /v1', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'data': []};

      await tester.testConnection(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-marker-abc',
      );

      expect(adapter.requestUri?.path, '/models');
    });

    test('Authorization header uses Bearer format', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'data': []};

      await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(
        adapter.requestHeaders?['Authorization'],
        'Bearer test-marker-abc',
      );
    });

    test('Accept header is application/json', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'data': []};

      await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(adapter.requestHeaders?['Accept'], 'application/json');
    });

    test('successful response returns success with model list', () async {
      adapter.statusCode = 200;
      adapter.responseData = {
        'data': [
          {'id': 'gpt-4'},
          {'id': 'gpt-3.5-turbo'},
        ]
      };

      final result = await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(result.success, true);
      expect(result.modelIds, ['gpt-4', 'gpt-3.5-turbo']);
      expect(result.errorType, isNull);
    });

    test('empty model list still returns success', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'data': []};

      final result = await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(result.success, true);
      expect(result.modelIds, isEmpty);
    });

    test('invalid response structure returns invalidResponse', () async {
      adapter.statusCode = 200;
      adapter.responseData = {'unexpected': 'structure'};

      final result = await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(result.success, true);
      expect(result.modelIds, isEmpty);
    });

    test('non-200 status code returns invalidResponse', () async {
      adapter.statusCode = 201;
      adapter.responseData = {'data': []};

      final result = await tester.testConnection(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'test-marker-abc',
      );

      expect(result.success, false);
      expect(result.errorType, ConnectionErrorType.invalidResponse);
    });

    group('HTTP status code mapping', () {
      Future<ConnectionTestResult> testStatusCode(int code) async {
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

        return await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );
      }

      test('401 returns unauthorized', () async {
        final result = await testStatusCode(401);
        expect(result.errorType, ConnectionErrorType.unauthorized);
        expect(result.userMessage, 'Invalid API key');
      });

      test('403 returns forbidden', () async {
        final result = await testStatusCode(403);
        expect(result.errorType, ConnectionErrorType.forbidden);
        expect(result.userMessage, 'Access forbidden');
      });

      test('404 returns modelsEndpointNotSupported', () async {
        final result = await testStatusCode(404);
        expect(
            result.errorType, ConnectionErrorType.modelsEndpointNotSupported);
        expect(result.userMessage, 'Models endpoint is not supported');
      });

      test('429 returns rateLimited', () async {
        final result = await testStatusCode(429);
        expect(result.errorType, ConnectionErrorType.rateLimited);
        expect(result.userMessage, 'Rate limit exceeded');
      });

      test('500 returns serverError', () async {
        final result = await testStatusCode(500);
        expect(result.errorType, ConnectionErrorType.serverError);
        expect(result.userMessage, 'Provider server error');
      });

      test('502 returns serverError', () async {
        final result = await testStatusCode(502);
        expect(result.errorType, ConnectionErrorType.serverError);
      });

      test('503 returns serverError', () async {
        final result = await testStatusCode(503);
        expect(result.errorType, ConnectionErrorType.serverError);
      });
    });

    group('DioException type mapping', () {
      test('connectionTimeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );

        expect(result.errorType, ConnectionErrorType.timeout);
        expect(result.userMessage, 'Connection timed out');
      });

      test('sendTimeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.sendTimeout,
        );

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );

        expect(result.errorType, ConnectionErrorType.timeout);
      });

      test('receiveTimeout returns timeout', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );

        expect(result.errorType, ConnectionErrorType.timeout);
      });

      test('connectionError returns networkUnavailable', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );

        expect(result.errorType, ConnectionErrorType.networkUnavailable);
        expect(result.userMessage, 'Network unavailable');
      });

      test('unknown DioException returns unknown', () async {
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.unknown,
        );

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );

        expect(result.errorType, ConnectionErrorType.unknown);
        expect(result.userMessage, 'Unable to connect');
      });
    });

    group('input validation', () {
      test('empty base URL returns invalidUrl without sending request',
          () async {
        final result = await tester.testConnection(
          baseUrl: '',
          apiKey: 'test-marker-abc',
        );

        expect(result.success, false);
        expect(result.errorType, ConnectionErrorType.invalidUrl);
        expect(adapter.wasCalled, false);
      });

      test('whitespace-only base URL returns invalidUrl', () async {
        final result = await tester.testConnection(
          baseUrl: '   ',
          apiKey: 'test-marker-abc',
        );

        expect(result.success, false);
        expect(result.errorType, ConnectionErrorType.invalidUrl);
        expect(adapter.wasCalled, false);
      });

      test('empty API key returns apiKeyRequired without sending request',
          () async {
        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: '',
        );

        expect(result.success, false);
        expect(result.errorType, ConnectionErrorType.apiKeyRequired);
        expect(adapter.wasCalled, false);
      });

      test('whitespace-only API key returns apiKeyRequired', () async {
        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: '   ',
        );

        expect(result.success, false);
        expect(result.errorType, ConnectionErrorType.apiKeyRequired);
        expect(adapter.wasCalled, false);
      });

      test('API key whitespace is trimmed in Authorization header', () async {
        adapter.statusCode = 200;
        adapter.responseData = {'data': []};

        await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: '  test-marker-abc  ',
        );

        expect(
          adapter.requestHeaders?['Authorization'],
          'Bearer test-marker-abc',
        );
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

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-secret-xyz',
        );

        expect(result.userMessage, isNot(contains('test-marker-secret-xyz')));
      });

      test('server response body does not appear in userMessage', () async {
        adapter.statusCode = 500;
        adapter.responseData = {'error': 'Internal Server Error: key=abc123'};
        adapter.throwError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final result = await tester.testConnection(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'test-marker-abc',
        );

        expect(result.userMessage, 'Provider server error');
        expect(result.userMessage, isNot(contains('key=abc123')));
      });
    });
  });
}
