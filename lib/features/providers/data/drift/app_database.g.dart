// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProviderConfigsTable extends ProviderConfigs
    with TableInfo<$ProviderConfigsTable, ProviderConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultModelMeta =
      const VerificationMeta('defaultModel');
  @override
  late final GeneratedColumn<String> defaultModel = GeneratedColumn<String>(
      'default_model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [providerId, displayName, baseUrl, defaultModel, enabled, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_configs';
  @override
  VerificationContext validateIntegrity(Insertable<ProviderConfig> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('default_model')) {
      context.handle(
          _defaultModelMeta,
          defaultModel.isAcceptableOrUnknown(
              data['default_model']!, _defaultModelMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId};
  @override
  ProviderConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderConfig(
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url'])!,
      defaultModel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_model']),
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProviderConfigsTable createAlias(String alias) {
    return $ProviderConfigsTable(attachedDatabase, alias);
  }
}

class ProviderConfig extends DataClass implements Insertable<ProviderConfig> {
  final String providerId;
  final String displayName;
  final String baseUrl;
  final String? defaultModel;
  final bool enabled;
  final DateTime updatedAt;
  const ProviderConfig(
      {required this.providerId,
      required this.displayName,
      required this.baseUrl,
      this.defaultModel,
      required this.enabled,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['display_name'] = Variable<String>(displayName);
    map['base_url'] = Variable<String>(baseUrl);
    if (!nullToAbsent || defaultModel != null) {
      map['default_model'] = Variable<String>(defaultModel);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProviderConfigsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConfigsCompanion(
      providerId: Value(providerId),
      displayName: Value(displayName),
      baseUrl: Value(baseUrl),
      defaultModel: defaultModel == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultModel),
      enabled: Value(enabled),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderConfig.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderConfig(
      providerId: serializer.fromJson<String>(json['providerId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      defaultModel: serializer.fromJson<String?>(json['defaultModel']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'displayName': serializer.toJson<String>(displayName),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'defaultModel': serializer.toJson<String?>(defaultModel),
      'enabled': serializer.toJson<bool>(enabled),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProviderConfig copyWith(
          {String? providerId,
          String? displayName,
          String? baseUrl,
          Value<String?> defaultModel = const Value.absent(),
          bool? enabled,
          DateTime? updatedAt}) =>
      ProviderConfig(
        providerId: providerId ?? this.providerId,
        displayName: displayName ?? this.displayName,
        baseUrl: baseUrl ?? this.baseUrl,
        defaultModel:
            defaultModel.present ? defaultModel.value : this.defaultModel,
        enabled: enabled ?? this.enabled,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProviderConfig copyWithCompanion(ProviderConfigsCompanion data) {
    return ProviderConfig(
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      defaultModel: data.defaultModel.present
          ? data.defaultModel.value
          : this.defaultModel,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfig(')
          ..write('providerId: $providerId, ')
          ..write('displayName: $displayName, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('defaultModel: $defaultModel, ')
          ..write('enabled: $enabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      providerId, displayName, baseUrl, defaultModel, enabled, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          other.providerId == this.providerId &&
          other.displayName == this.displayName &&
          other.baseUrl == this.baseUrl &&
          other.defaultModel == this.defaultModel &&
          other.enabled == this.enabled &&
          other.updatedAt == this.updatedAt);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderConfig> {
  final Value<String> providerId;
  final Value<String> displayName;
  final Value<String> baseUrl;
  final Value<String?> defaultModel;
  final Value<bool> enabled;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProviderConfigsCompanion({
    this.providerId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.defaultModel = const Value.absent(),
    this.enabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    required String providerId,
    required String displayName,
    required String baseUrl,
    this.defaultModel = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : providerId = Value(providerId),
        displayName = Value(displayName),
        baseUrl = Value(baseUrl),
        updatedAt = Value(updatedAt);
  static Insertable<ProviderConfig> custom({
    Expression<String>? providerId,
    Expression<String>? displayName,
    Expression<String>? baseUrl,
    Expression<String>? defaultModel,
    Expression<bool>? enabled,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (displayName != null) 'display_name': displayName,
      if (baseUrl != null) 'base_url': baseUrl,
      if (defaultModel != null) 'default_model': defaultModel,
      if (enabled != null) 'enabled': enabled,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderConfigsCompanion copyWith(
      {Value<String>? providerId,
      Value<String>? displayName,
      Value<String>? baseUrl,
      Value<String?>? defaultModel,
      Value<bool>? enabled,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProviderConfigsCompanion(
      providerId: providerId ?? this.providerId,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      enabled: enabled ?? this.enabled,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (defaultModel.present) {
      map['default_model'] = Variable<String>(defaultModel.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfigsCompanion(')
          ..write('providerId: $providerId, ')
          ..write('displayName: $displayName, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('defaultModel: $defaultModel, ')
          ..write('enabled: $enabled, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProviderConfigsTable providerConfigs =
      $ProviderConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [providerConfigs];
}

typedef $$ProviderConfigsTableCreateCompanionBuilder = ProviderConfigsCompanion
    Function({
  required String providerId,
  required String displayName,
  required String baseUrl,
  Value<String?> defaultModel,
  Value<bool> enabled,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProviderConfigsTableUpdateCompanionBuilder = ProviderConfigsCompanion
    Function({
  Value<String> providerId,
  Value<String> displayName,
  Value<String> baseUrl,
  Value<String?> defaultModel,
  Value<bool> enabled,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProviderConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultModel => $composableBuilder(
      column: $table.defaultModel, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProviderConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultModel => $composableBuilder(
      column: $table.defaultModel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProviderConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get defaultModel => $composableBuilder(
      column: $table.defaultModel, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProviderConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProviderConfigsTable,
    ProviderConfig,
    $$ProviderConfigsTableFilterComposer,
    $$ProviderConfigsTableOrderingComposer,
    $$ProviderConfigsTableAnnotationComposer,
    $$ProviderConfigsTableCreateCompanionBuilder,
    $$ProviderConfigsTableUpdateCompanionBuilder,
    (
      ProviderConfig,
      BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderConfig>
    ),
    ProviderConfig,
    PrefetchHooks Function()> {
  $$ProviderConfigsTableTableManager(
      _$AppDatabase db, $ProviderConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> providerId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> baseUrl = const Value.absent(),
            Value<String?> defaultModel = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderConfigsCompanion(
            providerId: providerId,
            displayName: displayName,
            baseUrl: baseUrl,
            defaultModel: defaultModel,
            enabled: enabled,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String providerId,
            required String displayName,
            required String baseUrl,
            Value<String?> defaultModel = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderConfigsCompanion.insert(
            providerId: providerId,
            displayName: displayName,
            baseUrl: baseUrl,
            defaultModel: defaultModel,
            enabled: enabled,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProviderConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProviderConfigsTable,
    ProviderConfig,
    $$ProviderConfigsTableFilterComposer,
    $$ProviderConfigsTableOrderingComposer,
    $$ProviderConfigsTableAnnotationComposer,
    $$ProviderConfigsTableCreateCompanionBuilder,
    $$ProviderConfigsTableUpdateCompanionBuilder,
    (
      ProviderConfig,
      BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderConfig>
    ),
    ProviderConfig,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
}
