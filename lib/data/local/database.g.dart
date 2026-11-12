// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialIdMeta = const VerificationMeta(
    'credentialId',
  );
  @override
  late final GeneratedColumn<String> credentialId = GeneratedColumn<String>(
    'credential_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    credentialId,
    name,
    config,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('credential_id')) {
      context.handle(
        _credentialIdMeta,
        credentialId.isAcceptableOrUnknown(
          data['credential_id']!,
          _credentialIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    } else if (isInserting) {
      context.missing(_configMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      credentialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final String id;
  final String credentialId;
  final String name;
  final String config;
  final DateTime updatedAt;
  const Character({
    required this.id,
    required this.credentialId,
    required this.name,
    required this.config,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['credential_id'] = Variable<String>(credentialId);
    map['name'] = Variable<String>(name);
    map['config'] = Variable<String>(config);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      credentialId: Value(credentialId),
      name: Value(name),
      config: Value(config),
      updatedAt: Value(updatedAt),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<String>(json['id']),
      credentialId: serializer.fromJson<String>(json['credentialId']),
      name: serializer.fromJson<String>(json['name']),
      config: serializer.fromJson<String>(json['config']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'credentialId': serializer.toJson<String>(credentialId),
      'name': serializer.toJson<String>(name),
      'config': serializer.toJson<String>(config),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Character copyWith({
    String? id,
    String? credentialId,
    String? name,
    String? config,
    DateTime? updatedAt,
  }) => Character(
    id: id ?? this.id,
    credentialId: credentialId ?? this.credentialId,
    name: name ?? this.name,
    config: config ?? this.config,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      credentialId: data.credentialId.present
          ? data.credentialId.value
          : this.credentialId,
      name: data.name.present ? data.name.value : this.name,
      config: data.config.present ? data.config.value : this.config,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('credentialId: $credentialId, ')
          ..write('name: $name, ')
          ..write('config: $config, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, credentialId, name, config, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.credentialId == this.credentialId &&
          other.name == this.name &&
          other.config == this.config &&
          other.updatedAt == this.updatedAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<String> id;
  final Value<String> credentialId;
  final Value<String> name;
  final Value<String> config;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.credentialId = const Value.absent(),
    this.name = const Value.absent(),
    this.config = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String credentialId,
    required String name,
    required String config,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       credentialId = Value(credentialId),
       name = Value(name),
       config = Value(config),
       updatedAt = Value(updatedAt);
  static Insertable<Character> custom({
    Expression<String>? id,
    Expression<String>? credentialId,
    Expression<String>? name,
    Expression<String>? config,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (credentialId != null) 'credential_id': credentialId,
      if (name != null) 'name': name,
      if (config != null) 'config': config,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? id,
    Value<String>? credentialId,
    Value<String>? name,
    Value<String>? config,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      name: name ?? this.name,
      config: config ?? this.config,
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
    if (credentialId.present) {
      map['credential_id'] = Variable<String>(credentialId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
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
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('credentialId: $credentialId, ')
          ..write('name: $name, ')
          ..write('config: $config, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CallsTable extends Calls with TableInfo<$CallsTable, Call> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialIdMeta = const VerificationMeta(
    'credentialId',
  );
  @override
  late final GeneratedColumn<String> credentialId = GeneratedColumn<String>(
    'credential_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterSnapshotMeta = const VerificationMeta(
    'characterSnapshot',
  );
  @override
  late final GeneratedColumn<String> characterSnapshot =
      GeneratedColumn<String>(
        'character_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _liveIdMeta = const VerificationMeta('liveId');
  @override
  late final GeneratedColumn<String> liveId = GeneratedColumn<String>(
    'live_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endConfirmedMeta = const VerificationMeta(
    'endConfirmed',
  );
  @override
  late final GeneratedColumn<bool> endConfirmed = GeneratedColumn<bool>(
    'end_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("end_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _endReasonMeta = const VerificationMeta(
    'endReason',
  );
  @override
  late final GeneratedColumn<String> endReason = GeneratedColumn<String>(
    'end_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _controlReadyAtMeta = const VerificationMeta(
    'controlReadyAt',
  );
  @override
  late final GeneratedColumn<DateTime> controlReadyAt =
      GeneratedColumn<DateTime>(
        'control_ready_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localReleasedAtMeta = const VerificationMeta(
    'localReleasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localReleasedAt =
      GeneratedColumn<DateTime>(
        'local_released_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _billedSecondsMeta = const VerificationMeta(
    'billedSeconds',
  );
  @override
  late final GeneratedColumn<int> billedSeconds = GeneratedColumn<int>(
    'billed_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditsCostMeta = const VerificationMeta(
    'creditsCost',
  );
  @override
  late final GeneratedColumn<String> creditsCost = GeneratedColumn<String>(
    'credits_cost',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    credentialId,
    characterId,
    characterSnapshot,
    liveId,
    phase,
    endConfirmed,
    endReason,
    errorCode,
    createdAt,
    controlReadyAt,
    localReleasedAt,
    billedSeconds,
    creditsCost,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calls';
  @override
  VerificationContext validateIntegrity(
    Insertable<Call> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('credential_id')) {
      context.handle(
        _credentialIdMeta,
        credentialId.isAcceptableOrUnknown(
          data['credential_id']!,
          _credentialIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('character_snapshot')) {
      context.handle(
        _characterSnapshotMeta,
        characterSnapshot.isAcceptableOrUnknown(
          data['character_snapshot']!,
          _characterSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterSnapshotMeta);
    }
    if (data.containsKey('live_id')) {
      context.handle(
        _liveIdMeta,
        liveId.isAcceptableOrUnknown(data['live_id']!, _liveIdMeta),
      );
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('end_confirmed')) {
      context.handle(
        _endConfirmedMeta,
        endConfirmed.isAcceptableOrUnknown(
          data['end_confirmed']!,
          _endConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('end_reason')) {
      context.handle(
        _endReasonMeta,
        endReason.isAcceptableOrUnknown(data['end_reason']!, _endReasonMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('control_ready_at')) {
      context.handle(
        _controlReadyAtMeta,
        controlReadyAt.isAcceptableOrUnknown(
          data['control_ready_at']!,
          _controlReadyAtMeta,
        ),
      );
    }
    if (data.containsKey('local_released_at')) {
      context.handle(
        _localReleasedAtMeta,
        localReleasedAt.isAcceptableOrUnknown(
          data['local_released_at']!,
          _localReleasedAtMeta,
        ),
      );
    }
    if (data.containsKey('billed_seconds')) {
      context.handle(
        _billedSecondsMeta,
        billedSeconds.isAcceptableOrUnknown(
          data['billed_seconds']!,
          _billedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('credits_cost')) {
      context.handle(
        _creditsCostMeta,
        creditsCost.isAcceptableOrUnknown(
          data['credits_cost']!,
          _creditsCostMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {credentialId, liveId},
  ];
  @override
  Call map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Call(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      credentialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      characterSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_snapshot'],
      )!,
      liveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}live_id'],
      ),
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      endConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}end_confirmed'],
      )!,
      endReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_reason'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      controlReadyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}control_ready_at'],
      ),
      localReleasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_released_at'],
      ),
      billedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billed_seconds'],
      ),
      creditsCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credits_cost'],
      ),
    );
  }

  @override
  $CallsTable createAlias(String alias) {
    return $CallsTable(attachedDatabase, alias);
  }
}

class Call extends DataClass implements Insertable<Call> {
  final String id;
  final String credentialId;
  final String characterId;
  final String characterSnapshot;
  final String? liveId;
  final String phase;
  final bool endConfirmed;
  final String? endReason;
  final String? errorCode;
  final DateTime createdAt;
  final DateTime? controlReadyAt;
  final DateTime? localReleasedAt;
  final int? billedSeconds;
  final String? creditsCost;
  const Call({
    required this.id,
    required this.credentialId,
    required this.characterId,
    required this.characterSnapshot,
    this.liveId,
    required this.phase,
    required this.endConfirmed,
    this.endReason,
    this.errorCode,
    required this.createdAt,
    this.controlReadyAt,
    this.localReleasedAt,
    this.billedSeconds,
    this.creditsCost,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['credential_id'] = Variable<String>(credentialId);
    map['character_id'] = Variable<String>(characterId);
    map['character_snapshot'] = Variable<String>(characterSnapshot);
    if (!nullToAbsent || liveId != null) {
      map['live_id'] = Variable<String>(liveId);
    }
    map['phase'] = Variable<String>(phase);
    map['end_confirmed'] = Variable<bool>(endConfirmed);
    if (!nullToAbsent || endReason != null) {
      map['end_reason'] = Variable<String>(endReason);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || controlReadyAt != null) {
      map['control_ready_at'] = Variable<DateTime>(controlReadyAt);
    }
    if (!nullToAbsent || localReleasedAt != null) {
      map['local_released_at'] = Variable<DateTime>(localReleasedAt);
    }
    if (!nullToAbsent || billedSeconds != null) {
      map['billed_seconds'] = Variable<int>(billedSeconds);
    }
    if (!nullToAbsent || creditsCost != null) {
      map['credits_cost'] = Variable<String>(creditsCost);
    }
    return map;
  }

  CallsCompanion toCompanion(bool nullToAbsent) {
    return CallsCompanion(
      id: Value(id),
      credentialId: Value(credentialId),
      characterId: Value(characterId),
      characterSnapshot: Value(characterSnapshot),
      liveId: liveId == null && nullToAbsent
          ? const Value.absent()
          : Value(liveId),
      phase: Value(phase),
      endConfirmed: Value(endConfirmed),
      endReason: endReason == null && nullToAbsent
          ? const Value.absent()
          : Value(endReason),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      createdAt: Value(createdAt),
      controlReadyAt: controlReadyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(controlReadyAt),
      localReleasedAt: localReleasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localReleasedAt),
      billedSeconds: billedSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(billedSeconds),
      creditsCost: creditsCost == null && nullToAbsent
          ? const Value.absent()
          : Value(creditsCost),
    );
  }

  factory Call.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Call(
      id: serializer.fromJson<String>(json['id']),
      credentialId: serializer.fromJson<String>(json['credentialId']),
      characterId: serializer.fromJson<String>(json['characterId']),
      characterSnapshot: serializer.fromJson<String>(json['characterSnapshot']),
      liveId: serializer.fromJson<String?>(json['liveId']),
      phase: serializer.fromJson<String>(json['phase']),
      endConfirmed: serializer.fromJson<bool>(json['endConfirmed']),
      endReason: serializer.fromJson<String?>(json['endReason']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      controlReadyAt: serializer.fromJson<DateTime?>(json['controlReadyAt']),
      localReleasedAt: serializer.fromJson<DateTime?>(json['localReleasedAt']),
      billedSeconds: serializer.fromJson<int?>(json['billedSeconds']),
      creditsCost: serializer.fromJson<String?>(json['creditsCost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'credentialId': serializer.toJson<String>(credentialId),
      'characterId': serializer.toJson<String>(characterId),
      'characterSnapshot': serializer.toJson<String>(characterSnapshot),
      'liveId': serializer.toJson<String?>(liveId),
      'phase': serializer.toJson<String>(phase),
      'endConfirmed': serializer.toJson<bool>(endConfirmed),
      'endReason': serializer.toJson<String?>(endReason),
      'errorCode': serializer.toJson<String?>(errorCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'controlReadyAt': serializer.toJson<DateTime?>(controlReadyAt),
      'localReleasedAt': serializer.toJson<DateTime?>(localReleasedAt),
      'billedSeconds': serializer.toJson<int?>(billedSeconds),
      'creditsCost': serializer.toJson<String?>(creditsCost),
    };
  }

  Call copyWith({
    String? id,
    String? credentialId,
    String? characterId,
    String? characterSnapshot,
    Value<String?> liveId = const Value.absent(),
    String? phase,
    bool? endConfirmed,
    Value<String?> endReason = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> controlReadyAt = const Value.absent(),
    Value<DateTime?> localReleasedAt = const Value.absent(),
    Value<int?> billedSeconds = const Value.absent(),
    Value<String?> creditsCost = const Value.absent(),
  }) => Call(
    id: id ?? this.id,
    credentialId: credentialId ?? this.credentialId,
    characterId: characterId ?? this.characterId,
    characterSnapshot: characterSnapshot ?? this.characterSnapshot,
    liveId: liveId.present ? liveId.value : this.liveId,
    phase: phase ?? this.phase,
    endConfirmed: endConfirmed ?? this.endConfirmed,
    endReason: endReason.present ? endReason.value : this.endReason,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    createdAt: createdAt ?? this.createdAt,
    controlReadyAt: controlReadyAt.present
        ? controlReadyAt.value
        : this.controlReadyAt,
    localReleasedAt: localReleasedAt.present
        ? localReleasedAt.value
        : this.localReleasedAt,
    billedSeconds: billedSeconds.present
        ? billedSeconds.value
        : this.billedSeconds,
    creditsCost: creditsCost.present ? creditsCost.value : this.creditsCost,
  );
  Call copyWithCompanion(CallsCompanion data) {
    return Call(
      id: data.id.present ? data.id.value : this.id,
      credentialId: data.credentialId.present
          ? data.credentialId.value
          : this.credentialId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      characterSnapshot: data.characterSnapshot.present
          ? data.characterSnapshot.value
          : this.characterSnapshot,
      liveId: data.liveId.present ? data.liveId.value : this.liveId,
      phase: data.phase.present ? data.phase.value : this.phase,
      endConfirmed: data.endConfirmed.present
          ? data.endConfirmed.value
          : this.endConfirmed,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      controlReadyAt: data.controlReadyAt.present
          ? data.controlReadyAt.value
          : this.controlReadyAt,
      localReleasedAt: data.localReleasedAt.present
          ? data.localReleasedAt.value
          : this.localReleasedAt,
      billedSeconds: data.billedSeconds.present
          ? data.billedSeconds.value
          : this.billedSeconds,
      creditsCost: data.creditsCost.present
          ? data.creditsCost.value
          : this.creditsCost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Call(')
          ..write('id: $id, ')
          ..write('credentialId: $credentialId, ')
          ..write('characterId: $characterId, ')
          ..write('characterSnapshot: $characterSnapshot, ')
          ..write('liveId: $liveId, ')
          ..write('phase: $phase, ')
          ..write('endConfirmed: $endConfirmed, ')
          ..write('endReason: $endReason, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('controlReadyAt: $controlReadyAt, ')
          ..write('localReleasedAt: $localReleasedAt, ')
          ..write('billedSeconds: $billedSeconds, ')
          ..write('creditsCost: $creditsCost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    credentialId,
    characterId,
    characterSnapshot,
    liveId,
    phase,
    endConfirmed,
    endReason,
    errorCode,
    createdAt,
    controlReadyAt,
    localReleasedAt,
    billedSeconds,
    creditsCost,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Call &&
          other.id == this.id &&
          other.credentialId == this.credentialId &&
          other.characterId == this.characterId &&
          other.characterSnapshot == this.characterSnapshot &&
          other.liveId == this.liveId &&
          other.phase == this.phase &&
          other.endConfirmed == this.endConfirmed &&
          other.endReason == this.endReason &&
          other.errorCode == this.errorCode &&
          other.createdAt == this.createdAt &&
          other.controlReadyAt == this.controlReadyAt &&
          other.localReleasedAt == this.localReleasedAt &&
          other.billedSeconds == this.billedSeconds &&
          other.creditsCost == this.creditsCost);
}

class CallsCompanion extends UpdateCompanion<Call> {
  final Value<String> id;
  final Value<String> credentialId;
  final Value<String> characterId;
  final Value<String> characterSnapshot;
  final Value<String?> liveId;
  final Value<String> phase;
  final Value<bool> endConfirmed;
  final Value<String?> endReason;
  final Value<String?> errorCode;
  final Value<DateTime> createdAt;
  final Value<DateTime?> controlReadyAt;
  final Value<DateTime?> localReleasedAt;
  final Value<int?> billedSeconds;
  final Value<String?> creditsCost;
  final Value<int> rowid;
  const CallsCompanion({
    this.id = const Value.absent(),
    this.credentialId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.characterSnapshot = const Value.absent(),
    this.liveId = const Value.absent(),
    this.phase = const Value.absent(),
    this.endConfirmed = const Value.absent(),
    this.endReason = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.controlReadyAt = const Value.absent(),
    this.localReleasedAt = const Value.absent(),
    this.billedSeconds = const Value.absent(),
    this.creditsCost = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CallsCompanion.insert({
    required String id,
    required String credentialId,
    required String characterId,
    required String characterSnapshot,
    this.liveId = const Value.absent(),
    required String phase,
    this.endConfirmed = const Value.absent(),
    this.endReason = const Value.absent(),
    this.errorCode = const Value.absent(),
    required DateTime createdAt,
    this.controlReadyAt = const Value.absent(),
    this.localReleasedAt = const Value.absent(),
    this.billedSeconds = const Value.absent(),
    this.creditsCost = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       credentialId = Value(credentialId),
       characterId = Value(characterId),
       characterSnapshot = Value(characterSnapshot),
       phase = Value(phase),
       createdAt = Value(createdAt);
  static Insertable<Call> custom({
    Expression<String>? id,
    Expression<String>? credentialId,
    Expression<String>? characterId,
    Expression<String>? characterSnapshot,
    Expression<String>? liveId,
    Expression<String>? phase,
    Expression<bool>? endConfirmed,
    Expression<String>? endReason,
    Expression<String>? errorCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? controlReadyAt,
    Expression<DateTime>? localReleasedAt,
    Expression<int>? billedSeconds,
    Expression<String>? creditsCost,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (credentialId != null) 'credential_id': credentialId,
      if (characterId != null) 'character_id': characterId,
      if (characterSnapshot != null) 'character_snapshot': characterSnapshot,
      if (liveId != null) 'live_id': liveId,
      if (phase != null) 'phase': phase,
      if (endConfirmed != null) 'end_confirmed': endConfirmed,
      if (endReason != null) 'end_reason': endReason,
      if (errorCode != null) 'error_code': errorCode,
      if (createdAt != null) 'created_at': createdAt,
      if (controlReadyAt != null) 'control_ready_at': controlReadyAt,
      if (localReleasedAt != null) 'local_released_at': localReleasedAt,
      if (billedSeconds != null) 'billed_seconds': billedSeconds,
      if (creditsCost != null) 'credits_cost': creditsCost,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CallsCompanion copyWith({
    Value<String>? id,
    Value<String>? credentialId,
    Value<String>? characterId,
    Value<String>? characterSnapshot,
    Value<String?>? liveId,
    Value<String>? phase,
    Value<bool>? endConfirmed,
    Value<String?>? endReason,
    Value<String?>? errorCode,
    Value<DateTime>? createdAt,
    Value<DateTime?>? controlReadyAt,
    Value<DateTime?>? localReleasedAt,
    Value<int?>? billedSeconds,
    Value<String?>? creditsCost,
    Value<int>? rowid,
  }) {
    return CallsCompanion(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      characterId: characterId ?? this.characterId,
      characterSnapshot: characterSnapshot ?? this.characterSnapshot,
      liveId: liveId ?? this.liveId,
      phase: phase ?? this.phase,
      endConfirmed: endConfirmed ?? this.endConfirmed,
      endReason: endReason ?? this.endReason,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      controlReadyAt: controlReadyAt ?? this.controlReadyAt,
      localReleasedAt: localReleasedAt ?? this.localReleasedAt,
      billedSeconds: billedSeconds ?? this.billedSeconds,
      creditsCost: creditsCost ?? this.creditsCost,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (credentialId.present) {
      map['credential_id'] = Variable<String>(credentialId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (characterSnapshot.present) {
      map['character_snapshot'] = Variable<String>(characterSnapshot.value);
    }
    if (liveId.present) {
      map['live_id'] = Variable<String>(liveId.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (endConfirmed.present) {
      map['end_confirmed'] = Variable<bool>(endConfirmed.value);
    }
    if (endReason.present) {
      map['end_reason'] = Variable<String>(endReason.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (controlReadyAt.present) {
      map['control_ready_at'] = Variable<DateTime>(controlReadyAt.value);
    }
    if (localReleasedAt.present) {
      map['local_released_at'] = Variable<DateTime>(localReleasedAt.value);
    }
    if (billedSeconds.present) {
      map['billed_seconds'] = Variable<int>(billedSeconds.value);
    }
    if (creditsCost.present) {
      map['credits_cost'] = Variable<String>(creditsCost.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallsCompanion(')
          ..write('id: $id, ')
          ..write('credentialId: $credentialId, ')
          ..write('characterId: $characterId, ')
          ..write('characterSnapshot: $characterSnapshot, ')
          ..write('liveId: $liveId, ')
          ..write('phase: $phase, ')
          ..write('endConfirmed: $endConfirmed, ')
          ..write('endReason: $endReason, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('controlReadyAt: $controlReadyAt, ')
          ..write('localReleasedAt: $localReleasedAt, ')
          ..write('billedSeconds: $billedSeconds, ')
          ..write('creditsCost: $creditsCost, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _callIdMeta = const VerificationMeta('callId');
  @override
  late final GeneratedColumn<String> callId = GeneratedColumn<String>(
    'call_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calls (id)',
    ),
  );
  static const VerificationMeta _speakerMeta = const VerificationMeta(
    'speaker',
  );
  @override
  late final GeneratedColumn<String> speaker = GeneratedColumn<String>(
    'speaker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryMeta = const VerificationMeta(
    'delivery',
  );
  @override
  late final GeneratedColumn<String> delivery = GeneratedColumn<String>(
    'delivery',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    callId,
    speaker,
    content,
    delivery,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('call_id')) {
      context.handle(
        _callIdMeta,
        callId.isAcceptableOrUnknown(data['call_id']!, _callIdMeta),
      );
    } else if (isInserting) {
      context.missing(_callIdMeta);
    }
    if (data.containsKey('speaker')) {
      context.handle(
        _speakerMeta,
        speaker.isAcceptableOrUnknown(data['speaker']!, _speakerMeta),
      );
    } else if (isInserting) {
      context.missing(_speakerMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('delivery')) {
      context.handle(
        _deliveryMeta,
        delivery.isAcceptableOrUnknown(data['delivery']!, _deliveryMeta),
      );
    } else if (isInserting) {
      context.missing(_deliveryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      callId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}call_id'],
      )!,
      speaker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}speaker'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      delivery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String callId;
  final String speaker;
  final String content;
  final String delivery;
  final DateTime createdAt;
  const Message({
    required this.id,
    required this.callId,
    required this.speaker,
    required this.content,
    required this.delivery,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['call_id'] = Variable<String>(callId);
    map['speaker'] = Variable<String>(speaker);
    map['content'] = Variable<String>(content);
    map['delivery'] = Variable<String>(delivery);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      callId: Value(callId),
      speaker: Value(speaker),
      content: Value(content),
      delivery: Value(delivery),
      createdAt: Value(createdAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      callId: serializer.fromJson<String>(json['callId']),
      speaker: serializer.fromJson<String>(json['speaker']),
      content: serializer.fromJson<String>(json['content']),
      delivery: serializer.fromJson<String>(json['delivery']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'callId': serializer.toJson<String>(callId),
      'speaker': serializer.toJson<String>(speaker),
      'content': serializer.toJson<String>(content),
      'delivery': serializer.toJson<String>(delivery),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Message copyWith({
    String? id,
    String? callId,
    String? speaker,
    String? content,
    String? delivery,
    DateTime? createdAt,
  }) => Message(
    id: id ?? this.id,
    callId: callId ?? this.callId,
    speaker: speaker ?? this.speaker,
    content: content ?? this.content,
    delivery: delivery ?? this.delivery,
    createdAt: createdAt ?? this.createdAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      callId: data.callId.present ? data.callId.value : this.callId,
      speaker: data.speaker.present ? data.speaker.value : this.speaker,
      content: data.content.present ? data.content.value : this.content,
      delivery: data.delivery.present ? data.delivery.value : this.delivery,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('callId: $callId, ')
          ..write('speaker: $speaker, ')
          ..write('content: $content, ')
          ..write('delivery: $delivery, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, callId, speaker, content, delivery, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.callId == this.callId &&
          other.speaker == this.speaker &&
          other.content == this.content &&
          other.delivery == this.delivery &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> callId;
  final Value<String> speaker;
  final Value<String> content;
  final Value<String> delivery;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.callId = const Value.absent(),
    this.speaker = const Value.absent(),
    this.content = const Value.absent(),
    this.delivery = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String callId,
    required String speaker,
    required String content,
    required String delivery,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       callId = Value(callId),
       speaker = Value(speaker),
       content = Value(content),
       delivery = Value(delivery),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? callId,
    Expression<String>? speaker,
    Expression<String>? content,
    Expression<String>? delivery,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callId != null) 'call_id': callId,
      if (speaker != null) 'speaker': speaker,
      if (content != null) 'content': content,
      if (delivery != null) 'delivery': delivery,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? callId,
    Value<String>? speaker,
    Value<String>? content,
    Value<String>? delivery,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      speaker: speaker ?? this.speaker,
      content: content ?? this.content,
      delivery: delivery ?? this.delivery,
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
    if (callId.present) {
      map['call_id'] = Variable<String>(callId.value);
    }
    if (speaker.present) {
      map['speaker'] = Variable<String>(speaker.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (delivery.present) {
      map['delivery'] = Variable<String>(delivery.value);
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
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('callId: $callId, ')
          ..write('speaker: $speaker, ')
          ..write('content: $content, ')
          ..write('delivery: $delivery, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CallsTable calls = $CallsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    characters,
    calls,
    messages,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$CharactersTableCreateCompanionBuilder = CharactersCompanion Function({
  required String id,
  required String credentialId,
  required String name,
  required String config,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CharactersTableUpdateCompanionBuilder = CharactersCompanion Function({
  Value<String> id,
  Value<String> credentialId,
  Value<String> name,
  Value<String> config,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (
            Character,
            BaseReferences<_$AppDatabase, $CharactersTable, Character>,
          ),
          Character,
          PrefetchHooks Function()
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> credentialId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> config = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                credentialId: credentialId,
                name: name,
                config: config,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String credentialId,
                required String name,
                required String config,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                credentialId: credentialId,
                name: name,
                config: config,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharactersTable, Character>(table),
                  BaseReferences<_$AppDatabase, $CharactersTable, Character>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, BaseReferences<_$AppDatabase, $CharactersTable, Character>),
      Character,
      PrefetchHooks Function()
    >;
typedef $$CallsTableCreateCompanionBuilder = CallsCompanion Function({
  required String id,
  required String credentialId,
  required String characterId,
  required String characterSnapshot,
  Value<String?> liveId,
  required String phase,
  Value<bool> endConfirmed,
  Value<String?> endReason,
  Value<String?> errorCode,
  required DateTime createdAt,
  Value<DateTime?> controlReadyAt,
  Value<DateTime?> localReleasedAt,
  Value<int?> billedSeconds,
  Value<String?> creditsCost,
  Value<int> rowid,
});
typedef $$CallsTableUpdateCompanionBuilder = CallsCompanion Function({
  Value<String> id,
  Value<String> credentialId,
  Value<String> characterId,
  Value<String> characterSnapshot,
  Value<String?> liveId,
  Value<String> phase,
  Value<bool> endConfirmed,
  Value<String?> endReason,
  Value<String?> errorCode,
  Value<DateTime> createdAt,
  Value<DateTime?> controlReadyAt,
  Value<DateTime?> localReleasedAt,
  Value<int?> billedSeconds,
  Value<String?> creditsCost,
  Value<int> rowid,
});

final class $$CallsTableReferences
    extends BaseReferences<_$AppDatabase, $CallsTable, Call> {
  $$CallsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'calls__id__messages__call_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.callId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CallsTableFilterComposer extends Composer<_$AppDatabase, $CallsTable> {
  $$CallsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterSnapshot => $composableBuilder(
    column: $table.characterSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get liveId => $composableBuilder(
    column: $table.liveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get endConfirmed => $composableBuilder(
    column: $table.endConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get controlReadyAt => $composableBuilder(
    column: $table.controlReadyAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localReleasedAt => $composableBuilder(
    column: $table.localReleasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billedSeconds => $composableBuilder(
    column: $table.billedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditsCost => $composableBuilder(
    column: $table.creditsCost,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallsTable> {
  $$CallsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterSnapshot => $composableBuilder(
    column: $table.characterSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get liveId => $composableBuilder(
    column: $table.liveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get endConfirmed => $composableBuilder(
    column: $table.endConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get controlReadyAt => $composableBuilder(
    column: $table.controlReadyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localReleasedAt => $composableBuilder(
    column: $table.localReleasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billedSeconds => $composableBuilder(
    column: $table.billedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditsCost => $composableBuilder(
    column: $table.creditsCost,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CallsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallsTable> {
  $$CallsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get characterSnapshot => $composableBuilder(
    column: $table.characterSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get liveId =>
      $composableBuilder(column: $table.liveId, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<bool> get endConfirmed => $composableBuilder(
    column: $table.endConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get controlReadyAt => $composableBuilder(
    column: $table.controlReadyAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localReleasedAt => $composableBuilder(
    column: $table.localReleasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billedSeconds => $composableBuilder(
    column: $table.billedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creditsCost => $composableBuilder(
    column: $table.creditsCost,
    builder: (column) => column,
  );

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.callId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallsTable,
          Call,
          $$CallsTableFilterComposer,
          $$CallsTableOrderingComposer,
          $$CallsTableAnnotationComposer,
          $$CallsTableCreateCompanionBuilder,
          $$CallsTableUpdateCompanionBuilder,
          (Call, $$CallsTableReferences),
          Call,
          PrefetchHooks Function({bool messagesRefs})
        > {
  $$CallsTableTableManager(_$AppDatabase db, $CallsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> credentialId = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> characterSnapshot = const Value.absent(),
                Value<String?> liveId = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<bool> endConfirmed = const Value.absent(),
                Value<String?> endReason = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> controlReadyAt = const Value.absent(),
                Value<DateTime?> localReleasedAt = const Value.absent(),
                Value<int?> billedSeconds = const Value.absent(),
                Value<String?> creditsCost = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CallsCompanion(
                id: id,
                credentialId: credentialId,
                characterId: characterId,
                characterSnapshot: characterSnapshot,
                liveId: liveId,
                phase: phase,
                endConfirmed: endConfirmed,
                endReason: endReason,
                errorCode: errorCode,
                createdAt: createdAt,
                controlReadyAt: controlReadyAt,
                localReleasedAt: localReleasedAt,
                billedSeconds: billedSeconds,
                creditsCost: creditsCost,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String credentialId,
                required String characterId,
                required String characterSnapshot,
                Value<String?> liveId = const Value.absent(),
                required String phase,
                Value<bool> endConfirmed = const Value.absent(),
                Value<String?> endReason = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> controlReadyAt = const Value.absent(),
                Value<DateTime?> localReleasedAt = const Value.absent(),
                Value<int?> billedSeconds = const Value.absent(),
                Value<String?> creditsCost = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CallsCompanion.insert(
                id: id,
                credentialId: credentialId,
                characterId: characterId,
                characterSnapshot: characterSnapshot,
                liveId: liveId,
                phase: phase,
                endConfirmed: endConfirmed,
                endReason: endReason,
                errorCode: errorCode,
                createdAt: createdAt,
                controlReadyAt: controlReadyAt,
                localReleasedAt: localReleasedAt,
                billedSeconds: billedSeconds,
                creditsCost: creditsCost,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CallsTable, Call>(table),
                  $$CallsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedDataByColumns<
                      Call,
                      $CallsTable,
                      Message,
                      $MessagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$CallsTableReferences
                          ._messagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CallsTableReferences(db, table, p0).messagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'call_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CallsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallsTable,
      Call,
      $$CallsTableFilterComposer,
      $$CallsTableOrderingComposer,
      $$CallsTableAnnotationComposer,
      $$CallsTableCreateCompanionBuilder,
      $$CallsTableUpdateCompanionBuilder,
      (Call, $$CallsTableReferences),
      Call,
      PrefetchHooks Function({bool messagesRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String callId,
  required String speaker,
  required String content,
  required String delivery,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> callId,
  Value<String> speaker,
  Value<String> content,
  Value<String> delivery,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CallsTable _callIdTable(_$AppDatabase db) =>
      db.calls.createAlias('messages__call_id__calls__id');

  $$CallsTableProcessedTableManager get callId {
    final $_column = $_itemColumn<String>('call_id')!;

    final manager = $$CallsTableTableManager(
      $_db,
      $_db.calls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_callIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speaker => $composableBuilder(
    column: $table.speaker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get delivery => $composableBuilder(
    column: $table.delivery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CallsTableFilterComposer get callId {
    final $$CallsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableFilterComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speaker => $composableBuilder(
    column: $table.speaker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get delivery => $composableBuilder(
    column: $table.delivery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CallsTableOrderingComposer get callId {
    final $$CallsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableOrderingComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get speaker =>
      $composableBuilder(column: $table.speaker, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get delivery =>
      $composableBuilder(column: $table.delivery, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CallsTableAnnotationComposer get callId {
    final $$CallsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callId,
      referencedTable: $db.calls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallsTableAnnotationComposer(
            $db: $db,
            $table: $db.calls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool callId})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> callId = const Value.absent(),
                Value<String> speaker = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> delivery = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                callId: callId,
                speaker: speaker,
                content: content,
                delivery: delivery,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String callId,
                required String speaker,
                required String content,
                required String delivery,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                callId: callId,
                speaker: speaker,
                content: content,
                delivery: delivery,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, Message>(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({callId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (callId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.callId,
                        referencedTable: $$MessagesTableReferences._callIdTable(
                          db,
                        ),
                        referencedColumn: $$MessagesTableReferences
                            ._callIdTable(db)
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
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool callId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CallsTableTableManager get calls =>
      $$CallsTableTableManager(_db, _db.calls);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}
