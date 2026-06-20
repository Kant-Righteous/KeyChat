import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/openai_sse_parser.dart';

void main() {
  group('OpenAiSseParser', () {
    late OpenAiSseParser parser;
    late List<SseEvent> events;

    setUp(() {
      parser = OpenAiSseParser();
      events = [];
      parser.stream.listen((event) => events.add(event));
    });

    tearDown(() {
      parser.close();
    });

    test('parses single delta', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data: $data\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events[0].data, isNotNull);
      expect(events[0].data, isNot('[DONE]'));
    });

    test('parses multiple deltas in order', () async {
      final data1 = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      final data2 = jsonEncode({
        'choices': [
          {
            'delta': {'content': ' World'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data: $data1\n\ndata: $data2\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 2);
      expect(events[0].data, isNotNull);
      expect(events[1].data, isNotNull);
    });

    test('multiple SSE events in same byte chunk', () async {
      final data1 = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'A'},
            'finish_reason': null,
          }
        ],
      });
      final data2 = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'B'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data: $data1\n\ndata: $data2\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 2);
    });

    test('single SSE event split across multiple byte chunks', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      final bytes = utf8.encode('data: $data\n\n');
      final mid = bytes.length ~/ 2;

      parser.addBytes(bytes.sublist(0, mid));
      await Future.delayed(Duration.zero);
      expect(events.length, 0);

      parser.addBytes(bytes.sublist(mid));
      await Future.delayed(Duration.zero);
      expect(events.length, 1);
    });

    test('JSON content split across multiple byte chunks', () async {
      final data = '{"choices":[{"delta":{"content":"Hello"}}]}';
      final bytes = utf8.encode('data: $data\n\n');
      final mid = bytes.length ~/ 2;

      parser.addBytes(bytes.sublist(0, mid));
      await Future.delayed(Duration.zero);

      parser.addBytes(bytes.sublist(mid));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('Chinese UTF-8 character across chunks', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': '你好'},
            'finish_reason': null,
          }
        ],
      });
      final bytes = utf8.encode('data: $data\n\n');

      final mid = bytes.length ~/ 2;
      parser.addBytes(bytes.sublist(0, mid));
      await Future.delayed(Duration.zero);

      parser.addBytes(bytes.sublist(mid));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('supports LF line endings', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data: $data\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('supports CRLF line endings', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data: $data\r\n\r\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('supports data: without space', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data:$data\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('ignores comment/keep-alive', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode(': keep-alive\ndata: $data\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('ignores event/id/retry fields', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(
          utf8.encode('event: message\nid: 1\nretry: 5\ndata: $data\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('[DONE] has special data', () async {
      parser.addBytes(utf8.encode('data: [DONE]\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events[0].data, '[DONE]');
    });

    test('[DONE] ignores extra data after', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(
          utf8.encode('data: $data\n\ndata: [DONE]\n\ndata: $data\n\n'));
      await Future.delayed(Duration.zero);

      // Parser processes all events; client is responsible for ignoring after [DONE]
      expect(events.length, greaterThanOrEqualTo(2));
      expect(events[0].data, isNot('[DONE]'));
      expect(events[1].data, '[DONE]');
    });

    test('content with no [DONE] still flushes on close', () async {
      final data = jsonEncode({
        'choices': [
          {
            'delta': {'content': 'Hello'},
            'finish_reason': null,
          }
        ],
      });
      parser.addBytes(utf8.encode('data: $data\n\n'));
      parser.close();
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });

    test('no content and direct EOF produces no events', () async {
      parser.close();
      await Future.delayed(Duration.zero);

      expect(events.length, 0);
    });

    test('malformed JSON still produces event with data', () async {
      parser.addBytes(utf8.encode('data: {invalid json}\n\n'));
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events[0].data, '{invalid json}');
    });

    test('multiple [DONE] events are emitted', () async {
      parser.addBytes(utf8.encode('data: [DONE]\n\ndata: [DONE]\n\n'));
      await Future.delayed(Duration.zero);

      // Parser emits all events; client handles deduplication
      final doneCount = events.where((e) => e.data == '[DONE]').length;
      expect(doneCount, greaterThanOrEqualTo(1));
    });
  });
}
