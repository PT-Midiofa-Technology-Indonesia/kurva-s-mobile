import 'package:json_annotation/json_annotation.dart';

part 'prospect_models.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectStage {
  const ProspectStage({
    required this.stage,
    required this.stageName,
    required this.totalProjects,
    required this.projects,
  });

  final String stage;
  final String stageName;
  final int totalProjects;
  final List<ProspectProject> projects;

  factory ProspectStage.fromJson(Map<String, dynamic> json) {
    return ProspectStage(
      stage: _asString(json['stage']),
      stageName: _asString(json['stageName']),
      totalProjects: _asInt(json['totalProjects']),
      projects: _objectList(json['projects'], ProspectProject.fromJson),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectStageToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectProject {
  const ProspectProject({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.stage,
    required this.stageName,
    required this.client,
    required this.estimatedValue,
    required this.projectStartDate,
    required this.projectEndDate,
    required this.tenderSubmissionDeadline,
    required this.totalDocumentRequirements,
    required this.totalUploadedDocuments,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String stage;
  final String stageName;
  final ProspectReference? client;
  final num? estimatedValue;
  final String? projectStartDate;
  final String? projectEndDate;
  final String? tenderSubmissionDeadline;
  final int totalDocumentRequirements;
  final int totalUploadedDocuments;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory ProspectProject.fromJson(Map<String, dynamic> json) {
    return ProspectProject(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      description: _asStringOrNull(json['description']),
      stage: _asString(json['stage']),
      stageName: _asString(json['stageName']),
      client: json['client'] is Map<String, dynamic>
          ? ProspectReference.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      estimatedValue: _asNum(json['estimatedValue']),
      projectStartDate: _asStringOrNull(json['projectStartDate']),
      projectEndDate: _asStringOrNull(json['projectEndDate']),
      tenderSubmissionDeadline: _asStringOrNull(
        json['tenderSubmissionDeadline'],
      ),
      totalDocumentRequirements: _asInt(json['totalDocumentRequirements']),
      totalUploadedDocuments: _asInt(json['totalUploadedDocuments']),
      isActive: json['isActive'] as bool? ?? false,
      createdAt: _asStringOrNull(json['createdAt']),
      updatedAt: _asStringOrNull(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectProjectToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectDetail {
  const ProspectDetail({
    required this.prospect,
    required this.availableStages,
    required this.documents,
    required this.activity,
  });

  final ProspectProjectDetail prospect;
  final List<ProspectStageOption> availableStages;
  final List<ProspectDocumentRequirement> documents;
  final ProspectActivity activity;

  factory ProspectDetail.fromJson(Map<String, dynamic> json) {
    return ProspectDetail(
      prospect: ProspectProjectDetail.fromJson(
        json['prospect'] as Map<String, dynamic>? ?? const {},
      ),
      availableStages: _objectList(
        json['availableStages'],
        ProspectStageOption.fromJson,
      ),
      documents: _objectList(
        json['documents'],
        ProspectDocumentRequirement.fromJson,
      ),
      activity: ProspectActivity.fromJson(
        json['activity'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectProjectDetail extends ProspectProject {
  const ProspectProjectDetail({
    required super.id,
    required super.code,
    required super.name,
    required super.description,
    required super.stage,
    required super.stageName,
    required super.client,
    required this.projectType,
    required super.estimatedValue,
    required super.projectStartDate,
    required super.projectEndDate,
    required super.tenderSubmissionDeadline,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  }) : super(totalDocumentRequirements: 0, totalUploadedDocuments: 0);

  final ProspectReference? projectType;

  factory ProspectProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProspectProjectDetail(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      description: _asStringOrNull(json['description']),
      stage: _asString(json['stage']),
      stageName: _asString(json['stageName']),
      client: json['client'] is Map<String, dynamic>
          ? ProspectReference.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      projectType: json['projectType'] is Map<String, dynamic>
          ? ProspectReference.fromJson(
              json['projectType'] as Map<String, dynamic>,
            )
          : null,
      estimatedValue: _asNum(json['estimatedValue']),
      projectStartDate: _asStringOrNull(json['projectStartDate']),
      projectEndDate: _asStringOrNull(json['projectEndDate']),
      tenderSubmissionDeadline: _asStringOrNull(
        json['tenderSubmissionDeadline'],
      ),
      isActive: json['isActive'] as bool? ?? false,
      createdAt: _asStringOrNull(json['createdAt']),
      updatedAt: _asStringOrNull(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ProspectProjectDetailToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectReference {
  const ProspectReference({required this.id, required this.name, this.code});

  final String id;
  final String name;
  final String? code;

  factory ProspectReference.fromJson(Map<String, dynamic> json) {
    return ProspectReference(
      id: _asString(json['id']),
      name: _asString(json['name']),
      code: _asStringOrNull(json['code']),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectReferenceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectProjectType {
  const ProspectProjectType({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;

  factory ProspectProjectType.fromJson(Map<String, dynamic> json) {
    return ProspectProjectType(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      description: _asStringOrNull(json['description']),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$ProspectProjectTypeToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectStageOption {
  const ProspectStageOption({required this.value, required this.label});

  final String value;
  final String label;

  factory ProspectStageOption.fromJson(Map<String, dynamic> json) {
    return ProspectStageOption(
      value: _asString(json['value']),
      label: _asString(json['label']),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectStageOptionToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectDocumentRequirement {
  const ProspectDocumentRequirement({
    required this.id,
    required this.isMandatory,
    required this.isActive,
    required this.documentType,
    required this.uploadedDocument,
    required this.uploadedDocuments,
  });

  final String id;
  final bool isMandatory;
  final bool isActive;
  final ProspectDocumentType? documentType;
  final ProspectUploadedDocument? uploadedDocument;
  final List<ProspectUploadedDocument> uploadedDocuments;

  factory ProspectDocumentRequirement.fromJson(Map<String, dynamic> json) {
    final uploadedDocuments = _uploadedDocuments(json);
    return ProspectDocumentRequirement(
      id: _asString(json['id']),
      isMandatory: json['isMandatory'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      documentType: json['documentType'] is Map<String, dynamic>
          ? ProspectDocumentType.fromJson(
              json['documentType'] as Map<String, dynamic>,
            )
          : null,
      uploadedDocument: uploadedDocuments.isEmpty
          ? null
          : uploadedDocuments.first,
      uploadedDocuments: uploadedDocuments,
    );
  }

  Map<String, dynamic> toJson() => _$ProspectDocumentRequirementToJson(this);
}

List<ProspectUploadedDocument> _uploadedDocuments(Map<String, dynamic> json) {
  final value =
      json['uploadedDocuments'] ??
      json['documents'] ??
      json['uploadedDocument'];
  if (value is Map<String, dynamic>) {
    return [ProspectUploadedDocument.fromJson(value)];
  }

  return _objectList(value, ProspectUploadedDocument.fromJson);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectDocumentType {
  const ProspectDocumentType({
    required this.id,
    required this.code,
    required this.name,
    required this.allowedFileTypes,
    required this.allowedFileSize,
  });

  final String id;
  final String code;
  final String name;
  final String allowedFileTypes;
  final int allowedFileSize;

  factory ProspectDocumentType.fromJson(Map<String, dynamic> json) {
    return ProspectDocumentType(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      allowedFileTypes: _asString(json['allowedFileTypes']),
      allowedFileSize: _asInt(json['allowedFileSize']),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectDocumentTypeToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectUploadedDocument {
  const ProspectUploadedDocument({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
  });

  final String id;
  final String fileName;
  final int fileSize;
  final String fileUrl;

  factory ProspectUploadedDocument.fromJson(Map<String, dynamic> json) {
    return ProspectUploadedDocument(
      id: _asString(json['id']),
      fileName: _asString(json['fileName'] ?? json['name']),
      fileSize: _asInt(json['fileSize'] ?? json['size']),
      fileUrl: _asString(json['fileUrl'] ?? json['url']),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectUploadedDocumentToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectActivity {
  const ProspectActivity({
    required this.id,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.documents,
  });

  final String? id;
  final String? description;
  final String? createdBy;
  final String? createdAt;
  final List<ProspectUploadedDocument> documents;

  factory ProspectActivity.fromJson(Map<String, dynamic> json) {
    return ProspectActivity(
      id: _asStringOrNull(json['id']),
      description: _asStringOrNull(json['description']),
      createdBy: _asStringOrNull(json['createdBy']),
      createdAt: _asStringOrNull(json['createdAt']),
      documents: _objectList(
        json['documents'],
        ProspectUploadedDocument.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => _$ProspectActivityToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProspectStageHistory {
  const ProspectStageHistory({
    required this.stage,
    required this.stageName,
    required this.createdAt,
    required this.description,
    required this.documents,
    required this.activity,
    required this.isCurrent,
  });

  final String stage;
  final String stageName;
  final String? createdAt;
  final String? description;
  final List<ProspectUploadedDocument> documents;
  final ProspectActivity? activity;
  final bool isCurrent;

  factory ProspectStageHistory.fromJson(Map<String, dynamic> json) {
    final activityJson = json['activity'];

    return ProspectStageHistory(
      stage: _asString(json['stage'] ?? json['value']),
      stageName: _asString(json['stageName'] ?? json['label'] ?? json['name']),
      createdAt:
          _asStringOrNull(json['createdAt']) ??
          _asStringOrNull(json['changedAt']) ??
          _asStringOrNull(json['enteredAt']) ??
          _asStringOrNull(json['date']),
      description:
          _asStringOrNull(json['description']) ??
          (activityJson is Map<String, dynamic>
              ? _asStringOrNull(activityJson['description'])
              : _asStringOrNull(activityJson)) ??
          _asStringOrNull(json['notes']),
      documents: _objectList(
        json['documents'] ?? json['uploadedDocuments'],
        ProspectUploadedDocument.fromJson,
      ),
      activity: activityJson is Map<String, dynamic>
          ? ProspectActivity.fromJson(activityJson)
          : null,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$ProspectStageHistoryToJson(this);
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
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '');
}

String _asString(Object? value) {
  return _asStringOrNull(value) ?? '';
}

String? _asStringOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  if (value is Map<String, dynamic>) {
    return _asStringOrNull(
      value['name'] ?? value['label'] ?? value['code'] ?? value['id'],
    );
  }

  return value.toString();
}
