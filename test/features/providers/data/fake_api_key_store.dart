import 'package:keychat/features/providers/data/api_key_store.dart';

class FakeApiKeyStore implements ApiKeyStore {
  final Map<String, String> _keys = {};

  @override
  Future<void> saveKey(String providerId, String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('API Key cannot be empty');
    }
    _keys[providerId] = trimmed;
  }

  @override
  Future<String?> readKey(String providerId) async {
    return _keys[providerId];
  }

  @override
  Future<bool> hasKey(String providerId) async {
    return _keys.containsKey(providerId);
  }

  @override
  Future<void> deleteKey(String providerId) async {
    _keys.remove(providerId);
  }
}
