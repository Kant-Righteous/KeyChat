import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class TestHttpAdapter implements HttpClientAdapter {
  int? statusCode;
  dynamic responseData;
  Stream<String>? streamResponse;
  String? requestMethod;
  Uri? requestUri;
  Map<String, dynamic>? requestHeaders;
  bool wasCalled = false;
  DioException? throwError;

  void reset() {
    statusCode = null;
    responseData = null;
    streamResponse = null;
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

    if (streamResponse != null) {
      final stream = streamResponse!.transform(
        StreamTransformer<String, Uint8List>.fromHandlers(
          handleData: (data, sink) {
            sink.add(Uint8List.fromList(utf8.encode(data)));
          },
        ),
      );
      return ResponseBody(
        stream,
        statusCode ?? 200,
        headers: {
          'content-type': ['text/event-stream'],
        },
      );
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
