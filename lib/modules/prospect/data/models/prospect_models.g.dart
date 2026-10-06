// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prospect_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ProspectStageToJson(ProspectStage instance) =>
    <String, dynamic>{
      'stage': instance.stage,
      'stageName': instance.stageName,
      'totalProjects': instance.totalProjects,
      'projects': instance.projects.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$ProspectProjectToJson(ProspectProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'stage': instance.stage,
      'stageName': instance.stageName,
      'client': instance.client?.toJson(),
      'estimatedValue': instance.estimatedValue,
      'projectStartDate': instance.projectStartDate,
      'projectEndDate': instance.projectEndDate,
      'tenderSubmissionDeadline': instance.tenderSubmissionDeadline,
      'totalDocumentRequirements': instance.totalDocumentRequirements,
      'totalUploadedDocuments': instance.totalUploadedDocuments,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

Map<String, dynamic> _$ProspectDetailToJson(
  ProspectDetail instance,
) => <String, dynamic>{
  'prospect': instance.prospect.toJson(),
  'availableStages': instance.availableStages.map((e) => e.toJson()).toList(),
  'documents': instance.documents.map((e) => e.toJson()).toList(),
  'activity': instance.activity.toJson(),
};

Map<String, dynamic> _$ProspectProjectDetailToJson(
  ProspectProjectDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'stage': instance.stage,
  'stageName': instance.stageName,
  'client': instance.client?.toJson(),
  'estimatedValue': instance.estimatedValue,
  'projectStartDate': instance.projectStartDate,
  'projectEndDate': instance.projectEndDate,
  'tenderSubmissionDeadline': instance.tenderSubmissionDeadline,
  'totalDocumentRequirements': instance.totalDocumentRequirements,
  'totalUploadedDocuments': instance.totalUploadedDocuments,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'projectType': instance.projectType?.toJson(),
};

Map<String, dynamic> _$ProspectReferenceToJson(ProspectReference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
    };

Map<String, dynamic> _$ProspectProjectTypeToJson(
  ProspectProjectType instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'isActive': instance.isActive,
};

Map<String, dynamic> _$ProspectStageOptionToJson(
  ProspectStageOption instance,
) => <String, dynamic>{'value': instance.value, 'label': instance.label};

Map<String, dynamic> _$ProspectDocumentRequirementToJson(
  ProspectDocumentRequirement instance,
) => <String, dynamic>{
  'id': instance.id,
  'isMandatory': instance.isMandatory,
  'isActive': instance.isActive,
  'documentType': instance.documentType?.toJson(),
  'uploadedDocument': instance.uploadedDocument?.toJson(),
  'uploadedDocuments': instance.uploadedDocuments
      .map((e) => e.toJson())
      .toList(),
};

Map<String, dynamic> _$ProspectDocumentTypeToJson(
  ProspectDocumentType instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'allowedFileTypes': instance.allowedFileTypes,
  'allowedFileSize': instance.allowedFileSize,
};

Map<String, dynamic> _$ProspectUploadedDocumentToJson(
  ProspectUploadedDocument instance,
) => <String, dynamic>{
  'id': instance.id,
  'fileName': instance.fileName,
  'fileSize': instance.fileSize,
  'fileUrl': instance.fileUrl,
};

Map<String, dynamic> _$ProspectActivityToJson(ProspectActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt,
      'documents': instance.documents.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$ProspectStageHistoryToJson(
  ProspectStageHistory instance,
) => <String, dynamic>{
  'stage': instance.stage,
  'stageName': instance.stageName,
  'createdAt': instance.createdAt,
  'description': instance.description,
  'documents': instance.documents.map((e) => e.toJson()).toList(),
  'activity': instance.activity?.toJson(),
  'isCurrent': instance.isCurrent,
};
