// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OutboxOperationsTable extends OutboxOperations
    with TableInfo<$OutboxOperationsTable, OutboxOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetResourceKeyMeta = const VerificationMeta(
    'targetResourceKey',
  );
  @override
  late final GeneratedColumn<String> targetResourceKey =
      GeneratedColumn<String>(
        'target_resource_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _httpMethodMeta = const VerificationMeta(
    'httpMethod',
  );
  @override
  late final GeneratedColumn<String> httpMethod = GeneratedColumn<String>(
    'http_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('POST'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadVersionMeta = const VerificationMeta(
    'payloadVersion',
  );
  @override
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
    'payload_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _processingStartedAtMeta =
      const VerificationMeta('processingStartedAt');
  @override
  late final GeneratedColumn<DateTime> processingStartedAt =
      GeneratedColumn<DateTime>(
        'processing_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dependsOnOperationIdMeta =
      const VerificationMeta('dependsOnOperationId');
  @override
  late final GeneratedColumn<String> dependsOnOperationId =
      GeneratedColumn<String>(
        'depends_on_operation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
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
    operationId,
    idempotencyKey,
    accountId,
    companyId,
    operationType,
    targetResourceKey,
    endpoint,
    httpMethod,
    payloadJson,
    payloadVersion,
    state,
    attemptCount,
    nextAttemptAt,
    processingStartedAt,
    dependsOnOperationId,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('target_resource_key')) {
      context.handle(
        _targetResourceKeyMeta,
        targetResourceKey.isAcceptableOrUnknown(
          data['target_resource_key']!,
          _targetResourceKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetResourceKeyMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('http_method')) {
      context.handle(
        _httpMethodMeta,
        httpMethod.isAcceptableOrUnknown(data['http_method']!, _httpMethodMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('payload_version')) {
      context.handle(
        _payloadVersionMeta,
        payloadVersion.isAcceptableOrUnknown(
          data['payload_version']!,
          _payloadVersionMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('processing_started_at')) {
      context.handle(
        _processingStartedAtMeta,
        processingStartedAt.isAcceptableOrUnknown(
          data['processing_started_at']!,
          _processingStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('depends_on_operation_id')) {
      context.handle(
        _dependsOnOperationIdMeta,
        dependsOnOperationId.isAcceptableOrUnknown(
          data['depends_on_operation_id']!,
          _dependsOnOperationIdMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  OutboxOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOperation(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      targetResourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_resource_key'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      httpMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}http_method'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      payloadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_version'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      processingStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processing_started_at'],
      ),
      dependsOnOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on_operation_id'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OutboxOperationsTable createAlias(String alias) {
    return $OutboxOperationsTable(attachedDatabase, alias);
  }
}

class OutboxOperation extends DataClass implements Insertable<OutboxOperation> {
  final String operationId;
  final String idempotencyKey;
  final String accountId;
  final String companyId;
  final String operationType;
  final String targetResourceKey;
  final String endpoint;
  final String httpMethod;
  final String payloadJson;
  final int payloadVersion;
  final String state;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final DateTime? processingStartedAt;
  final String? dependsOnOperationId;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxOperation({
    required this.operationId,
    required this.idempotencyKey,
    required this.accountId,
    required this.companyId,
    required this.operationType,
    required this.targetResourceKey,
    required this.endpoint,
    required this.httpMethod,
    required this.payloadJson,
    required this.payloadVersion,
    required this.state,
    required this.attemptCount,
    this.nextAttemptAt,
    this.processingStartedAt,
    this.dependsOnOperationId,
    this.lastErrorCode,
    this.lastErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['account_id'] = Variable<String>(accountId);
    map['company_id'] = Variable<String>(companyId);
    map['operation_type'] = Variable<String>(operationType);
    map['target_resource_key'] = Variable<String>(targetResourceKey);
    map['endpoint'] = Variable<String>(endpoint);
    map['http_method'] = Variable<String>(httpMethod);
    map['payload_json'] = Variable<String>(payloadJson);
    map['payload_version'] = Variable<int>(payloadVersion);
    map['state'] = Variable<String>(state);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || processingStartedAt != null) {
      map['processing_started_at'] = Variable<DateTime>(processingStartedAt);
    }
    if (!nullToAbsent || dependsOnOperationId != null) {
      map['depends_on_operation_id'] = Variable<String>(dependsOnOperationId);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxOperationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOperationsCompanion(
      operationId: Value(operationId),
      idempotencyKey: Value(idempotencyKey),
      accountId: Value(accountId),
      companyId: Value(companyId),
      operationType: Value(operationType),
      targetResourceKey: Value(targetResourceKey),
      endpoint: Value(endpoint),
      httpMethod: Value(httpMethod),
      payloadJson: Value(payloadJson),
      payloadVersion: Value(payloadVersion),
      state: Value(state),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      processingStartedAt: processingStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processingStartedAt),
      dependsOnOperationId: dependsOnOperationId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOnOperationId),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOperation(
      operationId: serializer.fromJson<String>(json['operationId']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      accountId: serializer.fromJson<String>(json['accountId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      targetResourceKey: serializer.fromJson<String>(json['targetResourceKey']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      httpMethod: serializer.fromJson<String>(json['httpMethod']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      payloadVersion: serializer.fromJson<int>(json['payloadVersion']),
      state: serializer.fromJson<String>(json['state']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      processingStartedAt: serializer.fromJson<DateTime?>(
        json['processingStartedAt'],
      ),
      dependsOnOperationId: serializer.fromJson<String?>(
        json['dependsOnOperationId'],
      ),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'accountId': serializer.toJson<String>(accountId),
      'companyId': serializer.toJson<String>(companyId),
      'operationType': serializer.toJson<String>(operationType),
      'targetResourceKey': serializer.toJson<String>(targetResourceKey),
      'endpoint': serializer.toJson<String>(endpoint),
      'httpMethod': serializer.toJson<String>(httpMethod),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'payloadVersion': serializer.toJson<int>(payloadVersion),
      'state': serializer.toJson<String>(state),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'processingStartedAt': serializer.toJson<DateTime?>(processingStartedAt),
      'dependsOnOperationId': serializer.toJson<String?>(dependsOnOperationId),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxOperation copyWith({
    String? operationId,
    String? idempotencyKey,
    String? accountId,
    String? companyId,
    String? operationType,
    String? targetResourceKey,
    String? endpoint,
    String? httpMethod,
    String? payloadJson,
    int? payloadVersion,
    String? state,
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<DateTime?> processingStartedAt = const Value.absent(),
    Value<String?> dependsOnOperationId = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OutboxOperation(
    operationId: operationId ?? this.operationId,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    accountId: accountId ?? this.accountId,
    companyId: companyId ?? this.companyId,
    operationType: operationType ?? this.operationType,
    targetResourceKey: targetResourceKey ?? this.targetResourceKey,
    endpoint: endpoint ?? this.endpoint,
    httpMethod: httpMethod ?? this.httpMethod,
    payloadJson: payloadJson ?? this.payloadJson,
    payloadVersion: payloadVersion ?? this.payloadVersion,
    state: state ?? this.state,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    processingStartedAt: processingStartedAt.present
        ? processingStartedAt.value
        : this.processingStartedAt,
    dependsOnOperationId: dependsOnOperationId.present
        ? dependsOnOperationId.value
        : this.dependsOnOperationId,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OutboxOperation copyWithCompanion(OutboxOperationsCompanion data) {
    return OutboxOperation(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      targetResourceKey: data.targetResourceKey.present
          ? data.targetResourceKey.value
          : this.targetResourceKey,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      httpMethod: data.httpMethod.present
          ? data.httpMethod.value
          : this.httpMethod,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      state: data.state.present ? data.state.value : this.state,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      processingStartedAt: data.processingStartedAt.present
          ? data.processingStartedAt.value
          : this.processingStartedAt,
      dependsOnOperationId: data.dependsOnOperationId.present
          ? data.dependsOnOperationId.value
          : this.dependsOnOperationId,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperation(')
          ..write('operationId: $operationId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('operationType: $operationType, ')
          ..write('targetResourceKey: $targetResourceKey, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('processingStartedAt: $processingStartedAt, ')
          ..write('dependsOnOperationId: $dependsOnOperationId, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    idempotencyKey,
    accountId,
    companyId,
    operationType,
    targetResourceKey,
    endpoint,
    httpMethod,
    payloadJson,
    payloadVersion,
    state,
    attemptCount,
    nextAttemptAt,
    processingStartedAt,
    dependsOnOperationId,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOperation &&
          other.operationId == this.operationId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.accountId == this.accountId &&
          other.companyId == this.companyId &&
          other.operationType == this.operationType &&
          other.targetResourceKey == this.targetResourceKey &&
          other.endpoint == this.endpoint &&
          other.httpMethod == this.httpMethod &&
          other.payloadJson == this.payloadJson &&
          other.payloadVersion == this.payloadVersion &&
          other.state == this.state &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.processingStartedAt == this.processingStartedAt &&
          other.dependsOnOperationId == this.dependsOnOperationId &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxOperationsCompanion extends UpdateCompanion<OutboxOperation> {
  final Value<String> operationId;
  final Value<String> idempotencyKey;
  final Value<String> accountId;
  final Value<String> companyId;
  final Value<String> operationType;
  final Value<String> targetResourceKey;
  final Value<String> endpoint;
  final Value<String> httpMethod;
  final Value<String> payloadJson;
  final Value<int> payloadVersion;
  final Value<String> state;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime?> processingStartedAt;
  final Value<String?> dependsOnOperationId;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxOperationsCompanion({
    this.operationId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.accountId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.targetResourceKey = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.httpMethod = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.processingStartedAt = const Value.absent(),
    this.dependsOnOperationId = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxOperationsCompanion.insert({
    required String operationId,
    required String idempotencyKey,
    required String accountId,
    required String companyId,
    required String operationType,
    required String targetResourceKey,
    required String endpoint,
    this.httpMethod = const Value.absent(),
    required String payloadJson,
    this.payloadVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.processingStartedAt = const Value.absent(),
    this.dependsOnOperationId = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       idempotencyKey = Value(idempotencyKey),
       accountId = Value(accountId),
       companyId = Value(companyId),
       operationType = Value(operationType),
       targetResourceKey = Value(targetResourceKey),
       endpoint = Value(endpoint),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OutboxOperation> custom({
    Expression<String>? operationId,
    Expression<String>? idempotencyKey,
    Expression<String>? accountId,
    Expression<String>? companyId,
    Expression<String>? operationType,
    Expression<String>? targetResourceKey,
    Expression<String>? endpoint,
    Expression<String>? httpMethod,
    Expression<String>? payloadJson,
    Expression<int>? payloadVersion,
    Expression<String>? state,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? processingStartedAt,
    Expression<String>? dependsOnOperationId,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (accountId != null) 'account_id': accountId,
      if (companyId != null) 'company_id': companyId,
      if (operationType != null) 'operation_type': operationType,
      if (targetResourceKey != null) 'target_resource_key': targetResourceKey,
      if (endpoint != null) 'endpoint': endpoint,
      if (httpMethod != null) 'http_method': httpMethod,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (state != null) 'state': state,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (processingStartedAt != null)
        'processing_started_at': processingStartedAt,
      if (dependsOnOperationId != null)
        'depends_on_operation_id': dependsOnOperationId,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxOperationsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? idempotencyKey,
    Value<String>? accountId,
    Value<String>? companyId,
    Value<String>? operationType,
    Value<String>? targetResourceKey,
    Value<String>? endpoint,
    Value<String>? httpMethod,
    Value<String>? payloadJson,
    Value<int>? payloadVersion,
    Value<String>? state,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime?>? processingStartedAt,
    Value<String?>? dependsOnOperationId,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutboxOperationsCompanion(
      operationId: operationId ?? this.operationId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      accountId: accountId ?? this.accountId,
      companyId: companyId ?? this.companyId,
      operationType: operationType ?? this.operationType,
      targetResourceKey: targetResourceKey ?? this.targetResourceKey,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      payloadJson: payloadJson ?? this.payloadJson,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      processingStartedAt: processingStartedAt ?? this.processingStartedAt,
      dependsOnOperationId: dependsOnOperationId ?? this.dependsOnOperationId,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (targetResourceKey.present) {
      map['target_resource_key'] = Variable<String>(targetResourceKey.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (httpMethod.present) {
      map['http_method'] = Variable<String>(httpMethod.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (processingStartedAt.present) {
      map['processing_started_at'] = Variable<DateTime>(
        processingStartedAt.value,
      );
    }
    if (dependsOnOperationId.present) {
      map['depends_on_operation_id'] = Variable<String>(
        dependsOnOperationId.value,
      );
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
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
    return (StringBuffer('OutboxOperationsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('operationType: $operationType, ')
          ..write('targetResourceKey: $targetResourceKey, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('processingStartedAt: $processingStartedAt, ')
          ..write('dependsOnOperationId: $dependsOnOperationId, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxAttachmentsTable extends OutboxAttachments
    with TableInfo<$OutboxAttachmentsTable, OutboxAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES outbox_operations (operation_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durablePathMeta = const VerificationMeta(
    'durablePath',
  );
  @override
  late final GeneratedColumn<String> durablePath = GeneratedColumn<String>(
    'durable_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
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
    attachmentId,
    operationId,
    fieldName,
    durablePath,
    originalName,
    mimeType,
    sizeBytes,
    checksum,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('durable_path')) {
      context.handle(
        _durablePathMeta,
        durablePath.isAcceptableOrUnknown(
          data['durable_path']!,
          _durablePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durablePathMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
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
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  OutboxAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxAttachment(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      durablePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}durable_path'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxAttachmentsTable createAlias(String alias) {
    return $OutboxAttachmentsTable(attachedDatabase, alias);
  }
}

class OutboxAttachment extends DataClass
    implements Insertable<OutboxAttachment> {
  final String attachmentId;
  final String operationId;
  final String fieldName;
  final String durablePath;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final String checksum;
  final DateTime createdAt;
  const OutboxAttachment({
    required this.attachmentId,
    required this.operationId,
    required this.fieldName,
    required this.durablePath,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksum,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    map['operation_id'] = Variable<String>(operationId);
    map['field_name'] = Variable<String>(fieldName);
    map['durable_path'] = Variable<String>(durablePath);
    map['original_name'] = Variable<String>(originalName);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['checksum'] = Variable<String>(checksum);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return OutboxAttachmentsCompanion(
      attachmentId: Value(attachmentId),
      operationId: Value(operationId),
      fieldName: Value(fieldName),
      durablePath: Value(durablePath),
      originalName: Value(originalName),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      checksum: Value(checksum),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxAttachment(
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      operationId: serializer.fromJson<String>(json['operationId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      durablePath: serializer.fromJson<String>(json['durablePath']),
      originalName: serializer.fromJson<String>(json['originalName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      checksum: serializer.fromJson<String>(json['checksum']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<String>(attachmentId),
      'operationId': serializer.toJson<String>(operationId),
      'fieldName': serializer.toJson<String>(fieldName),
      'durablePath': serializer.toJson<String>(durablePath),
      'originalName': serializer.toJson<String>(originalName),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'checksum': serializer.toJson<String>(checksum),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxAttachment copyWith({
    String? attachmentId,
    String? operationId,
    String? fieldName,
    String? durablePath,
    String? originalName,
    String? mimeType,
    int? sizeBytes,
    String? checksum,
    DateTime? createdAt,
  }) => OutboxAttachment(
    attachmentId: attachmentId ?? this.attachmentId,
    operationId: operationId ?? this.operationId,
    fieldName: fieldName ?? this.fieldName,
    durablePath: durablePath ?? this.durablePath,
    originalName: originalName ?? this.originalName,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    checksum: checksum ?? this.checksum,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxAttachment copyWithCompanion(OutboxAttachmentsCompanion data) {
    return OutboxAttachment(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      durablePath: data.durablePath.present
          ? data.durablePath.value
          : this.durablePath,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxAttachment(')
          ..write('attachmentId: $attachmentId, ')
          ..write('operationId: $operationId, ')
          ..write('fieldName: $fieldName, ')
          ..write('durablePath: $durablePath, ')
          ..write('originalName: $originalName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attachmentId,
    operationId,
    fieldName,
    durablePath,
    originalName,
    mimeType,
    sizeBytes,
    checksum,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxAttachment &&
          other.attachmentId == this.attachmentId &&
          other.operationId == this.operationId &&
          other.fieldName == this.fieldName &&
          other.durablePath == this.durablePath &&
          other.originalName == this.originalName &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.checksum == this.checksum &&
          other.createdAt == this.createdAt);
}

class OutboxAttachmentsCompanion extends UpdateCompanion<OutboxAttachment> {
  final Value<String> attachmentId;
  final Value<String> operationId;
  final Value<String> fieldName;
  final Value<String> durablePath;
  final Value<String> originalName;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> checksum;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OutboxAttachmentsCompanion({
    this.attachmentId = const Value.absent(),
    this.operationId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.durablePath = const Value.absent(),
    this.originalName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.checksum = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxAttachmentsCompanion.insert({
    required String attachmentId,
    required String operationId,
    required String fieldName,
    required String durablePath,
    required String originalName,
    required String mimeType,
    required int sizeBytes,
    required String checksum,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : attachmentId = Value(attachmentId),
       operationId = Value(operationId),
       fieldName = Value(fieldName),
       durablePath = Value(durablePath),
       originalName = Value(originalName),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       checksum = Value(checksum),
       createdAt = Value(createdAt);
  static Insertable<OutboxAttachment> custom({
    Expression<String>? attachmentId,
    Expression<String>? operationId,
    Expression<String>? fieldName,
    Expression<String>? durablePath,
    Expression<String>? originalName,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? checksum,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (operationId != null) 'operation_id': operationId,
      if (fieldName != null) 'field_name': fieldName,
      if (durablePath != null) 'durable_path': durablePath,
      if (originalName != null) 'original_name': originalName,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (checksum != null) 'checksum': checksum,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxAttachmentsCompanion copyWith({
    Value<String>? attachmentId,
    Value<String>? operationId,
    Value<String>? fieldName,
    Value<String>? durablePath,
    Value<String>? originalName,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String>? checksum,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OutboxAttachmentsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      operationId: operationId ?? this.operationId,
      fieldName: fieldName ?? this.fieldName,
      durablePath: durablePath ?? this.durablePath,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum ?? this.checksum,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (durablePath.present) {
      map['durable_path'] = Variable<String>(durablePath.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
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
    return (StringBuffer('OutboxAttachmentsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('operationId: $operationId, ')
          ..write('fieldName: $fieldName, ')
          ..write('durablePath: $durablePath, ')
          ..write('originalName: $originalName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiCacheTable extends ApiCache
    with TableInfo<$ApiCacheTable, ApiCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointKeyMeta = const VerificationMeta(
    'endpointKey',
  );
  @override
  late final GeneratedColumn<String> endpointKey = GeneratedColumn<String>(
    'endpoint_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryHashMeta = const VerificationMeta(
    'queryHash',
  );
  @override
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
    'query_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    accountId,
    companyId,
    endpointKey,
    queryHash,
    payloadJson,
    fetchedAt,
    expiresAt,
    etag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('endpoint_key')) {
      context.handle(
        _endpointKeyMeta,
        endpointKey.isAcceptableOrUnknown(
          data['endpoint_key']!,
          _endpointKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endpointKeyMeta);
    }
    if (data.containsKey('query_hash')) {
      context.handle(
        _queryHashMeta,
        queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta),
      );
    } else if (isInserting) {
      context.missing(_queryHashMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  ApiCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiCacheData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      endpointKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint_key'],
      )!,
      queryHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query_hash'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $ApiCacheTable createAlias(String alias) {
    return $ApiCacheTable(attachedDatabase, alias);
  }
}

class ApiCacheData extends DataClass implements Insertable<ApiCacheData> {
  final String cacheKey;
  final String accountId;
  final String companyId;
  final String endpointKey;
  final String queryHash;
  final String payloadJson;
  final DateTime fetchedAt;
  final DateTime? expiresAt;
  final String? etag;
  const ApiCacheData({
    required this.cacheKey,
    required this.accountId,
    required this.companyId,
    required this.endpointKey,
    required this.queryHash,
    required this.payloadJson,
    required this.fetchedAt,
    this.expiresAt,
    this.etag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['account_id'] = Variable<String>(accountId);
    map['company_id'] = Variable<String>(companyId);
    map['endpoint_key'] = Variable<String>(endpointKey);
    map['query_hash'] = Variable<String>(queryHash);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  ApiCacheCompanion toCompanion(bool nullToAbsent) {
    return ApiCacheCompanion(
      cacheKey: Value(cacheKey),
      accountId: Value(accountId),
      companyId: Value(companyId),
      endpointKey: Value(endpointKey),
      queryHash: Value(queryHash),
      payloadJson: Value(payloadJson),
      fetchedAt: Value(fetchedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory ApiCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiCacheData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      accountId: serializer.fromJson<String>(json['accountId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      endpointKey: serializer.fromJson<String>(json['endpointKey']),
      queryHash: serializer.fromJson<String>(json['queryHash']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'accountId': serializer.toJson<String>(accountId),
      'companyId': serializer.toJson<String>(companyId),
      'endpointKey': serializer.toJson<String>(endpointKey),
      'queryHash': serializer.toJson<String>(queryHash),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  ApiCacheData copyWith({
    String? cacheKey,
    String? accountId,
    String? companyId,
    String? endpointKey,
    String? queryHash,
    String? payloadJson,
    DateTime? fetchedAt,
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<String?> etag = const Value.absent(),
  }) => ApiCacheData(
    cacheKey: cacheKey ?? this.cacheKey,
    accountId: accountId ?? this.accountId,
    companyId: companyId ?? this.companyId,
    endpointKey: endpointKey ?? this.endpointKey,
    queryHash: queryHash ?? this.queryHash,
    payloadJson: payloadJson ?? this.payloadJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    etag: etag.present ? etag.value : this.etag,
  );
  ApiCacheData copyWithCompanion(ApiCacheCompanion data) {
    return ApiCacheData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      endpointKey: data.endpointKey.present
          ? data.endpointKey.value
          : this.endpointKey,
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('endpointKey: $endpointKey, ')
          ..write('queryHash: $queryHash, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    accountId,
    companyId,
    endpointKey,
    queryHash,
    payloadJson,
    fetchedAt,
    expiresAt,
    etag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiCacheData &&
          other.cacheKey == this.cacheKey &&
          other.accountId == this.accountId &&
          other.companyId == this.companyId &&
          other.endpointKey == this.endpointKey &&
          other.queryHash == this.queryHash &&
          other.payloadJson == this.payloadJson &&
          other.fetchedAt == this.fetchedAt &&
          other.expiresAt == this.expiresAt &&
          other.etag == this.etag);
}

class ApiCacheCompanion extends UpdateCompanion<ApiCacheData> {
  final Value<String> cacheKey;
  final Value<String> accountId;
  final Value<String> companyId;
  final Value<String> endpointKey;
  final Value<String> queryHash;
  final Value<String> payloadJson;
  final Value<DateTime> fetchedAt;
  final Value<DateTime?> expiresAt;
  final Value<String?> etag;
  final Value<int> rowid;
  const ApiCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.accountId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.endpointKey = const Value.absent(),
    this.queryHash = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiCacheCompanion.insert({
    required String cacheKey,
    required String accountId,
    required String companyId,
    required String endpointKey,
    required String queryHash,
    required String payloadJson,
    required DateTime fetchedAt,
    this.expiresAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       accountId = Value(accountId),
       companyId = Value(companyId),
       endpointKey = Value(endpointKey),
       queryHash = Value(queryHash),
       payloadJson = Value(payloadJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<ApiCacheData> custom({
    Expression<String>? cacheKey,
    Expression<String>? accountId,
    Expression<String>? companyId,
    Expression<String>? endpointKey,
    Expression<String>? queryHash,
    Expression<String>? payloadJson,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (accountId != null) 'account_id': accountId,
      if (companyId != null) 'company_id': companyId,
      if (endpointKey != null) 'endpoint_key': endpointKey,
      if (queryHash != null) 'query_hash': queryHash,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiCacheCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? accountId,
    Value<String>? companyId,
    Value<String>? endpointKey,
    Value<String>? queryHash,
    Value<String>? payloadJson,
    Value<DateTime>? fetchedAt,
    Value<DateTime?>? expiresAt,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return ApiCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      accountId: accountId ?? this.accountId,
      companyId: companyId ?? this.companyId,
      endpointKey: endpointKey ?? this.endpointKey,
      queryHash: queryHash ?? this.queryHash,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (endpointKey.present) {
      map['endpoint_key'] = Variable<String>(endpointKey.value);
    }
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('endpointKey: $endpointKey, ')
          ..write('queryHash: $queryHash, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceDaySnapshotsTable extends AttendanceDaySnapshots
    with TableInfo<$AttendanceDaySnapshotsTable, AttendanceDaySnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceDaySnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attendanceDateMeta = const VerificationMeta(
    'attendanceDate',
  );
  @override
  late final GeneratedColumn<String> attendanceDate = GeneratedColumn<String>(
    'attendance_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverTimeMeta = const VerificationMeta(
    'serverTime',
  );
  @override
  late final GeneratedColumn<DateTime> serverTime = GeneratedColumn<DateTime>(
    'server_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    companyId,
    attendanceDate,
    payloadJson,
    serverTime,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_day_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceDaySnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('attendance_date')) {
      context.handle(
        _attendanceDateMeta,
        attendanceDate.isAcceptableOrUnknown(
          data['attendance_date']!,
          _attendanceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attendanceDateMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_time')) {
      context.handle(
        _serverTimeMeta,
        serverTime.isAcceptableOrUnknown(data['server_time']!, _serverTimeMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    accountId,
    companyId,
    attendanceDate,
  };
  @override
  AttendanceDaySnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceDaySnapshot(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      attendanceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attendance_date'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      serverTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_time'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $AttendanceDaySnapshotsTable createAlias(String alias) {
    return $AttendanceDaySnapshotsTable(attachedDatabase, alias);
  }
}

class AttendanceDaySnapshot extends DataClass
    implements Insertable<AttendanceDaySnapshot> {
  final String accountId;
  final String companyId;
  final String attendanceDate;
  final String payloadJson;
  final DateTime? serverTime;
  final DateTime fetchedAt;
  const AttendanceDaySnapshot({
    required this.accountId,
    required this.companyId,
    required this.attendanceDate,
    required this.payloadJson,
    this.serverTime,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['company_id'] = Variable<String>(companyId);
    map['attendance_date'] = Variable<String>(attendanceDate);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverTime != null) {
      map['server_time'] = Variable<DateTime>(serverTime);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  AttendanceDaySnapshotsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceDaySnapshotsCompanion(
      accountId: Value(accountId),
      companyId: Value(companyId),
      attendanceDate: Value(attendanceDate),
      payloadJson: Value(payloadJson),
      serverTime: serverTime == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTime),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory AttendanceDaySnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceDaySnapshot(
      accountId: serializer.fromJson<String>(json['accountId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      attendanceDate: serializer.fromJson<String>(json['attendanceDate']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverTime: serializer.fromJson<DateTime?>(json['serverTime']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'companyId': serializer.toJson<String>(companyId),
      'attendanceDate': serializer.toJson<String>(attendanceDate),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverTime': serializer.toJson<DateTime?>(serverTime),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  AttendanceDaySnapshot copyWith({
    String? accountId,
    String? companyId,
    String? attendanceDate,
    String? payloadJson,
    Value<DateTime?> serverTime = const Value.absent(),
    DateTime? fetchedAt,
  }) => AttendanceDaySnapshot(
    accountId: accountId ?? this.accountId,
    companyId: companyId ?? this.companyId,
    attendanceDate: attendanceDate ?? this.attendanceDate,
    payloadJson: payloadJson ?? this.payloadJson,
    serverTime: serverTime.present ? serverTime.value : this.serverTime,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  AttendanceDaySnapshot copyWithCompanion(
    AttendanceDaySnapshotsCompanion data,
  ) {
    return AttendanceDaySnapshot(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      attendanceDate: data.attendanceDate.present
          ? data.attendanceDate.value
          : this.attendanceDate,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      serverTime: data.serverTime.present
          ? data.serverTime.value
          : this.serverTime,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceDaySnapshot(')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverTime: $serverTime, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    companyId,
    attendanceDate,
    payloadJson,
    serverTime,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceDaySnapshot &&
          other.accountId == this.accountId &&
          other.companyId == this.companyId &&
          other.attendanceDate == this.attendanceDate &&
          other.payloadJson == this.payloadJson &&
          other.serverTime == this.serverTime &&
          other.fetchedAt == this.fetchedAt);
}

class AttendanceDaySnapshotsCompanion
    extends UpdateCompanion<AttendanceDaySnapshot> {
  final Value<String> accountId;
  final Value<String> companyId;
  final Value<String> attendanceDate;
  final Value<String> payloadJson;
  final Value<DateTime?> serverTime;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const AttendanceDaySnapshotsCompanion({
    this.accountId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.attendanceDate = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverTime = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceDaySnapshotsCompanion.insert({
    required String accountId,
    required String companyId,
    required String attendanceDate,
    required String payloadJson,
    this.serverTime = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       companyId = Value(companyId),
       attendanceDate = Value(attendanceDate),
       payloadJson = Value(payloadJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<AttendanceDaySnapshot> custom({
    Expression<String>? accountId,
    Expression<String>? companyId,
    Expression<String>? attendanceDate,
    Expression<String>? payloadJson,
    Expression<DateTime>? serverTime,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (companyId != null) 'company_id': companyId,
      if (attendanceDate != null) 'attendance_date': attendanceDate,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverTime != null) 'server_time': serverTime,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceDaySnapshotsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? companyId,
    Value<String>? attendanceDate,
    Value<String>? payloadJson,
    Value<DateTime?>? serverTime,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return AttendanceDaySnapshotsCompanion(
      accountId: accountId ?? this.accountId,
      companyId: companyId ?? this.companyId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      payloadJson: payloadJson ?? this.payloadJson,
      serverTime: serverTime ?? this.serverTime,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (attendanceDate.present) {
      map['attendance_date'] = Variable<String>(attendanceDate.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverTime.present) {
      map['server_time'] = Variable<DateTime>(serverTime.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceDaySnapshotsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverTime: $serverTime, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceOvertimeReferencesTable extends AttendanceOvertimeReferences
    with
        TableInfo<
          $AttendanceOvertimeReferencesTable,
          AttendanceOvertimeReference
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceOvertimeReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _overtimeIdMeta = const VerificationMeta(
    'overtimeId',
  );
  @override
  late final GeneratedColumn<String> overtimeId = GeneratedColumn<String>(
    'overtime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overtimeDateMeta = const VerificationMeta(
    'overtimeDate',
  );
  @override
  late final GeneratedColumn<String> overtimeDate = GeneratedColumn<String>(
    'overtime_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localWorkDateMeta = const VerificationMeta(
    'localWorkDate',
  );
  @override
  late final GeneratedColumn<String> localWorkDate = GeneratedColumn<String>(
    'local_work_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationTypeMeta = const VerificationMeta(
    'locationType',
  );
  @override
  late final GeneratedColumn<String> locationType = GeneratedColumn<String>(
    'location_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRangeStartMeta = const VerificationMeta(
    'sourceRangeStart',
  );
  @override
  late final GeneratedColumn<String> sourceRangeStart = GeneratedColumn<String>(
    'source_range_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRangeEndMeta = const VerificationMeta(
    'sourceRangeEnd',
  );
  @override
  late final GeneratedColumn<String> sourceRangeEnd = GeneratedColumn<String>(
    'source_range_end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    overtimeId,
    accountId,
    companyId,
    overtimeDate,
    startTime,
    endTime,
    startAtUtc,
    endAtUtc,
    localWorkDate,
    status,
    title,
    reason,
    locationType,
    locationId,
    locationName,
    projectId,
    projectName,
    fetchedAt,
    sourceRangeStart,
    sourceRangeEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_overtime_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceOvertimeReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('overtime_id')) {
      context.handle(
        _overtimeIdMeta,
        overtimeId.isAcceptableOrUnknown(data['overtime_id']!, _overtimeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_overtimeIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('overtime_date')) {
      context.handle(
        _overtimeDateMeta,
        overtimeDate.isAcceptableOrUnknown(
          data['overtime_date']!,
          _overtimeDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overtimeDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('local_work_date')) {
      context.handle(
        _localWorkDateMeta,
        localWorkDate.isAcceptableOrUnknown(
          data['local_work_date']!,
          _localWorkDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localWorkDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('location_type')) {
      context.handle(
        _locationTypeMeta,
        locationType.isAcceptableOrUnknown(
          data['location_type']!,
          _locationTypeMeta,
        ),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('source_range_start')) {
      context.handle(
        _sourceRangeStartMeta,
        sourceRangeStart.isAcceptableOrUnknown(
          data['source_range_start']!,
          _sourceRangeStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRangeStartMeta);
    }
    if (data.containsKey('source_range_end')) {
      context.handle(
        _sourceRangeEndMeta,
        sourceRangeEnd.isAcceptableOrUnknown(
          data['source_range_end']!,
          _sourceRangeEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRangeEndMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, companyId, overtimeId};
  @override
  AttendanceOvertimeReference map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceOvertimeReference(
      overtimeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overtime_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      overtimeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overtime_date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      localWorkDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_work_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      locationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_type'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      sourceRangeStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_range_start'],
      )!,
      sourceRangeEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_range_end'],
      )!,
    );
  }

  @override
  $AttendanceOvertimeReferencesTable createAlias(String alias) {
    return $AttendanceOvertimeReferencesTable(attachedDatabase, alias);
  }
}

class AttendanceOvertimeReference extends DataClass
    implements Insertable<AttendanceOvertimeReference> {
  final String overtimeId;
  final String accountId;
  final String companyId;
  final String overtimeDate;
  final String startTime;
  final String endTime;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String localWorkDate;
  final String status;
  final String? title;
  final String? reason;
  final String? locationType;
  final String? locationId;
  final String? locationName;
  final String? projectId;
  final String? projectName;
  final DateTime fetchedAt;
  final String sourceRangeStart;
  final String sourceRangeEnd;
  const AttendanceOvertimeReference({
    required this.overtimeId,
    required this.accountId,
    required this.companyId,
    required this.overtimeDate,
    required this.startTime,
    required this.endTime,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.localWorkDate,
    required this.status,
    this.title,
    this.reason,
    this.locationType,
    this.locationId,
    this.locationName,
    this.projectId,
    this.projectName,
    required this.fetchedAt,
    required this.sourceRangeStart,
    required this.sourceRangeEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['overtime_id'] = Variable<String>(overtimeId);
    map['account_id'] = Variable<String>(accountId);
    map['company_id'] = Variable<String>(companyId);
    map['overtime_date'] = Variable<String>(overtimeDate);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    map['local_work_date'] = Variable<String>(localWorkDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || locationType != null) {
      map['location_type'] = Variable<String>(locationType);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['source_range_start'] = Variable<String>(sourceRangeStart);
    map['source_range_end'] = Variable<String>(sourceRangeEnd);
    return map;
  }

  AttendanceOvertimeReferencesCompanion toCompanion(bool nullToAbsent) {
    return AttendanceOvertimeReferencesCompanion(
      overtimeId: Value(overtimeId),
      accountId: Value(accountId),
      companyId: Value(companyId),
      overtimeDate: Value(overtimeDate),
      startTime: Value(startTime),
      endTime: Value(endTime),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      localWorkDate: Value(localWorkDate),
      status: Value(status),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      locationType: locationType == null && nullToAbsent
          ? const Value.absent()
          : Value(locationType),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      fetchedAt: Value(fetchedAt),
      sourceRangeStart: Value(sourceRangeStart),
      sourceRangeEnd: Value(sourceRangeEnd),
    );
  }

  factory AttendanceOvertimeReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceOvertimeReference(
      overtimeId: serializer.fromJson<String>(json['overtimeId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      overtimeDate: serializer.fromJson<String>(json['overtimeDate']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      localWorkDate: serializer.fromJson<String>(json['localWorkDate']),
      status: serializer.fromJson<String>(json['status']),
      title: serializer.fromJson<String?>(json['title']),
      reason: serializer.fromJson<String?>(json['reason']),
      locationType: serializer.fromJson<String?>(json['locationType']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      sourceRangeStart: serializer.fromJson<String>(json['sourceRangeStart']),
      sourceRangeEnd: serializer.fromJson<String>(json['sourceRangeEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'overtimeId': serializer.toJson<String>(overtimeId),
      'accountId': serializer.toJson<String>(accountId),
      'companyId': serializer.toJson<String>(companyId),
      'overtimeDate': serializer.toJson<String>(overtimeDate),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'localWorkDate': serializer.toJson<String>(localWorkDate),
      'status': serializer.toJson<String>(status),
      'title': serializer.toJson<String?>(title),
      'reason': serializer.toJson<String?>(reason),
      'locationType': serializer.toJson<String?>(locationType),
      'locationId': serializer.toJson<String?>(locationId),
      'locationName': serializer.toJson<String?>(locationName),
      'projectId': serializer.toJson<String?>(projectId),
      'projectName': serializer.toJson<String?>(projectName),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'sourceRangeStart': serializer.toJson<String>(sourceRangeStart),
      'sourceRangeEnd': serializer.toJson<String>(sourceRangeEnd),
    };
  }

  AttendanceOvertimeReference copyWith({
    String? overtimeId,
    String? accountId,
    String? companyId,
    String? overtimeDate,
    String? startTime,
    String? endTime,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    String? localWorkDate,
    String? status,
    Value<String?> title = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<String?> locationType = const Value.absent(),
    Value<String?> locationId = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    Value<String?> projectName = const Value.absent(),
    DateTime? fetchedAt,
    String? sourceRangeStart,
    String? sourceRangeEnd,
  }) => AttendanceOvertimeReference(
    overtimeId: overtimeId ?? this.overtimeId,
    accountId: accountId ?? this.accountId,
    companyId: companyId ?? this.companyId,
    overtimeDate: overtimeDate ?? this.overtimeDate,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    localWorkDate: localWorkDate ?? this.localWorkDate,
    status: status ?? this.status,
    title: title.present ? title.value : this.title,
    reason: reason.present ? reason.value : this.reason,
    locationType: locationType.present ? locationType.value : this.locationType,
    locationId: locationId.present ? locationId.value : this.locationId,
    locationName: locationName.present ? locationName.value : this.locationName,
    projectId: projectId.present ? projectId.value : this.projectId,
    projectName: projectName.present ? projectName.value : this.projectName,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    sourceRangeStart: sourceRangeStart ?? this.sourceRangeStart,
    sourceRangeEnd: sourceRangeEnd ?? this.sourceRangeEnd,
  );
  AttendanceOvertimeReference copyWithCompanion(
    AttendanceOvertimeReferencesCompanion data,
  ) {
    return AttendanceOvertimeReference(
      overtimeId: data.overtimeId.present
          ? data.overtimeId.value
          : this.overtimeId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      overtimeDate: data.overtimeDate.present
          ? data.overtimeDate.value
          : this.overtimeDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      localWorkDate: data.localWorkDate.present
          ? data.localWorkDate.value
          : this.localWorkDate,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      reason: data.reason.present ? data.reason.value : this.reason,
      locationType: data.locationType.present
          ? data.locationType.value
          : this.locationType,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      sourceRangeStart: data.sourceRangeStart.present
          ? data.sourceRangeStart.value
          : this.sourceRangeStart,
      sourceRangeEnd: data.sourceRangeEnd.present
          ? data.sourceRangeEnd.value
          : this.sourceRangeEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceOvertimeReference(')
          ..write('overtimeId: $overtimeId, ')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('overtimeDate: $overtimeDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('localWorkDate: $localWorkDate, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('reason: $reason, ')
          ..write('locationType: $locationType, ')
          ..write('locationId: $locationId, ')
          ..write('locationName: $locationName, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('sourceRangeStart: $sourceRangeStart, ')
          ..write('sourceRangeEnd: $sourceRangeEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    overtimeId,
    accountId,
    companyId,
    overtimeDate,
    startTime,
    endTime,
    startAtUtc,
    endAtUtc,
    localWorkDate,
    status,
    title,
    reason,
    locationType,
    locationId,
    locationName,
    projectId,
    projectName,
    fetchedAt,
    sourceRangeStart,
    sourceRangeEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceOvertimeReference &&
          other.overtimeId == this.overtimeId &&
          other.accountId == this.accountId &&
          other.companyId == this.companyId &&
          other.overtimeDate == this.overtimeDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.localWorkDate == this.localWorkDate &&
          other.status == this.status &&
          other.title == this.title &&
          other.reason == this.reason &&
          other.locationType == this.locationType &&
          other.locationId == this.locationId &&
          other.locationName == this.locationName &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.fetchedAt == this.fetchedAt &&
          other.sourceRangeStart == this.sourceRangeStart &&
          other.sourceRangeEnd == this.sourceRangeEnd);
}

class AttendanceOvertimeReferencesCompanion
    extends UpdateCompanion<AttendanceOvertimeReference> {
  final Value<String> overtimeId;
  final Value<String> accountId;
  final Value<String> companyId;
  final Value<String> overtimeDate;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<String> localWorkDate;
  final Value<String> status;
  final Value<String?> title;
  final Value<String?> reason;
  final Value<String?> locationType;
  final Value<String?> locationId;
  final Value<String?> locationName;
  final Value<String?> projectId;
  final Value<String?> projectName;
  final Value<DateTime> fetchedAt;
  final Value<String> sourceRangeStart;
  final Value<String> sourceRangeEnd;
  final Value<int> rowid;
  const AttendanceOvertimeReferencesCompanion({
    this.overtimeId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.overtimeDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.localWorkDate = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.reason = const Value.absent(),
    this.locationType = const Value.absent(),
    this.locationId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.sourceRangeStart = const Value.absent(),
    this.sourceRangeEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceOvertimeReferencesCompanion.insert({
    required String overtimeId,
    required String accountId,
    required String companyId,
    required String overtimeDate,
    required String startTime,
    required String endTime,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required String localWorkDate,
    required String status,
    this.title = const Value.absent(),
    this.reason = const Value.absent(),
    this.locationType = const Value.absent(),
    this.locationId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    required DateTime fetchedAt,
    required String sourceRangeStart,
    required String sourceRangeEnd,
    this.rowid = const Value.absent(),
  }) : overtimeId = Value(overtimeId),
       accountId = Value(accountId),
       companyId = Value(companyId),
       overtimeDate = Value(overtimeDate),
       startTime = Value(startTime),
       endTime = Value(endTime),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       localWorkDate = Value(localWorkDate),
       status = Value(status),
       fetchedAt = Value(fetchedAt),
       sourceRangeStart = Value(sourceRangeStart),
       sourceRangeEnd = Value(sourceRangeEnd);
  static Insertable<AttendanceOvertimeReference> custom({
    Expression<String>? overtimeId,
    Expression<String>? accountId,
    Expression<String>? companyId,
    Expression<String>? overtimeDate,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<String>? localWorkDate,
    Expression<String>? status,
    Expression<String>? title,
    Expression<String>? reason,
    Expression<String>? locationType,
    Expression<String>? locationId,
    Expression<String>? locationName,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<DateTime>? fetchedAt,
    Expression<String>? sourceRangeStart,
    Expression<String>? sourceRangeEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (overtimeId != null) 'overtime_id': overtimeId,
      if (accountId != null) 'account_id': accountId,
      if (companyId != null) 'company_id': companyId,
      if (overtimeDate != null) 'overtime_date': overtimeDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (localWorkDate != null) 'local_work_date': localWorkDate,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (reason != null) 'reason': reason,
      if (locationType != null) 'location_type': locationType,
      if (locationId != null) 'location_id': locationId,
      if (locationName != null) 'location_name': locationName,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (sourceRangeStart != null) 'source_range_start': sourceRangeStart,
      if (sourceRangeEnd != null) 'source_range_end': sourceRangeEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceOvertimeReferencesCompanion copyWith({
    Value<String>? overtimeId,
    Value<String>? accountId,
    Value<String>? companyId,
    Value<String>? overtimeDate,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<String>? localWorkDate,
    Value<String>? status,
    Value<String?>? title,
    Value<String?>? reason,
    Value<String?>? locationType,
    Value<String?>? locationId,
    Value<String?>? locationName,
    Value<String?>? projectId,
    Value<String?>? projectName,
    Value<DateTime>? fetchedAt,
    Value<String>? sourceRangeStart,
    Value<String>? sourceRangeEnd,
    Value<int>? rowid,
  }) {
    return AttendanceOvertimeReferencesCompanion(
      overtimeId: overtimeId ?? this.overtimeId,
      accountId: accountId ?? this.accountId,
      companyId: companyId ?? this.companyId,
      overtimeDate: overtimeDate ?? this.overtimeDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      localWorkDate: localWorkDate ?? this.localWorkDate,
      status: status ?? this.status,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      locationType: locationType ?? this.locationType,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      sourceRangeStart: sourceRangeStart ?? this.sourceRangeStart,
      sourceRangeEnd: sourceRangeEnd ?? this.sourceRangeEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (overtimeId.present) {
      map['overtime_id'] = Variable<String>(overtimeId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (overtimeDate.present) {
      map['overtime_date'] = Variable<String>(overtimeDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (localWorkDate.present) {
      map['local_work_date'] = Variable<String>(localWorkDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (locationType.present) {
      map['location_type'] = Variable<String>(locationType.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (sourceRangeStart.present) {
      map['source_range_start'] = Variable<String>(sourceRangeStart.value);
    }
    if (sourceRangeEnd.present) {
      map['source_range_end'] = Variable<String>(sourceRangeEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceOvertimeReferencesCompanion(')
          ..write('overtimeId: $overtimeId, ')
          ..write('accountId: $accountId, ')
          ..write('companyId: $companyId, ')
          ..write('overtimeDate: $overtimeDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('localWorkDate: $localWorkDate, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('reason: $reason, ')
          ..write('locationType: $locationType, ')
          ..write('locationId: $locationId, ')
          ..write('locationName: $locationName, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('sourceRangeStart: $sourceRangeStart, ')
          ..write('sourceRangeEnd: $sourceRangeEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxOperationsTable outboxOperations = $OutboxOperationsTable(
    this,
  );
  late final $OutboxAttachmentsTable outboxAttachments =
      $OutboxAttachmentsTable(this);
  late final $ApiCacheTable apiCache = $ApiCacheTable(this);
  late final $AttendanceDaySnapshotsTable attendanceDaySnapshots =
      $AttendanceDaySnapshotsTable(this);
  late final $AttendanceOvertimeReferencesTable attendanceOvertimeReferences =
      $AttendanceOvertimeReferencesTable(this);
  late final Index outboxRetryIdx = Index(
    'outbox_retry_idx',
    'CREATE INDEX outbox_retry_idx ON outbox_operations (state, next_attempt_at)',
  );
  late final Index outboxScopeIdx = Index(
    'outbox_scope_idx',
    'CREATE INDEX outbox_scope_idx ON outbox_operations (account_id, company_id)',
  );
  late final Index outboxResourceIdx = Index(
    'outbox_resource_idx',
    'CREATE INDEX outbox_resource_idx ON outbox_operations (target_resource_key)',
  );
  late final Index outboxCreatedIdx = Index(
    'outbox_created_idx',
    'CREATE INDEX outbox_created_idx ON outbox_operations (created_at)',
  );
  late final Index outboxAttendanceScopeIdx = Index(
    'outbox_attendance_scope_idx',
    'CREATE INDEX outbox_attendance_scope_idx ON outbox_operations (account_id, company_id, operation_type, state)',
  );
  late final Index attachmentOperationIdx = Index(
    'attachment_operation_idx',
    'CREATE INDEX attachment_operation_idx ON outbox_attachments (operation_id)',
  );
  late final Index cacheScopeIdx = Index(
    'cache_scope_idx',
    'CREATE INDEX cache_scope_idx ON api_cache (account_id, company_id)',
  );
  late final Index cacheExpiryIdx = Index(
    'cache_expiry_idx',
    'CREATE INDEX cache_expiry_idx ON api_cache (expires_at)',
  );
  late final Index attendanceSnapshotScopeIdx = Index(
    'attendance_snapshot_scope_idx',
    'CREATE INDEX attendance_snapshot_scope_idx ON attendance_day_snapshots (account_id, company_id, attendance_date)',
  );
  late final Index attendanceOvertimeWorkDateIdx = Index(
    'attendance_overtime_work_date_idx',
    'CREATE INDEX attendance_overtime_work_date_idx ON attendance_overtime_references (account_id, company_id, local_work_date, status)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxOperations,
    outboxAttachments,
    apiCache,
    attendanceDaySnapshots,
    attendanceOvertimeReferences,
    outboxRetryIdx,
    outboxScopeIdx,
    outboxResourceIdx,
    outboxCreatedIdx,
    outboxAttendanceScopeIdx,
    attachmentOperationIdx,
    cacheScopeIdx,
    cacheExpiryIdx,
    attendanceSnapshotScopeIdx,
    attendanceOvertimeWorkDateIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'outbox_operations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('outbox_attachments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$OutboxOperationsTableCreateCompanionBuilder =
    OutboxOperationsCompanion Function({
      required String operationId,
      required String idempotencyKey,
      required String accountId,
      required String companyId,
      required String operationType,
      required String targetResourceKey,
      required String endpoint,
      Value<String> httpMethod,
      required String payloadJson,
      Value<int> payloadVersion,
      Value<String> state,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> processingStartedAt,
      Value<String?> dependsOnOperationId,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OutboxOperationsTableUpdateCompanionBuilder =
    OutboxOperationsCompanion Function({
      Value<String> operationId,
      Value<String> idempotencyKey,
      Value<String> accountId,
      Value<String> companyId,
      Value<String> operationType,
      Value<String> targetResourceKey,
      Value<String> endpoint,
      Value<String> httpMethod,
      Value<String> payloadJson,
      Value<int> payloadVersion,
      Value<String> state,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> processingStartedAt,
      Value<String?> dependsOnOperationId,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$OutboxOperationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $OutboxOperationsTable, OutboxOperation> {
  $$OutboxOperationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$OutboxAttachmentsTable, List<OutboxAttachment>>
  _outboxAttachmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.outboxAttachments,
        aliasName: $_aliasNameGenerator(
          db.outboxOperations.operationId,
          db.outboxAttachments.operationId,
        ),
      );

  $$OutboxAttachmentsTableProcessedTableManager get outboxAttachmentsRefs {
    final manager =
        $$OutboxAttachmentsTableTableManager(
          $_db,
          $_db.outboxAttachments,
        ).filter(
          (f) => f.operationId.operationId.sqlEquals(
            $_itemColumn<String>('operation_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _outboxAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OutboxOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetResourceKey => $composableBuilder(
    column: $table.targetResourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processingStartedAt => $composableBuilder(
    column: $table.processingStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOnOperationId => $composableBuilder(
    column: $table.dependsOnOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> outboxAttachmentsRefs(
    Expression<bool> Function($$OutboxAttachmentsTableFilterComposer f) f,
  ) {
    final $$OutboxAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.outboxAttachments,
      getReferencedColumn: (t) => t.operationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.outboxAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OutboxOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetResourceKey => $composableBuilder(
    column: $table.targetResourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processingStartedAt => $composableBuilder(
    column: $table.processingStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOnOperationId => $composableBuilder(
    column: $table.dependsOnOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetResourceKey => $composableBuilder(
    column: $table.targetResourceKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get processingStartedAt => $composableBuilder(
    column: $table.processingStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOnOperationId => $composableBuilder(
    column: $table.dependsOnOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> outboxAttachmentsRefs<T extends Object>(
    Expression<T> Function($$OutboxAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$OutboxAttachmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.operationId,
          referencedTable: $db.outboxAttachments,
          getReferencedColumn: (t) => t.operationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OutboxAttachmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.outboxAttachments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OutboxOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxOperationsTable,
          OutboxOperation,
          $$OutboxOperationsTableFilterComposer,
          $$OutboxOperationsTableOrderingComposer,
          $$OutboxOperationsTableAnnotationComposer,
          $$OutboxOperationsTableCreateCompanionBuilder,
          $$OutboxOperationsTableUpdateCompanionBuilder,
          (OutboxOperation, $$OutboxOperationsTableReferences),
          OutboxOperation,
          PrefetchHooks Function({bool outboxAttachmentsRefs})
        > {
  $$OutboxOperationsTableTableManager(
    _$AppDatabase db,
    $OutboxOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> targetResourceKey = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> httpMethod = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> payloadVersion = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> processingStartedAt = const Value.absent(),
                Value<String?> dependsOnOperationId = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxOperationsCompanion(
                operationId: operationId,
                idempotencyKey: idempotencyKey,
                accountId: accountId,
                companyId: companyId,
                operationType: operationType,
                targetResourceKey: targetResourceKey,
                endpoint: endpoint,
                httpMethod: httpMethod,
                payloadJson: payloadJson,
                payloadVersion: payloadVersion,
                state: state,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                processingStartedAt: processingStartedAt,
                dependsOnOperationId: dependsOnOperationId,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String idempotencyKey,
                required String accountId,
                required String companyId,
                required String operationType,
                required String targetResourceKey,
                required String endpoint,
                Value<String> httpMethod = const Value.absent(),
                required String payloadJson,
                Value<int> payloadVersion = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> processingStartedAt = const Value.absent(),
                Value<String?> dependsOnOperationId = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxOperationsCompanion.insert(
                operationId: operationId,
                idempotencyKey: idempotencyKey,
                accountId: accountId,
                companyId: companyId,
                operationType: operationType,
                targetResourceKey: targetResourceKey,
                endpoint: endpoint,
                httpMethod: httpMethod,
                payloadJson: payloadJson,
                payloadVersion: payloadVersion,
                state: state,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                processingStartedAt: processingStartedAt,
                dependsOnOperationId: dependsOnOperationId,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OutboxOperationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({outboxAttachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (outboxAttachmentsRefs) db.outboxAttachments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (outboxAttachmentsRefs)
                    await $_getPrefetchedData<
                      OutboxOperation,
                      $OutboxOperationsTable,
                      OutboxAttachment
                    >(
                      currentTable: table,
                      referencedTable: $$OutboxOperationsTableReferences
                          ._outboxAttachmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OutboxOperationsTableReferences(
                            db,
                            table,
                            p0,
                          ).outboxAttachmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.operationId == item.operationId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$OutboxOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxOperationsTable,
      OutboxOperation,
      $$OutboxOperationsTableFilterComposer,
      $$OutboxOperationsTableOrderingComposer,
      $$OutboxOperationsTableAnnotationComposer,
      $$OutboxOperationsTableCreateCompanionBuilder,
      $$OutboxOperationsTableUpdateCompanionBuilder,
      (OutboxOperation, $$OutboxOperationsTableReferences),
      OutboxOperation,
      PrefetchHooks Function({bool outboxAttachmentsRefs})
    >;
typedef $$OutboxAttachmentsTableCreateCompanionBuilder =
    OutboxAttachmentsCompanion Function({
      required String attachmentId,
      required String operationId,
      required String fieldName,
      required String durablePath,
      required String originalName,
      required String mimeType,
      required int sizeBytes,
      required String checksum,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$OutboxAttachmentsTableUpdateCompanionBuilder =
    OutboxAttachmentsCompanion Function({
      Value<String> attachmentId,
      Value<String> operationId,
      Value<String> fieldName,
      Value<String> durablePath,
      Value<String> originalName,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<String> checksum,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$OutboxAttachmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OutboxAttachmentsTable,
          OutboxAttachment
        > {
  $$OutboxAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OutboxOperationsTable _operationIdTable(_$AppDatabase db) =>
      db.outboxOperations.createAlias(
        $_aliasNameGenerator(
          db.outboxAttachments.operationId,
          db.outboxOperations.operationId,
        ),
      );

  $$OutboxOperationsTableProcessedTableManager get operationId {
    final $_column = $_itemColumn<String>('operation_id')!;

    final manager = $$OutboxOperationsTableTableManager(
      $_db,
      $_db.outboxOperations,
    ).filter((f) => f.operationId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutboxAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxAttachmentsTable> {
  $$OutboxAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durablePath => $composableBuilder(
    column: $table.durablePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OutboxOperationsTableFilterComposer get operationId {
    final $$OutboxOperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.outboxOperations,
      getReferencedColumn: (t) => t.operationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxOperationsTableFilterComposer(
            $db: $db,
            $table: $db.outboxOperations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxAttachmentsTable> {
  $$OutboxAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durablePath => $composableBuilder(
    column: $table.durablePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OutboxOperationsTableOrderingComposer get operationId {
    final $$OutboxOperationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.outboxOperations,
      getReferencedColumn: (t) => t.operationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxOperationsTableOrderingComposer(
            $db: $db,
            $table: $db.outboxOperations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxAttachmentsTable> {
  $$OutboxAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get durablePath => $composableBuilder(
    column: $table.durablePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OutboxOperationsTableAnnotationComposer get operationId {
    final $$OutboxOperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.outboxOperations,
      getReferencedColumn: (t) => t.operationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxOperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.outboxOperations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxAttachmentsTable,
          OutboxAttachment,
          $$OutboxAttachmentsTableFilterComposer,
          $$OutboxAttachmentsTableOrderingComposer,
          $$OutboxAttachmentsTableAnnotationComposer,
          $$OutboxAttachmentsTableCreateCompanionBuilder,
          $$OutboxAttachmentsTableUpdateCompanionBuilder,
          (OutboxAttachment, $$OutboxAttachmentsTableReferences),
          OutboxAttachment,
          PrefetchHooks Function({bool operationId})
        > {
  $$OutboxAttachmentsTableTableManager(
    _$AppDatabase db,
    $OutboxAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> attachmentId = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> durablePath = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxAttachmentsCompanion(
                attachmentId: attachmentId,
                operationId: operationId,
                fieldName: fieldName,
                durablePath: durablePath,
                originalName: originalName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                checksum: checksum,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attachmentId,
                required String operationId,
                required String fieldName,
                required String durablePath,
                required String originalName,
                required String mimeType,
                required int sizeBytes,
                required String checksum,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxAttachmentsCompanion.insert(
                attachmentId: attachmentId,
                operationId: operationId,
                fieldName: fieldName,
                durablePath: durablePath,
                originalName: originalName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                checksum: checksum,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OutboxAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({operationId = false}) {
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
                    if (operationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.operationId,
                                referencedTable:
                                    $$OutboxAttachmentsTableReferences
                                        ._operationIdTable(db),
                                referencedColumn:
                                    $$OutboxAttachmentsTableReferences
                                        ._operationIdTable(db)
                                        .operationId,
                              )
                              as T;
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

typedef $$OutboxAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxAttachmentsTable,
      OutboxAttachment,
      $$OutboxAttachmentsTableFilterComposer,
      $$OutboxAttachmentsTableOrderingComposer,
      $$OutboxAttachmentsTableAnnotationComposer,
      $$OutboxAttachmentsTableCreateCompanionBuilder,
      $$OutboxAttachmentsTableUpdateCompanionBuilder,
      (OutboxAttachment, $$OutboxAttachmentsTableReferences),
      OutboxAttachment,
      PrefetchHooks Function({bool operationId})
    >;
typedef $$ApiCacheTableCreateCompanionBuilder =
    ApiCacheCompanion Function({
      required String cacheKey,
      required String accountId,
      required String companyId,
      required String endpointKey,
      required String queryHash,
      required String payloadJson,
      required DateTime fetchedAt,
      Value<DateTime?> expiresAt,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$ApiCacheTableUpdateCompanionBuilder =
    ApiCacheCompanion Function({
      Value<String> cacheKey,
      Value<String> accountId,
      Value<String> companyId,
      Value<String> endpointKey,
      Value<String> queryHash,
      Value<String> payloadJson,
      Value<DateTime> fetchedAt,
      Value<DateTime?> expiresAt,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$ApiCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpointKey => $composableBuilder(
    column: $table.endpointKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queryHash => $composableBuilder(
    column: $table.queryHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpointKey => $composableBuilder(
    column: $table.endpointKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queryHash => $composableBuilder(
    column: $table.queryHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get endpointKey => $composableBuilder(
    column: $table.endpointKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$ApiCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiCacheTable,
          ApiCacheData,
          $$ApiCacheTableFilterComposer,
          $$ApiCacheTableOrderingComposer,
          $$ApiCacheTableAnnotationComposer,
          $$ApiCacheTableCreateCompanionBuilder,
          $$ApiCacheTableUpdateCompanionBuilder,
          (
            ApiCacheData,
            BaseReferences<_$AppDatabase, $ApiCacheTable, ApiCacheData>,
          ),
          ApiCacheData,
          PrefetchHooks Function()
        > {
  $$ApiCacheTableTableManager(_$AppDatabase db, $ApiCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> endpointKey = const Value.absent(),
                Value<String> queryHash = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheCompanion(
                cacheKey: cacheKey,
                accountId: accountId,
                companyId: companyId,
                endpointKey: endpointKey,
                queryHash: queryHash,
                payloadJson: payloadJson,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String accountId,
                required String companyId,
                required String endpointKey,
                required String queryHash,
                required String payloadJson,
                required DateTime fetchedAt,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheCompanion.insert(
                cacheKey: cacheKey,
                accountId: accountId,
                companyId: companyId,
                endpointKey: endpointKey,
                queryHash: queryHash,
                payloadJson: payloadJson,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiCacheTable,
      ApiCacheData,
      $$ApiCacheTableFilterComposer,
      $$ApiCacheTableOrderingComposer,
      $$ApiCacheTableAnnotationComposer,
      $$ApiCacheTableCreateCompanionBuilder,
      $$ApiCacheTableUpdateCompanionBuilder,
      (
        ApiCacheData,
        BaseReferences<_$AppDatabase, $ApiCacheTable, ApiCacheData>,
      ),
      ApiCacheData,
      PrefetchHooks Function()
    >;
typedef $$AttendanceDaySnapshotsTableCreateCompanionBuilder =
    AttendanceDaySnapshotsCompanion Function({
      required String accountId,
      required String companyId,
      required String attendanceDate,
      required String payloadJson,
      Value<DateTime?> serverTime,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$AttendanceDaySnapshotsTableUpdateCompanionBuilder =
    AttendanceDaySnapshotsCompanion Function({
      Value<String> accountId,
      Value<String> companyId,
      Value<String> attendanceDate,
      Value<String> payloadJson,
      Value<DateTime?> serverTime,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$AttendanceDaySnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceDaySnapshotsTable> {
  $$AttendanceDaySnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attendanceDate => $composableBuilder(
    column: $table.attendanceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceDaySnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceDaySnapshotsTable> {
  $$AttendanceDaySnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attendanceDate => $composableBuilder(
    column: $table.attendanceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceDaySnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceDaySnapshotsTable> {
  $$AttendanceDaySnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get attendanceDate => $composableBuilder(
    column: $table.attendanceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$AttendanceDaySnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceDaySnapshotsTable,
          AttendanceDaySnapshot,
          $$AttendanceDaySnapshotsTableFilterComposer,
          $$AttendanceDaySnapshotsTableOrderingComposer,
          $$AttendanceDaySnapshotsTableAnnotationComposer,
          $$AttendanceDaySnapshotsTableCreateCompanionBuilder,
          $$AttendanceDaySnapshotsTableUpdateCompanionBuilder,
          (
            AttendanceDaySnapshot,
            BaseReferences<
              _$AppDatabase,
              $AttendanceDaySnapshotsTable,
              AttendanceDaySnapshot
            >,
          ),
          AttendanceDaySnapshot,
          PrefetchHooks Function()
        > {
  $$AttendanceDaySnapshotsTableTableManager(
    _$AppDatabase db,
    $AttendanceDaySnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceDaySnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceDaySnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceDaySnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> attendanceDate = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime?> serverTime = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceDaySnapshotsCompanion(
                accountId: accountId,
                companyId: companyId,
                attendanceDate: attendanceDate,
                payloadJson: payloadJson,
                serverTime: serverTime,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String companyId,
                required String attendanceDate,
                required String payloadJson,
                Value<DateTime?> serverTime = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceDaySnapshotsCompanion.insert(
                accountId: accountId,
                companyId: companyId,
                attendanceDate: attendanceDate,
                payloadJson: payloadJson,
                serverTime: serverTime,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceDaySnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceDaySnapshotsTable,
      AttendanceDaySnapshot,
      $$AttendanceDaySnapshotsTableFilterComposer,
      $$AttendanceDaySnapshotsTableOrderingComposer,
      $$AttendanceDaySnapshotsTableAnnotationComposer,
      $$AttendanceDaySnapshotsTableCreateCompanionBuilder,
      $$AttendanceDaySnapshotsTableUpdateCompanionBuilder,
      (
        AttendanceDaySnapshot,
        BaseReferences<
          _$AppDatabase,
          $AttendanceDaySnapshotsTable,
          AttendanceDaySnapshot
        >,
      ),
      AttendanceDaySnapshot,
      PrefetchHooks Function()
    >;
typedef $$AttendanceOvertimeReferencesTableCreateCompanionBuilder =
    AttendanceOvertimeReferencesCompanion Function({
      required String overtimeId,
      required String accountId,
      required String companyId,
      required String overtimeDate,
      required String startTime,
      required String endTime,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      required String localWorkDate,
      required String status,
      Value<String?> title,
      Value<String?> reason,
      Value<String?> locationType,
      Value<String?> locationId,
      Value<String?> locationName,
      Value<String?> projectId,
      Value<String?> projectName,
      required DateTime fetchedAt,
      required String sourceRangeStart,
      required String sourceRangeEnd,
      Value<int> rowid,
    });
typedef $$AttendanceOvertimeReferencesTableUpdateCompanionBuilder =
    AttendanceOvertimeReferencesCompanion Function({
      Value<String> overtimeId,
      Value<String> accountId,
      Value<String> companyId,
      Value<String> overtimeDate,
      Value<String> startTime,
      Value<String> endTime,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<String> localWorkDate,
      Value<String> status,
      Value<String?> title,
      Value<String?> reason,
      Value<String?> locationType,
      Value<String?> locationId,
      Value<String?> locationName,
      Value<String?> projectId,
      Value<String?> projectName,
      Value<DateTime> fetchedAt,
      Value<String> sourceRangeStart,
      Value<String> sourceRangeEnd,
      Value<int> rowid,
    });

class $$AttendanceOvertimeReferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceOvertimeReferencesTable> {
  $$AttendanceOvertimeReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get overtimeId => $composableBuilder(
    column: $table.overtimeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overtimeDate => $composableBuilder(
    column: $table.overtimeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localWorkDate => $composableBuilder(
    column: $table.localWorkDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationType => $composableBuilder(
    column: $table.locationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRangeStart => $composableBuilder(
    column: $table.sourceRangeStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRangeEnd => $composableBuilder(
    column: $table.sourceRangeEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceOvertimeReferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceOvertimeReferencesTable> {
  $$AttendanceOvertimeReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get overtimeId => $composableBuilder(
    column: $table.overtimeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overtimeDate => $composableBuilder(
    column: $table.overtimeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localWorkDate => $composableBuilder(
    column: $table.localWorkDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationType => $composableBuilder(
    column: $table.locationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRangeStart => $composableBuilder(
    column: $table.sourceRangeStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRangeEnd => $composableBuilder(
    column: $table.sourceRangeEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceOvertimeReferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceOvertimeReferencesTable> {
  $$AttendanceOvertimeReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get overtimeId => $composableBuilder(
    column: $table.overtimeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get overtimeDate => $composableBuilder(
    column: $table.overtimeDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<String> get localWorkDate => $composableBuilder(
    column: $table.localWorkDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get locationType => $composableBuilder(
    column: $table.locationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get sourceRangeStart => $composableBuilder(
    column: $table.sourceRangeStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRangeEnd => $composableBuilder(
    column: $table.sourceRangeEnd,
    builder: (column) => column,
  );
}

class $$AttendanceOvertimeReferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceOvertimeReferencesTable,
          AttendanceOvertimeReference,
          $$AttendanceOvertimeReferencesTableFilterComposer,
          $$AttendanceOvertimeReferencesTableOrderingComposer,
          $$AttendanceOvertimeReferencesTableAnnotationComposer,
          $$AttendanceOvertimeReferencesTableCreateCompanionBuilder,
          $$AttendanceOvertimeReferencesTableUpdateCompanionBuilder,
          (
            AttendanceOvertimeReference,
            BaseReferences<
              _$AppDatabase,
              $AttendanceOvertimeReferencesTable,
              AttendanceOvertimeReference
            >,
          ),
          AttendanceOvertimeReference,
          PrefetchHooks Function()
        > {
  $$AttendanceOvertimeReferencesTableTableManager(
    _$AppDatabase db,
    $AttendanceOvertimeReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceOvertimeReferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceOvertimeReferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceOvertimeReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> overtimeId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> overtimeDate = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<String> localWorkDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> locationType = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String> sourceRangeStart = const Value.absent(),
                Value<String> sourceRangeEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceOvertimeReferencesCompanion(
                overtimeId: overtimeId,
                accountId: accountId,
                companyId: companyId,
                overtimeDate: overtimeDate,
                startTime: startTime,
                endTime: endTime,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                localWorkDate: localWorkDate,
                status: status,
                title: title,
                reason: reason,
                locationType: locationType,
                locationId: locationId,
                locationName: locationName,
                projectId: projectId,
                projectName: projectName,
                fetchedAt: fetchedAt,
                sourceRangeStart: sourceRangeStart,
                sourceRangeEnd: sourceRangeEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String overtimeId,
                required String accountId,
                required String companyId,
                required String overtimeDate,
                required String startTime,
                required String endTime,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                required String localWorkDate,
                required String status,
                Value<String?> title = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> locationType = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                required DateTime fetchedAt,
                required String sourceRangeStart,
                required String sourceRangeEnd,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceOvertimeReferencesCompanion.insert(
                overtimeId: overtimeId,
                accountId: accountId,
                companyId: companyId,
                overtimeDate: overtimeDate,
                startTime: startTime,
                endTime: endTime,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                localWorkDate: localWorkDate,
                status: status,
                title: title,
                reason: reason,
                locationType: locationType,
                locationId: locationId,
                locationName: locationName,
                projectId: projectId,
                projectName: projectName,
                fetchedAt: fetchedAt,
                sourceRangeStart: sourceRangeStart,
                sourceRangeEnd: sourceRangeEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceOvertimeReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceOvertimeReferencesTable,
      AttendanceOvertimeReference,
      $$AttendanceOvertimeReferencesTableFilterComposer,
      $$AttendanceOvertimeReferencesTableOrderingComposer,
      $$AttendanceOvertimeReferencesTableAnnotationComposer,
      $$AttendanceOvertimeReferencesTableCreateCompanionBuilder,
      $$AttendanceOvertimeReferencesTableUpdateCompanionBuilder,
      (
        AttendanceOvertimeReference,
        BaseReferences<
          _$AppDatabase,
          $AttendanceOvertimeReferencesTable,
          AttendanceOvertimeReference
        >,
      ),
      AttendanceOvertimeReference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxOperationsTableTableManager get outboxOperations =>
      $$OutboxOperationsTableTableManager(_db, _db.outboxOperations);
  $$OutboxAttachmentsTableTableManager get outboxAttachments =>
      $$OutboxAttachmentsTableTableManager(_db, _db.outboxAttachments);
  $$ApiCacheTableTableManager get apiCache =>
      $$ApiCacheTableTableManager(_db, _db.apiCache);
  $$AttendanceDaySnapshotsTableTableManager get attendanceDaySnapshots =>
      $$AttendanceDaySnapshotsTableTableManager(
        _db,
        _db.attendanceDaySnapshots,
      );
  $$AttendanceOvertimeReferencesTableTableManager
  get attendanceOvertimeReferences =>
      $$AttendanceOvertimeReferencesTableTableManager(
        _db,
        _db.attendanceOvertimeReferences,
      );
}
