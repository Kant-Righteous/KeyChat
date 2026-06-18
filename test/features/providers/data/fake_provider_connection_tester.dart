import 'dart:async';

import 'package:keychat/features/providers/data/provider_connection_tester.dart';

class FakeProviderConnectionTester implements ProviderConnectionTester {
  ConnectionTestResult? _nextResult;
  Completer<void>? _completer;
  String? lastBaseUrl;
  String? lastApiKey;
  int callCount = 0;

  void setResult(ConnectionTestResult result) {
    _nextResult = result;
  }

  Completer<void> startSlowResponse() {
    _completer = Completer<void>();
    return _completer!;
  }

  @override
  Future<ConnectionTestResult> testConnection({
    required String baseUrl,
    required String apiKey,
  }) async {
    callCount++;
    lastBaseUrl = baseUrl;
    lastApiKey = apiKey;

    if (_completer != null && !_completer!.isCompleted) {
      await _completer!.future;
    }

    return _nextResult ??
        const ConnectionTestResult.failure(
          errorType: ConnectionErrorType.unknown,
          userMessage: 'No result configured',
        );
  }
}
