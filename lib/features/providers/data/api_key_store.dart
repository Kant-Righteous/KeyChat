abstract class ApiKeyStore {
  Future<void> saveKey(String providerId, String apiKey);
  Future<String?> readKey(String providerId);
  Future<bool> hasKey(String providerId);
  Future<void> deleteKey(String providerId);
}
