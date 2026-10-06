// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TodayAttendanceToJson(TodayAttendance instance) =>
    <String, dynamic>{
      'date': instance.date,
      'serverTime': instance.serverTime,
      'regular': instance.regular.toJson(),
      'overtime': instance.overtime.toJson(),
    };

Map<String, dynamic> _$RegularAttendanceToJson(RegularAttendance instance) =>
    <String, dynamic>{
      'checkedIn': instance.checkedIn,
      'checkedOut': instance.checkedOut,
      'attendanceId': instance.attendanceId,
      'workplace': instance.workplace?.toJson(),
      'clientSessionId': instance.clientSessionId,
      'checkInOccurredAt': instance.checkInOccurredAt,
      'checkInSyncedAt': instance.checkInSyncedAt,
      'checkOutOccurredAt': instance.checkOutOccurredAt,
      'checkOutSyncedAt': instance.checkOutSyncedAt,
    };

Map<String, dynamic> _$AttendanceWorkplaceToJson(
  AttendanceWorkplace instance,
) => <String, dynamic>{
  'type': instance.type,
  'id': instance.id,
  'name': instance.name,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'radiusMeters': instance.radiusMeters,
  'workStartTime': instance.workStartTime,
  'workEndTime': instance.workEndTime,
};

Map<String, dynamic> _$OvertimeAttendanceToJson(OvertimeAttendance instance) =>
    <String, dynamic>{
      'available': instance.available,
      'overtimeId': instance.overtimeId,
      'reason': instance.reason,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'window': instance.window?.toJson(),
      'checkedIn': instance.checkedIn,
      'checkedOut': instance.checkedOut,
      'attendanceId': instance.attendanceId,
      'workplace': instance.workplace?.toJson(),
      'clientSessionId': instance.clientSessionId,
      'checkInOccurredAt': instance.checkInOccurredAt,
      'checkInSyncedAt': instance.checkInSyncedAt,
      'checkOutOccurredAt': instance.checkOutOccurredAt,
      'checkOutSyncedAt': instance.checkOutSyncedAt,
    };

Map<String, dynamic> _$OvertimeAttendanceWindowToJson(
  OvertimeAttendanceWindow instance,
) => <String, dynamic>{'from': instance.from, 'to': instance.to};
