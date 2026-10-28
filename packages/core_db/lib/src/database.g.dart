// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SmsOutboxTable extends SmsOutbox
    with TableInfo<$SmsOutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientMeta = const VerificationMeta(
    'recipient',
  );
  @override
  late final GeneratedColumn<String> recipient = GeneratedColumn<String>(
    'recipient',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OutboxKind>($SmsOutboxTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<SmsStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SmsStatus>($SmsOutboxTable.$converterstatus);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _guardStatusMeta = const VerificationMeta(
    'guardStatus',
  );
  @override
  late final GeneratedColumn<String> guardStatus = GeneratedColumn<String>(
    'guard_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guardAttemptsMeta = const VerificationMeta(
    'guardAttempts',
  );
  @override
  late final GeneratedColumn<int> guardAttempts = GeneratedColumn<int>(
    'guard_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _guardUpdatedAtMeta = const VerificationMeta(
    'guardUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> guardUpdatedAt =
      GeneratedColumn<DateTime>(
        'guard_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipient,
    body,
    kind,
    status,
    attempts,
    createdAt,
    nextAttemptAt,
    lastAttemptAt,
    guardStatus,
    guardAttempts,
    guardUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipient')) {
      context.handle(
        _recipientMeta,
        recipient.isAcceptableOrUnknown(data['recipient']!, _recipientMeta),
      );
    } else if (isInserting) {
      context.missing(_recipientMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('guard_status')) {
      context.handle(
        _guardStatusMeta,
        guardStatus.isAcceptableOrUnknown(
          data['guard_status']!,
          _guardStatusMeta,
        ),
      );
    }
    if (data.containsKey('guard_attempts')) {
      context.handle(
        _guardAttemptsMeta,
        guardAttempts.isAcceptableOrUnknown(
          data['guard_attempts']!,
          _guardAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('guard_updated_at')) {
      context.handle(
        _guardUpdatedAtMeta,
        guardUpdatedAt.isAcceptableOrUnknown(
          data['guard_updated_at']!,
          _guardUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      kind: $SmsOutboxTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      status: $SmsOutboxTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      guardStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guard_status'],
      ),
      guardAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guard_attempts'],
      )!,
      guardUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}guard_updated_at'],
      ),
    );
  }

  @override
  $SmsOutboxTable createAlias(String alias) {
    return $SmsOutboxTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxKind, String, String> $converterkind =
      const EnumNameConverter<OutboxKind>(OutboxKind.values);
  static JsonTypeConverter2<SmsStatus, String, String> $converterstatus =
      const EnumNameConverter<SmsStatus>(SmsStatus.values);
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  /// Unique id (one per contact per SOS).
  final String id;

  /// Destination number.
  final String recipient;

  /// Message text.
  final String body;

  /// Purpose.
  final OutboxKind kind;

  /// Life-cycle status.
  final SmsStatus status;

  /// Times handed to the radio.
  final int attempts;

  /// Creation time.
  final DateTime createdAt;

  /// Earliest next attempt.
  final DateTime nextAttemptAt;

  /// Last attempt, if any.
  final DateTime? lastAttemptAt;

  /// Written ONLY by the native safety guard: its view of the message
  /// (sending, sent, delivered, failed), or null if it never touched it.
  final String? guardStatus;

  /// Written ONLY by the native safety guard: its send attempts.
  final int guardAttempts;

  /// Written ONLY by the native safety guard: when it last updated the row.
  final DateTime? guardUpdatedAt;
  const OutboxRow({
    required this.id,
    required this.recipient,
    required this.body,
    required this.kind,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.nextAttemptAt,
    this.lastAttemptAt,
    this.guardStatus,
    required this.guardAttempts,
    this.guardUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipient'] = Variable<String>(recipient);
    map['body'] = Variable<String>(body);
    {
      map['kind'] = Variable<String>(
        $SmsOutboxTable.$converterkind.toSql(kind),
      );
    }
    {
      map['status'] = Variable<String>(
        $SmsOutboxTable.$converterstatus.toSql(status),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || guardStatus != null) {
      map['guard_status'] = Variable<String>(guardStatus);
    }
    map['guard_attempts'] = Variable<int>(guardAttempts);
    if (!nullToAbsent || guardUpdatedAt != null) {
      map['guard_updated_at'] = Variable<DateTime>(guardUpdatedAt);
    }
    return map;
  }

  SmsOutboxCompanion toCompanion(bool nullToAbsent) {
    return SmsOutboxCompanion(
      id: Value(id),
      recipient: Value(recipient),
      body: Value(body),
      kind: Value(kind),
      status: Value(status),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      nextAttemptAt: Value(nextAttemptAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      guardStatus: guardStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(guardStatus),
      guardAttempts: Value(guardAttempts),
      guardUpdatedAt: guardUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(guardUpdatedAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<String>(json['id']),
      recipient: serializer.fromJson<String>(json['recipient']),
      body: serializer.fromJson<String>(json['body']),
      kind: $SmsOutboxTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      status: $SmsOutboxTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      guardStatus: serializer.fromJson<String?>(json['guardStatus']),
      guardAttempts: serializer.fromJson<int>(json['guardAttempts']),
      guardUpdatedAt: serializer.fromJson<DateTime?>(json['guardUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipient': serializer.toJson<String>(recipient),
      'body': serializer.toJson<String>(body),
      'kind': serializer.toJson<String>(
        $SmsOutboxTable.$converterkind.toJson(kind),
      ),
      'status': serializer.toJson<String>(
        $SmsOutboxTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'guardStatus': serializer.toJson<String?>(guardStatus),
      'guardAttempts': serializer.toJson<int>(guardAttempts),
      'guardUpdatedAt': serializer.toJson<DateTime?>(guardUpdatedAt),
    };
  }

  OutboxRow copyWith({
    String? id,
    String? recipient,
    String? body,
    OutboxKind? kind,
    SmsStatus? status,
    int? attempts,
    DateTime? createdAt,
    DateTime? nextAttemptAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> guardStatus = const Value.absent(),
    int? guardAttempts,
    Value<DateTime?> guardUpdatedAt = const Value.absent(),
  }) => OutboxRow(
    id: id ?? this.id,
    recipient: recipient ?? this.recipient,
    body: body ?? this.body,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    guardStatus: guardStatus.present ? guardStatus.value : this.guardStatus,
    guardAttempts: guardAttempts ?? this.guardAttempts,
    guardUpdatedAt: guardUpdatedAt.present
        ? guardUpdatedAt.value
        : this.guardUpdatedAt,
  );
  OutboxRow copyWithCompanion(SmsOutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      recipient: data.recipient.present ? data.recipient.value : this.recipient,
      body: data.body.present ? data.body.value : this.body,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      guardStatus: data.guardStatus.present
          ? data.guardStatus.value
          : this.guardStatus,
      guardAttempts: data.guardAttempts.present
          ? data.guardAttempts.value
          : this.guardAttempts,
      guardUpdatedAt: data.guardUpdatedAt.present
          ? data.guardUpdatedAt.value
          : this.guardUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('recipient: $recipient, ')
          ..write('body: $body, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('guardStatus: $guardStatus, ')
          ..write('guardAttempts: $guardAttempts, ')
          ..write('guardUpdatedAt: $guardUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipient,
    body,
    kind,
    status,
    attempts,
    createdAt,
    nextAttemptAt,
    lastAttemptAt,
    guardStatus,
    guardAttempts,
    guardUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.recipient == this.recipient &&
          other.body == this.body &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.guardStatus == this.guardStatus &&
          other.guardAttempts == this.guardAttempts &&
          other.guardUpdatedAt == this.guardUpdatedAt);
}

class SmsOutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> id;
  final Value<String> recipient;
  final Value<String> body;
  final Value<OutboxKind> kind;
  final Value<SmsStatus> status;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> guardStatus;
  final Value<int> guardAttempts;
  final Value<DateTime?> guardUpdatedAt;
  final Value<int> rowid;
  const SmsOutboxCompanion({
    this.id = const Value.absent(),
    this.recipient = const Value.absent(),
    this.body = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.guardStatus = const Value.absent(),
    this.guardAttempts = const Value.absent(),
    this.guardUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsOutboxCompanion.insert({
    required String id,
    required String recipient,
    required String body,
    required OutboxKind kind,
    required SmsStatus status,
    required int attempts,
    required DateTime createdAt,
    required DateTime nextAttemptAt,
    this.lastAttemptAt = const Value.absent(),
    this.guardStatus = const Value.absent(),
    this.guardAttempts = const Value.absent(),
    this.guardUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipient = Value(recipient),
       body = Value(body),
       kind = Value(kind),
       status = Value(status),
       attempts = Value(attempts),
       createdAt = Value(createdAt),
       nextAttemptAt = Value(nextAttemptAt);
  static Insertable<OutboxRow> custom({
    Expression<String>? id,
    Expression<String>? recipient,
    Expression<String>? body,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? guardStatus,
    Expression<int>? guardAttempts,
    Expression<DateTime>? guardUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipient != null) 'recipient': recipient,
      if (body != null) 'body': body,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (guardStatus != null) 'guard_status': guardStatus,
      if (guardAttempts != null) 'guard_attempts': guardAttempts,
      if (guardUpdatedAt != null) 'guard_updated_at': guardUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? recipient,
    Value<String>? body,
    Value<OutboxKind>? kind,
    Value<SmsStatus>? status,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? guardStatus,
    Value<int>? guardAttempts,
    Value<DateTime?>? guardUpdatedAt,
    Value<int>? rowid,
  }) {
    return SmsOutboxCompanion(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      body: body ?? this.body,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      guardStatus: guardStatus ?? this.guardStatus,
      guardAttempts: guardAttempts ?? this.guardAttempts,
      guardUpdatedAt: guardUpdatedAt ?? this.guardUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipient.present) {
      map['recipient'] = Variable<String>(recipient.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SmsOutboxTable.$converterkind.toSql(kind.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SmsOutboxTable.$converterstatus.toSql(status.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (guardStatus.present) {
      map['guard_status'] = Variable<String>(guardStatus.value);
    }
    if (guardAttempts.present) {
      map['guard_attempts'] = Variable<int>(guardAttempts.value);
    }
    if (guardUpdatedAt.present) {
      map['guard_updated_at'] = Variable<DateTime>(guardUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsOutboxCompanion(')
          ..write('id: $id, ')
          ..write('recipient: $recipient, ')
          ..write('body: $body, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('guardStatus: $guardStatus, ')
          ..write('guardAttempts: $guardAttempts, ')
          ..write('guardUpdatedAt: $guardUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StateSnapshotsTable extends StateSnapshots
    with TableInfo<$StateSnapshotsTable, SnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StateSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, takenAt, version, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'state_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $StateSnapshotsTable createAlias(String alias) {
    return $StateSnapshotsTable(attachedDatabase, alias);
  }
}

class SnapshotRow extends DataClass implements Insertable<SnapshotRow> {
  /// Auto id.
  final int id;

  /// When the snapshot was taken.
  final DateTime takenAt;

  /// Snapshot format version.
  final int version;

  /// The snapshot as JSON.
  final String json;
  const SnapshotRow({
    required this.id,
    required this.takenAt,
    required this.version,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['version'] = Variable<int>(version);
    map['json'] = Variable<String>(json);
    return map;
  }

  StateSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return StateSnapshotsCompanion(
      id: Value(id),
      takenAt: Value(takenAt),
      version: Value(version),
      json: Value(json),
    );
  }

  factory SnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotRow(
      id: serializer.fromJson<int>(json['id']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      version: serializer.fromJson<int>(json['version']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'version': serializer.toJson<int>(version),
      'json': serializer.toJson<String>(json),
    };
  }

  SnapshotRow copyWith({
    int? id,
    DateTime? takenAt,
    int? version,
    String? json,
  }) => SnapshotRow(
    id: id ?? this.id,
    takenAt: takenAt ?? this.takenAt,
    version: version ?? this.version,
    json: json ?? this.json,
  );
  SnapshotRow copyWithCompanion(StateSnapshotsCompanion data) {
    return SnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      version: data.version.present ? data.version.value : this.version,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRow(')
          ..write('id: $id, ')
          ..write('takenAt: $takenAt, ')
          ..write('version: $version, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, takenAt, version, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotRow &&
          other.id == this.id &&
          other.takenAt == this.takenAt &&
          other.version == this.version &&
          other.json == this.json);
}

class StateSnapshotsCompanion extends UpdateCompanion<SnapshotRow> {
  final Value<int> id;
  final Value<DateTime> takenAt;
  final Value<int> version;
  final Value<String> json;
  const StateSnapshotsCompanion({
    this.id = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.version = const Value.absent(),
    this.json = const Value.absent(),
  });
  StateSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime takenAt,
    required int version,
    required String json,
  }) : takenAt = Value(takenAt),
       version = Value(version),
       json = Value(json);
  static Insertable<SnapshotRow> custom({
    Expression<int>? id,
    Expression<DateTime>? takenAt,
    Expression<int>? version,
    Expression<String>? json,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (takenAt != null) 'taken_at': takenAt,
      if (version != null) 'version': version,
      if (json != null) 'json': json,
    });
  }

  StateSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? takenAt,
    Value<int>? version,
    Value<String>? json,
  }) {
    return StateSnapshotsCompanion(
      id: id ?? this.id,
      takenAt: takenAt ?? this.takenAt,
      version: version ?? this.version,
      json: json ?? this.json,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StateSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('takenAt: $takenAt, ')
          ..write('version: $version, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }
}

class $EventLogTable extends EventLog with TableInfo<$EventLogTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, type, detail];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    } else if (isInserting) {
      context.missing(_detailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
    );
  }

  @override
  $EventLogTable createAlias(String alias) {
    return $EventLogTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  /// Auto id.
  final int id;

  /// When it happened.
  final DateTime at;

  /// Event type name.
  final String type;

  /// Short detail.
  final String detail;
  const EventRow({
    required this.id,
    required this.at,
    required this.type,
    required this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['type'] = Variable<String>(type);
    map['detail'] = Variable<String>(detail);
    return map;
  }

  EventLogCompanion toCompanion(bool nullToAbsent) {
    return EventLogCompanion(
      id: Value(id),
      at: Value(at),
      type: Value(type),
      detail: Value(detail),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      type: serializer.fromJson<String>(json['type']),
      detail: serializer.fromJson<String>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'type': serializer.toJson<String>(type),
      'detail': serializer.toJson<String>(detail),
    };
  }

  EventRow copyWith({int? id, DateTime? at, String? type, String? detail}) =>
      EventRow(
        id: id ?? this.id,
        at: at ?? this.at,
        type: type ?? this.type,
        detail: detail ?? this.detail,
      );
  EventRow copyWithCompanion(EventLogCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      type: data.type.present ? data.type.value : this.type,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('type: $type, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, type, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.type == this.type &&
          other.detail == this.detail);
}

class EventLogCompanion extends UpdateCompanion<EventRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> type;
  final Value<String> detail;
  const EventLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.type = const Value.absent(),
    this.detail = const Value.absent(),
  });
  EventLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String type,
    required String detail,
  }) : at = Value(at),
       type = Value(type),
       detail = Value(detail);
  static Insertable<EventRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? type,
    Expression<String>? detail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (type != null) 'type': type,
      if (detail != null) 'detail': detail,
    });
  }

  EventLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? type,
    Value<String>? detail,
  }) {
    return EventLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      type: type ?? this.type,
      detail: detail ?? this.detail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('type: $type, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, TripRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, startedAt, endedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class TripRow extends DataClass implements Insertable<TripRow> {
  /// Auto id.
  final int id;

  /// Name.
  final String name;

  /// Start.
  final DateTime startedAt;

  /// End, null while the trek is running.
  final DateTime? endedAt;
  const TripRow({
    required this.id,
    required this.name,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      name: Value(name),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory TripRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  TripRow copyWith({
    int? id,
    String? name,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => TripRow(
    id: id ?? this.id,
    name: name ?? this.name,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  TripRow copyWithCompanion(TripsCompanion data) {
    return TripRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, startedAt, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class TripsCompanion extends UpdateCompanion<TripRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
  }) : name = Value(name),
       startedAt = Value(startedAt);
  static Insertable<TripRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id)',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    at,
    latitude,
    longitude,
    accuracyM,
    altitudeM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      )!,
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      ),
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPointRow extends DataClass implements Insertable<TrackPointRow> {
  /// Auto id.
  final int id;

  /// Owning trip.
  final int tripId;

  /// GPS time.
  final DateTime at;

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// Accuracy radius in metres.
  final double accuracyM;

  /// Altitude in metres, if known.
  final double? altitudeM;
  const TrackPointRow({
    required this.id,
    required this.tripId,
    required this.at,
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    this.altitudeM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['at'] = Variable<DateTime>(at);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['accuracy_m'] = Variable<double>(accuracyM);
    if (!nullToAbsent || altitudeM != null) {
      map['altitude_m'] = Variable<double>(altitudeM);
    }
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      at: Value(at),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracyM: Value(accuracyM),
      altitudeM: altitudeM == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeM),
    );
  }

  factory TrackPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPointRow(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      at: serializer.fromJson<DateTime>(json['at']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracyM: serializer.fromJson<double>(json['accuracyM']),
      altitudeM: serializer.fromJson<double?>(json['altitudeM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'at': serializer.toJson<DateTime>(at),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracyM': serializer.toJson<double>(accuracyM),
      'altitudeM': serializer.toJson<double?>(altitudeM),
    };
  }

  TrackPointRow copyWith({
    int? id,
    int? tripId,
    DateTime? at,
    double? latitude,
    double? longitude,
    double? accuracyM,
    Value<double?> altitudeM = const Value.absent(),
  }) => TrackPointRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    at: at ?? this.at,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracyM: accuracyM ?? this.accuracyM,
    altitudeM: altitudeM.present ? altitudeM.value : this.altitudeM,
  );
  TrackPointRow copyWithCompanion(TrackPointsCompanion data) {
    return TrackPointRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      at: data.at.present ? data.at.value : this.at,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('at: $at, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tripId, at, latitude, longitude, accuracyM, altitudeM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPointRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.at == this.at &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracyM == this.accuracyM &&
          other.altitudeM == this.altitudeM);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPointRow> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<DateTime> at;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracyM;
  final Value<double?> altitudeM;
  const TrackPointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.at = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.altitudeM = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required DateTime at,
    required double latitude,
    required double longitude,
    required double accuracyM,
    this.altitudeM = const Value.absent(),
  }) : tripId = Value(tripId),
       at = Value(at),
       latitude = Value(latitude),
       longitude = Value(longitude),
       accuracyM = Value(accuracyM);
  static Insertable<TrackPointRow> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<DateTime>? at,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracyM,
    Expression<double>? altitudeM,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (at != null) 'at': at,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (altitudeM != null) 'altitude_m': altitudeM,
    });
  }

  TrackPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? tripId,
    Value<DateTime>? at,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? accuracyM,
    Value<double?>? altitudeM,
  }) {
    return TrackPointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      at: at ?? this.at,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyM: accuracyM ?? this.accuracyM,
      altitudeM: altitudeM ?? this.altitudeM,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('at: $at, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
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
    Insertable<SettingRow> instance, {
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
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
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

class SettingRow extends DataClass implements Insertable<SettingRow> {
  /// Key.
  final String key;

  /// Value.
  final String value;
  const SettingRow({required this.key, required this.value});
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

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
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

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
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
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
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
  static Insertable<SettingRow> custom({
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

class $PinsTable extends Pins with TableInfo<$PinsTable, PinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, lat, lon, accuracyM, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<PinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PinRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $PinsTable createAlias(String alias) {
    return $PinsTable(attachedDatabase, alias);
  }
}

class PinRow extends DataClass implements Insertable<PinRow> {
  /// Row id.
  final int id;

  /// When it was dropped (trusted time).
  final DateTime at;

  /// Degrees north.
  final double lat;

  /// Degrees east.
  final double lon;

  /// Accuracy radius in metres, if known.
  final double? accuracyM;

  /// Short name ("Pin 3").
  final String label;
  const PinRow({
    required this.id,
    required this.at,
    required this.lat,
    required this.lon,
    this.accuracyM,
    required this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    map['label'] = Variable<String>(label);
    return map;
  }

  PinsCompanion toCompanion(bool nullToAbsent) {
    return PinsCompanion(
      id: Value(id),
      at: Value(at),
      lat: Value(lat),
      lon: Value(lon),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      label: Value(label),
    );
  }

  factory PinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PinRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'label': serializer.toJson<String>(label),
    };
  }

  PinRow copyWith({
    int? id,
    DateTime? at,
    double? lat,
    double? lon,
    Value<double?> accuracyM = const Value.absent(),
    String? label,
  }) => PinRow(
    id: id ?? this.id,
    at: at ?? this.at,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    label: label ?? this.label,
  );
  PinRow copyWithCompanion(PinsCompanion data) {
    return PinRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PinRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, lat, lon, accuracyM, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.accuracyM == this.accuracyM &&
          other.label == this.label);
}

class PinsCompanion extends UpdateCompanion<PinRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> accuracyM;
  final Value<String> label;
  const PinsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.label = const Value.absent(),
  });
  PinsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required double lat,
    required double lon,
    this.accuracyM = const Value.absent(),
    required String label,
  }) : at = Value(at),
       lat = Value(lat),
       lon = Value(lon),
       label = Value(label);
  static Insertable<PinRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? accuracyM,
    Expression<String>? label,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (label != null) 'label': label,
    });
  }

  PinsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? accuracyM,
    Value<String>? label,
  }) {
    return PinsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracyM: accuracyM ?? this.accuracyM,
      label: label ?? this.label,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }
}

abstract class _$PagdandiDatabase extends GeneratedDatabase {
  _$PagdandiDatabase(QueryExecutor e) : super(e);
  $PagdandiDatabaseManager get managers => $PagdandiDatabaseManager(this);
  late final $SmsOutboxTable smsOutbox = $SmsOutboxTable(this);
  late final $StateSnapshotsTable stateSnapshots = $StateSnapshotsTable(this);
  late final $EventLogTable eventLog = $EventLogTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PinsTable pins = $PinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    smsOutbox,
    stateSnapshots,
    eventLog,
    trips,
    trackPoints,
    settings,
    pins,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SmsOutboxTableCreateCompanionBuilder = SmsOutboxCompanion Function({
  required String id,
  required String recipient,
  required String body,
  required OutboxKind kind,
  required SmsStatus status,
  required int attempts,
  required DateTime createdAt,
  required DateTime nextAttemptAt,
  Value<DateTime?> lastAttemptAt,
  Value<String?> guardStatus,
  Value<int> guardAttempts,
  Value<DateTime?> guardUpdatedAt,
  Value<int> rowid,
});
typedef $$SmsOutboxTableUpdateCompanionBuilder = SmsOutboxCompanion Function({
  Value<String> id,
  Value<String> recipient,
  Value<String> body,
  Value<OutboxKind> kind,
  Value<SmsStatus> status,
  Value<int> attempts,
  Value<DateTime> createdAt,
  Value<DateTime> nextAttemptAt,
  Value<DateTime?> lastAttemptAt,
  Value<String?> guardStatus,
  Value<int> guardAttempts,
  Value<DateTime?> guardUpdatedAt,
  Value<int> rowid,
});

class $$SmsOutboxTableFilterComposer
    extends Composer<_$PagdandiDatabase, $SmsOutboxTable> {
  $$SmsOutboxTableFilterComposer({
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

  ColumnFilters<String> get recipient => $composableBuilder(
    column: $table.recipient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutboxKind, OutboxKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SmsStatus, SmsStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guardStatus => $composableBuilder(
    column: $table.guardStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get guardAttempts => $composableBuilder(
    column: $table.guardAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get guardUpdatedAt => $composableBuilder(
    column: $table.guardUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsOutboxTableOrderingComposer
    extends Composer<_$PagdandiDatabase, $SmsOutboxTable> {
  $$SmsOutboxTableOrderingComposer({
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

  ColumnOrderings<String> get recipient => $composableBuilder(
    column: $table.recipient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guardStatus => $composableBuilder(
    column: $table.guardStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get guardAttempts => $composableBuilder(
    column: $table.guardAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get guardUpdatedAt => $composableBuilder(
    column: $table.guardUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsOutboxTableAnnotationComposer
    extends Composer<_$PagdandiDatabase, $SmsOutboxTable> {
  $$SmsOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipient =>
      $composableBuilder(column: $table.recipient, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OutboxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SmsStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guardStatus => $composableBuilder(
    column: $table.guardStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get guardAttempts => $composableBuilder(
    column: $table.guardAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get guardUpdatedAt => $composableBuilder(
    column: $table.guardUpdatedAt,
    builder: (column) => column,
  );
}

class $$SmsOutboxTableTableManager
    extends
        RootTableManager<
          _$PagdandiDatabase,
          $SmsOutboxTable,
          OutboxRow,
          $$SmsOutboxTableFilterComposer,
          $$SmsOutboxTableOrderingComposer,
          $$SmsOutboxTableAnnotationComposer,
          $$SmsOutboxTableCreateCompanionBuilder,
          $$SmsOutboxTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$PagdandiDatabase, $SmsOutboxTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$SmsOutboxTableTableManager(_$PagdandiDatabase db, $SmsOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipient = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<OutboxKind> kind = const Value.absent(),
                Value<SmsStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> guardStatus = const Value.absent(),
                Value<int> guardAttempts = const Value.absent(),
                Value<DateTime?> guardUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsOutboxCompanion(
                id: id,
                recipient: recipient,
                body: body,
                kind: kind,
                status: status,
                attempts: attempts,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                lastAttemptAt: lastAttemptAt,
                guardStatus: guardStatus,
                guardAttempts: guardAttempts,
                guardUpdatedAt: guardUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipient,
                required String body,
                required OutboxKind kind,
                required SmsStatus status,
                required int attempts,
                required DateTime createdAt,
                required DateTime nextAttemptAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> guardStatus = const Value.absent(),
                Value<int> guardAttempts = const Value.absent(),
                Value<DateTime?> guardUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsOutboxCompanion.insert(
                id: id,
                recipient: recipient,
                body: body,
                kind: kind,
                status: status,
                attempts: attempts,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                lastAttemptAt: lastAttemptAt,
                guardStatus: guardStatus,
                guardAttempts: guardAttempts,
                guardUpdatedAt: guardUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmsOutboxTable, OutboxRow>(table),
                  BaseReferences<
                    _$PagdandiDatabase,
                    $SmsOutboxTable,
                    OutboxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $SmsOutboxTable,
      OutboxRow,
      $$SmsOutboxTableFilterComposer,
      $$SmsOutboxTableOrderingComposer,
      $$SmsOutboxTableAnnotationComposer,
      $$SmsOutboxTableCreateCompanionBuilder,
      $$SmsOutboxTableUpdateCompanionBuilder,
      (
        OutboxRow,
        BaseReferences<_$PagdandiDatabase, $SmsOutboxTable, OutboxRow>,
      ),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$StateSnapshotsTableCreateCompanionBuilder =
    StateSnapshotsCompanion Function({
      Value<int> id,
      required DateTime takenAt,
      required int version,
      required String json,
    });
typedef $$StateSnapshotsTableUpdateCompanionBuilder =
    StateSnapshotsCompanion Function({
      Value<int> id,
      Value<DateTime> takenAt,
      Value<int> version,
      Value<String> json,
    });

class $$StateSnapshotsTableFilterComposer
    extends Composer<_$PagdandiDatabase, $StateSnapshotsTable> {
  $$StateSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StateSnapshotsTableOrderingComposer
    extends Composer<_$PagdandiDatabase, $StateSnapshotsTable> {
  $$StateSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StateSnapshotsTableAnnotationComposer
    extends Composer<_$PagdandiDatabase, $StateSnapshotsTable> {
  $$StateSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$StateSnapshotsTableTableManager
    extends
        RootTableManager<
          _$PagdandiDatabase,
          $StateSnapshotsTable,
          SnapshotRow,
          $$StateSnapshotsTableFilterComposer,
          $$StateSnapshotsTableOrderingComposer,
          $$StateSnapshotsTableAnnotationComposer,
          $$StateSnapshotsTableCreateCompanionBuilder,
          $$StateSnapshotsTableUpdateCompanionBuilder,
          (
            SnapshotRow,
            BaseReferences<
              _$PagdandiDatabase,
              $StateSnapshotsTable,
              SnapshotRow
            >,
          ),
          SnapshotRow,
          PrefetchHooks Function()
        > {
  $$StateSnapshotsTableTableManager(
    _$PagdandiDatabase db,
    $StateSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StateSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StateSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StateSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> json = const Value.absent(),
              }) => StateSnapshotsCompanion(
                id: id,
                takenAt: takenAt,
                version: version,
                json: json,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime takenAt,
                required int version,
                required String json,
              }) => StateSnapshotsCompanion.insert(
                id: id,
                takenAt: takenAt,
                version: version,
                json: json,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StateSnapshotsTable, SnapshotRow>(table),
                  BaseReferences<
                    _$PagdandiDatabase,
                    $StateSnapshotsTable,
                    SnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StateSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $StateSnapshotsTable,
      SnapshotRow,
      $$StateSnapshotsTableFilterComposer,
      $$StateSnapshotsTableOrderingComposer,
      $$StateSnapshotsTableAnnotationComposer,
      $$StateSnapshotsTableCreateCompanionBuilder,
      $$StateSnapshotsTableUpdateCompanionBuilder,
      (
        SnapshotRow,
        BaseReferences<_$PagdandiDatabase, $StateSnapshotsTable, SnapshotRow>,
      ),
      SnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$EventLogTableCreateCompanionBuilder = EventLogCompanion Function({
  Value<int> id,
  required DateTime at,
  required String type,
  required String detail,
});
typedef $$EventLogTableUpdateCompanionBuilder = EventLogCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> type,
  Value<String> detail,
});

class $$EventLogTableFilterComposer
    extends Composer<_$PagdandiDatabase, $EventLogTable> {
  $$EventLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventLogTableOrderingComposer
    extends Composer<_$PagdandiDatabase, $EventLogTable> {
  $$EventLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventLogTableAnnotationComposer
    extends Composer<_$PagdandiDatabase, $EventLogTable> {
  $$EventLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$EventLogTableTableManager
    extends
        RootTableManager<
          _$PagdandiDatabase,
          $EventLogTable,
          EventRow,
          $$EventLogTableFilterComposer,
          $$EventLogTableOrderingComposer,
          $$EventLogTableAnnotationComposer,
          $$EventLogTableCreateCompanionBuilder,
          $$EventLogTableUpdateCompanionBuilder,
          (
            EventRow,
            BaseReferences<_$PagdandiDatabase, $EventLogTable, EventRow>,
          ),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventLogTableTableManager(_$PagdandiDatabase db, $EventLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> detail = const Value.absent(),
          }) => EventLogCompanion(id: id, at: at, type: type, detail: detail),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String type,
                required String detail,
              }) => EventLogCompanion.insert(
                id: id,
                at: at,
                type: type,
                detail: detail,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventLogTable, EventRow>(table),
                  BaseReferences<_$PagdandiDatabase, $EventLogTable, EventRow>(
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

typedef $$EventLogTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $EventLogTable,
      EventRow,
      $$EventLogTableFilterComposer,
      $$EventLogTableOrderingComposer,
      $$EventLogTableAnnotationComposer,
      $$EventLogTableCreateCompanionBuilder,
      $$EventLogTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$PagdandiDatabase, $EventLogTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$TripsTableCreateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  required String name,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
});
typedef $$TripsTableUpdateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
});

final class $$TripsTableReferences
    extends BaseReferences<_$PagdandiDatabase, $TripsTable, TripRow> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPointRow>>
  _trackPointsRefsTable(_$PagdandiDatabase db) => MultiTypedResultKey.fromTable(
    db.trackPoints,
    aliasName: 'trips__id__track_points__trip_id',
  );

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager(
      $_db,
      $_db.trackPoints,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer
    extends Composer<_$PagdandiDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackPointsRefs(
    Expression<bool> Function($$TrackPointsTableFilterComposer f) f,
  ) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$PagdandiDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$PagdandiDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  Expression<T> trackPointsRefs<T extends Object>(
    Expression<T> Function($$TrackPointsTableAnnotationComposer a) f,
  ) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$PagdandiDatabase,
          $TripsTable,
          TripRow,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (TripRow, $$TripsTableReferences),
          TripRow,
          PrefetchHooks Function({bool trackPointsRefs})
        > {
  $$TripsTableTableManager(_$PagdandiDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                name: name,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                name: name,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TripsTable, TripRow>(table),
                  $$TripsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackPointsRefs) db.trackPoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackPointsRefs)
                    await $_getPrefetchedDataByColumns<
                      TripRow,
                      $TripsTable,
                      TrackPointRow,
                      $TrackPointsTable
                    >(
                      currentTable: table,
                      referencedTable: $$TripsTableReferences
                          ._trackPointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TripsTableReferences(db, table, p0).trackPointsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'trip_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $TripsTable,
      TripRow,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (TripRow, $$TripsTableReferences),
      TripRow,
      PrefetchHooks Function({bool trackPointsRefs})
    >;
typedef $$TrackPointsTableCreateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      required int tripId,
      required DateTime at,
      required double latitude,
      required double longitude,
      required double accuracyM,
      Value<double?> altitudeM,
    });
typedef $$TrackPointsTableUpdateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      Value<int> tripId,
      Value<DateTime> at,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> accuracyM,
      Value<double?> altitudeM,
    });

final class $$TrackPointsTableReferences
    extends
        BaseReferences<_$PagdandiDatabase, $TrackPointsTable, TrackPointRow> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$PagdandiDatabase db) =>
      db.trips.createAlias('track_points__trip_id__trips__id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<int>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$PagdandiDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$PagdandiDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$PagdandiDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableTableManager
    extends
        RootTableManager<
          _$PagdandiDatabase,
          $TrackPointsTable,
          TrackPointRow,
          $$TrackPointsTableFilterComposer,
          $$TrackPointsTableOrderingComposer,
          $$TrackPointsTableAnnotationComposer,
          $$TrackPointsTableCreateCompanionBuilder,
          $$TrackPointsTableUpdateCompanionBuilder,
          (TrackPointRow, $$TrackPointsTableReferences),
          TrackPointRow,
          PrefetchHooks Function({bool tripId})
        > {
  $$TrackPointsTableTableManager(_$PagdandiDatabase db, $TrackPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tripId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> accuracyM = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
              }) => TrackPointsCompanion(
                id: id,
                tripId: tripId,
                at: at,
                latitude: latitude,
                longitude: longitude,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tripId,
                required DateTime at,
                required double latitude,
                required double longitude,
                required double accuracyM,
                Value<double?> altitudeM = const Value.absent(),
              }) => TrackPointsCompanion.insert(
                id: id,
                tripId: tripId,
                at: at,
                latitude: latitude,
                longitude: longitude,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackPointsTable, TrackPointRow>(table),
                  $$TrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
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
                    if (tripId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tripId,
                        referencedTable: $$TrackPointsTableReferences
                            ._tripIdTable(db),
                        referencedColumn: $$TrackPointsTableReferences
                            ._tripIdTable(db)
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

typedef $$TrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $TrackPointsTable,
      TrackPointRow,
      $$TrackPointsTableFilterComposer,
      $$TrackPointsTableOrderingComposer,
      $$TrackPointsTableAnnotationComposer,
      $$TrackPointsTableCreateCompanionBuilder,
      $$TrackPointsTableUpdateCompanionBuilder,
      (TrackPointRow, $$TrackPointsTableReferences),
      TrackPointRow,
      PrefetchHooks Function({bool tripId})
    >;
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
    extends Composer<_$PagdandiDatabase, $SettingsTable> {
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
    extends Composer<_$PagdandiDatabase, $SettingsTable> {
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
    extends Composer<_$PagdandiDatabase, $SettingsTable> {
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
          _$PagdandiDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$PagdandiDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$PagdandiDatabase db, $SettingsTable table)
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
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<
                    _$PagdandiDatabase,
                    $SettingsTable,
                    SettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$PagdandiDatabase, $SettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$PinsTableCreateCompanionBuilder = PinsCompanion Function({
  Value<int> id,
  required DateTime at,
  required double lat,
  required double lon,
  Value<double?> accuracyM,
  required String label,
});
typedef $$PinsTableUpdateCompanionBuilder = PinsCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<double> lat,
  Value<double> lon,
  Value<double?> accuracyM,
  Value<String> label,
});

class $$PinsTableFilterComposer
    extends Composer<_$PagdandiDatabase, $PinsTable> {
  $$PinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PinsTableOrderingComposer
    extends Composer<_$PagdandiDatabase, $PinsTable> {
  $$PinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PinsTableAnnotationComposer
    extends Composer<_$PagdandiDatabase, $PinsTable> {
  $$PinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$PinsTableTableManager
    extends
        RootTableManager<
          _$PagdandiDatabase,
          $PinsTable,
          PinRow,
          $$PinsTableFilterComposer,
          $$PinsTableOrderingComposer,
          $$PinsTableAnnotationComposer,
          $$PinsTableCreateCompanionBuilder,
          $$PinsTableUpdateCompanionBuilder,
          (PinRow, BaseReferences<_$PagdandiDatabase, $PinsTable, PinRow>),
          PinRow,
          PrefetchHooks Function()
        > {
  $$PinsTableTableManager(_$PagdandiDatabase db, $PinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<String> label = const Value.absent(),
              }) => PinsCompanion(
                id: id,
                at: at,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                label: label,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required double lat,
                required double lon,
                Value<double?> accuracyM = const Value.absent(),
                required String label,
              }) => PinsCompanion.insert(
                id: id,
                at: at,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                label: label,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PinsTable, PinRow>(table),
                  BaseReferences<_$PagdandiDatabase, $PinsTable, PinRow>(
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

typedef $$PinsTableProcessedTableManager =
    ProcessedTableManager<
      _$PagdandiDatabase,
      $PinsTable,
      PinRow,
      $$PinsTableFilterComposer,
      $$PinsTableOrderingComposer,
      $$PinsTableAnnotationComposer,
      $$PinsTableCreateCompanionBuilder,
      $$PinsTableUpdateCompanionBuilder,
      (PinRow, BaseReferences<_$PagdandiDatabase, $PinsTable, PinRow>),
      PinRow,
      PrefetchHooks Function()
    >;

class $PagdandiDatabaseManager {
  final _$PagdandiDatabase _db;
  $PagdandiDatabaseManager(this._db);
  $$SmsOutboxTableTableManager get smsOutbox =>
      $$SmsOutboxTableTableManager(_db, _db.smsOutbox);
  $$StateSnapshotsTableTableManager get stateSnapshots =>
      $$StateSnapshotsTableTableManager(_db, _db.stateSnapshots);
  $$EventLogTableTableManager get eventLog =>
      $$EventLogTableTableManager(_db, _db.eventLog);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$PinsTableTableManager get pins => $$PinsTableTableManager(_db, _db.pins);
}
