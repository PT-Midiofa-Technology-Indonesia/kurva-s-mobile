// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overtime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$OvertimeListResultToJson(OvertimeListResult instance) =>
    <String, dynamic>{
      'records': instance.records.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
      'links': instance.links.toJson(),
    };

Map<String, dynamic> _$OvertimeRecordToJson(OvertimeRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'reason': instance.reason,
      'overtimeDate': instance.overtimeDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'totalMinutes': instance.totalMinutes,
      'status': instance.status,
      'locationType': instance.locationType,
      'location': instance.location?.toJson(),
      'project': instance.project?.toJson(),
      'adminNote': instance.adminNote,
      'createdAt': instance.createdAt,
      'statusLabel': instance.statusLabel,
      'canSubmit': instance.canSubmit,
    };

Map<String, dynamic> _$OvertimeReferenceToJson(OvertimeReference instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

Map<String, dynamic> _$OvertimeRequestInputToJson(
  OvertimeRequestInput instance,
) => <String, dynamic>{
  'overtimeDate': instance.overtimeDate.toIso8601String(),
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'locationType': instance.locationType,
  'locationId': instance.locationId,
  'projectId': instance.projectId,
  'reason': instance.reason,
};
