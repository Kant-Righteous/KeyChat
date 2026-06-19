import 'package:dio/dio.dart';
import 'package:keychat/features/providers/data/provider_connection_tester.dart';

class DioProviderConnectionTester implements ProviderConnectionTester {
  final Dio _dio;

  DioProviderConnectionTester({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  static String buildModelsUrl(String baseUrl) {
    var url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return '$url/models';
  }

  static List<String>? parseModelIds(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final dataList = data['data'];
    if (dataList is! List) return null;

    final ids = <String>[];
    for (final item in dataList) {
      if (item is Map<String, dynamic>) {
        final id = item['id'];
        if (id is String && id.trim().isNotEmpty) {
          ids.add(id.trim());
        }
      }
    }

    final seen = <String>{};
    final unique = <String>[];
    for (final id in ids) {
      if (seen.add(id)) {
        unique.add(id);
      }
    }
    return unique;
  }

  @override
  Future<ConnectionTestResult> testConnection({
    required String baseUrl,
    required String apiKey,
  }) async {
    final trimmedUrl = baseUrl.trim();
    if (trimmedUrl.isEmpty) {
      return const ConnectionTestResult.failure(
        errorType: ConnectionErrorType.invalidUrl,
        userMessage: 'Invalid Base URL',
      );
    }

    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      return const ConnectionTestResult.failure(
        errorType: ConnectionErrorType.apiKeyRequired,
        userMessage: 'API key required',
      );
    }

    final url = buildModelsUrl(trimmedUrl);

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $trimmedKey',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final modelIds = parseModelIds(response.data);
        if (modelIds == null) {
          return const ConnectionTestResult.failure(
            errorType: ConnectionErrorType.invalidResponse,
            userMessage: 'Invalid provider response',
          );
        }
        return ConnectionTestResult.success(modelIds: modelIds);
      }

      return const ConnectionTestResult.failure(
        errorType: ConnectionErrorType.invalidResponse,
        userMessage: 'Invalid provider response',
      );
    } on DioException catch (e) {
      return _mapDioError(e);
    } catch (_) {
      return const ConnectionTestResult.failure(
        errorType: ConnectionErrorType.unknown,
        userMessage: 'Unable to connect',
      );
    }
  }

  ConnectionTestResult _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.timeout,
          userMessage: 'Connection timed out',
        );
      case DioExceptionType.connectionError:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.networkUnavailable,
          userMessage: 'Network unavailable',
        );
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode);
      default:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.unknown,
          userMessage: 'Unable to connect',
        );
    }
  }

  ConnectionTestResult _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 401:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.unauthorized,
          userMessage: 'Invalid API key',
        );
      case 403:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.forbidden,
          userMessage: 'Access forbidden',
        );
      case 404:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.modelsEndpointNotSupported,
          userMessage: 'Models endpoint is not supported',
        );
      case 429:
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.rateLimited,
          userMessage: 'Rate limit exceeded',
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const ConnectionTestResult.failure(
            errorType: ConnectionErrorType.serverError,
            userMessage: 'Provider server error',
          );
        }
        return const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.invalidResponse,
          userMessage: 'Invalid provider response',
        );
    }
  }
}
