// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ProjectListResultToJson(ProjectListResult instance) =>
    <String, dynamic>{
      'data': instance.projects.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
      'links': instance.links.toJson(),
    };

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'status': instance.status,
  'prospectStage': instance.prospectStage,
  'client': instance.client?.toJson(),
  'projectType': instance.projectType?.toJson(),
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'durationDays': instance.durationDays,
  'nodesCount': instance.nodesCount,
  'summary': instance.summary?.toJson(),
  'permissions': instance.permissions,
  'createdAt': instance.createdAt,
};

Map<String, dynamic> _$ProjectReferenceToJson(ProjectReference instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

Map<String, dynamic> _$ProjectSummaryToJson(ProjectSummary instance) =>
    <String, dynamic>{
      'taskProject': instance.taskProject,
      'qualityControl': instance.qualityControl,
      'taskMeeting': instance.taskMeeting,
      'qualityMeeting': instance.qualityMeeting,
    };

Map<String, dynamic> _$ProjectPaginationMetaToJson(
  ProjectPaginationMeta instance,
) => <String, dynamic>{
  'currentPage': instance.currentPage,
  'perPage': instance.perPage,
  'total': instance.total,
  'lastPage': instance.lastPage,
  'from': instance.from,
  'to': instance.to,
};

Map<String, dynamic> _$ProjectPaginationLinksToJson(
  ProjectPaginationLinks instance,
) => <String, dynamic>{
  'first': instance.first,
  'last': instance.last,
  'prev': instance.prev,
  'next': instance.next,
};

Map<String, dynamic> _$ProjectTaskToJson(
  ProjectTask instance,
) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'parentId': instance.parentId,
  'code': instance.code,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'canSubmit': instance.canSubmit,
  'canClaim': instance.canClaim,
  'canBreakdown': instance.canBreakdown,
  'canAssign': instance.canAssign,
  'canAssignDraft': instance.canAssignDraft,
  'isDraft': instance.isDraft,
  'isFinalLevel': instance.isFinalLevel,
  'type': instance.type,
  'creator': instance.creator?.toJson(),
  'assignee': instance.assignee?.toJson(),
  'assignees': instance.assignees.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'previousEvidence': instance.previousEvidence.map((e) => e.toJson()).toList(),
  'updatedEvidence': instance.updatedEvidence.map((e) => e.toJson()).toList(),
  'qcApproval': instance.qcApproval?.toJson(),
  'qcOwner': instance.qcOwner?.toJson(),
  'qcUpdatedAt': instance.qcUpdatedAt,
  'qcStatus': instance.qcStatus,
  'qcNote': instance.qcNote,
  'qcEvidence': instance.qcEvidence.map((e) => e.toJson()).toList(),
  'personnelCount': instance.personnelCount,
  'childCount': instance.childCount,
  'volumeBoq': instance.volumeBoq,
  'currentProgress': instance.currentProgress,
  'maxTargetVolume': instance.maxTargetVolume,
  'uom': instance.uom?.toJson(),
  'durationDays': instance.durationDays,
  'assignDate': instance.assignDate,
  'targetVolume': instance.targetVolume,
  'completedVolume': instance.completedVolume,
  'manpowerName': instance.manpowerName,
  'helpersCount': instance.helpersCount,
  'helpers': instance.helpers.map((e) => e.toJson()).toList(),
  'manpower': instance.manpower.map((e) => e.toJson()).toList(),
  'retryCount': instance.retryCount,
  'doneAt': instance.doneAt,
  'version': instance.version,
  'note': instance.note,
  'manpowerNote': instance.manpowerNote,
};

Map<String, dynamic> _$ProjectTaskManpowerToJson(
  ProjectTaskManpower instance,
) => <String, dynamic>{
  'id': instance.id,
  'employee': instance.employee?.toJson(),
  'helpers': instance.helpers.map((e) => e.toJson()).toList(),
  'targetVolume': instance.targetVolume,
  'completedVolume': instance.completedVolume,
  'status': instance.status,
  'statusLabel': instance.statusLabel,
  'isRevision': instance.isRevision,
  'canDelete': instance.canDelete,
  'canSubmit': instance.canSubmit,
  'note': instance.note,
  'assignDate': instance.assignDate,
  'retryCount': instance.retryCount,
};

Map<String, dynamic> _$ProjectTaskManpowerPersonToJson(
  ProjectTaskManpowerPerson instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
};

Map<String, dynamic> _$ProjectTaskUomToJson(ProjectTaskUom instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

Map<String, dynamic> _$ProjectAttachmentToJson(ProjectAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'size': instance.size,
      'mimeType': instance.mimeType,
    };

Map<String, dynamic> _$ProjectBreakdownOptionToJson(
  ProjectBreakdownOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'title': instance.title,
  'isSelected': instance.isSelected,
  'alreadyBrokenDown': instance.alreadyBrokenDown,
};
