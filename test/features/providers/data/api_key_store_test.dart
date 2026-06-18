import 'package:flutter_test/flutter_test.dart';
import 'fake_api_key_store.dart';

void main() {
  group('ApiKeyStore', () {
    late FakeApiKeyStore store;

    setUp(() {
      store = FakeApiKeyStore();
    });

    test('save and read key', () async {
      await store.saveKey('openai', 'sk-test123');
      final result = await store.readKey('openai');
      expect(result, 'sk-test123');
    });

    test('hasKey returns true when key exists', () async {
      await store.saveKey('openai', 'sk-test123');
      expect(await store.hasKey('openai'), true);
    });

    test('hasKey returns false when key does not exist', () async {
      expect(await store.hasKey('openai'), false);
    });

    test('delete key removes it', () async {
      await store.saveKey('openai', 'sk-test123');
      await store.deleteKey('openai');
      expect(await store.hasKey('openai'), false);
      expect(await store.readKey('openai'), null);
    });

    test('save trims whitespace', () async {
      await store.saveKey('openai', '  sk-test123  ');
      final result = await store.readKey('openai');
      expect(result, 'sk-test123');
    });

    test('save rejects empty key', () async {
      expect(
        () => store.saveKey('openai', ''),
        throwsArgumentError,
      );
    });

    test('save rejects whitespace-only key', () async {
      expect(
        () => store.saveKey('openai', '   '),
        throwsArgumentError,
      );
    });
  });
}
