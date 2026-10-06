// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_operation_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ProjectTaskDonePayloadToJson(
  ProjectTaskDonePayload instance,
) => <String, dynamic>{
  'projectId': instance.projectId,
  'taskId': instance.taskId,
  'note': instance.note,
  'completedVolume': ?instance.completedVolume,
  'expectedVersion': instance.expectedVersion,
  'clientOccurredAt': instance.clientOccurredAt.toIso8601String(),
};

Map<String, dynamic> _$ProjectQcDecisionPayloadToJson(
  ProjectQcDecisionPayload instance,
) => <String, dynamic>{
  'projectId': instance.projectId,
  'qcTaskId': instance.qcTaskId,
  'decision': instance.decision,
  'note': instance.note,
  'expectedVersion': instance.expectedVersion,
  'clientOccurredAt': instance.clientOccurredAt.toIso8601String(),
};
