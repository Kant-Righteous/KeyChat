import 'package:drift/drift.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

class DriftProviderConfigStore implements ProviderConfigStore {
  final AppDatabase _db;

  DriftProviderConfigStore(this._db);

  @override
  Future<void> saveConfig(ProviderConfigData config) async {
    await _db.into(_db.providerConfigs).insertOnConflictUpdate(
          ProviderConfigsCompanion(
            providerId: Value(config.providerId),
            displayName: Value(config.displayName),
            baseUrl: Value(config.baseUrl),
            defaultModel: Value(config.defaultModel),
            enabled: Value(config.enabled),
            updatedAt: Value(config.updatedAt),
          ),
        );
  }

  @override
  Future<ProviderConfigData?> readConfig(String providerId) async {
    final query = _db.select(_db.providerConfigs)
      ..where((t) => t.providerId.equals(providerId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toConfig(row);
  }

  @override
  Future<List<ProviderConfigData>> readAllConfigs() async {
    final rows = await _db.select(_db.providerConfigs).get();
    return rows.map(_toConfig).toList();
  }

  @override
  Future<void> deleteConfig(String providerId) async {
    (_db.delete(_db.providerConfigs)
          ..where((t) => t.providerId.equals(providerId)))
        .go();
  }

  ProviderConfigData _toConfig(ProviderConfig row) {
    return ProviderConfigData(
      providerId: row.providerId,
      displayName: row.displayName,
      baseUrl: row.baseUrl,
      defaultModel: row.defaultModel,
      enabled: row.enabled,
      updatedAt: row.updatedAt,
    );
  }
}
