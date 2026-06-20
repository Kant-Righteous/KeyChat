import 'dart:async';
import 'dart:convert';

class SseEvent {
  final String? data;

  const SseEvent({this.data});
}

class OpenAiSseParser {
  final _controller = StreamController<SseEvent>.broadcast();
  final _buffer = StringBuffer();
  String _lineBuffer = '';

  Stream<SseEvent> get stream => _controller.stream;

  void addBytes(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    _processText(text);
  }

  void _processText(String text) {
    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '\n') {
        _processLine(_lineBuffer);
        _lineBuffer = '';
      } else if (char == '\r') {
        _processLine(_lineBuffer);
        _lineBuffer = '';
        if (i + 1 < text.length && text[i + 1] == '\n') {
          i++;
        }
      } else {
        _lineBuffer += char;
      }
    }
  }

  void _processLine(String line) {
    if (line.isEmpty) {
      _flushEvent();
      return;
    }

    if (line.startsWith(':')) {
      return;
    }

    if (line.startsWith('event:') ||
        line.startsWith('id:') ||
        line.startsWith('retry:')) {
      return;
    }

    if (line.startsWith('data:')) {
      var data = line.substring(5);
      if (data.startsWith(' ')) {
        data = data.substring(1);
      }
      if (_buffer.isNotEmpty) {
        _buffer.write('\n');
      }
      _buffer.write(data);
      return;
    }

    if (line.startsWith('data:')) {
      var data = line.substring(5);
      if (data.startsWith(' ')) {
        data = data.substring(1);
      }
      if (_buffer.isNotEmpty) {
        _buffer.write('\n');
      }
      _buffer.write(data);
    }
  }

  void _flushEvent() {
    if (_buffer.isEmpty) return;

    final data = _buffer.toString();
    _buffer.clear();

    if (data == '[DONE]') {
      _controller.add(const SseEvent(data: '[DONE]'));
      return;
    }

    _controller.add(SseEvent(data: data));
  }

  void close() {
    if (_lineBuffer.isNotEmpty) {
      _processLine(_lineBuffer);
      _lineBuffer = '';
    }
    if (_buffer.isNotEmpty) {
      _flushEvent();
    }
    _controller.close();
  }
}
