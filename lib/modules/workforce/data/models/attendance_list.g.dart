// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AttendanceListResultToJson(
  AttendanceListResult instance,
) => <String, dynamic>{
  'records': instance.records.map((e) => e.toJson()).toList(),
  'meta': instance.meta.toJson(),
  'links': instance.links.toJson(),
};

Map<String, dynamic> _$AttendanceRecordToJson(AttendanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'attendanceDate': instance.attendanceDate,
      'checkIn': instance.checkIn,
      'checkOut': instance.checkOut,
      'status': instance.status,
      'lateMinutes': instance.lateMinutes,
      'earlyLeaveMinutes': instance.earlyLeaveMinutes,
      'locationType': instance.locationType,
      'location': instance.location?.toJson(),
      'project': instance.project?.toJson(),
      'checkInDistanceMeters': instance.checkInDistanceMeters,
      'checkOutDistanceMeters': instance.checkOutDistanceMeters,
      'adminNote': instance.adminNote,
      'clientSessionId': instance.clientSessionId,
      'checkInOccurredAt': instance.checkInOccurredAt,
      'checkInSyncedAt': instance.checkInSyncedAt,
      'checkOutOccurredAt': instance.checkOutOccurredAt,
      'checkOutSyncedAt': instance.checkOutSyncedAt,
      'selfies': instance.selfies?.toJson(),
      'createdAt': instance.createdAt,
    };

Map<String, dynamic> _$AttendanceSelfiesToJson(AttendanceSelfies instance) =>
    <String, dynamic>{
      'checkIn': instance.checkIn,
      'checkOut': instance.checkOut,
    };

Map<String, dynamic> _$AttendanceReferenceToJson(
  AttendanceReference instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

Map<String, dynamic> _$AttendancePaginationMetaToJson(
  AttendancePaginationMeta instance,
) => <String, dynamic>{
  'currentPage': instance.currentPage,
  'perPage': instance.perPage,
  'total': instance.total,
  'lastPage': instance.lastPage,
  'from': instance.from,
  'to': instance.to,
};

Map<String, dynamic> _$AttendancePaginationLinksToJson(
  AttendancePaginationLinks instance,
) => <String, dynamic>{
  'first': instance.first,
  'last': instance.last,
  'prev': instance.prev,
  'next': instance.next,
};
