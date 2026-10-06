import 'package:json_annotation/json_annotation.dart';

import 'attendance_list.dart';

import '../../../../shared/utils/date_formatter.dart';

part 'leave.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class LeaveListResult {
  const LeaveListResult({
    required this.records,
    required this.meta,
    required this.links,
  });

  final List<LeaveRecord> records;
  final AttendancePaginationMeta meta;
  final AttendancePaginationLinks links;

  factory LeaveListResult.fromJson(Map<String, dynamic> json) {
    return LeaveListResult(
      records: _objectList(json['data'], LeaveRecord.fromJson),
      meta: AttendancePaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      links: AttendancePaginationLinks.fromJson(
        json['links'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => _$LeaveListResultToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LeaveRecord {
  const LeaveRecord({
    required this.id,
    required this.code,
    required this.reason,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.adminNote,
    required this.balance,
    required this.submittedAt,
    this.apiStatusLabel,
    this.canSubmit,
  });

  final String id;
  final String code;
  final String? reason;
  final LeaveReference? leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String status;
  final String? adminNote;
  final LeaveBalance? balance;
  final String? submittedAt;
  final String? apiStatusLabel;
  final bool? canSubmit;

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      reason: json['reason'] as String?,
      leaveType: json['leaveType'] is Map<String, dynamic>
          ? LeaveReference.fromJson(json['leaveType'] as Map<String, dynamic>)
          : null,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      totalDays: _asInt(json['totalDays']),
      status: json['status'] as String? ?? '',
      adminNote: json['adminNote'] as String?,
      balance: json['balance'] is Map<String, dynamic>
          ? LeaveBalance.fromJson(json['balance'] as Map<String, dynamic>)
          : null,
      submittedAt: json['submittedAt'] as String?,
      apiStatusLabel: json['statusLabel'] as String?,
      canSubmit: json['canSubmit'] as bool?,
    );
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get title {
    final value = reason?.trim();
    if (value != null && value.isNotEmpty) return value;
    return leaveType?.name ?? code;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get statusLabel => apiStatusLabel ?? status;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get normalizedStatus {
    final value = status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    return switch (value) {
      'pending_approval' => 'pending',
      'pendingapproval' => 'pending',
      _ => value,
    };
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get canCancel => canSubmit ?? normalizedStatus == 'pending';

  Map<String, dynamic> toJson() => _$LeaveRecordToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LeaveType {
  const LeaveType({
    required this.id,
    required this.code,
    required this.name,
    required this.isPaid,
    required this.requiresDocument,
    required this.quota,
    required this.balance,
  });

  final String id;
  final String code;
  final String name;
  final bool isPaid;
  final bool requiresDocument;
  final int quota;
  final LeaveBalance? balance;

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isPaid: json['isPaid'] as bool? ?? false,
      requiresDocument: json['requiresDocument'] as bool? ?? false,
      quota: _asInt(json['quota']),
      balance: json['balance'] is Map<String, dynamic>
          ? LeaveBalance.fromJson(json['balance'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$LeaveTypeToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LeaveReference {
  const LeaveReference({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory LeaveReference.fromJson(Map<String, dynamic> json) {
    return LeaveReference(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$LeaveReferenceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class LeaveBalance {
  const LeaveBalance({
    required this.quota,
    required this.used,
    required this.remaining,
  });

  final int quota;
  final int used;
  final int remaining;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      quota: _asInt(json['quota']),
      used: _asInt(json['used']),
      remaining: _asInt(json['remaining']),
    );
  }

  Map<String, dynamic> toJson() => _$LeaveBalanceToJson(this);
}

class LeaveListFilter {
  const LeaveListFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.year,
    this.perPage = 15,
  });

  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? year;
  final int perPage;

  int get activeCount {
    return [
      status,
      startDate,
      endDate,
      year,
    ].where((value) => value != null).length;
  }

  Map<String, Object?> toQueryParameters({required int page}) {
    return {
      'status': status,
      'startDate': formatDateParam(startDate),
      'endDate': formatDateParam(endDate),
      'year': year,
      'perPage': perPage,
      'page': page,
    }..removeWhere((_, value) => value == null || value == '');
  }
}

class LeaveListState {
  const LeaveListState({
    required this.records,
    required this.meta,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<LeaveRecord> records;
  final AttendancePaginationMeta meta;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => meta.currentPage < meta.lastPage;

  LeaveListState copyWith({
    List<LeaveRecord>? records,
    AttendancePaginationMeta? meta,
    bool? isLoadingMore,
    Object? loadMoreError = _unset,
  }) {
    return LeaveListState(
      records: records ?? this.records,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: identical(loadMoreError, _unset)
          ? this.loadMoreError
          : loadMoreError,
    );
  }
}

const _unset = Object();

@JsonSerializable(createFactory: false, explicitToJson: true)
class LeaveRequestInput {
  const LeaveRequestInput({
    required this.leaveTypeId,
    required this.reason,
    required this.startDate,
    required this.endDate,
  });

  final String leaveTypeId;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;

  Map<String, Object?> toJson() {
    final json = _$LeaveRequestInputToJson(this);
    json['startDate'] = formatDateParam(startDate);
    json['endDate'] = formatDateParam(endDate);
    return json;
  }
}

List<T> _objectList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(mapper)
      .toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
