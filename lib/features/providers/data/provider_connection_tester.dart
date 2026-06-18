enum ConnectionErrorType {
  invalidUrl,
  apiKeyRequired,
  unauthorized,
  forbidden,
  rateLimited,
  timeout,
  networkUnavailable,
  serverError,
  modelsEndpointNotSupported,
  invalidResponse,
  unknown,
}

class ConnectionTestResult {
  final bool success;
  final List<String> modelIds;
  final ConnectionErrorType? errorType;
  final String? userMessage;

  const ConnectionTestResult.success({
    required this.modelIds,
  })  : success = true,
        errorType = null,
        userMessage = null;

  const ConnectionTestResult.failure({
    required this.errorType,
    required this.userMessage,
  })  : success = false,
        modelIds = const [];
}

abstract interface class ProviderConnectionTester {
  Future<ConnectionTestResult> testConnection({
    required String baseUrl,
    required String apiKey,
  });
}
