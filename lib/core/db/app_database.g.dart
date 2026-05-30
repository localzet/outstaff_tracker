// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersLocalTable extends UsersLocal
    with TableInfo<$UsersLocalTable, UsersLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kimaiUserIdMeta =
      const VerificationMeta('kimaiUserId');
  @override
  late final GeneratedColumn<int> kimaiUserId = GeneratedColumn<int>(
      'kimai_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timezoneMeta =
      const VerificationMeta('timezone');
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
      'timezone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('UTC'));
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
      [id, kimaiUserId, displayName, email, timezone, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_local';
  @override
  VerificationContext validateIntegrity(Insertable<UsersLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kimai_user_id')) {
      context.handle(
          _kimaiUserIdMeta,
          kimaiUserId.isAcceptableOrUnknown(
              data['kimai_user_id']!, _kimaiUserIdMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('timezone')) {
      context.handle(_timezoneMeta,
          timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta));
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
  UsersLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kimaiUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kimai_user_id']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      timezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UsersLocalTable createAlias(String alias) {
    return $UsersLocalTable(attachedDatabase, alias);
  }
}

class UsersLocalData extends DataClass implements Insertable<UsersLocalData> {
  final String id;
  final int? kimaiUserId;
  final String? displayName;
  final String? email;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UsersLocalData(
      {required this.id,
      this.kimaiUserId,
      this.displayName,
      this.email,
      required this.timezone,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || kimaiUserId != null) {
      map['kimai_user_id'] = Variable<int>(kimaiUserId);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['timezone'] = Variable<String>(timezone);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersLocalCompanion toCompanion(bool nullToAbsent) {
    return UsersLocalCompanion(
      id: Value(id),
      kimaiUserId: kimaiUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(kimaiUserId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      timezone: Value(timezone),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UsersLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersLocalData(
      id: serializer.fromJson<String>(json['id']),
      kimaiUserId: serializer.fromJson<int?>(json['kimaiUserId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      email: serializer.fromJson<String?>(json['email']),
      timezone: serializer.fromJson<String>(json['timezone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kimaiUserId': serializer.toJson<int?>(kimaiUserId),
      'displayName': serializer.toJson<String?>(displayName),
      'email': serializer.toJson<String?>(email),
      'timezone': serializer.toJson<String>(timezone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UsersLocalData copyWith(
          {String? id,
          Value<int?> kimaiUserId = const Value.absent(),
          Value<String?> displayName = const Value.absent(),
          Value<String?> email = const Value.absent(),
          String? timezone,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UsersLocalData(
        id: id ?? this.id,
        kimaiUserId: kimaiUserId.present ? kimaiUserId.value : this.kimaiUserId,
        displayName: displayName.present ? displayName.value : this.displayName,
        email: email.present ? email.value : this.email,
        timezone: timezone ?? this.timezone,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UsersLocalData copyWithCompanion(UsersLocalCompanion data) {
    return UsersLocalData(
      id: data.id.present ? data.id.value : this.id,
      kimaiUserId:
          data.kimaiUserId.present ? data.kimaiUserId.value : this.kimaiUserId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersLocalData(')
          ..write('id: $id, ')
          ..write('kimaiUserId: $kimaiUserId, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('timezone: $timezone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, kimaiUserId, displayName, email, timezone, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersLocalData &&
          other.id == this.id &&
          other.kimaiUserId == this.kimaiUserId &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.timezone == this.timezone &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersLocalCompanion extends UpdateCompanion<UsersLocalData> {
  final Value<String> id;
  final Value<int?> kimaiUserId;
  final Value<String?> displayName;
  final Value<String?> email;
  final Value<String> timezone;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersLocalCompanion({
    this.id = const Value.absent(),
    this.kimaiUserId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.timezone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersLocalCompanion.insert({
    required String id,
    this.kimaiUserId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.timezone = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<UsersLocalData> custom({
    Expression<String>? id,
    Expression<int>? kimaiUserId,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<String>? timezone,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kimaiUserId != null) 'kimai_user_id': kimaiUserId,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (timezone != null) 'timezone': timezone,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersLocalCompanion copyWith(
      {Value<String>? id,
      Value<int?>? kimaiUserId,
      Value<String?>? displayName,
      Value<String?>? email,
      Value<String>? timezone,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UsersLocalCompanion(
      id: id ?? this.id,
      kimaiUserId: kimaiUserId ?? this.kimaiUserId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      timezone: timezone ?? this.timezone,
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
    if (kimaiUserId.present) {
      map['kimai_user_id'] = Variable<int>(kimaiUserId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
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
    return (StringBuffer('UsersLocalCompanion(')
          ..write('id: $id, ')
          ..write('kimaiUserId: $kimaiUserId, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('timezone: $timezone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, lastSyncedAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String? value;
  final DateTime? lastSyncedAt;
  final DateTime updatedAt;
  const SyncStateData(
      {required this.key,
      this.value,
      this.lastSyncedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncStateData copyWith(
          {String? key,
          Value<String?> value = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      SyncStateData(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, lastSyncedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        updatedAt = Value(updatedAt);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith(
      {Value<String>? key,
      Value<String?>? value,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
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
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KimaiProjectsTable extends KimaiProjects
    with TableInfo<$KimaiProjectsTable, KimaiProject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KimaiProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visibleMeta =
      const VerificationMeta('visible');
  @override
  late final GeneratedColumn<bool> visible = GeneratedColumn<bool>(
      'visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("visible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _billableMeta =
      const VerificationMeta('billable');
  @override
  late final GeneratedColumn<bool> billable = GeneratedColumn<bool>(
      'billable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("billable" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kimaiUpdatedAtMeta =
      const VerificationMeta('kimaiUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> kimaiUpdatedAt =
      GeneratedColumn<DateTime>('kimai_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        customerName,
        visible,
        billable,
        color,
        kimaiUpdatedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kimai_projects';
  @override
  VerificationContext validateIntegrity(Insertable<KimaiProject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('visible')) {
      context.handle(_visibleMeta,
          visible.isAcceptableOrUnknown(data['visible']!, _visibleMeta));
    }
    if (data.containsKey('billable')) {
      context.handle(_billableMeta,
          billable.isAcceptableOrUnknown(data['billable']!, _billableMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('kimai_updated_at')) {
      context.handle(
          _kimaiUpdatedAtMeta,
          kimaiUpdatedAt.isAcceptableOrUnknown(
              data['kimai_updated_at']!, _kimaiUpdatedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KimaiProject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KimaiProject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      visible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}visible'])!,
      billable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}billable'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      kimaiUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}kimai_updated_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $KimaiProjectsTable createAlias(String alias) {
    return $KimaiProjectsTable(attachedDatabase, alias);
  }
}

class KimaiProject extends DataClass implements Insertable<KimaiProject> {
  final int id;
  final String name;
  final String? customerName;
  final bool visible;
  final bool billable;
  final String? color;
  final DateTime? kimaiUpdatedAt;
  final DateTime syncedAt;
  const KimaiProject(
      {required this.id,
      required this.name,
      this.customerName,
      required this.visible,
      required this.billable,
      this.color,
      this.kimaiUpdatedAt,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['visible'] = Variable<bool>(visible);
    map['billable'] = Variable<bool>(billable);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || kimaiUpdatedAt != null) {
      map['kimai_updated_at'] = Variable<DateTime>(kimaiUpdatedAt);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  KimaiProjectsCompanion toCompanion(bool nullToAbsent) {
    return KimaiProjectsCompanion(
      id: Value(id),
      name: Value(name),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      visible: Value(visible),
      billable: Value(billable),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      kimaiUpdatedAt: kimaiUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(kimaiUpdatedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory KimaiProject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KimaiProject(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      visible: serializer.fromJson<bool>(json['visible']),
      billable: serializer.fromJson<bool>(json['billable']),
      color: serializer.fromJson<String?>(json['color']),
      kimaiUpdatedAt: serializer.fromJson<DateTime?>(json['kimaiUpdatedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'customerName': serializer.toJson<String?>(customerName),
      'visible': serializer.toJson<bool>(visible),
      'billable': serializer.toJson<bool>(billable),
      'color': serializer.toJson<String?>(color),
      'kimaiUpdatedAt': serializer.toJson<DateTime?>(kimaiUpdatedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  KimaiProject copyWith(
          {int? id,
          String? name,
          Value<String?> customerName = const Value.absent(),
          bool? visible,
          bool? billable,
          Value<String?> color = const Value.absent(),
          Value<DateTime?> kimaiUpdatedAt = const Value.absent(),
          DateTime? syncedAt}) =>
      KimaiProject(
        id: id ?? this.id,
        name: name ?? this.name,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        visible: visible ?? this.visible,
        billable: billable ?? this.billable,
        color: color.present ? color.value : this.color,
        kimaiUpdatedAt:
            kimaiUpdatedAt.present ? kimaiUpdatedAt.value : this.kimaiUpdatedAt,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  KimaiProject copyWithCompanion(KimaiProjectsCompanion data) {
    return KimaiProject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      visible: data.visible.present ? data.visible.value : this.visible,
      billable: data.billable.present ? data.billable.value : this.billable,
      color: data.color.present ? data.color.value : this.color,
      kimaiUpdatedAt: data.kimaiUpdatedAt.present
          ? data.kimaiUpdatedAt.value
          : this.kimaiUpdatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KimaiProject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('customerName: $customerName, ')
          ..write('visible: $visible, ')
          ..write('billable: $billable, ')
          ..write('color: $color, ')
          ..write('kimaiUpdatedAt: $kimaiUpdatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, customerName, visible, billable,
      color, kimaiUpdatedAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KimaiProject &&
          other.id == this.id &&
          other.name == this.name &&
          other.customerName == this.customerName &&
          other.visible == this.visible &&
          other.billable == this.billable &&
          other.color == this.color &&
          other.kimaiUpdatedAt == this.kimaiUpdatedAt &&
          other.syncedAt == this.syncedAt);
}

class KimaiProjectsCompanion extends UpdateCompanion<KimaiProject> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> customerName;
  final Value<bool> visible;
  final Value<bool> billable;
  final Value<String?> color;
  final Value<DateTime?> kimaiUpdatedAt;
  final Value<DateTime> syncedAt;
  const KimaiProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.customerName = const Value.absent(),
    this.visible = const Value.absent(),
    this.billable = const Value.absent(),
    this.color = const Value.absent(),
    this.kimaiUpdatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  KimaiProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.customerName = const Value.absent(),
    this.visible = const Value.absent(),
    this.billable = const Value.absent(),
    this.color = const Value.absent(),
    this.kimaiUpdatedAt = const Value.absent(),
    required DateTime syncedAt,
  })  : name = Value(name),
        syncedAt = Value(syncedAt);
  static Insertable<KimaiProject> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? customerName,
    Expression<bool>? visible,
    Expression<bool>? billable,
    Expression<String>? color,
    Expression<DateTime>? kimaiUpdatedAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (customerName != null) 'customer_name': customerName,
      if (visible != null) 'visible': visible,
      if (billable != null) 'billable': billable,
      if (color != null) 'color': color,
      if (kimaiUpdatedAt != null) 'kimai_updated_at': kimaiUpdatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  KimaiProjectsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? customerName,
      Value<bool>? visible,
      Value<bool>? billable,
      Value<String?>? color,
      Value<DateTime?>? kimaiUpdatedAt,
      Value<DateTime>? syncedAt}) {
    return KimaiProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      customerName: customerName ?? this.customerName,
      visible: visible ?? this.visible,
      billable: billable ?? this.billable,
      color: color ?? this.color,
      kimaiUpdatedAt: kimaiUpdatedAt ?? this.kimaiUpdatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (visible.present) {
      map['visible'] = Variable<bool>(visible.value);
    }
    if (billable.present) {
      map['billable'] = Variable<bool>(billable.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (kimaiUpdatedAt.present) {
      map['kimai_updated_at'] = Variable<DateTime>(kimaiUpdatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KimaiProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('customerName: $customerName, ')
          ..write('visible: $visible, ')
          ..write('billable: $billable, ')
          ..write('color: $color, ')
          ..write('kimaiUpdatedAt: $kimaiUpdatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $AppProjectsTable extends AppProjects
    with TableInfo<$AppProjectsTable, AppProject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kimaiProjectIdMeta =
      const VerificationMeta('kimaiProjectId');
  @override
  late final GeneratedColumn<int> kimaiProjectId = GeneratedColumn<int>(
      'kimai_project_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL REFERENCES kimai_projects(id)');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
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
  static const VerificationMeta _hourlyRateMeta =
      const VerificationMeta('hourlyRate');
  @override
  late final GeneratedColumn<double> hourlyRate = GeneratedColumn<double>(
      'hourly_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hourlyRateMinorMeta =
      const VerificationMeta('hourlyRateMinor');
  @override
  late final GeneratedColumn<int> hourlyRateMinor = GeneratedColumn<int>(
      'hourly_rate_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weeklyGoalHoursMeta =
      const VerificationMeta('weeklyGoalHours');
  @override
  late final GeneratedColumn<double> weeklyGoalHours = GeneratedColumn<double>(
      'weekly_goal_hours', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _payoutRuleMeta =
      const VerificationMeta('payoutRule');
  @override
  late final GeneratedColumn<String> payoutRule = GeneratedColumn<String>(
      'payout_rule', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
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
        kimaiProjectId,
        name,
        color,
        enabled,
        hourlyRate,
        hourlyRateMinor,
        weeklyGoalHours,
        currency,
        payoutRule,
        archived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_projects';
  @override
  VerificationContext validateIntegrity(Insertable<AppProject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kimai_project_id')) {
      context.handle(
          _kimaiProjectIdMeta,
          kimaiProjectId.isAcceptableOrUnknown(
              data['kimai_project_id']!, _kimaiProjectIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('hourly_rate')) {
      context.handle(
          _hourlyRateMeta,
          hourlyRate.isAcceptableOrUnknown(
              data['hourly_rate']!, _hourlyRateMeta));
    }
    if (data.containsKey('hourly_rate_minor')) {
      context.handle(
          _hourlyRateMinorMeta,
          hourlyRateMinor.isAcceptableOrUnknown(
              data['hourly_rate_minor']!, _hourlyRateMinorMeta));
    }
    if (data.containsKey('weekly_goal_hours')) {
      context.handle(
          _weeklyGoalHoursMeta,
          weeklyGoalHours.isAcceptableOrUnknown(
              data['weekly_goal_hours']!, _weeklyGoalHoursMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('payout_rule')) {
      context.handle(
          _payoutRuleMeta,
          payoutRule.isAcceptableOrUnknown(
              data['payout_rule']!, _payoutRuleMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
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
  AppProject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppProject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kimaiProjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kimai_project_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      hourlyRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hourly_rate']),
      hourlyRateMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hourly_rate_minor']),
      weeklyGoalHours: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}weekly_goal_hours']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      payoutRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payout_rule'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppProjectsTable createAlias(String alias) {
    return $AppProjectsTable(attachedDatabase, alias);
  }
}

class AppProject extends DataClass implements Insertable<AppProject> {
  final String id;
  final int? kimaiProjectId;
  final String name;
  final String? color;
  final bool enabled;
  final double? hourlyRate;
  final int? hourlyRateMinor;
  final double? weeklyGoalHours;
  final String currency;
  final String payoutRule;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppProject(
      {required this.id,
      this.kimaiProjectId,
      required this.name,
      this.color,
      required this.enabled,
      this.hourlyRate,
      this.hourlyRateMinor,
      this.weeklyGoalHours,
      required this.currency,
      required this.payoutRule,
      required this.archived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || kimaiProjectId != null) {
      map['kimai_project_id'] = Variable<int>(kimaiProjectId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || hourlyRate != null) {
      map['hourly_rate'] = Variable<double>(hourlyRate);
    }
    if (!nullToAbsent || hourlyRateMinor != null) {
      map['hourly_rate_minor'] = Variable<int>(hourlyRateMinor);
    }
    if (!nullToAbsent || weeklyGoalHours != null) {
      map['weekly_goal_hours'] = Variable<double>(weeklyGoalHours);
    }
    map['currency'] = Variable<String>(currency);
    map['payout_rule'] = Variable<String>(payoutRule);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppProjectsCompanion toCompanion(bool nullToAbsent) {
    return AppProjectsCompanion(
      id: Value(id),
      kimaiProjectId: kimaiProjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(kimaiProjectId),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      enabled: Value(enabled),
      hourlyRate: hourlyRate == null && nullToAbsent
          ? const Value.absent()
          : Value(hourlyRate),
      hourlyRateMinor: hourlyRateMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(hourlyRateMinor),
      weeklyGoalHours: weeklyGoalHours == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyGoalHours),
      currency: Value(currency),
      payoutRule: Value(payoutRule),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppProject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppProject(
      id: serializer.fromJson<String>(json['id']),
      kimaiProjectId: serializer.fromJson<int?>(json['kimaiProjectId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      hourlyRate: serializer.fromJson<double?>(json['hourlyRate']),
      hourlyRateMinor: serializer.fromJson<int?>(json['hourlyRateMinor']),
      weeklyGoalHours: serializer.fromJson<double?>(json['weeklyGoalHours']),
      currency: serializer.fromJson<String>(json['currency']),
      payoutRule: serializer.fromJson<String>(json['payoutRule']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kimaiProjectId': serializer.toJson<int?>(kimaiProjectId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'enabled': serializer.toJson<bool>(enabled),
      'hourlyRate': serializer.toJson<double?>(hourlyRate),
      'hourlyRateMinor': serializer.toJson<int?>(hourlyRateMinor),
      'weeklyGoalHours': serializer.toJson<double?>(weeklyGoalHours),
      'currency': serializer.toJson<String>(currency),
      'payoutRule': serializer.toJson<String>(payoutRule),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppProject copyWith(
          {String? id,
          Value<int?> kimaiProjectId = const Value.absent(),
          String? name,
          Value<String?> color = const Value.absent(),
          bool? enabled,
          Value<double?> hourlyRate = const Value.absent(),
          Value<int?> hourlyRateMinor = const Value.absent(),
          Value<double?> weeklyGoalHours = const Value.absent(),
          String? currency,
          String? payoutRule,
          bool? archived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AppProject(
        id: id ?? this.id,
        kimaiProjectId:
            kimaiProjectId.present ? kimaiProjectId.value : this.kimaiProjectId,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        enabled: enabled ?? this.enabled,
        hourlyRate: hourlyRate.present ? hourlyRate.value : this.hourlyRate,
        hourlyRateMinor: hourlyRateMinor.present
            ? hourlyRateMinor.value
            : this.hourlyRateMinor,
        weeklyGoalHours: weeklyGoalHours.present
            ? weeklyGoalHours.value
            : this.weeklyGoalHours,
        currency: currency ?? this.currency,
        payoutRule: payoutRule ?? this.payoutRule,
        archived: archived ?? this.archived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppProject copyWithCompanion(AppProjectsCompanion data) {
    return AppProject(
      id: data.id.present ? data.id.value : this.id,
      kimaiProjectId: data.kimaiProjectId.present
          ? data.kimaiProjectId.value
          : this.kimaiProjectId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      hourlyRate:
          data.hourlyRate.present ? data.hourlyRate.value : this.hourlyRate,
      hourlyRateMinor: data.hourlyRateMinor.present
          ? data.hourlyRateMinor.value
          : this.hourlyRateMinor,
      weeklyGoalHours: data.weeklyGoalHours.present
          ? data.weeklyGoalHours.value
          : this.weeklyGoalHours,
      currency: data.currency.present ? data.currency.value : this.currency,
      payoutRule:
          data.payoutRule.present ? data.payoutRule.value : this.payoutRule,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppProject(')
          ..write('id: $id, ')
          ..write('kimaiProjectId: $kimaiProjectId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('enabled: $enabled, ')
          ..write('hourlyRate: $hourlyRate, ')
          ..write('hourlyRateMinor: $hourlyRateMinor, ')
          ..write('weeklyGoalHours: $weeklyGoalHours, ')
          ..write('currency: $currency, ')
          ..write('payoutRule: $payoutRule, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kimaiProjectId,
      name,
      color,
      enabled,
      hourlyRate,
      hourlyRateMinor,
      weeklyGoalHours,
      currency,
      payoutRule,
      archived,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppProject &&
          other.id == this.id &&
          other.kimaiProjectId == this.kimaiProjectId &&
          other.name == this.name &&
          other.color == this.color &&
          other.enabled == this.enabled &&
          other.hourlyRate == this.hourlyRate &&
          other.hourlyRateMinor == this.hourlyRateMinor &&
          other.weeklyGoalHours == this.weeklyGoalHours &&
          other.currency == this.currency &&
          other.payoutRule == this.payoutRule &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppProjectsCompanion extends UpdateCompanion<AppProject> {
  final Value<String> id;
  final Value<int?> kimaiProjectId;
  final Value<String> name;
  final Value<String?> color;
  final Value<bool> enabled;
  final Value<double?> hourlyRate;
  final Value<int?> hourlyRateMinor;
  final Value<double?> weeklyGoalHours;
  final Value<String> currency;
  final Value<String> payoutRule;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppProjectsCompanion({
    this.id = const Value.absent(),
    this.kimaiProjectId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.enabled = const Value.absent(),
    this.hourlyRate = const Value.absent(),
    this.hourlyRateMinor = const Value.absent(),
    this.weeklyGoalHours = const Value.absent(),
    this.currency = const Value.absent(),
    this.payoutRule = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppProjectsCompanion.insert({
    required String id,
    this.kimaiProjectId = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.enabled = const Value.absent(),
    this.hourlyRate = const Value.absent(),
    this.hourlyRateMinor = const Value.absent(),
    this.weeklyGoalHours = const Value.absent(),
    this.currency = const Value.absent(),
    this.payoutRule = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AppProject> custom({
    Expression<String>? id,
    Expression<int>? kimaiProjectId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<bool>? enabled,
    Expression<double>? hourlyRate,
    Expression<int>? hourlyRateMinor,
    Expression<double>? weeklyGoalHours,
    Expression<String>? currency,
    Expression<String>? payoutRule,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kimaiProjectId != null) 'kimai_project_id': kimaiProjectId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (enabled != null) 'enabled': enabled,
      if (hourlyRate != null) 'hourly_rate': hourlyRate,
      if (hourlyRateMinor != null) 'hourly_rate_minor': hourlyRateMinor,
      if (weeklyGoalHours != null) 'weekly_goal_hours': weeklyGoalHours,
      if (currency != null) 'currency': currency,
      if (payoutRule != null) 'payout_rule': payoutRule,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppProjectsCompanion copyWith(
      {Value<String>? id,
      Value<int?>? kimaiProjectId,
      Value<String>? name,
      Value<String?>? color,
      Value<bool>? enabled,
      Value<double?>? hourlyRate,
      Value<int?>? hourlyRateMinor,
      Value<double?>? weeklyGoalHours,
      Value<String>? currency,
      Value<String>? payoutRule,
      Value<bool>? archived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppProjectsCompanion(
      id: id ?? this.id,
      kimaiProjectId: kimaiProjectId ?? this.kimaiProjectId,
      name: name ?? this.name,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      hourlyRateMinor: hourlyRateMinor ?? this.hourlyRateMinor,
      weeklyGoalHours: weeklyGoalHours ?? this.weeklyGoalHours,
      currency: currency ?? this.currency,
      payoutRule: payoutRule ?? this.payoutRule,
      archived: archived ?? this.archived,
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
    if (kimaiProjectId.present) {
      map['kimai_project_id'] = Variable<int>(kimaiProjectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (hourlyRate.present) {
      map['hourly_rate'] = Variable<double>(hourlyRate.value);
    }
    if (hourlyRateMinor.present) {
      map['hourly_rate_minor'] = Variable<int>(hourlyRateMinor.value);
    }
    if (weeklyGoalHours.present) {
      map['weekly_goal_hours'] = Variable<double>(weeklyGoalHours.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (payoutRule.present) {
      map['payout_rule'] = Variable<String>(payoutRule.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
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
    return (StringBuffer('AppProjectsCompanion(')
          ..write('id: $id, ')
          ..write('kimaiProjectId: $kimaiProjectId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('enabled: $enabled, ')
          ..write('hourlyRate: $hourlyRate, ')
          ..write('hourlyRateMinor: $hourlyRateMinor, ')
          ..write('weeklyGoalHours: $weeklyGoalHours, ')
          ..write('currency: $currency, ')
          ..write('payoutRule: $payoutRule, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PayoutDatesTable extends PayoutDates
    with TableInfo<$PayoutDatesTable, PayoutDate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayoutDatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appProjectIdMeta =
      const VerificationMeta('appProjectId');
  @override
  late final GeneratedColumn<String> appProjectId = GeneratedColumn<String>(
      'app_project_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES app_projects(id)');
  static const VerificationMeta _payoutDateMeta =
      const VerificationMeta('payoutDate');
  @override
  late final GeneratedColumn<DateTime> payoutDate = GeneratedColumn<DateTime>(
      'payout_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _expectedAmountMeta =
      const VerificationMeta('expectedAmount');
  @override
  late final GeneratedColumn<double> expectedAmount = GeneratedColumn<double>(
      'expected_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
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
        appProjectId,
        payoutDate,
        expectedAmount,
        currency,
        note,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payout_dates';
  @override
  VerificationContext validateIntegrity(Insertable<PayoutDate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_project_id')) {
      context.handle(
          _appProjectIdMeta,
          appProjectId.isAcceptableOrUnknown(
              data['app_project_id']!, _appProjectIdMeta));
    } else if (isInserting) {
      context.missing(_appProjectIdMeta);
    }
    if (data.containsKey('payout_date')) {
      context.handle(
          _payoutDateMeta,
          payoutDate.isAcceptableOrUnknown(
              data['payout_date']!, _payoutDateMeta));
    } else if (isInserting) {
      context.missing(_payoutDateMeta);
    }
    if (data.containsKey('expected_amount')) {
      context.handle(
          _expectedAmountMeta,
          expectedAmount.isAcceptableOrUnknown(
              data['expected_amount']!, _expectedAmountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
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
  PayoutDate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayoutDate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      appProjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_project_id'])!,
      payoutDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}payout_date'])!,
      expectedAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_amount']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PayoutDatesTable createAlias(String alias) {
    return $PayoutDatesTable(attachedDatabase, alias);
  }
}

class PayoutDate extends DataClass implements Insertable<PayoutDate> {
  final String id;
  final String appProjectId;
  final DateTime payoutDate;
  final double? expectedAmount;
  final String currency;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PayoutDate(
      {required this.id,
      required this.appProjectId,
      required this.payoutDate,
      this.expectedAmount,
      required this.currency,
      this.note,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['app_project_id'] = Variable<String>(appProjectId);
    map['payout_date'] = Variable<DateTime>(payoutDate);
    if (!nullToAbsent || expectedAmount != null) {
      map['expected_amount'] = Variable<double>(expectedAmount);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PayoutDatesCompanion toCompanion(bool nullToAbsent) {
    return PayoutDatesCompanion(
      id: Value(id),
      appProjectId: Value(appProjectId),
      payoutDate: Value(payoutDate),
      expectedAmount: expectedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedAmount),
      currency: Value(currency),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PayoutDate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayoutDate(
      id: serializer.fromJson<String>(json['id']),
      appProjectId: serializer.fromJson<String>(json['appProjectId']),
      payoutDate: serializer.fromJson<DateTime>(json['payoutDate']),
      expectedAmount: serializer.fromJson<double?>(json['expectedAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appProjectId': serializer.toJson<String>(appProjectId),
      'payoutDate': serializer.toJson<DateTime>(payoutDate),
      'expectedAmount': serializer.toJson<double?>(expectedAmount),
      'currency': serializer.toJson<String>(currency),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PayoutDate copyWith(
          {String? id,
          String? appProjectId,
          DateTime? payoutDate,
          Value<double?> expectedAmount = const Value.absent(),
          String? currency,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PayoutDate(
        id: id ?? this.id,
        appProjectId: appProjectId ?? this.appProjectId,
        payoutDate: payoutDate ?? this.payoutDate,
        expectedAmount:
            expectedAmount.present ? expectedAmount.value : this.expectedAmount,
        currency: currency ?? this.currency,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PayoutDate copyWithCompanion(PayoutDatesCompanion data) {
    return PayoutDate(
      id: data.id.present ? data.id.value : this.id,
      appProjectId: data.appProjectId.present
          ? data.appProjectId.value
          : this.appProjectId,
      payoutDate:
          data.payoutDate.present ? data.payoutDate.value : this.payoutDate,
      expectedAmount: data.expectedAmount.present
          ? data.expectedAmount.value
          : this.expectedAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayoutDate(')
          ..write('id: $id, ')
          ..write('appProjectId: $appProjectId, ')
          ..write('payoutDate: $payoutDate, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('currency: $currency, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appProjectId, payoutDate, expectedAmount,
      currency, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayoutDate &&
          other.id == this.id &&
          other.appProjectId == this.appProjectId &&
          other.payoutDate == this.payoutDate &&
          other.expectedAmount == this.expectedAmount &&
          other.currency == this.currency &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PayoutDatesCompanion extends UpdateCompanion<PayoutDate> {
  final Value<String> id;
  final Value<String> appProjectId;
  final Value<DateTime> payoutDate;
  final Value<double?> expectedAmount;
  final Value<String> currency;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PayoutDatesCompanion({
    this.id = const Value.absent(),
    this.appProjectId = const Value.absent(),
    this.payoutDate = const Value.absent(),
    this.expectedAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PayoutDatesCompanion.insert({
    required String id,
    required String appProjectId,
    required DateTime payoutDate,
    this.expectedAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        appProjectId = Value(appProjectId),
        payoutDate = Value(payoutDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PayoutDate> custom({
    Expression<String>? id,
    Expression<String>? appProjectId,
    Expression<DateTime>? payoutDate,
    Expression<double>? expectedAmount,
    Expression<String>? currency,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appProjectId != null) 'app_project_id': appProjectId,
      if (payoutDate != null) 'payout_date': payoutDate,
      if (expectedAmount != null) 'expected_amount': expectedAmount,
      if (currency != null) 'currency': currency,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PayoutDatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? appProjectId,
      Value<DateTime>? payoutDate,
      Value<double?>? expectedAmount,
      Value<String>? currency,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PayoutDatesCompanion(
      id: id ?? this.id,
      appProjectId: appProjectId ?? this.appProjectId,
      payoutDate: payoutDate ?? this.payoutDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      currency: currency ?? this.currency,
      note: note ?? this.note,
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
    if (appProjectId.present) {
      map['app_project_id'] = Variable<String>(appProjectId.value);
    }
    if (payoutDate.present) {
      map['payout_date'] = Variable<DateTime>(payoutDate.value);
    }
    if (expectedAmount.present) {
      map['expected_amount'] = Variable<double>(expectedAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('PayoutDatesCompanion(')
          ..write('id: $id, ')
          ..write('appProjectId: $appProjectId, ')
          ..write('payoutDate: $payoutDate, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('currency: $currency, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimesheetsTable extends Timesheets
    with TableInfo<$TimesheetsTable, Timesheet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimesheetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _kimaiProjectIdMeta =
      const VerificationMeta('kimaiProjectId');
  @override
  late final GeneratedColumn<int> kimaiProjectId = GeneratedColumn<int>(
      'kimai_project_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL REFERENCES kimai_projects(id)');
  static const VerificationMeta _appProjectIdMeta =
      const VerificationMeta('appProjectId');
  @override
  late final GeneratedColumn<String> appProjectId = GeneratedColumn<String>(
      'app_project_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL REFERENCES app_projects(id)');
  static const VerificationMeta _activityNameMeta =
      const VerificationMeta('activityName');
  @override
  late final GeneratedColumn<String> activityName = GeneratedColumn<String>(
      'activity_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _beginAtMeta =
      const VerificationMeta('beginAt');
  @override
  late final GeneratedColumn<DateTime> beginAt = GeneratedColumn<DateTime>(
      'begin_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
      'end_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exportedMeta =
      const VerificationMeta('exported');
  @override
  late final GeneratedColumn<bool> exported = GeneratedColumn<bool>(
      'exported', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("exported" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kimaiUpdatedAtMeta =
      const VerificationMeta('kimaiUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> kimaiUpdatedAt =
      GeneratedColumn<DateTime>('kimai_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kimaiProjectId,
        appProjectId,
        activityName,
        description,
        beginAt,
        endAt,
        durationSeconds,
        rate,
        amountMinor,
        currency,
        exported,
        tags,
        kimaiUpdatedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timesheets';
  @override
  VerificationContext validateIntegrity(Insertable<Timesheet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kimai_project_id')) {
      context.handle(
          _kimaiProjectIdMeta,
          kimaiProjectId.isAcceptableOrUnknown(
              data['kimai_project_id']!, _kimaiProjectIdMeta));
    }
    if (data.containsKey('app_project_id')) {
      context.handle(
          _appProjectIdMeta,
          appProjectId.isAcceptableOrUnknown(
              data['app_project_id']!, _appProjectIdMeta));
    }
    if (data.containsKey('activity_name')) {
      context.handle(
          _activityNameMeta,
          activityName.isAcceptableOrUnknown(
              data['activity_name']!, _activityNameMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('begin_at')) {
      context.handle(_beginAtMeta,
          beginAt.isAcceptableOrUnknown(data['begin_at']!, _beginAtMeta));
    } else if (isInserting) {
      context.missing(_beginAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
          _endAtMeta, endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('exported')) {
      context.handle(_exportedMeta,
          exported.isAcceptableOrUnknown(data['exported']!, _exportedMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('kimai_updated_at')) {
      context.handle(
          _kimaiUpdatedAtMeta,
          kimaiUpdatedAt.isAcceptableOrUnknown(
              data['kimai_updated_at']!, _kimaiUpdatedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Timesheet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Timesheet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kimaiProjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kimai_project_id']),
      appProjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_project_id']),
      activityName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_name']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      beginAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}begin_at'])!,
      endAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_at']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate']),
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency']),
      exported: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}exported'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      kimaiUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}kimai_updated_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $TimesheetsTable createAlias(String alias) {
    return $TimesheetsTable(attachedDatabase, alias);
  }
}

class Timesheet extends DataClass implements Insertable<Timesheet> {
  final int id;
  final int? kimaiProjectId;
  final String? appProjectId;
  final String? activityName;
  final String? description;
  final DateTime beginAt;
  final DateTime? endAt;
  final int durationSeconds;
  final double? rate;
  final int? amountMinor;
  final String? currency;
  final bool exported;
  final String? tags;
  final DateTime? kimaiUpdatedAt;
  final DateTime syncedAt;
  const Timesheet(
      {required this.id,
      this.kimaiProjectId,
      this.appProjectId,
      this.activityName,
      this.description,
      required this.beginAt,
      this.endAt,
      required this.durationSeconds,
      this.rate,
      this.amountMinor,
      this.currency,
      required this.exported,
      this.tags,
      this.kimaiUpdatedAt,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || kimaiProjectId != null) {
      map['kimai_project_id'] = Variable<int>(kimaiProjectId);
    }
    if (!nullToAbsent || appProjectId != null) {
      map['app_project_id'] = Variable<String>(appProjectId);
    }
    if (!nullToAbsent || activityName != null) {
      map['activity_name'] = Variable<String>(activityName);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['begin_at'] = Variable<DateTime>(beginAt);
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || rate != null) {
      map['rate'] = Variable<double>(rate);
    }
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    map['exported'] = Variable<bool>(exported);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || kimaiUpdatedAt != null) {
      map['kimai_updated_at'] = Variable<DateTime>(kimaiUpdatedAt);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  TimesheetsCompanion toCompanion(bool nullToAbsent) {
    return TimesheetsCompanion(
      id: Value(id),
      kimaiProjectId: kimaiProjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(kimaiProjectId),
      appProjectId: appProjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(appProjectId),
      activityName: activityName == null && nullToAbsent
          ? const Value.absent()
          : Value(activityName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      beginAt: Value(beginAt),
      endAt:
          endAt == null && nullToAbsent ? const Value.absent() : Value(endAt),
      durationSeconds: Value(durationSeconds),
      rate: rate == null && nullToAbsent ? const Value.absent() : Value(rate),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      exported: Value(exported),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      kimaiUpdatedAt: kimaiUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(kimaiUpdatedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory Timesheet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Timesheet(
      id: serializer.fromJson<int>(json['id']),
      kimaiProjectId: serializer.fromJson<int?>(json['kimaiProjectId']),
      appProjectId: serializer.fromJson<String?>(json['appProjectId']),
      activityName: serializer.fromJson<String?>(json['activityName']),
      description: serializer.fromJson<String?>(json['description']),
      beginAt: serializer.fromJson<DateTime>(json['beginAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      rate: serializer.fromJson<double?>(json['rate']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      currency: serializer.fromJson<String?>(json['currency']),
      exported: serializer.fromJson<bool>(json['exported']),
      tags: serializer.fromJson<String?>(json['tags']),
      kimaiUpdatedAt: serializer.fromJson<DateTime?>(json['kimaiUpdatedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kimaiProjectId': serializer.toJson<int?>(kimaiProjectId),
      'appProjectId': serializer.toJson<String?>(appProjectId),
      'activityName': serializer.toJson<String?>(activityName),
      'description': serializer.toJson<String?>(description),
      'beginAt': serializer.toJson<DateTime>(beginAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'rate': serializer.toJson<double?>(rate),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'currency': serializer.toJson<String?>(currency),
      'exported': serializer.toJson<bool>(exported),
      'tags': serializer.toJson<String?>(tags),
      'kimaiUpdatedAt': serializer.toJson<DateTime?>(kimaiUpdatedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  Timesheet copyWith(
          {int? id,
          Value<int?> kimaiProjectId = const Value.absent(),
          Value<String?> appProjectId = const Value.absent(),
          Value<String?> activityName = const Value.absent(),
          Value<String?> description = const Value.absent(),
          DateTime? beginAt,
          Value<DateTime?> endAt = const Value.absent(),
          int? durationSeconds,
          Value<double?> rate = const Value.absent(),
          Value<int?> amountMinor = const Value.absent(),
          Value<String?> currency = const Value.absent(),
          bool? exported,
          Value<String?> tags = const Value.absent(),
          Value<DateTime?> kimaiUpdatedAt = const Value.absent(),
          DateTime? syncedAt}) =>
      Timesheet(
        id: id ?? this.id,
        kimaiProjectId:
            kimaiProjectId.present ? kimaiProjectId.value : this.kimaiProjectId,
        appProjectId:
            appProjectId.present ? appProjectId.value : this.appProjectId,
        activityName:
            activityName.present ? activityName.value : this.activityName,
        description: description.present ? description.value : this.description,
        beginAt: beginAt ?? this.beginAt,
        endAt: endAt.present ? endAt.value : this.endAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        rate: rate.present ? rate.value : this.rate,
        amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
        currency: currency.present ? currency.value : this.currency,
        exported: exported ?? this.exported,
        tags: tags.present ? tags.value : this.tags,
        kimaiUpdatedAt:
            kimaiUpdatedAt.present ? kimaiUpdatedAt.value : this.kimaiUpdatedAt,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  Timesheet copyWithCompanion(TimesheetsCompanion data) {
    return Timesheet(
      id: data.id.present ? data.id.value : this.id,
      kimaiProjectId: data.kimaiProjectId.present
          ? data.kimaiProjectId.value
          : this.kimaiProjectId,
      appProjectId: data.appProjectId.present
          ? data.appProjectId.value
          : this.appProjectId,
      activityName: data.activityName.present
          ? data.activityName.value
          : this.activityName,
      description:
          data.description.present ? data.description.value : this.description,
      beginAt: data.beginAt.present ? data.beginAt.value : this.beginAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      rate: data.rate.present ? data.rate.value : this.rate,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      exported: data.exported.present ? data.exported.value : this.exported,
      tags: data.tags.present ? data.tags.value : this.tags,
      kimaiUpdatedAt: data.kimaiUpdatedAt.present
          ? data.kimaiUpdatedAt.value
          : this.kimaiUpdatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Timesheet(')
          ..write('id: $id, ')
          ..write('kimaiProjectId: $kimaiProjectId, ')
          ..write('appProjectId: $appProjectId, ')
          ..write('activityName: $activityName, ')
          ..write('description: $description, ')
          ..write('beginAt: $beginAt, ')
          ..write('endAt: $endAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('rate: $rate, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('exported: $exported, ')
          ..write('tags: $tags, ')
          ..write('kimaiUpdatedAt: $kimaiUpdatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kimaiProjectId,
      appProjectId,
      activityName,
      description,
      beginAt,
      endAt,
      durationSeconds,
      rate,
      amountMinor,
      currency,
      exported,
      tags,
      kimaiUpdatedAt,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Timesheet &&
          other.id == this.id &&
          other.kimaiProjectId == this.kimaiProjectId &&
          other.appProjectId == this.appProjectId &&
          other.activityName == this.activityName &&
          other.description == this.description &&
          other.beginAt == this.beginAt &&
          other.endAt == this.endAt &&
          other.durationSeconds == this.durationSeconds &&
          other.rate == this.rate &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.exported == this.exported &&
          other.tags == this.tags &&
          other.kimaiUpdatedAt == this.kimaiUpdatedAt &&
          other.syncedAt == this.syncedAt);
}

class TimesheetsCompanion extends UpdateCompanion<Timesheet> {
  final Value<int> id;
  final Value<int?> kimaiProjectId;
  final Value<String?> appProjectId;
  final Value<String?> activityName;
  final Value<String?> description;
  final Value<DateTime> beginAt;
  final Value<DateTime?> endAt;
  final Value<int> durationSeconds;
  final Value<double?> rate;
  final Value<int?> amountMinor;
  final Value<String?> currency;
  final Value<bool> exported;
  final Value<String?> tags;
  final Value<DateTime?> kimaiUpdatedAt;
  final Value<DateTime> syncedAt;
  const TimesheetsCompanion({
    this.id = const Value.absent(),
    this.kimaiProjectId = const Value.absent(),
    this.appProjectId = const Value.absent(),
    this.activityName = const Value.absent(),
    this.description = const Value.absent(),
    this.beginAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.rate = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.exported = const Value.absent(),
    this.tags = const Value.absent(),
    this.kimaiUpdatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  TimesheetsCompanion.insert({
    this.id = const Value.absent(),
    this.kimaiProjectId = const Value.absent(),
    this.appProjectId = const Value.absent(),
    this.activityName = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime beginAt,
    this.endAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.rate = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.exported = const Value.absent(),
    this.tags = const Value.absent(),
    this.kimaiUpdatedAt = const Value.absent(),
    required DateTime syncedAt,
  })  : beginAt = Value(beginAt),
        syncedAt = Value(syncedAt);
  static Insertable<Timesheet> custom({
    Expression<int>? id,
    Expression<int>? kimaiProjectId,
    Expression<String>? appProjectId,
    Expression<String>? activityName,
    Expression<String>? description,
    Expression<DateTime>? beginAt,
    Expression<DateTime>? endAt,
    Expression<int>? durationSeconds,
    Expression<double>? rate,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<bool>? exported,
    Expression<String>? tags,
    Expression<DateTime>? kimaiUpdatedAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kimaiProjectId != null) 'kimai_project_id': kimaiProjectId,
      if (appProjectId != null) 'app_project_id': appProjectId,
      if (activityName != null) 'activity_name': activityName,
      if (description != null) 'description': description,
      if (beginAt != null) 'begin_at': beginAt,
      if (endAt != null) 'end_at': endAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (rate != null) 'rate': rate,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (exported != null) 'exported': exported,
      if (tags != null) 'tags': tags,
      if (kimaiUpdatedAt != null) 'kimai_updated_at': kimaiUpdatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  TimesheetsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? kimaiProjectId,
      Value<String?>? appProjectId,
      Value<String?>? activityName,
      Value<String?>? description,
      Value<DateTime>? beginAt,
      Value<DateTime?>? endAt,
      Value<int>? durationSeconds,
      Value<double?>? rate,
      Value<int?>? amountMinor,
      Value<String?>? currency,
      Value<bool>? exported,
      Value<String?>? tags,
      Value<DateTime?>? kimaiUpdatedAt,
      Value<DateTime>? syncedAt}) {
    return TimesheetsCompanion(
      id: id ?? this.id,
      kimaiProjectId: kimaiProjectId ?? this.kimaiProjectId,
      appProjectId: appProjectId ?? this.appProjectId,
      activityName: activityName ?? this.activityName,
      description: description ?? this.description,
      beginAt: beginAt ?? this.beginAt,
      endAt: endAt ?? this.endAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rate: rate ?? this.rate,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      exported: exported ?? this.exported,
      tags: tags ?? this.tags,
      kimaiUpdatedAt: kimaiUpdatedAt ?? this.kimaiUpdatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kimaiProjectId.present) {
      map['kimai_project_id'] = Variable<int>(kimaiProjectId.value);
    }
    if (appProjectId.present) {
      map['app_project_id'] = Variable<String>(appProjectId.value);
    }
    if (activityName.present) {
      map['activity_name'] = Variable<String>(activityName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (beginAt.present) {
      map['begin_at'] = Variable<DateTime>(beginAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exported.present) {
      map['exported'] = Variable<bool>(exported.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (kimaiUpdatedAt.present) {
      map['kimai_updated_at'] = Variable<DateTime>(kimaiUpdatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimesheetsCompanion(')
          ..write('id: $id, ')
          ..write('kimaiProjectId: $kimaiProjectId, ')
          ..write('appProjectId: $appProjectId, ')
          ..write('activityName: $activityName, ')
          ..write('description: $description, ')
          ..write('beginAt: $beginAt, ')
          ..write('endAt: $endAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('rate: $rate, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('exported: $exported, ')
          ..write('tags: $tags, ')
          ..write('kimaiUpdatedAt: $kimaiUpdatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncLogsTable extends SyncLogs with TableInfo<$SyncLogsTable, SyncLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _debugMeta = const VerificationMeta('debug');
  @override
  late final GeneratedColumn<String> debug = GeneratedColumn<String>(
      'debug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _finishedAtMeta =
      const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
      'finished_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, operation, status, message, error, debug, startedAt, finishedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('debug')) {
      context.handle(
          _debugMeta, debug.isAcceptableOrUnknown(data['debug']!, _debugMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
          _finishedAtMeta,
          finishedAt.isAcceptableOrUnknown(
              data['finished_at']!, _finishedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message']),
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      debug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}debug']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      finishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}finished_at']),
    );
  }

  @override
  $SyncLogsTable createAlias(String alias) {
    return $SyncLogsTable(attachedDatabase, alias);
  }
}

class SyncLog extends DataClass implements Insertable<SyncLog> {
  final String id;
  final String operation;
  final String status;
  final String? message;
  final String? error;
  final String? debug;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const SyncLog(
      {required this.id,
      required this.operation,
      required this.status,
      this.message,
      this.error,
      this.debug,
      required this.startedAt,
      this.finishedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation'] = Variable<String>(operation);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || debug != null) {
      map['debug'] = Variable<String>(debug);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  SyncLogsCompanion toCompanion(bool nullToAbsent) {
    return SyncLogsCompanion(
      id: Value(id),
      operation: Value(operation),
      status: Value(status),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      debug:
          debug == null && nullToAbsent ? const Value.absent() : Value(debug),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory SyncLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLog(
      id: serializer.fromJson<String>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String?>(json['message']),
      error: serializer.fromJson<String?>(json['error']),
      debug: serializer.fromJson<String?>(json['debug']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operation': serializer.toJson<String>(operation),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String?>(message),
      'error': serializer.toJson<String?>(error),
      'debug': serializer.toJson<String?>(debug),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  SyncLog copyWith(
          {String? id,
          String? operation,
          String? status,
          Value<String?> message = const Value.absent(),
          Value<String?> error = const Value.absent(),
          Value<String?> debug = const Value.absent(),
          DateTime? startedAt,
          Value<DateTime?> finishedAt = const Value.absent()}) =>
      SyncLog(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        status: status ?? this.status,
        message: message.present ? message.value : this.message,
        error: error.present ? error.value : this.error,
        debug: debug.present ? debug.value : this.debug,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
      );
  SyncLog copyWithCompanion(SyncLogsCompanion data) {
    return SyncLog(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
      error: data.error.present ? data.error.value : this.error,
      debug: data.debug.present ? data.debug.value : this.debug,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt:
          data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLog(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('error: $error, ')
          ..write('debug: $debug, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, operation, status, message, error, debug, startedAt, finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLog &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.status == this.status &&
          other.message == this.message &&
          other.error == this.error &&
          other.debug == this.debug &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class SyncLogsCompanion extends UpdateCompanion<SyncLog> {
  final Value<String> id;
  final Value<String> operation;
  final Value<String> status;
  final Value<String?> message;
  final Value<String?> error;
  final Value<String?> debug;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const SyncLogsCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
    this.error = const Value.absent(),
    this.debug = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncLogsCompanion.insert({
    required String id,
    required String operation,
    required String status,
    this.message = const Value.absent(),
    this.error = const Value.absent(),
    this.debug = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        operation = Value(operation),
        status = Value(status),
        startedAt = Value(startedAt);
  static Insertable<SyncLog> custom({
    Expression<String>? id,
    Expression<String>? operation,
    Expression<String>? status,
    Expression<String>? message,
    Expression<String>? error,
    Expression<String>? debug,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (error != null) 'error': error,
      if (debug != null) 'debug': debug,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? operation,
      Value<String>? status,
      Value<String?>? message,
      Value<String?>? error,
      Value<String?>? debug,
      Value<DateTime>? startedAt,
      Value<DateTime?>? finishedAt,
      Value<int>? rowid}) {
    return SyncLogsCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
      debug: debug ?? this.debug,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (debug.present) {
      map['debug'] = Variable<String>(debug.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogsCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('error: $error, ')
          ..write('debug: $debug, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersLocalTable usersLocal = $UsersLocalTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $KimaiProjectsTable kimaiProjects = $KimaiProjectsTable(this);
  late final $AppProjectsTable appProjects = $AppProjectsTable(this);
  late final $PayoutDatesTable payoutDates = $PayoutDatesTable(this);
  late final $TimesheetsTable timesheets = $TimesheetsTable(this);
  late final $SyncLogsTable syncLogs = $SyncLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        usersLocal,
        syncState,
        kimaiProjects,
        appProjects,
        payoutDates,
        timesheets,
        syncLogs
      ];
}

typedef $$UsersLocalTableCreateCompanionBuilder = UsersLocalCompanion Function({
  required String id,
  Value<int?> kimaiUserId,
  Value<String?> displayName,
  Value<String?> email,
  Value<String> timezone,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UsersLocalTableUpdateCompanionBuilder = UsersLocalCompanion Function({
  Value<String> id,
  Value<int?> kimaiUserId,
  Value<String?> displayName,
  Value<String?> email,
  Value<String> timezone,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UsersLocalTableFilterComposer
    extends Composer<_$AppDatabase, $UsersLocalTable> {
  $$UsersLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kimaiUserId => $composableBuilder(
      column: $table.kimaiUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UsersLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersLocalTable> {
  $$UsersLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kimaiUserId => $composableBuilder(
      column: $table.kimaiUserId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersLocalTable> {
  $$UsersLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kimaiUserId => $composableBuilder(
      column: $table.kimaiUserId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersLocalTable,
    UsersLocalData,
    $$UsersLocalTableFilterComposer,
    $$UsersLocalTableOrderingComposer,
    $$UsersLocalTableAnnotationComposer,
    $$UsersLocalTableCreateCompanionBuilder,
    $$UsersLocalTableUpdateCompanionBuilder,
    (
      UsersLocalData,
      BaseReferences<_$AppDatabase, $UsersLocalTable, UsersLocalData>
    ),
    UsersLocalData,
    PrefetchHooks Function()> {
  $$UsersLocalTableTableManager(_$AppDatabase db, $UsersLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int?> kimaiUserId = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> timezone = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersLocalCompanion(
            id: id,
            kimaiUserId: kimaiUserId,
            displayName: displayName,
            email: email,
            timezone: timezone,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<int?> kimaiUserId = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> timezone = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersLocalCompanion.insert(
            id: id,
            kimaiUserId: kimaiUserId,
            displayName: displayName,
            email: email,
            timezone: timezone,
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

typedef $$UsersLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersLocalTable,
    UsersLocalData,
    $$UsersLocalTableFilterComposer,
    $$UsersLocalTableOrderingComposer,
    $$UsersLocalTableAnnotationComposer,
    $$UsersLocalTableCreateCompanionBuilder,
    $$UsersLocalTableUpdateCompanionBuilder,
    (
      UsersLocalData,
      BaseReferences<_$AppDatabase, $UsersLocalTable, UsersLocalData>
    ),
    UsersLocalData,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  Value<String?> value,
  Value<DateTime?> lastSyncedAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            key: key,
            value: value,
            lastSyncedAt: lastSyncedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            key: key,
            value: value,
            lastSyncedAt: lastSyncedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;
typedef $$KimaiProjectsTableCreateCompanionBuilder = KimaiProjectsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> customerName,
  Value<bool> visible,
  Value<bool> billable,
  Value<String?> color,
  Value<DateTime?> kimaiUpdatedAt,
  required DateTime syncedAt,
});
typedef $$KimaiProjectsTableUpdateCompanionBuilder = KimaiProjectsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> customerName,
  Value<bool> visible,
  Value<bool> billable,
  Value<String?> color,
  Value<DateTime?> kimaiUpdatedAt,
  Value<DateTime> syncedAt,
});

final class $$KimaiProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $KimaiProjectsTable, KimaiProject> {
  $$KimaiProjectsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AppProjectsTable, List<AppProject>>
      _appProjectsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.appProjects,
              aliasName: $_aliasNameGenerator(
                  db.kimaiProjects.id, db.appProjects.kimaiProjectId));

  $$AppProjectsTableProcessedTableManager get appProjectsRefs {
    final manager = $$AppProjectsTableTableManager($_db, $_db.appProjects)
        .filter((f) => f.kimaiProjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_appProjectsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TimesheetsTable, List<Timesheet>>
      _timesheetsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.timesheets,
              aliasName: $_aliasNameGenerator(
                  db.kimaiProjects.id, db.timesheets.kimaiProjectId));

  $$TimesheetsTableProcessedTableManager get timesheetsRefs {
    final manager = $$TimesheetsTableTableManager($_db, $_db.timesheets)
        .filter((f) => f.kimaiProjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_timesheetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$KimaiProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $KimaiProjectsTable> {
  $$KimaiProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get visible => $composableBuilder(
      column: $table.visible, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get billable => $composableBuilder(
      column: $table.billable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get kimaiUpdatedAt => $composableBuilder(
      column: $table.kimaiUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> appProjectsRefs(
      Expression<bool> Function($$AppProjectsTableFilterComposer f) f) {
    final $$AppProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.kimaiProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableFilterComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> timesheetsRefs(
      Expression<bool> Function($$TimesheetsTableFilterComposer f) f) {
    final $$TimesheetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timesheets,
        getReferencedColumn: (t) => t.kimaiProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimesheetsTableFilterComposer(
              $db: $db,
              $table: $db.timesheets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$KimaiProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $KimaiProjectsTable> {
  $$KimaiProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get visible => $composableBuilder(
      column: $table.visible, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get billable => $composableBuilder(
      column: $table.billable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get kimaiUpdatedAt => $composableBuilder(
      column: $table.kimaiUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$KimaiProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KimaiProjectsTable> {
  $$KimaiProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<bool> get visible =>
      $composableBuilder(column: $table.visible, builder: (column) => column);

  GeneratedColumn<bool> get billable =>
      $composableBuilder(column: $table.billable, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get kimaiUpdatedAt => $composableBuilder(
      column: $table.kimaiUpdatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  Expression<T> appProjectsRefs<T extends Object>(
      Expression<T> Function($$AppProjectsTableAnnotationComposer a) f) {
    final $$AppProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.kimaiProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> timesheetsRefs<T extends Object>(
      Expression<T> Function($$TimesheetsTableAnnotationComposer a) f) {
    final $$TimesheetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timesheets,
        getReferencedColumn: (t) => t.kimaiProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimesheetsTableAnnotationComposer(
              $db: $db,
              $table: $db.timesheets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$KimaiProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KimaiProjectsTable,
    KimaiProject,
    $$KimaiProjectsTableFilterComposer,
    $$KimaiProjectsTableOrderingComposer,
    $$KimaiProjectsTableAnnotationComposer,
    $$KimaiProjectsTableCreateCompanionBuilder,
    $$KimaiProjectsTableUpdateCompanionBuilder,
    (KimaiProject, $$KimaiProjectsTableReferences),
    KimaiProject,
    PrefetchHooks Function({bool appProjectsRefs, bool timesheetsRefs})> {
  $$KimaiProjectsTableTableManager(_$AppDatabase db, $KimaiProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KimaiProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KimaiProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KimaiProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<bool> visible = const Value.absent(),
            Value<bool> billable = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<DateTime?> kimaiUpdatedAt = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
          }) =>
              KimaiProjectsCompanion(
            id: id,
            name: name,
            customerName: customerName,
            visible: visible,
            billable: billable,
            color: color,
            kimaiUpdatedAt: kimaiUpdatedAt,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> customerName = const Value.absent(),
            Value<bool> visible = const Value.absent(),
            Value<bool> billable = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<DateTime?> kimaiUpdatedAt = const Value.absent(),
            required DateTime syncedAt,
          }) =>
              KimaiProjectsCompanion.insert(
            id: id,
            name: name,
            customerName: customerName,
            visible: visible,
            billable: billable,
            color: color,
            kimaiUpdatedAt: kimaiUpdatedAt,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$KimaiProjectsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {appProjectsRefs = false, timesheetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (appProjectsRefs) db.appProjects,
                if (timesheetsRefs) db.timesheets
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (appProjectsRefs)
                    await $_getPrefetchedData<KimaiProject, $KimaiProjectsTable,
                            AppProject>(
                        currentTable: table,
                        referencedTable: $$KimaiProjectsTableReferences
                            ._appProjectsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KimaiProjectsTableReferences(db, table, p0)
                                .appProjectsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.kimaiProjectId == item.id),
                        typedResults: items),
                  if (timesheetsRefs)
                    await $_getPrefetchedData<KimaiProject, $KimaiProjectsTable,
                            Timesheet>(
                        currentTable: table,
                        referencedTable: $$KimaiProjectsTableReferences
                            ._timesheetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KimaiProjectsTableReferences(db, table, p0)
                                .timesheetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.kimaiProjectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$KimaiProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KimaiProjectsTable,
    KimaiProject,
    $$KimaiProjectsTableFilterComposer,
    $$KimaiProjectsTableOrderingComposer,
    $$KimaiProjectsTableAnnotationComposer,
    $$KimaiProjectsTableCreateCompanionBuilder,
    $$KimaiProjectsTableUpdateCompanionBuilder,
    (KimaiProject, $$KimaiProjectsTableReferences),
    KimaiProject,
    PrefetchHooks Function({bool appProjectsRefs, bool timesheetsRefs})>;
typedef $$AppProjectsTableCreateCompanionBuilder = AppProjectsCompanion
    Function({
  required String id,
  Value<int?> kimaiProjectId,
  required String name,
  Value<String?> color,
  Value<bool> enabled,
  Value<double?> hourlyRate,
  Value<int?> hourlyRateMinor,
  Value<double?> weeklyGoalHours,
  Value<String> currency,
  Value<String> payoutRule,
  Value<bool> archived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AppProjectsTableUpdateCompanionBuilder = AppProjectsCompanion
    Function({
  Value<String> id,
  Value<int?> kimaiProjectId,
  Value<String> name,
  Value<String?> color,
  Value<bool> enabled,
  Value<double?> hourlyRate,
  Value<int?> hourlyRateMinor,
  Value<double?> weeklyGoalHours,
  Value<String> currency,
  Value<String> payoutRule,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$AppProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $AppProjectsTable, AppProject> {
  $$AppProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KimaiProjectsTable _kimaiProjectIdTable(_$AppDatabase db) =>
      db.kimaiProjects.createAlias($_aliasNameGenerator(
          db.appProjects.kimaiProjectId, db.kimaiProjects.id));

  $$KimaiProjectsTableProcessedTableManager? get kimaiProjectId {
    final $_column = $_itemColumn<int>('kimai_project_id');
    if ($_column == null) return null;
    final manager = $$KimaiProjectsTableTableManager($_db, $_db.kimaiProjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_kimaiProjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PayoutDatesTable, List<PayoutDate>>
      _payoutDatesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.payoutDates,
              aliasName: $_aliasNameGenerator(
                  db.appProjects.id, db.payoutDates.appProjectId));

  $$PayoutDatesTableProcessedTableManager get payoutDatesRefs {
    final manager = $$PayoutDatesTableTableManager($_db, $_db.payoutDates)
        .filter(
            (f) => f.appProjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_payoutDatesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TimesheetsTable, List<Timesheet>>
      _timesheetsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.timesheets,
              aliasName: $_aliasNameGenerator(
                  db.appProjects.id, db.timesheets.appProjectId));

  $$TimesheetsTableProcessedTableManager get timesheetsRefs {
    final manager = $$TimesheetsTableTableManager($_db, $_db.timesheets).filter(
        (f) => f.appProjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_timesheetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AppProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $AppProjectsTable> {
  $$AppProjectsTableFilterComposer({
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

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hourlyRate => $composableBuilder(
      column: $table.hourlyRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hourlyRateMinor => $composableBuilder(
      column: $table.hourlyRateMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weeklyGoalHours => $composableBuilder(
      column: $table.weeklyGoalHours,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payoutRule => $composableBuilder(
      column: $table.payoutRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$KimaiProjectsTableFilterComposer get kimaiProjectId {
    final $$KimaiProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.kimaiProjectId,
        referencedTable: $db.kimaiProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KimaiProjectsTableFilterComposer(
              $db: $db,
              $table: $db.kimaiProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> payoutDatesRefs(
      Expression<bool> Function($$PayoutDatesTableFilterComposer f) f) {
    final $$PayoutDatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payoutDates,
        getReferencedColumn: (t) => t.appProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayoutDatesTableFilterComposer(
              $db: $db,
              $table: $db.payoutDates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> timesheetsRefs(
      Expression<bool> Function($$TimesheetsTableFilterComposer f) f) {
    final $$TimesheetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timesheets,
        getReferencedColumn: (t) => t.appProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimesheetsTableFilterComposer(
              $db: $db,
              $table: $db.timesheets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AppProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppProjectsTable> {
  $$AppProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hourlyRate => $composableBuilder(
      column: $table.hourlyRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hourlyRateMinor => $composableBuilder(
      column: $table.hourlyRateMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weeklyGoalHours => $composableBuilder(
      column: $table.weeklyGoalHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payoutRule => $composableBuilder(
      column: $table.payoutRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$KimaiProjectsTableOrderingComposer get kimaiProjectId {
    final $$KimaiProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.kimaiProjectId,
        referencedTable: $db.kimaiProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KimaiProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.kimaiProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppProjectsTable> {
  $$AppProjectsTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<double> get hourlyRate => $composableBuilder(
      column: $table.hourlyRate, builder: (column) => column);

  GeneratedColumn<int> get hourlyRateMinor => $composableBuilder(
      column: $table.hourlyRateMinor, builder: (column) => column);

  GeneratedColumn<double> get weeklyGoalHours => $composableBuilder(
      column: $table.weeklyGoalHours, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get payoutRule => $composableBuilder(
      column: $table.payoutRule, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$KimaiProjectsTableAnnotationComposer get kimaiProjectId {
    final $$KimaiProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.kimaiProjectId,
        referencedTable: $db.kimaiProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KimaiProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.kimaiProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> payoutDatesRefs<T extends Object>(
      Expression<T> Function($$PayoutDatesTableAnnotationComposer a) f) {
    final $$PayoutDatesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payoutDates,
        getReferencedColumn: (t) => t.appProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PayoutDatesTableAnnotationComposer(
              $db: $db,
              $table: $db.payoutDates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> timesheetsRefs<T extends Object>(
      Expression<T> Function($$TimesheetsTableAnnotationComposer a) f) {
    final $$TimesheetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timesheets,
        getReferencedColumn: (t) => t.appProjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimesheetsTableAnnotationComposer(
              $db: $db,
              $table: $db.timesheets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AppProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppProjectsTable,
    AppProject,
    $$AppProjectsTableFilterComposer,
    $$AppProjectsTableOrderingComposer,
    $$AppProjectsTableAnnotationComposer,
    $$AppProjectsTableCreateCompanionBuilder,
    $$AppProjectsTableUpdateCompanionBuilder,
    (AppProject, $$AppProjectsTableReferences),
    AppProject,
    PrefetchHooks Function(
        {bool kimaiProjectId, bool payoutDatesRefs, bool timesheetsRefs})> {
  $$AppProjectsTableTableManager(_$AppDatabase db, $AppProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int?> kimaiProjectId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<double?> hourlyRate = const Value.absent(),
            Value<int?> hourlyRateMinor = const Value.absent(),
            Value<double?> weeklyGoalHours = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> payoutRule = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppProjectsCompanion(
            id: id,
            kimaiProjectId: kimaiProjectId,
            name: name,
            color: color,
            enabled: enabled,
            hourlyRate: hourlyRate,
            hourlyRateMinor: hourlyRateMinor,
            weeklyGoalHours: weeklyGoalHours,
            currency: currency,
            payoutRule: payoutRule,
            archived: archived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<int?> kimaiProjectId = const Value.absent(),
            required String name,
            Value<String?> color = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<double?> hourlyRate = const Value.absent(),
            Value<int?> hourlyRateMinor = const Value.absent(),
            Value<double?> weeklyGoalHours = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> payoutRule = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppProjectsCompanion.insert(
            id: id,
            kimaiProjectId: kimaiProjectId,
            name: name,
            color: color,
            enabled: enabled,
            hourlyRate: hourlyRate,
            hourlyRateMinor: hourlyRateMinor,
            weeklyGoalHours: weeklyGoalHours,
            currency: currency,
            payoutRule: payoutRule,
            archived: archived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AppProjectsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {kimaiProjectId = false,
              payoutDatesRefs = false,
              timesheetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (payoutDatesRefs) db.payoutDates,
                if (timesheetsRefs) db.timesheets
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
                if (kimaiProjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.kimaiProjectId,
                    referencedTable:
                        $$AppProjectsTableReferences._kimaiProjectIdTable(db),
                    referencedColumn: $$AppProjectsTableReferences
                        ._kimaiProjectIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (payoutDatesRefs)
                    await $_getPrefetchedData<AppProject, $AppProjectsTable,
                            PayoutDate>(
                        currentTable: table,
                        referencedTable: $$AppProjectsTableReferences
                            ._payoutDatesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AppProjectsTableReferences(db, table, p0)
                                .payoutDatesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.appProjectId == item.id),
                        typedResults: items),
                  if (timesheetsRefs)
                    await $_getPrefetchedData<AppProject, $AppProjectsTable,
                            Timesheet>(
                        currentTable: table,
                        referencedTable: $$AppProjectsTableReferences
                            ._timesheetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AppProjectsTableReferences(db, table, p0)
                                .timesheetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.appProjectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AppProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppProjectsTable,
    AppProject,
    $$AppProjectsTableFilterComposer,
    $$AppProjectsTableOrderingComposer,
    $$AppProjectsTableAnnotationComposer,
    $$AppProjectsTableCreateCompanionBuilder,
    $$AppProjectsTableUpdateCompanionBuilder,
    (AppProject, $$AppProjectsTableReferences),
    AppProject,
    PrefetchHooks Function(
        {bool kimaiProjectId, bool payoutDatesRefs, bool timesheetsRefs})>;
typedef $$PayoutDatesTableCreateCompanionBuilder = PayoutDatesCompanion
    Function({
  required String id,
  required String appProjectId,
  required DateTime payoutDate,
  Value<double?> expectedAmount,
  Value<String> currency,
  Value<String?> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PayoutDatesTableUpdateCompanionBuilder = PayoutDatesCompanion
    Function({
  Value<String> id,
  Value<String> appProjectId,
  Value<DateTime> payoutDate,
  Value<double?> expectedAmount,
  Value<String> currency,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$PayoutDatesTableReferences
    extends BaseReferences<_$AppDatabase, $PayoutDatesTable, PayoutDate> {
  $$PayoutDatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AppProjectsTable _appProjectIdTable(_$AppDatabase db) =>
      db.appProjects.createAlias(
          $_aliasNameGenerator(db.payoutDates.appProjectId, db.appProjects.id));

  $$AppProjectsTableProcessedTableManager get appProjectId {
    final $_column = $_itemColumn<String>('app_project_id')!;

    final manager = $$AppProjectsTableTableManager($_db, $_db.appProjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_appProjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PayoutDatesTableFilterComposer
    extends Composer<_$AppDatabase, $PayoutDatesTable> {
  $$PayoutDatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get payoutDate => $composableBuilder(
      column: $table.payoutDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedAmount => $composableBuilder(
      column: $table.expectedAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$AppProjectsTableFilterComposer get appProjectId {
    final $$AppProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.appProjectId,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableFilterComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PayoutDatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PayoutDatesTable> {
  $$PayoutDatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get payoutDate => $composableBuilder(
      column: $table.payoutDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get expectedAmount => $composableBuilder(
      column: $table.expectedAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$AppProjectsTableOrderingComposer get appProjectId {
    final $$AppProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.appProjectId,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PayoutDatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayoutDatesTable> {
  $$PayoutDatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get payoutDate => $composableBuilder(
      column: $table.payoutDate, builder: (column) => column);

  GeneratedColumn<double> get expectedAmount => $composableBuilder(
      column: $table.expectedAmount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AppProjectsTableAnnotationComposer get appProjectId {
    final $$AppProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.appProjectId,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PayoutDatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PayoutDatesTable,
    PayoutDate,
    $$PayoutDatesTableFilterComposer,
    $$PayoutDatesTableOrderingComposer,
    $$PayoutDatesTableAnnotationComposer,
    $$PayoutDatesTableCreateCompanionBuilder,
    $$PayoutDatesTableUpdateCompanionBuilder,
    (PayoutDate, $$PayoutDatesTableReferences),
    PayoutDate,
    PrefetchHooks Function({bool appProjectId})> {
  $$PayoutDatesTableTableManager(_$AppDatabase db, $PayoutDatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayoutDatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayoutDatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayoutDatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> appProjectId = const Value.absent(),
            Value<DateTime> payoutDate = const Value.absent(),
            Value<double?> expectedAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PayoutDatesCompanion(
            id: id,
            appProjectId: appProjectId,
            payoutDate: payoutDate,
            expectedAmount: expectedAmount,
            currency: currency,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String appProjectId,
            required DateTime payoutDate,
            Value<double?> expectedAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PayoutDatesCompanion.insert(
            id: id,
            appProjectId: appProjectId,
            payoutDate: payoutDate,
            expectedAmount: expectedAmount,
            currency: currency,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PayoutDatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({appProjectId = false}) {
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
                if (appProjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.appProjectId,
                    referencedTable:
                        $$PayoutDatesTableReferences._appProjectIdTable(db),
                    referencedColumn:
                        $$PayoutDatesTableReferences._appProjectIdTable(db).id,
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

typedef $$PayoutDatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PayoutDatesTable,
    PayoutDate,
    $$PayoutDatesTableFilterComposer,
    $$PayoutDatesTableOrderingComposer,
    $$PayoutDatesTableAnnotationComposer,
    $$PayoutDatesTableCreateCompanionBuilder,
    $$PayoutDatesTableUpdateCompanionBuilder,
    (PayoutDate, $$PayoutDatesTableReferences),
    PayoutDate,
    PrefetchHooks Function({bool appProjectId})>;
typedef $$TimesheetsTableCreateCompanionBuilder = TimesheetsCompanion Function({
  Value<int> id,
  Value<int?> kimaiProjectId,
  Value<String?> appProjectId,
  Value<String?> activityName,
  Value<String?> description,
  required DateTime beginAt,
  Value<DateTime?> endAt,
  Value<int> durationSeconds,
  Value<double?> rate,
  Value<int?> amountMinor,
  Value<String?> currency,
  Value<bool> exported,
  Value<String?> tags,
  Value<DateTime?> kimaiUpdatedAt,
  required DateTime syncedAt,
});
typedef $$TimesheetsTableUpdateCompanionBuilder = TimesheetsCompanion Function({
  Value<int> id,
  Value<int?> kimaiProjectId,
  Value<String?> appProjectId,
  Value<String?> activityName,
  Value<String?> description,
  Value<DateTime> beginAt,
  Value<DateTime?> endAt,
  Value<int> durationSeconds,
  Value<double?> rate,
  Value<int?> amountMinor,
  Value<String?> currency,
  Value<bool> exported,
  Value<String?> tags,
  Value<DateTime?> kimaiUpdatedAt,
  Value<DateTime> syncedAt,
});

final class $$TimesheetsTableReferences
    extends BaseReferences<_$AppDatabase, $TimesheetsTable, Timesheet> {
  $$TimesheetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KimaiProjectsTable _kimaiProjectIdTable(_$AppDatabase db) =>
      db.kimaiProjects.createAlias($_aliasNameGenerator(
          db.timesheets.kimaiProjectId, db.kimaiProjects.id));

  $$KimaiProjectsTableProcessedTableManager? get kimaiProjectId {
    final $_column = $_itemColumn<int>('kimai_project_id');
    if ($_column == null) return null;
    final manager = $$KimaiProjectsTableTableManager($_db, $_db.kimaiProjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_kimaiProjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AppProjectsTable _appProjectIdTable(_$AppDatabase db) =>
      db.appProjects.createAlias(
          $_aliasNameGenerator(db.timesheets.appProjectId, db.appProjects.id));

  $$AppProjectsTableProcessedTableManager? get appProjectId {
    final $_column = $_itemColumn<String>('app_project_id');
    if ($_column == null) return null;
    final manager = $$AppProjectsTableTableManager($_db, $_db.appProjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_appProjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TimesheetsTableFilterComposer
    extends Composer<_$AppDatabase, $TimesheetsTable> {
  $$TimesheetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityName => $composableBuilder(
      column: $table.activityName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get beginAt => $composableBuilder(
      column: $table.beginAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endAt => $composableBuilder(
      column: $table.endAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get exported => $composableBuilder(
      column: $table.exported, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get kimaiUpdatedAt => $composableBuilder(
      column: $table.kimaiUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$KimaiProjectsTableFilterComposer get kimaiProjectId {
    final $$KimaiProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.kimaiProjectId,
        referencedTable: $db.kimaiProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KimaiProjectsTableFilterComposer(
              $db: $db,
              $table: $db.kimaiProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AppProjectsTableFilterComposer get appProjectId {
    final $$AppProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.appProjectId,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableFilterComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimesheetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimesheetsTable> {
  $$TimesheetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityName => $composableBuilder(
      column: $table.activityName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get beginAt => $composableBuilder(
      column: $table.beginAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
      column: $table.endAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get exported => $composableBuilder(
      column: $table.exported, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get kimaiUpdatedAt => $composableBuilder(
      column: $table.kimaiUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$KimaiProjectsTableOrderingComposer get kimaiProjectId {
    final $$KimaiProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.kimaiProjectId,
        referencedTable: $db.kimaiProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KimaiProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.kimaiProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AppProjectsTableOrderingComposer get appProjectId {
    final $$AppProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.appProjectId,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimesheetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimesheetsTable> {
  $$TimesheetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityName => $composableBuilder(
      column: $table.activityName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get beginAt =>
      $composableBuilder(column: $table.beginAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get exported =>
      $composableBuilder(column: $table.exported, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get kimaiUpdatedAt => $composableBuilder(
      column: $table.kimaiUpdatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$KimaiProjectsTableAnnotationComposer get kimaiProjectId {
    final $$KimaiProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.kimaiProjectId,
        referencedTable: $db.kimaiProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KimaiProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.kimaiProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AppProjectsTableAnnotationComposer get appProjectId {
    final $$AppProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.appProjectId,
        referencedTable: $db.appProjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.appProjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimesheetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimesheetsTable,
    Timesheet,
    $$TimesheetsTableFilterComposer,
    $$TimesheetsTableOrderingComposer,
    $$TimesheetsTableAnnotationComposer,
    $$TimesheetsTableCreateCompanionBuilder,
    $$TimesheetsTableUpdateCompanionBuilder,
    (Timesheet, $$TimesheetsTableReferences),
    Timesheet,
    PrefetchHooks Function({bool kimaiProjectId, bool appProjectId})> {
  $$TimesheetsTableTableManager(_$AppDatabase db, $TimesheetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimesheetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimesheetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimesheetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> kimaiProjectId = const Value.absent(),
            Value<String?> appProjectId = const Value.absent(),
            Value<String?> activityName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> beginAt = const Value.absent(),
            Value<DateTime?> endAt = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double?> rate = const Value.absent(),
            Value<int?> amountMinor = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<bool> exported = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<DateTime?> kimaiUpdatedAt = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
          }) =>
              TimesheetsCompanion(
            id: id,
            kimaiProjectId: kimaiProjectId,
            appProjectId: appProjectId,
            activityName: activityName,
            description: description,
            beginAt: beginAt,
            endAt: endAt,
            durationSeconds: durationSeconds,
            rate: rate,
            amountMinor: amountMinor,
            currency: currency,
            exported: exported,
            tags: tags,
            kimaiUpdatedAt: kimaiUpdatedAt,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> kimaiProjectId = const Value.absent(),
            Value<String?> appProjectId = const Value.absent(),
            Value<String?> activityName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            required DateTime beginAt,
            Value<DateTime?> endAt = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double?> rate = const Value.absent(),
            Value<int?> amountMinor = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<bool> exported = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<DateTime?> kimaiUpdatedAt = const Value.absent(),
            required DateTime syncedAt,
          }) =>
              TimesheetsCompanion.insert(
            id: id,
            kimaiProjectId: kimaiProjectId,
            appProjectId: appProjectId,
            activityName: activityName,
            description: description,
            beginAt: beginAt,
            endAt: endAt,
            durationSeconds: durationSeconds,
            rate: rate,
            amountMinor: amountMinor,
            currency: currency,
            exported: exported,
            tags: tags,
            kimaiUpdatedAt: kimaiUpdatedAt,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TimesheetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {kimaiProjectId = false, appProjectId = false}) {
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
                if (kimaiProjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.kimaiProjectId,
                    referencedTable:
                        $$TimesheetsTableReferences._kimaiProjectIdTable(db),
                    referencedColumn:
                        $$TimesheetsTableReferences._kimaiProjectIdTable(db).id,
                  ) as T;
                }
                if (appProjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.appProjectId,
                    referencedTable:
                        $$TimesheetsTableReferences._appProjectIdTable(db),
                    referencedColumn:
                        $$TimesheetsTableReferences._appProjectIdTable(db).id,
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

typedef $$TimesheetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimesheetsTable,
    Timesheet,
    $$TimesheetsTableFilterComposer,
    $$TimesheetsTableOrderingComposer,
    $$TimesheetsTableAnnotationComposer,
    $$TimesheetsTableCreateCompanionBuilder,
    $$TimesheetsTableUpdateCompanionBuilder,
    (Timesheet, $$TimesheetsTableReferences),
    Timesheet,
    PrefetchHooks Function({bool kimaiProjectId, bool appProjectId})>;
typedef $$SyncLogsTableCreateCompanionBuilder = SyncLogsCompanion Function({
  required String id,
  required String operation,
  required String status,
  Value<String?> message,
  Value<String?> error,
  Value<String?> debug,
  required DateTime startedAt,
  Value<DateTime?> finishedAt,
  Value<int> rowid,
});
typedef $$SyncLogsTableUpdateCompanionBuilder = SyncLogsCompanion Function({
  Value<String> id,
  Value<String> operation,
  Value<String> status,
  Value<String?> message,
  Value<String?> error,
  Value<String?> debug,
  Value<DateTime> startedAt,
  Value<DateTime?> finishedAt,
  Value<int> rowid,
});

class $$SyncLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get debug => $composableBuilder(
      column: $table.debug, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get debug => $composableBuilder(
      column: $table.debug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get debug =>
      $composableBuilder(column: $table.debug, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => column);
}

class $$SyncLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncLogsTable,
    SyncLog,
    $$SyncLogsTableFilterComposer,
    $$SyncLogsTableOrderingComposer,
    $$SyncLogsTableAnnotationComposer,
    $$SyncLogsTableCreateCompanionBuilder,
    $$SyncLogsTableUpdateCompanionBuilder,
    (SyncLog, BaseReferences<_$AppDatabase, $SyncLogsTable, SyncLog>),
    SyncLog,
    PrefetchHooks Function()> {
  $$SyncLogsTableTableManager(_$AppDatabase db, $SyncLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> message = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<String?> debug = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> finishedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncLogsCompanion(
            id: id,
            operation: operation,
            status: status,
            message: message,
            error: error,
            debug: debug,
            startedAt: startedAt,
            finishedAt: finishedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String operation,
            required String status,
            Value<String?> message = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<String?> debug = const Value.absent(),
            required DateTime startedAt,
            Value<DateTime?> finishedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncLogsCompanion.insert(
            id: id,
            operation: operation,
            status: status,
            message: message,
            error: error,
            debug: debug,
            startedAt: startedAt,
            finishedAt: finishedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncLogsTable,
    SyncLog,
    $$SyncLogsTableFilterComposer,
    $$SyncLogsTableOrderingComposer,
    $$SyncLogsTableAnnotationComposer,
    $$SyncLogsTableCreateCompanionBuilder,
    $$SyncLogsTableUpdateCompanionBuilder,
    (SyncLog, BaseReferences<_$AppDatabase, $SyncLogsTable, SyncLog>),
    SyncLog,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersLocalTableTableManager get usersLocal =>
      $$UsersLocalTableTableManager(_db, _db.usersLocal);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$KimaiProjectsTableTableManager get kimaiProjects =>
      $$KimaiProjectsTableTableManager(_db, _db.kimaiProjects);
  $$AppProjectsTableTableManager get appProjects =>
      $$AppProjectsTableTableManager(_db, _db.appProjects);
  $$PayoutDatesTableTableManager get payoutDates =>
      $$PayoutDatesTableTableManager(_db, _db.payoutDates);
  $$TimesheetsTableTableManager get timesheets =>
      $$TimesheetsTableTableManager(_db, _db.timesheets);
  $$SyncLogsTableTableManager get syncLogs =>
      $$SyncLogsTableTableManager(_db, _db.syncLogs);
}
