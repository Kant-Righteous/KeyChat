import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';

class SecureApiKeyStore implements ApiKeyStore {
  final FlutterSecureStorage _storage;

  SecureApiKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _storageKey(String providerId) =>
      'keychat.provider.$providerId.api_key';

  @override
  Future<void> saveKey(String providerId, String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('API Key cannot be empty');
    }
    await _storage.write(key: _storageKey(providerId), value: trimmed);
  }

  @override
  Future<String?> readKey(String providerId) async {
    return await _storage.read(key: _storageKey(providerId));
  }

  @override
  Future<bool> hasKey(String providerId) async {
    return await _storage.containsKey(key: _storageKey(providerId));
  }

  @override
  Future<void> deleteKey(String providerId) async {
    await _storage.delete(key: _storageKey(providerId));
  }
}
