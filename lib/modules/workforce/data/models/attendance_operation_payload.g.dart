// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_operation_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AttendanceOperationPayloadToJson(
  AttendanceOperationPayload instance,
) => <String, dynamic>{
  'clientSessionId': instance.clientSessionId,
  'action': _$AttendanceActionEnumMap[instance.action]!,
  'type': _$AttendanceTypeEnumMap[instance.type]!,
  'overtimeId': instance.overtimeId,
  'overtimeLabel': instance.overtimeLabel,
  'occurredAt': instance.occurredAt.toIso8601String(),
  'timezoneOffsetMinutes': instance.timezoneOffsetMinutes,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'accuracyMeters': instance.accuracyMeters,
  'isMocked': instance.isMocked,
};

const _$AttendanceActionEnumMap = {
  AttendanceAction.checkIn: 'checkIn',
  AttendanceAction.checkOut: 'checkOut',
};

const _$AttendanceTypeEnumMap = {
  AttendanceType.regular: 'regular',
  AttendanceType.overtime: 'overtime',
};
