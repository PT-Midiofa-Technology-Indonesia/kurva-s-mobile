import 'package:json_annotation/json_annotation.dart';

import '../../../../shared/utils/date_formatter.dart';
import 'attendance_list.dart';

part 'overtime.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class OvertimeListResult {
  const OvertimeListResult({
    required this.records,
    required this.meta,
    required this.links,
  });

  final List<OvertimeRecord> records;
  final AttendancePaginationMeta meta;
  final AttendancePaginationLinks links;

  factory OvertimeListResult.fromJson(Map<String, dynamic> json) {
    return OvertimeListResult(
      records: _objectList(json['data'], OvertimeRecord.fromJson),
      meta: AttendancePaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      links: AttendancePaginationLinks.fromJson(
        json['links'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => _$OvertimeListResultToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class OvertimeRecord {
  const OvertimeRecord({
    required this.id,
    required this.title,
    required this.reason,
    required this.overtimeDate,
    required this.startTime,
    required this.endTime,
    required this.totalMinutes,
    required this.status,
    required this.locationType,
    required this.location,
    required this.project,
    required this.adminNote,
    required this.createdAt,
    this.statusLabel,
    this.canSubmit,
  });

  final String id;
  final String? title;
  final String? reason;
  final String overtimeDate;
  final String startTime;
  final String endTime;
  final int totalMinutes;
  final String status;
  final String locationType;
  final OvertimeReference? location;
  final OvertimeReference? project;
  final String? adminNote;
  final String? createdAt;
  final String? statusLabel;
  final bool? canSubmit;

  factory OvertimeRecord.fromJson(Map<String, dynamic> json) {
    return OvertimeRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      reason: json['reason'] as String?,
      overtimeDate: json['overtimeDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      totalMinutes: _asInt(json['totalMinutes']),
      status: json['status'] as String? ?? '',
      locationType: json['locationType'] as String? ?? '',
      location: json['location'] is Map<String, dynamic>
          ? OvertimeReference.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      project: json['project'] is Map<String, dynamic>
          ? OvertimeReference.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      adminNote: json['adminNote'] as String?,
      createdAt: json['createdAt'] as String?,
      statusLabel: json['statusLabel'] as String?,
      canSubmit: json['canSubmit'] as bool?,
    );
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get displayStatusLabel => statusLabel ?? status;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get canCancel => canSubmit ?? false;

  Map<String, dynamic> toJson() => _$OvertimeRecordToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class OvertimeReference {
  const OvertimeReference({required this.id, required this.name});

  final String id;
  final String name;

  factory OvertimeReference.fromJson(Map<String, dynamic> json) {
    return OvertimeReference(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$OvertimeReferenceToJson(this);
}

class OvertimeListFilter {
  const OvertimeListFilter({
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

class OvertimeListState {
  const OvertimeListState({
    required this.records,
    required this.meta,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<OvertimeRecord> records;
  final AttendancePaginationMeta meta;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => meta.currentPage < meta.lastPage;

  OvertimeListState copyWith({
    List<OvertimeRecord>? records,
    AttendancePaginationMeta? meta,
    bool? isLoadingMore,
    Object? loadMoreError = _unset,
  }) {
    return OvertimeListState(
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
class OvertimeRequestInput {
  const OvertimeRequestInput({
    required this.overtimeDate,
    required this.startTime,
    required this.endTime,
    required this.locationType,
    required this.locationId,
    required this.reason,
    this.projectId,
  });

  final DateTime overtimeDate;
  final String startTime;
  final String endTime;
  final String locationType;
  final String locationId;
  final String? projectId;
  final String reason;

  Map<String, Object?> toJson() {
    final json = _$OvertimeRequestInputToJson(this);
    json['overtimeDate'] = formatDateParam(overtimeDate);
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
