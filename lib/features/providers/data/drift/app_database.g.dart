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
  static const VerificationMeta _protocolMeta =
      const VerificationMeta('protocol');
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
      'protocol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('openai_compatible'));
  static const VerificationMeta _supportsImageInputMeta =
      const VerificationMeta('supportsImageInput');
  @override
  late final GeneratedColumn<bool> supportsImageInput = GeneratedColumn<bool>(
      'supports_image_input', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("supports_image_input" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _supportsFileInputMeta =
      const VerificationMeta('supportsFileInput');
  @override
  late final GeneratedColumn<bool> supportsFileInput = GeneratedColumn<bool>(
      'supports_file_input', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("supports_file_input" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        providerId,
        displayName,
        baseUrl,
        defaultModel,
        enabled,
        updatedAt,
        protocol,
        supportsImageInput,
        supportsFileInput
      ];
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
    if (data.containsKey('protocol')) {
      context.handle(_protocolMeta,
          protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta));
    }
    if (data.containsKey('supports_image_input')) {
      context.handle(
          _supportsImageInputMeta,
          supportsImageInput.isAcceptableOrUnknown(
              data['supports_image_input']!, _supportsImageInputMeta));
    }
    if (data.containsKey('supports_file_input')) {
      context.handle(
          _supportsFileInputMeta,
          supportsFileInput.isAcceptableOrUnknown(
              data['supports_file_input']!, _supportsFileInputMeta));
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
      protocol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}protocol'])!,
      supportsImageInput: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}supports_image_input'])!,
      supportsFileInput: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}supports_file_input'])!,
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
  final String protocol;
  final bool supportsImageInput;
  final bool supportsFileInput;
  const ProviderConfig(
      {required this.providerId,
      required this.displayName,
      required this.baseUrl,
      this.defaultModel,
      required this.enabled,
      required this.updatedAt,
      required this.protocol,
      required this.supportsImageInput,
      required this.supportsFileInput});
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
    map['protocol'] = Variable<String>(protocol);
    map['supports_image_input'] = Variable<bool>(supportsImageInput);
    map['supports_file_input'] = Variable<bool>(supportsFileInput);
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
      protocol: Value(protocol),
      supportsImageInput: Value(supportsImageInput),
      supportsFileInput: Value(supportsFileInput),
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
      protocol: serializer.fromJson<String>(json['protocol']),
      supportsImageInput: serializer.fromJson<bool>(json['supportsImageInput']),
      supportsFileInput: serializer.fromJson<bool>(json['supportsFileInput']),
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
      'protocol': serializer.toJson<String>(protocol),
      'supportsImageInput': serializer.toJson<bool>(supportsImageInput),
      'supportsFileInput': serializer.toJson<bool>(supportsFileInput),
    };
  }

  ProviderConfig copyWith(
          {String? providerId,
          String? displayName,
          String? baseUrl,
          Value<String?> defaultModel = const Value.absent(),
          bool? enabled,
          DateTime? updatedAt,
          String? protocol,
          bool? supportsImageInput,
          bool? supportsFileInput}) =>
      ProviderConfig(
        providerId: providerId ?? this.providerId,
        displayName: displayName ?? this.displayName,
        baseUrl: baseUrl ?? this.baseUrl,
        defaultModel:
            defaultModel.present ? defaultModel.value : this.defaultModel,
        enabled: enabled ?? this.enabled,
        updatedAt: updatedAt ?? this.updatedAt,
        protocol: protocol ?? this.protocol,
        supportsImageInput: supportsImageInput ?? this.supportsImageInput,
        supportsFileInput: supportsFileInput ?? this.supportsFileInput,
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
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      supportsImageInput: data.supportsImageInput.present
          ? data.supportsImageInput.value
          : this.supportsImageInput,
      supportsFileInput: data.supportsFileInput.present
          ? data.supportsFileInput.value
          : this.supportsFileInput,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('protocol: $protocol, ')
          ..write('supportsImageInput: $supportsImageInput, ')
          ..write('supportsFileInput: $supportsFileInput')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      providerId,
      displayName,
      baseUrl,
      defaultModel,
      enabled,
      updatedAt,
      protocol,
      supportsImageInput,
      supportsFileInput);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          other.providerId == this.providerId &&
          other.displayName == this.displayName &&
          other.baseUrl == this.baseUrl &&
          other.defaultModel == this.defaultModel &&
          other.enabled == this.enabled &&
          other.updatedAt == this.updatedAt &&
          other.protocol == this.protocol &&
          other.supportsImageInput == this.supportsImageInput &&
          other.supportsFileInput == this.supportsFileInput);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderConfig> {
  final Value<String> providerId;
  final Value<String> displayName;
  final Value<String> baseUrl;
  final Value<String?> defaultModel;
  final Value<bool> enabled;
  final Value<DateTime> updatedAt;
  final Value<String> protocol;
  final Value<bool> supportsImageInput;
  final Value<bool> supportsFileInput;
  final Value<int> rowid;
  const ProviderConfigsCompanion({
    this.providerId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.defaultModel = const Value.absent(),
    this.enabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.protocol = const Value.absent(),
    this.supportsImageInput = const Value.absent(),
    this.supportsFileInput = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    required String providerId,
    required String displayName,
    required String baseUrl,
    this.defaultModel = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime updatedAt,
    this.protocol = const Value.absent(),
    this.supportsImageInput = const Value.absent(),
    this.supportsFileInput = const Value.absent(),
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
    Expression<String>? protocol,
    Expression<bool>? supportsImageInput,
    Expression<bool>? supportsFileInput,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (displayName != null) 'display_name': displayName,
      if (baseUrl != null) 'base_url': baseUrl,
      if (defaultModel != null) 'default_model': defaultModel,
      if (enabled != null) 'enabled': enabled,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (protocol != null) 'protocol': protocol,
      if (supportsImageInput != null)
        'supports_image_input': supportsImageInput,
      if (supportsFileInput != null) 'supports_file_input': supportsFileInput,
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
      Value<String>? protocol,
      Value<bool>? supportsImageInput,
      Value<bool>? supportsFileInput,
      Value<int>? rowid}) {
    return ProviderConfigsCompanion(
      providerId: providerId ?? this.providerId,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      enabled: enabled ?? this.enabled,
      updatedAt: updatedAt ?? this.updatedAt,
      protocol: protocol ?? this.protocol,
      supportsImageInput: supportsImageInput ?? this.supportsImageInput,
      supportsFileInput: supportsFileInput ?? this.supportsFileInput,
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
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (supportsImageInput.present) {
      map['supports_image_input'] = Variable<bool>(supportsImageInput.value);
    }
    if (supportsFileInput.present) {
      map['supports_file_input'] = Variable<bool>(supportsFileInput.value);
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
          ..write('protocol: $protocol, ')
          ..write('supportsImageInput: $supportsImageInput, ')
          ..write('supportsFileInput: $supportsFileInput, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentProfilesTable extends AgentProfiles
    with TableInfo<$AgentProfilesTable, AgentProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemPromptMeta =
      const VerificationMeta('systemPrompt');
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
      'system_prompt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, systemPrompt, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<AgentProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
          _systemPromptMeta,
          systemPrompt.isAcceptableOrUnknown(
              data['system_prompt']!, _systemPromptMeta));
    } else if (isInserting) {
      context.missing(_systemPromptMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      systemPrompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_prompt'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AgentProfilesTable createAlias(String alias) {
    return $AgentProfilesTable(attachedDatabase, alias);
  }
}

class AgentProfile extends DataClass implements Insertable<AgentProfile> {
  final String id;
  final String name;
  final String? description;
  final String systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AgentProfile(
      {required this.id,
      required this.name,
      this.description,
      required this.systemPrompt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['system_prompt'] = Variable<String>(systemPrompt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AgentProfilesCompanion toCompanion(bool nullToAbsent) {
    return AgentProfilesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      systemPrompt: Value(systemPrompt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      systemPrompt: serializer.fromJson<String>(json['systemPrompt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'systemPrompt': serializer.toJson<String>(systemPrompt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AgentProfile copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          String? systemPrompt,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AgentProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AgentProfile copyWithCompanion(AgentProfilesCompanion data) {
    return AgentProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, systemPrompt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.systemPrompt == this.systemPrompt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentProfilesCompanion extends UpdateCompanion<AgentProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> systemPrompt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AgentProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentProfilesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String systemPrompt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        systemPrompt = Value(systemPrompt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AgentProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? systemPrompt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? systemPrompt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AgentProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('AgentProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentIdMeta =
      const VerificationMeta('agentId');
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
      'agent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _agentNameSnapshotMeta =
      const VerificationMeta('agentNameSnapshot');
  @override
  late final GeneratedColumn<String> agentNameSnapshot =
      GeneratedColumn<String>('agent_name_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemPromptSnapshotMeta =
      const VerificationMeta('systemPromptSnapshot');
  @override
  late final GeneratedColumn<String> systemPromptSnapshot =
      GeneratedColumn<String>('system_prompt_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        providerId,
        model,
        agentId,
        agentNameSnapshot,
        systemPromptSnapshot,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(_agentIdMeta,
          agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta));
    }
    if (data.containsKey('agent_name_snapshot')) {
      context.handle(
          _agentNameSnapshotMeta,
          agentNameSnapshot.isAcceptableOrUnknown(
              data['agent_name_snapshot']!, _agentNameSnapshotMeta));
    }
    if (data.containsKey('system_prompt_snapshot')) {
      context.handle(
          _systemPromptSnapshotMeta,
          systemPromptSnapshot.isAcceptableOrUnknown(
              data['system_prompt_snapshot']!, _systemPromptSnapshotMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      agentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_id']),
      agentNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}agent_name_snapshot']),
      systemPromptSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}system_prompt_snapshot']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String id;
  final String title;
  final String providerId;
  final String model;
  final String? agentId;
  final String? agentNameSnapshot;
  final String? systemPromptSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Conversation(
      {required this.id,
      required this.title,
      required this.providerId,
      required this.model,
      this.agentId,
      this.agentNameSnapshot,
      this.systemPromptSnapshot,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['provider_id'] = Variable<String>(providerId);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    if (!nullToAbsent || agentNameSnapshot != null) {
      map['agent_name_snapshot'] = Variable<String>(agentNameSnapshot);
    }
    if (!nullToAbsent || systemPromptSnapshot != null) {
      map['system_prompt_snapshot'] = Variable<String>(systemPromptSnapshot);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      providerId: Value(providerId),
      model: Value(model),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      agentNameSnapshot: agentNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(agentNameSnapshot),
      systemPromptSnapshot: systemPromptSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPromptSnapshot),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      providerId: serializer.fromJson<String>(json['providerId']),
      model: serializer.fromJson<String>(json['model']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      agentNameSnapshot:
          serializer.fromJson<String?>(json['agentNameSnapshot']),
      systemPromptSnapshot:
          serializer.fromJson<String?>(json['systemPromptSnapshot']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'providerId': serializer.toJson<String>(providerId),
      'model': serializer.toJson<String>(model),
      'agentId': serializer.toJson<String?>(agentId),
      'agentNameSnapshot': serializer.toJson<String?>(agentNameSnapshot),
      'systemPromptSnapshot': serializer.toJson<String?>(systemPromptSnapshot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Conversation copyWith(
          {String? id,
          String? title,
          String? providerId,
          String? model,
          Value<String?> agentId = const Value.absent(),
          Value<String?> agentNameSnapshot = const Value.absent(),
          Value<String?> systemPromptSnapshot = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        providerId: providerId ?? this.providerId,
        model: model ?? this.model,
        agentId: agentId.present ? agentId.value : this.agentId,
        agentNameSnapshot: agentNameSnapshot.present
            ? agentNameSnapshot.value
            : this.agentNameSnapshot,
        systemPromptSnapshot: systemPromptSnapshot.present
            ? systemPromptSnapshot.value
            : this.systemPromptSnapshot,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      model: data.model.present ? data.model.value : this.model,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      agentNameSnapshot: data.agentNameSnapshot.present
          ? data.agentNameSnapshot.value
          : this.agentNameSnapshot,
      systemPromptSnapshot: data.systemPromptSnapshot.present
          ? data.systemPromptSnapshot.value
          : this.systemPromptSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('providerId: $providerId, ')
          ..write('model: $model, ')
          ..write('agentId: $agentId, ')
          ..write('agentNameSnapshot: $agentNameSnapshot, ')
          ..write('systemPromptSnapshot: $systemPromptSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, providerId, model, agentId,
      agentNameSnapshot, systemPromptSnapshot, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.providerId == this.providerId &&
          other.model == this.model &&
          other.agentId == this.agentId &&
          other.agentNameSnapshot == this.agentNameSnapshot &&
          other.systemPromptSnapshot == this.systemPromptSnapshot &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> providerId;
  final Value<String> model;
  final Value<String?> agentId;
  final Value<String?> agentNameSnapshot;
  final Value<String?> systemPromptSnapshot;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.providerId = const Value.absent(),
    this.model = const Value.absent(),
    this.agentId = const Value.absent(),
    this.agentNameSnapshot = const Value.absent(),
    this.systemPromptSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    required String title,
    required String providerId,
    required String model,
    this.agentId = const Value.absent(),
    this.agentNameSnapshot = const Value.absent(),
    this.systemPromptSnapshot = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        providerId = Value(providerId),
        model = Value(model),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? providerId,
    Expression<String>? model,
    Expression<String>? agentId,
    Expression<String>? agentNameSnapshot,
    Expression<String>? systemPromptSnapshot,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (providerId != null) 'provider_id': providerId,
      if (model != null) 'model': model,
      if (agentId != null) 'agent_id': agentId,
      if (agentNameSnapshot != null) 'agent_name_snapshot': agentNameSnapshot,
      if (systemPromptSnapshot != null)
        'system_prompt_snapshot': systemPromptSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? providerId,
      Value<String>? model,
      Value<String?>? agentId,
      Value<String?>? agentNameSnapshot,
      Value<String?>? systemPromptSnapshot,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      agentId: agentId ?? this.agentId,
      agentNameSnapshot: agentNameSnapshot ?? this.agentNameSnapshot,
      systemPromptSnapshot: systemPromptSnapshot ?? this.systemPromptSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (agentNameSnapshot.present) {
      map['agent_name_snapshot'] = Variable<String>(agentNameSnapshot.value);
    }
    if (systemPromptSnapshot.present) {
      map['system_prompt_snapshot'] =
          Variable<String>(systemPromptSnapshot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('providerId: $providerId, ')
          ..write('model: $model, ')
          ..write('agentId: $agentId, ')
          ..write('agentNameSnapshot: $agentNameSnapshot, ')
          ..write('systemPromptSnapshot: $systemPromptSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES conversations (id) ON DELETE CASCADE'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdSnapshotMeta =
      const VerificationMeta('providerIdSnapshot');
  @override
  late final GeneratedColumn<String> providerIdSnapshot =
      GeneratedColumn<String>('provider_id_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _providerNameSnapshotMeta =
      const VerificationMeta('providerNameSnapshot');
  @override
  late final GeneratedColumn<String> providerNameSnapshot =
      GeneratedColumn<String>('provider_name_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelIdSnapshotMeta =
      const VerificationMeta('modelIdSnapshot');
  @override
  late final GeneratedColumn<String> modelIdSnapshot = GeneratedColumn<String>(
      'model_id_snapshot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        conversationId,
        role,
        content,
        providerIdSnapshot,
        providerNameSnapshot,
        modelIdSnapshot,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('provider_id_snapshot')) {
      context.handle(
          _providerIdSnapshotMeta,
          providerIdSnapshot.isAcceptableOrUnknown(
              data['provider_id_snapshot']!, _providerIdSnapshotMeta));
    }
    if (data.containsKey('provider_name_snapshot')) {
      context.handle(
          _providerNameSnapshotMeta,
          providerNameSnapshot.isAcceptableOrUnknown(
              data['provider_name_snapshot']!, _providerNameSnapshotMeta));
    }
    if (data.containsKey('model_id_snapshot')) {
      context.handle(
          _modelIdSnapshotMeta,
          modelIdSnapshot.isAcceptableOrUnknown(
              data['model_id_snapshot']!, _modelIdSnapshotMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      providerIdSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}provider_id_snapshot']),
      providerNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}provider_name_snapshot']),
      modelIdSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}model_id_snapshot']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final String? providerIdSnapshot;
  final String? providerNameSnapshot;
  final String? modelIdSnapshot;
  final DateTime createdAt;
  const ChatMessage(
      {required this.id,
      required this.conversationId,
      required this.role,
      required this.content,
      this.providerIdSnapshot,
      this.providerNameSnapshot,
      this.modelIdSnapshot,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || providerIdSnapshot != null) {
      map['provider_id_snapshot'] = Variable<String>(providerIdSnapshot);
    }
    if (!nullToAbsent || providerNameSnapshot != null) {
      map['provider_name_snapshot'] = Variable<String>(providerNameSnapshot);
    }
    if (!nullToAbsent || modelIdSnapshot != null) {
      map['model_id_snapshot'] = Variable<String>(modelIdSnapshot);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      providerIdSnapshot: providerIdSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(providerIdSnapshot),
      providerNameSnapshot: providerNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(providerNameSnapshot),
      modelIdSnapshot: modelIdSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(modelIdSnapshot),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      providerIdSnapshot:
          serializer.fromJson<String?>(json['providerIdSnapshot']),
      providerNameSnapshot:
          serializer.fromJson<String?>(json['providerNameSnapshot']),
      modelIdSnapshot: serializer.fromJson<String?>(json['modelIdSnapshot']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'providerIdSnapshot': serializer.toJson<String?>(providerIdSnapshot),
      'providerNameSnapshot': serializer.toJson<String?>(providerNameSnapshot),
      'modelIdSnapshot': serializer.toJson<String?>(modelIdSnapshot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessage copyWith(
          {String? id,
          String? conversationId,
          String? role,
          String? content,
          Value<String?> providerIdSnapshot = const Value.absent(),
          Value<String?> providerNameSnapshot = const Value.absent(),
          Value<String?> modelIdSnapshot = const Value.absent(),
          DateTime? createdAt}) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        providerIdSnapshot: providerIdSnapshot.present
            ? providerIdSnapshot.value
            : this.providerIdSnapshot,
        providerNameSnapshot: providerNameSnapshot.present
            ? providerNameSnapshot.value
            : this.providerNameSnapshot,
        modelIdSnapshot: modelIdSnapshot.present
            ? modelIdSnapshot.value
            : this.modelIdSnapshot,
        createdAt: createdAt ?? this.createdAt,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      providerIdSnapshot: data.providerIdSnapshot.present
          ? data.providerIdSnapshot.value
          : this.providerIdSnapshot,
      providerNameSnapshot: data.providerNameSnapshot.present
          ? data.providerNameSnapshot.value
          : this.providerNameSnapshot,
      modelIdSnapshot: data.modelIdSnapshot.present
          ? data.modelIdSnapshot.value
          : this.modelIdSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('providerIdSnapshot: $providerIdSnapshot, ')
          ..write('providerNameSnapshot: $providerNameSnapshot, ')
          ..write('modelIdSnapshot: $modelIdSnapshot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, role, content,
      providerIdSnapshot, providerNameSnapshot, modelIdSnapshot, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.providerIdSnapshot == this.providerIdSnapshot &&
          other.providerNameSnapshot == this.providerNameSnapshot &&
          other.modelIdSnapshot == this.modelIdSnapshot &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> providerIdSnapshot;
  final Value<String?> providerNameSnapshot;
  final Value<String?> modelIdSnapshot;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.providerIdSnapshot = const Value.absent(),
    this.providerNameSnapshot = const Value.absent(),
    this.modelIdSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String role,
    required String content,
    this.providerIdSnapshot = const Value.absent(),
    this.providerNameSnapshot = const Value.absent(),
    this.modelIdSnapshot = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        conversationId = Value(conversationId),
        role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<ChatMessage> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? providerIdSnapshot,
    Expression<String>? providerNameSnapshot,
    Expression<String>? modelIdSnapshot,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (providerIdSnapshot != null)
        'provider_id_snapshot': providerIdSnapshot,
      if (providerNameSnapshot != null)
        'provider_name_snapshot': providerNameSnapshot,
      if (modelIdSnapshot != null) 'model_id_snapshot': modelIdSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? conversationId,
      Value<String>? role,
      Value<String>? content,
      Value<String?>? providerIdSnapshot,
      Value<String?>? providerNameSnapshot,
      Value<String?>? modelIdSnapshot,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      providerIdSnapshot: providerIdSnapshot ?? this.providerIdSnapshot,
      providerNameSnapshot: providerNameSnapshot ?? this.providerNameSnapshot,
      modelIdSnapshot: modelIdSnapshot ?? this.modelIdSnapshot,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (providerIdSnapshot.present) {
      map['provider_id_snapshot'] = Variable<String>(providerIdSnapshot.value);
    }
    if (providerNameSnapshot.present) {
      map['provider_name_snapshot'] =
          Variable<String>(providerNameSnapshot.value);
    }
    if (modelIdSnapshot.present) {
      map['model_id_snapshot'] = Variable<String>(modelIdSnapshot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('providerIdSnapshot: $providerIdSnapshot, ')
          ..write('providerNameSnapshot: $providerNameSnapshot, ')
          ..write('modelIdSnapshot: $modelIdSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatAttachmentsTable extends ChatAttachments
    with TableInfo<$ChatAttachmentsTable, ChatAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES chat_messages (id) ON DELETE CASCADE'));
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES conversations (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fileName,
        mimeType,
        fileSize,
        localPath,
        kind,
        messageId,
        conversationId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_attachments';
  @override
  VerificationContext validateIntegrity(Insertable<ChatAttachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatAttachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
    );
  }

  @override
  $ChatAttachmentsTable createAlias(String alias) {
    return $ChatAttachmentsTable(attachedDatabase, alias);
  }
}

class ChatAttachment extends DataClass implements Insertable<ChatAttachment> {
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String localPath;
  final String kind;
  final String messageId;
  final String conversationId;
  const ChatAttachment(
      {required this.id,
      required this.fileName,
      required this.mimeType,
      required this.fileSize,
      required this.localPath,
      required this.kind,
      required this.messageId,
      required this.conversationId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    map['local_path'] = Variable<String>(localPath);
    map['kind'] = Variable<String>(kind);
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    return map;
  }

  ChatAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return ChatAttachmentsCompanion(
      id: Value(id),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      localPath: Value(localPath),
      kind: Value(kind),
      messageId: Value(messageId),
      conversationId: Value(conversationId),
    );
  }

  factory ChatAttachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatAttachment(
      id: serializer.fromJson<String>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      localPath: serializer.fromJson<String>(json['localPath']),
      kind: serializer.fromJson<String>(json['kind']),
      messageId: serializer.fromJson<String>(json['messageId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'localPath': serializer.toJson<String>(localPath),
      'kind': serializer.toJson<String>(kind),
      'messageId': serializer.toJson<String>(messageId),
      'conversationId': serializer.toJson<String>(conversationId),
    };
  }

  ChatAttachment copyWith(
          {String? id,
          String? fileName,
          String? mimeType,
          int? fileSize,
          String? localPath,
          String? kind,
          String? messageId,
          String? conversationId}) =>
      ChatAttachment(
        id: id ?? this.id,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
        fileSize: fileSize ?? this.fileSize,
        localPath: localPath ?? this.localPath,
        kind: kind ?? this.kind,
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
      );
  ChatAttachment copyWithCompanion(ChatAttachmentsCompanion data) {
    return ChatAttachment(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      kind: data.kind.present ? data.kind.value : this.kind,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatAttachment(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('localPath: $localPath, ')
          ..write('kind: $kind, ')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fileName, mimeType, fileSize, localPath,
      kind, messageId, conversationId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatAttachment &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.localPath == this.localPath &&
          other.kind == this.kind &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId);
}

class ChatAttachmentsCompanion extends UpdateCompanion<ChatAttachment> {
  final Value<String> id;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<String> localPath;
  final Value<String> kind;
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<int> rowid;
  const ChatAttachmentsCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.localPath = const Value.absent(),
    this.kind = const Value.absent(),
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatAttachmentsCompanion.insert({
    required String id,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String localPath,
    required String kind,
    required String messageId,
    required String conversationId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fileName = Value(fileName),
        mimeType = Value(mimeType),
        fileSize = Value(fileSize),
        localPath = Value(localPath),
        kind = Value(kind),
        messageId = Value(messageId),
        conversationId = Value(conversationId);
  static Insertable<ChatAttachment> custom({
    Expression<String>? id,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<String>? localPath,
    Expression<String>? kind,
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (localPath != null) 'local_path': localPath,
      if (kind != null) 'kind': kind,
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatAttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? fileName,
      Value<String>? mimeType,
      Value<int>? fileSize,
      Value<String>? localPath,
      Value<String>? kind,
      Value<String>? messageId,
      Value<String>? conversationId,
      Value<int>? rowid}) {
    return ChatAttachmentsCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      localPath: localPath ?? this.localPath,
      kind: kind ?? this.kind,
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('localPath: $localPath, ')
          ..write('kind: $kind, ')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentDeliveryStatesTable extends AttachmentDeliveryStates
    with TableInfo<$AttachmentDeliveryStatesTable, AttachmentDeliveryStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentDeliveryStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta =
      const VerificationMeta('attachmentId');
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
      'attachment_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES chat_attachments (id) ON DELETE CASCADE'));
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [attachmentId, providerId, modelId, status, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_delivery_states';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttachmentDeliveryStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
          _attachmentIdMeta,
          attachmentId.isAcceptableOrUnknown(
              data['attachment_id']!, _attachmentIdMeta));
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  Set<GeneratedColumn> get $primaryKey => {attachmentId, providerId, modelId};
  @override
  AttachmentDeliveryStateRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentDeliveryStateRow(
      attachmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_id'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AttachmentDeliveryStatesTable createAlias(String alias) {
    return $AttachmentDeliveryStatesTable(attachedDatabase, alias);
  }
}

class AttachmentDeliveryStateRow extends DataClass
    implements Insertable<AttachmentDeliveryStateRow> {
  final String attachmentId;
  final String providerId;
  final String modelId;
  final String status;
  final DateTime updatedAt;
  const AttachmentDeliveryStateRow(
      {required this.attachmentId,
      required this.providerId,
      required this.modelId,
      required this.status,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    map['provider_id'] = Variable<String>(providerId);
    map['model_id'] = Variable<String>(modelId);
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AttachmentDeliveryStatesCompanion toCompanion(bool nullToAbsent) {
    return AttachmentDeliveryStatesCompanion(
      attachmentId: Value(attachmentId),
      providerId: Value(providerId),
      modelId: Value(modelId),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory AttachmentDeliveryStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentDeliveryStateRow(
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      modelId: serializer.fromJson<String>(json['modelId']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<String>(attachmentId),
      'providerId': serializer.toJson<String>(providerId),
      'modelId': serializer.toJson<String>(modelId),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AttachmentDeliveryStateRow copyWith(
          {String? attachmentId,
          String? providerId,
          String? modelId,
          String? status,
          DateTime? updatedAt}) =>
      AttachmentDeliveryStateRow(
        attachmentId: attachmentId ?? this.attachmentId,
        providerId: providerId ?? this.providerId,
        modelId: modelId ?? this.modelId,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AttachmentDeliveryStateRow copyWithCompanion(
      AttachmentDeliveryStatesCompanion data) {
    return AttachmentDeliveryStateRow(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentDeliveryStateRow(')
          ..write('attachmentId: $attachmentId, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(attachmentId, providerId, modelId, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentDeliveryStateRow &&
          other.attachmentId == this.attachmentId &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class AttachmentDeliveryStatesCompanion
    extends UpdateCompanion<AttachmentDeliveryStateRow> {
  final Value<String> attachmentId;
  final Value<String> providerId;
  final Value<String> modelId;
  final Value<String> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AttachmentDeliveryStatesCompanion({
    this.attachmentId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentDeliveryStatesCompanion.insert({
    required String attachmentId,
    required String providerId,
    required String modelId,
    required String status,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : attachmentId = Value(attachmentId),
        providerId = Value(providerId),
        modelId = Value(modelId),
        status = Value(status),
        updatedAt = Value(updatedAt);
  static Insertable<AttachmentDeliveryStateRow> custom({
    Expression<String>? attachmentId,
    Expression<String>? providerId,
    Expression<String>? modelId,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentDeliveryStatesCompanion copyWith(
      {Value<String>? attachmentId,
      Value<String>? providerId,
      Value<String>? modelId,
      Value<String>? status,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AttachmentDeliveryStatesCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    return (StringBuffer('AttachmentDeliveryStatesCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelAttachmentCapabilitiesTable extends ModelAttachmentCapabilities
    with
        TableInfo<$ModelAttachmentCapabilitiesTable,
            ModelAttachmentCapabilityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelAttachmentCapabilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES provider_configs (provider_id) ON DELETE CASCADE'));
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modalityMeta =
      const VerificationMeta('modality');
  @override
  late final GeneratedColumn<String> modality = GeneratedColumn<String>(
      'modality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [providerId, modelId, modality, status, source, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_attachment_capabilities';
  @override
  VerificationContext validateIntegrity(
      Insertable<ModelAttachmentCapabilityRow> instance,
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
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('modality')) {
      context.handle(_modalityMeta,
          modality.isAcceptableOrUnknown(data['modality']!, _modalityMeta));
    } else if (isInserting) {
      context.missing(_modalityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
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
  Set<GeneratedColumn> get $primaryKey =>
      {providerId, modelId, modality, source};
  @override
  ModelAttachmentCapabilityRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelAttachmentCapabilityRow(
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      modality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modality'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ModelAttachmentCapabilitiesTable createAlias(String alias) {
    return $ModelAttachmentCapabilitiesTable(attachedDatabase, alias);
  }
}

class ModelAttachmentCapabilityRow extends DataClass
    implements Insertable<ModelAttachmentCapabilityRow> {
  final String providerId;
  final String modelId;
  final String modality;
  final String status;
  final String source;
  final DateTime updatedAt;
  const ModelAttachmentCapabilityRow(
      {required this.providerId,
      required this.modelId,
      required this.modality,
      required this.status,
      required this.source,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['model_id'] = Variable<String>(modelId);
    map['modality'] = Variable<String>(modality);
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ModelAttachmentCapabilitiesCompanion toCompanion(bool nullToAbsent) {
    return ModelAttachmentCapabilitiesCompanion(
      providerId: Value(providerId),
      modelId: Value(modelId),
      modality: Value(modality),
      status: Value(status),
      source: Value(source),
      updatedAt: Value(updatedAt),
    );
  }

  factory ModelAttachmentCapabilityRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelAttachmentCapabilityRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      modelId: serializer.fromJson<String>(json['modelId']),
      modality: serializer.fromJson<String>(json['modality']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'modelId': serializer.toJson<String>(modelId),
      'modality': serializer.toJson<String>(modality),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ModelAttachmentCapabilityRow copyWith(
          {String? providerId,
          String? modelId,
          String? modality,
          String? status,
          String? source,
          DateTime? updatedAt}) =>
      ModelAttachmentCapabilityRow(
        providerId: providerId ?? this.providerId,
        modelId: modelId ?? this.modelId,
        modality: modality ?? this.modality,
        status: status ?? this.status,
        source: source ?? this.source,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ModelAttachmentCapabilityRow copyWithCompanion(
      ModelAttachmentCapabilitiesCompanion data) {
    return ModelAttachmentCapabilityRow(
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modality: data.modality.present ? data.modality.value : this.modality,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelAttachmentCapabilityRow(')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('modality: $modality, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(providerId, modelId, modality, status, source, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelAttachmentCapabilityRow &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId &&
          other.modality == this.modality &&
          other.status == this.status &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class ModelAttachmentCapabilitiesCompanion
    extends UpdateCompanion<ModelAttachmentCapabilityRow> {
  final Value<String> providerId;
  final Value<String> modelId;
  final Value<String> modality;
  final Value<String> status;
  final Value<String> source;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ModelAttachmentCapabilitiesCompanion({
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modality = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelAttachmentCapabilitiesCompanion.insert({
    required String providerId,
    required String modelId,
    required String modality,
    required String status,
    required String source,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : providerId = Value(providerId),
        modelId = Value(modelId),
        modality = Value(modality),
        status = Value(status),
        source = Value(source),
        updatedAt = Value(updatedAt);
  static Insertable<ModelAttachmentCapabilityRow> custom({
    Expression<String>? providerId,
    Expression<String>? modelId,
    Expression<String>? modality,
    Expression<String>? status,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (modality != null) 'modality': modality,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelAttachmentCapabilitiesCompanion copyWith(
      {Value<String>? providerId,
      Value<String>? modelId,
      Value<String>? modality,
      Value<String>? status,
      Value<String>? source,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ModelAttachmentCapabilitiesCompanion(
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      modality: modality ?? this.modality,
      status: status ?? this.status,
      source: source ?? this.source,
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
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modality.present) {
      map['modality'] = Variable<String>(modality.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
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
    return (StringBuffer('ModelAttachmentCapabilitiesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('modality: $modality, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
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
  late final $AgentProfilesTable agentProfiles = $AgentProfilesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ChatAttachmentsTable chatAttachments =
      $ChatAttachmentsTable(this);
  late final $AttachmentDeliveryStatesTable attachmentDeliveryStates =
      $AttachmentDeliveryStatesTable(this);
  late final $ModelAttachmentCapabilitiesTable modelAttachmentCapabilities =
      $ModelAttachmentCapabilitiesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        providerConfigs,
        agentProfiles,
        conversations,
        chatMessages,
        chatAttachments,
        attachmentDeliveryStates,
        modelAttachmentCapabilities
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('conversations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('chat_messages', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('chat_messages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('chat_attachments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('conversations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('chat_attachments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('chat_attachments',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('attachment_delivery_states',
                  kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('provider_configs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('model_attachment_capabilities',
                  kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ProviderConfigsTableCreateCompanionBuilder = ProviderConfigsCompanion
    Function({
  required String providerId,
  required String displayName,
  required String baseUrl,
  Value<String?> defaultModel,
  Value<bool> enabled,
  required DateTime updatedAt,
  Value<String> protocol,
  Value<bool> supportsImageInput,
  Value<bool> supportsFileInput,
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
  Value<String> protocol,
  Value<bool> supportsImageInput,
  Value<bool> supportsFileInput,
  Value<int> rowid,
});

final class $$ProviderConfigsTableReferences extends BaseReferences<
    _$AppDatabase, $ProviderConfigsTable, ProviderConfig> {
  $$ProviderConfigsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ModelAttachmentCapabilitiesTable,
      List<ModelAttachmentCapabilityRow>> _modelAttachmentCapabilitiesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.modelAttachmentCapabilities,
          aliasName: $_aliasNameGenerator(db.providerConfigs.providerId,
              db.modelAttachmentCapabilities.providerId));

  $$ModelAttachmentCapabilitiesTableProcessedTableManager
      get modelAttachmentCapabilitiesRefs {
    final manager = $$ModelAttachmentCapabilitiesTableTableManager(
            $_db, $_db.modelAttachmentCapabilities)
        .filter((f) => f.providerId.providerId
            .sqlEquals($_itemColumn<String>('provider_id')!));

    final cache = $_typedResult
        .readTableOrNull(_modelAttachmentCapabilitiesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

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

  ColumnFilters<String> get protocol => $composableBuilder(
      column: $table.protocol, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get supportsImageInput => $composableBuilder(
      column: $table.supportsImageInput,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get supportsFileInput => $composableBuilder(
      column: $table.supportsFileInput,
      builder: (column) => ColumnFilters(column));

  Expression<bool> modelAttachmentCapabilitiesRefs(
      Expression<bool> Function(
              $$ModelAttachmentCapabilitiesTableFilterComposer f)
          f) {
    final $$ModelAttachmentCapabilitiesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.providerId,
            referencedTable: $db.modelAttachmentCapabilities,
            getReferencedColumn: (t) => t.providerId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ModelAttachmentCapabilitiesTableFilterComposer(
                  $db: $db,
                  $table: $db.modelAttachmentCapabilities,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
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

  ColumnOrderings<String> get protocol => $composableBuilder(
      column: $table.protocol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get supportsImageInput => $composableBuilder(
      column: $table.supportsImageInput,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get supportsFileInput => $composableBuilder(
      column: $table.supportsFileInput,
      builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<bool> get supportsImageInput => $composableBuilder(
      column: $table.supportsImageInput, builder: (column) => column);

  GeneratedColumn<bool> get supportsFileInput => $composableBuilder(
      column: $table.supportsFileInput, builder: (column) => column);

  Expression<T> modelAttachmentCapabilitiesRefs<T extends Object>(
      Expression<T> Function(
              $$ModelAttachmentCapabilitiesTableAnnotationComposer a)
          f) {
    final $$ModelAttachmentCapabilitiesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.providerId,
            referencedTable: $db.modelAttachmentCapabilities,
            getReferencedColumn: (t) => t.providerId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ModelAttachmentCapabilitiesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.modelAttachmentCapabilities,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
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
    (ProviderConfig, $$ProviderConfigsTableReferences),
    ProviderConfig,
    PrefetchHooks Function({bool modelAttachmentCapabilitiesRefs})> {
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
            Value<String> protocol = const Value.absent(),
            Value<bool> supportsImageInput = const Value.absent(),
            Value<bool> supportsFileInput = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderConfigsCompanion(
            providerId: providerId,
            displayName: displayName,
            baseUrl: baseUrl,
            defaultModel: defaultModel,
            enabled: enabled,
            updatedAt: updatedAt,
            protocol: protocol,
            supportsImageInput: supportsImageInput,
            supportsFileInput: supportsFileInput,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String providerId,
            required String displayName,
            required String baseUrl,
            Value<String?> defaultModel = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            required DateTime updatedAt,
            Value<String> protocol = const Value.absent(),
            Value<bool> supportsImageInput = const Value.absent(),
            Value<bool> supportsFileInput = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderConfigsCompanion.insert(
            providerId: providerId,
            displayName: displayName,
            baseUrl: baseUrl,
            defaultModel: defaultModel,
            enabled: enabled,
            updatedAt: updatedAt,
            protocol: protocol,
            supportsImageInput: supportsImageInput,
            supportsFileInput: supportsFileInput,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProviderConfigsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({modelAttachmentCapabilitiesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (modelAttachmentCapabilitiesRefs)
                  db.modelAttachmentCapabilities
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (modelAttachmentCapabilitiesRefs)
                    await $_getPrefetchedData<
                            ProviderConfig,
                            $ProviderConfigsTable,
                            ModelAttachmentCapabilityRow>(
                        currentTable: table,
                        referencedTable: $$ProviderConfigsTableReferences
                            ._modelAttachmentCapabilitiesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProviderConfigsTableReferences(db, table, p0)
                                .modelAttachmentCapabilitiesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.providerId == item.providerId),
                        typedResults: items)
                ];
              },
            );
          },
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
    (ProviderConfig, $$ProviderConfigsTableReferences),
    ProviderConfig,
    PrefetchHooks Function({bool modelAttachmentCapabilitiesRefs})>;
typedef $$AgentProfilesTableCreateCompanionBuilder = AgentProfilesCompanion
    Function({
  required String id,
  required String name,
  Value<String?> description,
  required String systemPrompt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AgentProfilesTableUpdateCompanionBuilder = AgentProfilesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String> systemPrompt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AgentProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $AgentProfilesTable> {
  $$AgentProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AgentProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentProfilesTable> {
  $$AgentProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AgentProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentProfilesTable> {
  $$AgentProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AgentProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AgentProfilesTable,
    AgentProfile,
    $$AgentProfilesTableFilterComposer,
    $$AgentProfilesTableOrderingComposer,
    $$AgentProfilesTableAnnotationComposer,
    $$AgentProfilesTableCreateCompanionBuilder,
    $$AgentProfilesTableUpdateCompanionBuilder,
    (
      AgentProfile,
      BaseReferences<_$AppDatabase, $AgentProfilesTable, AgentProfile>
    ),
    AgentProfile,
    PrefetchHooks Function()> {
  $$AgentProfilesTableTableManager(_$AppDatabase db, $AgentProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> systemPrompt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentProfilesCompanion(
            id: id,
            name: name,
            description: description,
            systemPrompt: systemPrompt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            required String systemPrompt,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentProfilesCompanion.insert(
            id: id,
            name: name,
            description: description,
            systemPrompt: systemPrompt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AgentProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AgentProfilesTable,
    AgentProfile,
    $$AgentProfilesTableFilterComposer,
    $$AgentProfilesTableOrderingComposer,
    $$AgentProfilesTableAnnotationComposer,
    $$AgentProfilesTableCreateCompanionBuilder,
    $$AgentProfilesTableUpdateCompanionBuilder,
    (
      AgentProfile,
      BaseReferences<_$AppDatabase, $AgentProfilesTable, AgentProfile>
    ),
    AgentProfile,
    PrefetchHooks Function()>;
typedef $$ConversationsTableCreateCompanionBuilder = ConversationsCompanion
    Function({
  required String id,
  required String title,
  required String providerId,
  required String model,
  Value<String?> agentId,
  Value<String?> agentNameSnapshot,
  Value<String?> systemPromptSnapshot,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ConversationsTableUpdateCompanionBuilder = ConversationsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> providerId,
  Value<String> model,
  Value<String?> agentId,
  Value<String?> agentNameSnapshot,
  Value<String?> systemPromptSnapshot,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ConversationsTableReferences
    extends BaseReferences<_$AppDatabase, $ConversationsTable, Conversation> {
  $$ConversationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessage>>
      _chatMessagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatMessages,
              aliasName: $_aliasNameGenerator(
                  db.conversations.id, db.chatMessages.conversationId));

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager($_db, $_db.chatMessages)
        .filter(
            (f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ChatAttachmentsTable, List<ChatAttachment>>
      _chatAttachmentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatAttachments,
              aliasName: $_aliasNameGenerator(
                  db.conversations.id, db.chatAttachments.conversationId));

  $$ChatAttachmentsTableProcessedTableManager get chatAttachmentsRefs {
    final manager =
        $$ChatAttachmentsTableTableManager($_db, $_db.chatAttachments).filter(
            (f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_chatAttachmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentId => $composableBuilder(
      column: $table.agentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentNameSnapshot => $composableBuilder(
      column: $table.agentNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPromptSnapshot => $composableBuilder(
      column: $table.systemPromptSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> chatMessagesRefs(
      Expression<bool> Function($$ChatMessagesTableFilterComposer f) f) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableFilterComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> chatAttachmentsRefs(
      Expression<bool> Function($$ChatAttachmentsTableFilterComposer f) f) {
    final $$ChatAttachmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableFilterComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentId => $composableBuilder(
      column: $table.agentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentNameSnapshot => $composableBuilder(
      column: $table.agentNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPromptSnapshot => $composableBuilder(
      column: $table.systemPromptSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get agentNameSnapshot => $composableBuilder(
      column: $table.agentNameSnapshot, builder: (column) => column);

  GeneratedColumn<String> get systemPromptSnapshot => $composableBuilder(
      column: $table.systemPromptSnapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chatMessagesRefs<T extends Object>(
      Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> chatAttachmentsRefs<T extends Object>(
      Expression<T> Function($$ChatAttachmentsTableAnnotationComposer a) f) {
    final $$ChatAttachmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (Conversation, $$ConversationsTableReferences),
    Conversation,
    PrefetchHooks Function({bool chatMessagesRefs, bool chatAttachmentsRefs})> {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<String?> agentId = const Value.absent(),
            Value<String?> agentNameSnapshot = const Value.absent(),
            Value<String?> systemPromptSnapshot = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion(
            id: id,
            title: title,
            providerId: providerId,
            model: model,
            agentId: agentId,
            agentNameSnapshot: agentNameSnapshot,
            systemPromptSnapshot: systemPromptSnapshot,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String providerId,
            required String model,
            Value<String?> agentId = const Value.absent(),
            Value<String?> agentNameSnapshot = const Value.absent(),
            Value<String?> systemPromptSnapshot = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion.insert(
            id: id,
            title: title,
            providerId: providerId,
            model: model,
            agentId: agentId,
            agentNameSnapshot: agentNameSnapshot,
            systemPromptSnapshot: systemPromptSnapshot,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConversationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {chatMessagesRefs = false, chatAttachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (chatMessagesRefs) db.chatMessages,
                if (chatAttachmentsRefs) db.chatAttachments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData<Conversation, $ConversationsTable,
                            ChatMessage>(
                        currentTable: table,
                        referencedTable: $$ConversationsTableReferences
                            ._chatMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ConversationsTableReferences(db, table, p0)
                                .chatMessagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.conversationId == item.id),
                        typedResults: items),
                  if (chatAttachmentsRefs)
                    await $_getPrefetchedData<Conversation, $ConversationsTable, ChatAttachment>(
                        currentTable: table,
                        referencedTable: $$ConversationsTableReferences
                            ._chatAttachmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ConversationsTableReferences(db, table, p0)
                                .chatAttachmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.conversationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ConversationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (Conversation, $$ConversationsTableReferences),
    Conversation,
    PrefetchHooks Function({bool chatMessagesRefs, bool chatAttachmentsRefs})>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  required String id,
  required String conversationId,
  required String role,
  required String content,
  Value<String?> providerIdSnapshot,
  Value<String?> providerNameSnapshot,
  Value<String?> modelIdSnapshot,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<String> id,
  Value<String> conversationId,
  Value<String> role,
  Value<String> content,
  Value<String?> providerIdSnapshot,
  Value<String?> providerNameSnapshot,
  Value<String?> modelIdSnapshot,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ChatMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias($_aliasNameGenerator(
          db.chatMessages.conversationId, db.conversations.id));

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager($_db, $_db.conversations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ChatAttachmentsTable, List<ChatAttachment>>
      _chatAttachmentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatAttachments,
              aliasName: $_aliasNameGenerator(
                  db.chatMessages.id, db.chatAttachments.messageId));

  $$ChatAttachmentsTableProcessedTableManager get chatAttachmentsRefs {
    final manager = $$ChatAttachmentsTableTableManager(
            $_db, $_db.chatAttachments)
        .filter((f) => f.messageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_chatAttachmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerIdSnapshot => $composableBuilder(
      column: $table.providerIdSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerNameSnapshot => $composableBuilder(
      column: $table.providerNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelIdSnapshot => $composableBuilder(
      column: $table.modelIdSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableFilterComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> chatAttachmentsRefs(
      Expression<bool> Function($$ChatAttachmentsTableFilterComposer f) f) {
    final $$ChatAttachmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableFilterComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerIdSnapshot => $composableBuilder(
      column: $table.providerIdSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerNameSnapshot => $composableBuilder(
      column: $table.providerNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelIdSnapshot => $composableBuilder(
      column: $table.modelIdSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableOrderingComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get providerIdSnapshot => $composableBuilder(
      column: $table.providerIdSnapshot, builder: (column) => column);

  GeneratedColumn<String> get providerNameSnapshot => $composableBuilder(
      column: $table.providerNameSnapshot, builder: (column) => column);

  GeneratedColumn<String> get modelIdSnapshot => $composableBuilder(
      column: $table.modelIdSnapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableAnnotationComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> chatAttachmentsRefs<T extends Object>(
      Expression<T> Function($$ChatAttachmentsTableAnnotationComposer a) f) {
    final $$ChatAttachmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessage, $$ChatMessagesTableReferences),
    ChatMessage,
    PrefetchHooks Function({bool conversationId, bool chatAttachmentsRefs})> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> conversationId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> providerIdSnapshot = const Value.absent(),
            Value<String?> providerNameSnapshot = const Value.absent(),
            Value<String?> modelIdSnapshot = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            providerIdSnapshot: providerIdSnapshot,
            providerNameSnapshot: providerNameSnapshot,
            modelIdSnapshot: modelIdSnapshot,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String conversationId,
            required String role,
            required String content,
            Value<String?> providerIdSnapshot = const Value.absent(),
            Value<String?> providerNameSnapshot = const Value.absent(),
            Value<String?> modelIdSnapshot = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            providerIdSnapshot: providerIdSnapshot,
            providerNameSnapshot: providerNameSnapshot,
            modelIdSnapshot: modelIdSnapshot,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatMessagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {conversationId = false, chatAttachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (chatAttachmentsRefs) db.chatAttachments
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (conversationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.conversationId,
                    referencedTable:
                        $$ChatMessagesTableReferences._conversationIdTable(db),
                    referencedColumn: $$ChatMessagesTableReferences
                        ._conversationIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatAttachmentsRefs)
                    await $_getPrefetchedData<ChatMessage, $ChatMessagesTable,
                            ChatAttachment>(
                        currentTable: table,
                        referencedTable: $$ChatMessagesTableReferences
                            ._chatAttachmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatMessagesTableReferences(db, table, p0)
                                .chatAttachmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessage, $$ChatMessagesTableReferences),
    ChatMessage,
    PrefetchHooks Function({bool conversationId, bool chatAttachmentsRefs})>;
typedef $$ChatAttachmentsTableCreateCompanionBuilder = ChatAttachmentsCompanion
    Function({
  required String id,
  required String fileName,
  required String mimeType,
  required int fileSize,
  required String localPath,
  required String kind,
  required String messageId,
  required String conversationId,
  Value<int> rowid,
});
typedef $$ChatAttachmentsTableUpdateCompanionBuilder = ChatAttachmentsCompanion
    Function({
  Value<String> id,
  Value<String> fileName,
  Value<String> mimeType,
  Value<int> fileSize,
  Value<String> localPath,
  Value<String> kind,
  Value<String> messageId,
  Value<String> conversationId,
  Value<int> rowid,
});

final class $$ChatAttachmentsTableReferences extends BaseReferences<
    _$AppDatabase, $ChatAttachmentsTable, ChatAttachment> {
  $$ChatAttachmentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ChatMessagesTable _messageIdTable(_$AppDatabase db) =>
      db.chatMessages.createAlias($_aliasNameGenerator(
          db.chatAttachments.messageId, db.chatMessages.id));

  $$ChatMessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$ChatMessagesTableTableManager($_db, $_db.chatMessages)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias($_aliasNameGenerator(
          db.chatAttachments.conversationId, db.conversations.id));

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager($_db, $_db.conversations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$AttachmentDeliveryStatesTable,
      List<AttachmentDeliveryStateRow>> _attachmentDeliveryStatesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.attachmentDeliveryStates,
          aliasName: $_aliasNameGenerator(
              db.chatAttachments.id, db.attachmentDeliveryStates.attachmentId));

  $$AttachmentDeliveryStatesTableProcessedTableManager
      get attachmentDeliveryStatesRefs {
    final manager = $$AttachmentDeliveryStatesTableTableManager(
            $_db, $_db.attachmentDeliveryStates)
        .filter(
            (f) => f.attachmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_attachmentDeliveryStatesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatAttachmentsTable> {
  $$ChatAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  $$ChatMessagesTableFilterComposer get messageId {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableFilterComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableFilterComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> attachmentDeliveryStatesRefs(
      Expression<bool> Function($$AttachmentDeliveryStatesTableFilterComposer f)
          f) {
    final $$AttachmentDeliveryStatesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.attachmentDeliveryStates,
            getReferencedColumn: (t) => t.attachmentId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AttachmentDeliveryStatesTableFilterComposer(
                  $db: $db,
                  $table: $db.attachmentDeliveryStates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ChatAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatAttachmentsTable> {
  $$ChatAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  $$ChatMessagesTableOrderingComposer get messageId {
    final $$ChatMessagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableOrderingComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableOrderingComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatAttachmentsTable> {
  $$ChatAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$ChatMessagesTableAnnotationComposer get messageId {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableAnnotationComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> attachmentDeliveryStatesRefs<T extends Object>(
      Expression<T> Function(
              $$AttachmentDeliveryStatesTableAnnotationComposer a)
          f) {
    final $$AttachmentDeliveryStatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.attachmentDeliveryStates,
            getReferencedColumn: (t) => t.attachmentId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AttachmentDeliveryStatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.attachmentDeliveryStates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ChatAttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatAttachmentsTable,
    ChatAttachment,
    $$ChatAttachmentsTableFilterComposer,
    $$ChatAttachmentsTableOrderingComposer,
    $$ChatAttachmentsTableAnnotationComposer,
    $$ChatAttachmentsTableCreateCompanionBuilder,
    $$ChatAttachmentsTableUpdateCompanionBuilder,
    (ChatAttachment, $$ChatAttachmentsTableReferences),
    ChatAttachment,
    PrefetchHooks Function(
        {bool messageId,
        bool conversationId,
        bool attachmentDeliveryStatesRefs})> {
  $$ChatAttachmentsTableTableManager(
      _$AppDatabase db, $ChatAttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> conversationId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatAttachmentsCompanion(
            id: id,
            fileName: fileName,
            mimeType: mimeType,
            fileSize: fileSize,
            localPath: localPath,
            kind: kind,
            messageId: messageId,
            conversationId: conversationId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fileName,
            required String mimeType,
            required int fileSize,
            required String localPath,
            required String kind,
            required String messageId,
            required String conversationId,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatAttachmentsCompanion.insert(
            id: id,
            fileName: fileName,
            mimeType: mimeType,
            fileSize: fileSize,
            localPath: localPath,
            kind: kind,
            messageId: messageId,
            conversationId: conversationId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatAttachmentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {messageId = false,
              conversationId = false,
              attachmentDeliveryStatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (attachmentDeliveryStatesRefs) db.attachmentDeliveryStates
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$ChatAttachmentsTableReferences._messageIdTable(db),
                    referencedColumn:
                        $$ChatAttachmentsTableReferences._messageIdTable(db).id,
                  ) as T;
                }
                if (conversationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.conversationId,
                    referencedTable: $$ChatAttachmentsTableReferences
                        ._conversationIdTable(db),
                    referencedColumn: $$ChatAttachmentsTableReferences
                        ._conversationIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attachmentDeliveryStatesRefs)
                    await $_getPrefetchedData<ChatAttachment,
                            $ChatAttachmentsTable, AttachmentDeliveryStateRow>(
                        currentTable: table,
                        referencedTable: $$ChatAttachmentsTableReferences
                            ._attachmentDeliveryStatesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatAttachmentsTableReferences(db, table, p0)
                                .attachmentDeliveryStatesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.attachmentId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChatAttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatAttachmentsTable,
    ChatAttachment,
    $$ChatAttachmentsTableFilterComposer,
    $$ChatAttachmentsTableOrderingComposer,
    $$ChatAttachmentsTableAnnotationComposer,
    $$ChatAttachmentsTableCreateCompanionBuilder,
    $$ChatAttachmentsTableUpdateCompanionBuilder,
    (ChatAttachment, $$ChatAttachmentsTableReferences),
    ChatAttachment,
    PrefetchHooks Function(
        {bool messageId,
        bool conversationId,
        bool attachmentDeliveryStatesRefs})>;
typedef $$AttachmentDeliveryStatesTableCreateCompanionBuilder
    = AttachmentDeliveryStatesCompanion Function({
  required String attachmentId,
  required String providerId,
  required String modelId,
  required String status,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AttachmentDeliveryStatesTableUpdateCompanionBuilder
    = AttachmentDeliveryStatesCompanion Function({
  Value<String> attachmentId,
  Value<String> providerId,
  Value<String> modelId,
  Value<String> status,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$AttachmentDeliveryStatesTableReferences extends BaseReferences<
    _$AppDatabase, $AttachmentDeliveryStatesTable, AttachmentDeliveryStateRow> {
  $$AttachmentDeliveryStatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ChatAttachmentsTable _attachmentIdTable(_$AppDatabase db) =>
      db.chatAttachments.createAlias($_aliasNameGenerator(
          db.attachmentDeliveryStates.attachmentId, db.chatAttachments.id));

  $$ChatAttachmentsTableProcessedTableManager get attachmentId {
    final $_column = $_itemColumn<String>('attachment_id')!;

    final manager =
        $$ChatAttachmentsTableTableManager($_db, $_db.chatAttachments)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attachmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AttachmentDeliveryStatesTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentDeliveryStatesTable> {
  $$AttachmentDeliveryStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ChatAttachmentsTableFilterComposer get attachmentId {
    final $$ChatAttachmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableFilterComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentDeliveryStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentDeliveryStatesTable> {
  $$AttachmentDeliveryStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ChatAttachmentsTableOrderingComposer get attachmentId {
    final $$ChatAttachmentsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableOrderingComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentDeliveryStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentDeliveryStatesTable> {
  $$AttachmentDeliveryStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ChatAttachmentsTableAnnotationComposer get attachmentId {
    final $$ChatAttachmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.chatAttachments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatAttachmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatAttachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentDeliveryStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttachmentDeliveryStatesTable,
    AttachmentDeliveryStateRow,
    $$AttachmentDeliveryStatesTableFilterComposer,
    $$AttachmentDeliveryStatesTableOrderingComposer,
    $$AttachmentDeliveryStatesTableAnnotationComposer,
    $$AttachmentDeliveryStatesTableCreateCompanionBuilder,
    $$AttachmentDeliveryStatesTableUpdateCompanionBuilder,
    (AttachmentDeliveryStateRow, $$AttachmentDeliveryStatesTableReferences),
    AttachmentDeliveryStateRow,
    PrefetchHooks Function({bool attachmentId})> {
  $$AttachmentDeliveryStatesTableTableManager(
      _$AppDatabase db, $AttachmentDeliveryStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentDeliveryStatesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentDeliveryStatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentDeliveryStatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> attachmentId = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentDeliveryStatesCompanion(
            attachmentId: attachmentId,
            providerId: providerId,
            modelId: modelId,
            status: status,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String attachmentId,
            required String providerId,
            required String modelId,
            required String status,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentDeliveryStatesCompanion.insert(
            attachmentId: attachmentId,
            providerId: providerId,
            modelId: modelId,
            status: status,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AttachmentDeliveryStatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({attachmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (attachmentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attachmentId,
                    referencedTable: $$AttachmentDeliveryStatesTableReferences
                        ._attachmentIdTable(db),
                    referencedColumn: $$AttachmentDeliveryStatesTableReferences
                        ._attachmentIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AttachmentDeliveryStatesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AttachmentDeliveryStatesTable,
        AttachmentDeliveryStateRow,
        $$AttachmentDeliveryStatesTableFilterComposer,
        $$AttachmentDeliveryStatesTableOrderingComposer,
        $$AttachmentDeliveryStatesTableAnnotationComposer,
        $$AttachmentDeliveryStatesTableCreateCompanionBuilder,
        $$AttachmentDeliveryStatesTableUpdateCompanionBuilder,
        (AttachmentDeliveryStateRow, $$AttachmentDeliveryStatesTableReferences),
        AttachmentDeliveryStateRow,
        PrefetchHooks Function({bool attachmentId})>;
typedef $$ModelAttachmentCapabilitiesTableCreateCompanionBuilder
    = ModelAttachmentCapabilitiesCompanion Function({
  required String providerId,
  required String modelId,
  required String modality,
  required String status,
  required String source,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ModelAttachmentCapabilitiesTableUpdateCompanionBuilder
    = ModelAttachmentCapabilitiesCompanion Function({
  Value<String> providerId,
  Value<String> modelId,
  Value<String> modality,
  Value<String> status,
  Value<String> source,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ModelAttachmentCapabilitiesTableReferences extends BaseReferences<
    _$AppDatabase,
    $ModelAttachmentCapabilitiesTable,
    ModelAttachmentCapabilityRow> {
  $$ModelAttachmentCapabilitiesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProviderConfigsTable _providerIdTable(_$AppDatabase db) =>
      db.providerConfigs.createAlias($_aliasNameGenerator(
          db.modelAttachmentCapabilities.providerId,
          db.providerConfigs.providerId));

  $$ProviderConfigsTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager =
        $$ProviderConfigsTableTableManager($_db, $_db.providerConfigs)
            .filter((f) => f.providerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ModelAttachmentCapabilitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ModelAttachmentCapabilitiesTable> {
  $$ModelAttachmentCapabilitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modality => $composableBuilder(
      column: $table.modality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ProviderConfigsTableFilterComposer get providerId {
    final $$ProviderConfigsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.providerId,
        referencedTable: $db.providerConfigs,
        getReferencedColumn: (t) => t.providerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProviderConfigsTableFilterComposer(
              $db: $db,
              $table: $db.providerConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ModelAttachmentCapabilitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelAttachmentCapabilitiesTable> {
  $$ModelAttachmentCapabilitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modality => $composableBuilder(
      column: $table.modality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ProviderConfigsTableOrderingComposer get providerId {
    final $$ProviderConfigsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.providerId,
        referencedTable: $db.providerConfigs,
        getReferencedColumn: (t) => t.providerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProviderConfigsTableOrderingComposer(
              $db: $db,
              $table: $db.providerConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ModelAttachmentCapabilitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelAttachmentCapabilitiesTable> {
  $$ModelAttachmentCapabilitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get modality =>
      $composableBuilder(column: $table.modality, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProviderConfigsTableAnnotationComposer get providerId {
    final $$ProviderConfigsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.providerId,
        referencedTable: $db.providerConfigs,
        getReferencedColumn: (t) => t.providerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProviderConfigsTableAnnotationComposer(
              $db: $db,
              $table: $db.providerConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ModelAttachmentCapabilitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ModelAttachmentCapabilitiesTable,
    ModelAttachmentCapabilityRow,
    $$ModelAttachmentCapabilitiesTableFilterComposer,
    $$ModelAttachmentCapabilitiesTableOrderingComposer,
    $$ModelAttachmentCapabilitiesTableAnnotationComposer,
    $$ModelAttachmentCapabilitiesTableCreateCompanionBuilder,
    $$ModelAttachmentCapabilitiesTableUpdateCompanionBuilder,
    (
      ModelAttachmentCapabilityRow,
      $$ModelAttachmentCapabilitiesTableReferences
    ),
    ModelAttachmentCapabilityRow,
    PrefetchHooks Function({bool providerId})> {
  $$ModelAttachmentCapabilitiesTableTableManager(
      _$AppDatabase db, $ModelAttachmentCapabilitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelAttachmentCapabilitiesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelAttachmentCapabilitiesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelAttachmentCapabilitiesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> providerId = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<String> modality = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelAttachmentCapabilitiesCompanion(
            providerId: providerId,
            modelId: modelId,
            modality: modality,
            status: status,
            source: source,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String providerId,
            required String modelId,
            required String modality,
            required String status,
            required String source,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelAttachmentCapabilitiesCompanion.insert(
            providerId: providerId,
            modelId: modelId,
            modality: modality,
            status: status,
            source: source,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ModelAttachmentCapabilitiesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (providerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.providerId,
                    referencedTable:
                        $$ModelAttachmentCapabilitiesTableReferences
                            ._providerIdTable(db),
                    referencedColumn:
                        $$ModelAttachmentCapabilitiesTableReferences
                            ._providerIdTable(db)
                            .providerId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ModelAttachmentCapabilitiesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ModelAttachmentCapabilitiesTable,
        ModelAttachmentCapabilityRow,
        $$ModelAttachmentCapabilitiesTableFilterComposer,
        $$ModelAttachmentCapabilitiesTableOrderingComposer,
        $$ModelAttachmentCapabilitiesTableAnnotationComposer,
        $$ModelAttachmentCapabilitiesTableCreateCompanionBuilder,
        $$ModelAttachmentCapabilitiesTableUpdateCompanionBuilder,
        (
          ModelAttachmentCapabilityRow,
          $$ModelAttachmentCapabilitiesTableReferences
        ),
        ModelAttachmentCapabilityRow,
        PrefetchHooks Function({bool providerId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
  $$AgentProfilesTableTableManager get agentProfiles =>
      $$AgentProfilesTableTableManager(_db, _db.agentProfiles);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ChatAttachmentsTableTableManager get chatAttachments =>
      $$ChatAttachmentsTableTableManager(_db, _db.chatAttachments);
  $$AttachmentDeliveryStatesTableTableManager get attachmentDeliveryStates =>
      $$AttachmentDeliveryStatesTableTableManager(
          _db, _db.attachmentDeliveryStates);
  $$ModelAttachmentCapabilitiesTableTableManager
      get modelAttachmentCapabilities =>
          $$ModelAttachmentCapabilitiesTableTableManager(
              _db, _db.modelAttachmentCapabilities);
}
