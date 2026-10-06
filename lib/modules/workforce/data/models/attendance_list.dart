import 'package:json_annotation/json_annotation.dart';

import '../../../../shared/utils/date_formatter.dart';

part 'attendance_list.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendanceListResult {
  const AttendanceListResult({
    required this.records,
    required this.meta,
    required this.links,
  });

  final List<AttendanceRecord> records;
  final AttendancePaginationMeta meta;
  final AttendancePaginationLinks links;

  factory AttendanceListResult.fromJson(Map<String, dynamic> json) {
    return AttendanceListResult(
      records: _objectList(json['data'], AttendanceRecord.fromJson),
      meta: AttendancePaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      links: AttendancePaginationLinks.fromJson(
        json['links'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => _$AttendanceListResultToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.type,
    required this.attendanceDate,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    required this.locationType,
    required this.location,
    required this.project,
    required this.checkInDistanceMeters,
    required this.checkOutDistanceMeters,
    required this.adminNote,
    required this.clientSessionId,
    required this.checkInOccurredAt,
    required this.checkInSyncedAt,
    required this.checkOutOccurredAt,
    required this.checkOutSyncedAt,
    required this.selfies,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String attendanceDate;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final String locationType;
  final AttendanceReference? location;
  final AttendanceReference? project;
  final int? checkInDistanceMeters;
  final int? checkOutDistanceMeters;
  final String? adminNote;
  final String? clientSessionId;
  final String? checkInOccurredAt;
  final String? checkInSyncedAt;
  final String? checkOutOccurredAt;
  final String? checkOutSyncedAt;
  final AttendanceSelfies? selfies;
  final String? createdAt;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      attendanceDate: json['attendanceDate'] as String? ?? '',
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      status: json['status'] as String? ?? '',
      lateMinutes: _asInt(json['lateMinutes']),
      earlyLeaveMinutes: _asInt(json['earlyLeaveMinutes']),
      locationType: json['locationType'] as String? ?? '',
      location: json['location'] is Map<String, dynamic>
          ? AttendanceReference.fromJson(
              json['location'] as Map<String, dynamic>,
            )
          : null,
      project: json['project'] is Map<String, dynamic>
          ? AttendanceReference.fromJson(
              json['project'] as Map<String, dynamic>,
            )
          : null,
      checkInDistanceMeters: _nullableInt(json['checkInDistanceMeters']),
      checkOutDistanceMeters: _nullableInt(json['checkOutDistanceMeters']),
      adminNote: json['adminNote'] as String?,
      clientSessionId: json['clientSessionId'] as String?,
      checkInOccurredAt: json['checkInOccurredAt'] as String?,
      checkInSyncedAt: json['checkInSyncedAt'] as String?,
      checkOutOccurredAt: json['checkOutOccurredAt'] as String?,
      checkOutSyncedAt: json['checkOutSyncedAt'] as String?,
      selfies: json['selfies'] is Map<String, dynamic>
          ? AttendanceSelfies.fromJson(json['selfies'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String?,
    );
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get displayType {
    return switch (type) {
      'regular' => 'Regular',
      'overtime' => 'Lembur',
      _ => type.isEmpty ? '-' : _capitalize(type.replaceAll('_', ' ')),
    };
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get statusLabel => status;

  Map<String, dynamic> toJson() => _$AttendanceRecordToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendanceSelfies {
  const AttendanceSelfies({required this.checkIn, required this.checkOut});

  final String? checkIn;
  final String? checkOut;

  factory AttendanceSelfies.fromJson(Map<String, dynamic> json) {
    return AttendanceSelfies(
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$AttendanceSelfiesToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendanceReference {
  const AttendanceReference({required this.id, required this.name});

  final String id;
  final String name;

  factory AttendanceReference.fromJson(Map<String, dynamic> json) {
    return AttendanceReference(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$AttendanceReferenceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendancePaginationMeta {
  const AttendancePaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int from;
  final int to;

  factory AttendancePaginationMeta.fromJson(Map<String, dynamic> json) {
    return AttendancePaginationMeta(
      currentPage: _asInt(json['currentPage']),
      perPage: _asInt(json['perPage']),
      total: _asInt(json['total']),
      lastPage: _asInt(json['lastPage']),
      from: _asInt(json['from']),
      to: _asInt(json['to']),
    );
  }

  Map<String, dynamic> toJson() => _$AttendancePaginationMetaToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendancePaginationLinks {
  const AttendancePaginationLinks({
    required this.first,
    required this.last,
    required this.prev,
    required this.next,
  });

  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  factory AttendancePaginationLinks.fromJson(Map<String, dynamic> json) {
    return AttendancePaginationLinks(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$AttendancePaginationLinksToJson(this);
}

class AttendanceListFilter {
  const AttendanceListFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.year,
    this.locationType,
    this.perPage = 15,
  });

  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? year;
  final String? locationType;
  final int perPage;

  int get activeCount {
    return [
      status,
      startDate,
      endDate,
      year,
      locationType,
    ].where((value) => value != null).length;
  }

  AttendanceListFilter copyWith({
    Object? status = _unset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? year = _unset,
    Object? locationType = _unset,
    int? perPage,
  }) {
    return AttendanceListFilter(
      status: status == _unset ? this.status : status as String?,
      startDate: startDate == _unset ? this.startDate : startDate as DateTime?,
      endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
      year: year == _unset ? this.year : year as int?,
      locationType: locationType == _unset
          ? this.locationType
          : locationType as String?,
      perPage: perPage ?? this.perPage,
    );
  }

  Map<String, Object?> toQueryParameters({required int page}) {
    return {
      'status': status,
      'startDate': formatDateParam(startDate),
      'endDate': formatDateParam(endDate),
      'year': year,
      'locationType': locationType,
      'perPage': perPage,
      'page': page,
    }..removeWhere((_, value) => value == null || value == '');
  }
}

class AttendanceListState {
  const AttendanceListState({
    required this.records,
    required this.meta,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<AttendanceRecord> records;
  final AttendancePaginationMeta meta;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => meta.currentPage < meta.lastPage;

  AttendanceListState copyWith({
    List<AttendanceRecord>? records,
    AttendancePaginationMeta? meta,
    bool? isLoadingMore,
    Object? loadMoreError = _unset,
  }) {
    return AttendanceListState(
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

int? _nullableInt(Object? value) {
  if (value == null) return null;
  return _asInt(value);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

extension AttendanceRecordDisplay on AttendanceRecord {
  String get listDate =>
      '${formatIndonesianDate(attendanceDate, shortMonth: true)}'
      '${displayType == '-' ? '' : ' - $displayType'}';
}
