import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';

void main() {
  group('ProviderConfigs table schema', () {
    test('table contains only expected columns', () {
      final db = AppDatabase();
      final table = db.providerConfigs;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, contains('provider_id'));
      expect(columnNames, contains('display_name'));
      expect(columnNames, contains('base_url'));
      expect(columnNames, contains('default_model'));
      expect(columnNames, contains('enabled'));
      expect(columnNames, contains('updated_at'));
      expect(columnNames.length, 6);

      db.close();
    });

    test('table does not contain API key column', () {
      final db = AppDatabase();
      final table = db.providerConfigs;
      final columnNames = table.$columns.map((c) => c.name).toList();

      expect(columnNames, isNot(contains('api_key')));
      expect(columnNames, isNot(contains('apiKey')));
      expect(columnNames, isNot(contains('key')));
      expect(columnNames, isNot(contains('secret')));
      expect(columnNames, isNot(contains('token')));

      db.close();
    });

    test('provider_id is primary key', () {
      final db = AppDatabase();
      final table = db.providerConfigs;
      final primaryKey = table.primaryKey;

      expect(primaryKey.length, 1);
      expect(primaryKey.first.name, 'provider_id');

      db.close();
    });
  });
}
