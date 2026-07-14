import 'dart:io';

import 'package:flutter/services.dart';

abstract interface class GenerationKeepAlive {
  Future<void> start();

  Future<void> stop();
}

final class NoopGenerationKeepAlive implements GenerationKeepAlive {
  const NoopGenerationKeepAlive();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

final class AndroidGenerationKeepAlive implements GenerationKeepAlive {
  static const _channel = MethodChannel(
    'io.github.kantrighteous.keychat/background_generation',
  );

  bool _active = false;
  Future<void>? _startInFlight;

  @override
  Future<void> start() async {
    if (!Platform.isAndroid || _active) return;

    final currentStart = _startInFlight;
    if (currentStart != null) {
      await currentStart;
      return;
    }

    final startFuture = _startNative();
    _startInFlight = startFuture;
    try {
      await startFuture;
    } finally {
      _startInFlight = null;
    }
  }

  Future<void> _startNative() async {
    try {
      await _channel.invokeMethod<void>('start');
      _active = true;
    } on PlatformException {
      // The request can still proceed while the app remains in the foreground.
    } on MissingPluginException {
      // Non-Android hosts and unit tests do not provide the native service.
    }
  }

  @override
  Future<void> stop() async {
    if (!Platform.isAndroid) return;

    final currentStart = _startInFlight;
    if (currentStart != null) {
      await currentStart;
    }
    if (!_active) return;

    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // The native service is also stopped when the Android process exits.
    } on MissingPluginException {
      // Non-Android hosts and unit tests do not provide the native service.
    } finally {
      _active = false;
    }
  }
}
