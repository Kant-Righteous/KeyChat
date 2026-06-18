import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class TestHttpAdapter implements HttpClientAdapter {
  int? statusCode;
  dynamic responseData;
  String? requestMethod;
  Uri? requestUri;
  Map<String, dynamic>? requestHeaders;
  bool wasCalled = false;
  DioException? throwError;

  void reset() {
    statusCode = null;
    responseData = null;
    requestMethod = null;
    requestUri = null;
    requestHeaders = null;
    wasCalled = false;
    throwError = null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    wasCalled = true;
    requestMethod = options.method;
    requestUri = options.uri;
    requestHeaders = options.headers;

    if (throwError != null) {
      throw throwError!;
    }

    final body = jsonEncode(responseData ?? {});
    return ResponseBody.fromString(
      body,
      statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
