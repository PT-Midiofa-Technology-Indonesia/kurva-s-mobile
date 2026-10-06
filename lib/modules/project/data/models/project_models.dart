import 'package:json_annotation/json_annotation.dart';

part 'project_models.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectListResult {
  const ProjectListResult({
    required this.projects,
    required this.meta,
    required this.links,
  });

  @JsonKey(name: 'data')
  final List<Project> projects;
  final ProjectPaginationMeta meta;
  final ProjectPaginationLinks links;

  factory ProjectListResult.fromJson(Map<String, dynamic> json) {
    return ProjectListResult(
      projects: _objectList(json['data'], Project.fromJson),
      meta: ProjectPaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      links: ProjectPaginationLinks.fromJson(
        json['links'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
  Map<String, dynamic> toJson() => _$ProjectListResultToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class Project {
  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    required this.prospectStage,
    required this.client,
    required this.projectType,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.nodesCount,
    required this.summary,
    required this.permissions,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String status;
  final String prospectStage;
  final ProjectReference? client;
  final ProjectReference? projectType;
  final String? startDate;
  final String? endDate;
  final int durationDays;
  final int nodesCount;
  final ProjectSummary? summary;
  final List<String> permissions;
  final String? createdAt;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? '',
      prospectStage: json['prospectStage'] as String? ?? '',
      client: json['client'] is Map<String, dynamic>
          ? ProjectReference.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      projectType: json['projectType'] is Map<String, dynamic>
          ? ProjectReference.fromJson(
              json['projectType'] as Map<String, dynamic>,
            )
          : null,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      durationDays: _asInt(json['durationDays']),
      nodesCount: _asInt(json['nodesCount']),
      summary: json['summary'] is Map<String, dynamic>
          ? ProjectSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      permissions: _stringList(json['permissions']),
      createdAt: json['createdAt'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectReference {
  const ProjectReference({required this.id, required this.name});

  final String id;
  final String name;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '-';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  factory ProjectReference.fromJson(Map<String, dynamic> json) {
    return ProjectReference(
      id: _asString(json['id'] ?? json['uuid'] ?? json['employeeId']),
      name: _asString(
        json['name'] ??
            json['fullName'] ??
            json['employeeName'] ??
            json['title'] ??
            json['label'],
      ),
    );
  }
  Map<String, dynamic> toJson() => _$ProjectReferenceToJson(this);
}

class ProjectHelper {
  const ProjectHelper({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory ProjectHelper.fromJson(Map<String, dynamic> json) {
    return ProjectHelper(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
    );
  }
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectSummary {
  const ProjectSummary({
    required this.taskProject,
    required this.qualityControl,
    required this.taskMeeting,
    required this.qualityMeeting,
  });

  final int taskProject;
  final int qualityControl;
  final int taskMeeting;
  final int qualityMeeting;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      taskProject: _asInt(json['taskProject']),
      qualityControl: _asInt(json['qualityControl']),
      taskMeeting: _asInt(json['taskMeeting']),
      qualityMeeting: _asInt(json['qualityMeeting']),
    );
  }
  Map<String, dynamic> toJson() => _$ProjectSummaryToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectPaginationMeta {
  const ProjectPaginationMeta({
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

  factory ProjectPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ProjectPaginationMeta(
      currentPage: _asInt(json['currentPage']),
      perPage: _asInt(json['perPage']),
      total: _asInt(json['total']),
      lastPage: _asInt(json['lastPage']),
      from: _asInt(json['from']),
      to: _asInt(json['to']),
    );
  }
  Map<String, dynamic> toJson() => _$ProjectPaginationMetaToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectPaginationLinks {
  const ProjectPaginationLinks({
    required this.first,
    required this.last,
    required this.prev,
    required this.next,
  });

  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  factory ProjectPaginationLinks.fromJson(Map<String, dynamic> json) {
    return ProjectPaginationLinks(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$ProjectPaginationLinksToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.parentId,
    required this.code,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    this.canSubmit,
    this.canClaim = false,
    this.canBreakdown = false,
    this.canAssign = false,
    this.canAssignDraft = false,
    this.isDraft = false,
    this.isFinalLevel,
    required this.type,
    required this.creator,
    required this.assignee,
    required this.assignees,
    required this.createdAt,
    required this.updatedAt,
    required this.previousEvidence,
    required this.updatedEvidence,
    required this.qcApproval,
    this.qcOwner,
    required this.qcUpdatedAt,
    required this.qcStatus,
    required this.qcNote,
    required this.qcEvidence,
    required this.personnelCount,
    required this.childCount,
    this.volumeBoq = 0,
    this.currentProgress = 0,
    this.maxTargetVolume = 0,
    this.uom,
    this.durationDays,
    this.assignDate,
    this.targetVolume = 0,
    this.completedVolume = 0,
    this.manpowerName = '',
    this.helpersCount = 0,
    this.helpers = const [],
    this.manpower = const [],
    this.retryCount = 0,
    this.doneAt,
    this.version = 0,
    this.note,
    this.manpowerNote,
  });

  final String id;
  final String projectId;
  final String parentId;
  final String code;
  final String title;
  final String? description;
  final String status;
  final String statusLabel;
  final bool? canSubmit;
  final bool canClaim;
  final bool canBreakdown;
  final bool canAssign;
  final bool canAssignDraft;
  final bool isDraft;
  final bool? isFinalLevel;
  final String type;
  final ProjectReference? creator;
  final ProjectReference? assignee;
  final List<ProjectReference> assignees;
  final String? createdAt;
  final String? updatedAt;
  final List<ProjectAttachment> previousEvidence;
  final List<ProjectAttachment> updatedEvidence;
  final ProjectReference? qcApproval;
  final ProjectReference? qcOwner;
  final String? qcUpdatedAt;
  final String qcStatus;
  final String? qcNote;
  final List<ProjectAttachment> qcEvidence;
  final int personnelCount;
  final int childCount;
  final double volumeBoq;
  final double currentProgress;
  final double maxTargetVolume;
  final ProjectTaskUom? uom;
  final int? durationDays;
  final String? assignDate;
  final double targetVolume;
  final double completedVolume;
  final String manpowerName;
  final int helpersCount;
  final List<ProjectReference> helpers;
  final List<ProjectTaskManpower> manpower;
  final int retryCount;
  final String? doneAt;
  final int version;
  final String? note;
  final String? manpowerNote;

  factory ProjectTask.fromJson(
    Map<String, dynamic> json, {
    bool useWorkTaskPeople = false,
  }) {
    final workTask = json['workTask'] is Map<String, dynamic>
        ? json['workTask'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final taskEvidences = _attachments(json['evidences']);
    final storageBaseUrl = _storageBaseUrl(taskEvidences);
    final qcAssignee = _reference(json['assignee']);
    final assignee = useWorkTaskPeople
        ? _reference(workTask['assignee'])
        : qcAssignee;
    final helpers = _referenceList(json['helpers']);
    final assignees = useWorkTaskPeople
        ? const <ProjectReference>[]
        : _referenceList(
            json['assignees'] ??
                json['assignedEmployees'] ??
                json['employees'] ??
                json['members'] ??
                json['helpers'],
          );

    return ProjectTask(
      id: _asString(json['id'] ?? json['taskId'] ?? json['uuid']),
      projectId: _asString(json['projectId']),
      parentId: _asString(json['parentId'] ?? json['parentTaskId']),
      code: _asString(json['code'] ?? json['taskCode'] ?? json['wbsCode']),
      title: _asString(
        json['title'] ?? json['name'] ?? json['task'] ?? json['taskName'],
      ),
      description: _nullableString(
        json['description'] ?? json['note'] ?? workTask['note'],
      ),
      note: _nullableString(json['note']),
      manpowerNote: _nullableString(workTask['note'] ?? json['manpowerNote']),
      // Keep the status key and its display label separate. The detail API
      // supplies both (for example, `reopened` and `Reopened`).
      status: _asString(json['status'] ?? json['state']),
      statusLabel: _asString(
        json['statusLabel'] ?? json['status'] ?? json['state'],
      ),
      canSubmit: _asNullableBool(json['canSubmit']),
      canClaim: _asNullableBool(json['canClaim']) ?? false,
      canBreakdown: _asNullableBool(json['canBreakdown']) ?? false,
      canAssign: _asNullableBool(json['canAssign']) ?? false,
      canAssignDraft: _asNullableBool(json['canAssignDraft']) ?? false,
      isDraft: _asNullableBool(json['isDraft']) ?? false,
      isFinalLevel: _asNullableBool(json['isFinalLevel']),
      type: _asString(json['type'] ?? json['taskType']),
      creator: _reference(
        useWorkTaskPeople
            ? workTask['createdBy']
            : json['creator'] ?? json['createdBy'] ?? json['user'],
      ),
      assignee: assignee,
      assignees: assignees.isEmpty && assignee != null ? [assignee] : assignees,
      createdAt: _nullableString(json['createdAt'] ?? json['createdDate']),
      updatedAt: _nullableString(
        json['updatedAt'] ??
            json['updatedDate'] ??
            json['submittedAt'] ??
            json['doneAt'],
      ),
      previousEvidence: _attachments(
        json['previousEvidence'] ??
            json['previousFiles'] ??
            json['existingFiles'] ??
            json['evidences'] ??
            json['attachments'] ??
            json['documents'] ??
            workTask['evidences'],
      ),
      updatedEvidence: _attachments(
        json['updatedEvidence'] ??
            json['evidence'] ??
            json['files'] ??
            json['proofs'],
      ),
      qcApproval: _reference(
        json['qcApproval'] ??
            json['qcApprover'] ??
            json['reviewer'] ??
            json['decidedBy'] ??
            (json['qcFeedback'] is Map<String, dynamic>
                ? (json['qcFeedback'] as Map<String, dynamic>)['decidedBy']
                : null),
      ),
      qcOwner:
          _reference(
            json['claimedBy'] ??
                json['qcAssignee'] ??
                json['assignedQc'] ??
                json['qcOwner'],
          ) ??
          (useWorkTaskPeople ? qcAssignee : null),
      qcUpdatedAt: _nullableString(
        json['qcUpdatedAt'] ??
            json['reviewedAt'] ??
            json['decisionAt'] ??
            json['doneAt'] ??
            (json['qcFeedback'] is Map<String, dynamic>
                ? (json['qcFeedback'] as Map<String, dynamic>)['decidedAt']
                : null),
      ),
      qcStatus: _asString(
        json['qcStatus'] ??
            json['qcDecision'] ??
            json['decision'] ??
            json['reviewStatus'] ??
            (json['qcFeedback'] is Map<String, dynamic>
                ? (json['qcFeedback'] as Map<String, dynamic>)['decision']
                : null),
      ),
      qcNote: _nullableString(
        json['qcNote'] ??
            json['reviewNote'] ??
            (json['qcFeedback'] is Map<String, dynamic>
                ? (json['qcFeedback'] as Map<String, dynamic>)['comment']
                : null),
      ),
      qcEvidence: _attachments(
        json['qcEvidence'] ??
            json['qcEvidences'] ??
            json['qcFiles'] ??
            json['reviewFiles'] ??
            (json['qcFeedback'] is Map<String, dynamic>
                ? (json['qcFeedback'] as Map<String, dynamic>)['evidences']
                : null),
        urlPrefix: storageBaseUrl,
      ),
      personnelCount: _asInt(
        json['personnelCount'] ??
            json['assigneeCount'] ??
            json['employeesCount'] ??
            json['membersCount'] ??
            json['helpersCount'],
      ),
      childCount: _asInt(json['childCount']),
      volumeBoq: _asDouble(json['volumeBoq']),
      currentProgress: _asDouble(json['currentProgress']),
      maxTargetVolume: _asDouble(json['maxTargetVolume']),
      uom: _taskUom(json['uom'] ?? workTask['uom']),
      durationDays: json['durationDays'] == null
          ? null
          : _asInt(json['durationDays']),
      assignDate: _nullableString(json['assignDate']),
      targetVolume: _asDouble(json['targetVolume'] ?? workTask['targetVolume']),
      completedVolume: _asDouble(
        json['completedVolume'] ?? workTask['completedVolume'],
      ),
      manpowerName: _qcManpowerName(json, workTask),
      helpersCount: _asInt(json['helpersCount']),
      helpers: helpers,
      manpower: _manpowerList(json['manpower']),
      retryCount: _asInt(json['retryCount']),
      doneAt: _nullableString(json['doneAt']),
      version: _asInt(json['version'] ?? json['resourceVersion']),
    );
  }
  Map<String, dynamic> toJson() => _$ProjectTaskToJson(this);

  static List<ProjectTask> listFromPayload(Object? payload) {
    final items = _extractList(
      payload,
      keys: const [
        'tasks',
        'items',
        'data',
        'children',
        'nodes',
        'qcTasks',
        'qualityControls',
      ],
    );

    return items
        .whereType<Map<String, dynamic>>()
        .map(ProjectTask.fromJson)
        .toList(growable: false);
  }
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectTaskManpower {
  const ProjectTaskManpower({
    required this.id,
    required this.employee,
    required this.helpers,
    required this.targetVolume,
    required this.completedVolume,
    required this.status,
    required this.statusLabel,
    required this.isRevision,
    required this.canDelete,
    required this.canSubmit,
    required this.note,
    required this.assignDate,
    this.retryCount = 0,
  });

  final String id;
  final ProjectTaskManpowerPerson? employee;
  final List<ProjectTaskManpowerPerson> helpers;
  final double targetVolume;
  final double completedVolume;
  final String status;
  final String statusLabel;
  final bool isRevision;
  final bool canDelete;
  final bool canSubmit;
  final String? note;
  final String? assignDate;
  final int retryCount;

  factory ProjectTaskManpower.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    return ProjectTaskManpower(
      id: _asString(json['id']),
      employee: employee is Map<String, dynamic>
          ? ProjectTaskManpowerPerson.fromJson(employee)
          : null,
      helpers: _manpowerPeople(json['helpers']),
      targetVolume: _asDouble(json['targetVolume']),
      completedVolume: _asDouble(json['completedVolume']),
      status: _asString(json['status']),
      statusLabel: _asString(json['statusLabel'] ?? json['status']),
      isRevision: _asNullableBool(json['isRevision']) ?? false,
      canDelete: _asNullableBool(json['canDelete']) ?? false,
      canSubmit: _asNullableBool(json['canSubmit']) ?? false,
      note: _nullableString(json['note']),
      assignDate: _nullableString(json['assignDate']),
      retryCount: _asInt(json['retryCount']),
    );
  }

  Map<String, dynamic> toJson() => _$ProjectTaskManpowerToJson(this);
}

@JsonSerializable(createFactory: false)
class ProjectTaskManpowerPerson {
  const ProjectTaskManpowerPerson({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '-';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  factory ProjectTaskManpowerPerson.fromJson(Map<String, dynamic> json) {
    return ProjectTaskManpowerPerson(
      id: _asString(json['id']),
      name: _asString(json['name']),
      code: _asString(json['code']),
    );
  }

  Map<String, dynamic> toJson() => _$ProjectTaskManpowerPersonToJson(this);
}

@JsonSerializable(createFactory: false)
class ProjectTaskUom {
  const ProjectTaskUom({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory ProjectTaskUom.fromJson(Map<String, dynamic> json) {
    return ProjectTaskUom(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
    );
  }

  Map<String, dynamic> toJson() => _$ProjectTaskUomToJson(this);
}

class ProjectTasksResult {
  const ProjectTasksResult({
    required this.tasks,
    required this.inProgressCount,
    required this.doneCount,
  });

  final List<ProjectTask> tasks;
  final int inProgressCount;
  final int doneCount;

  factory ProjectTasksResult.fromPayload(Object? payload) {
    final tasks = ProjectTask.listFromPayload(payload);
    final counts = payload is Map ? payload['counts'] : null;
    final doneCount = counts is Map && counts['done'] != null
        ? _asInt(counts['done'])
        : tasks.where(_isCompletedProjectTask).length;
    final inProgressCount = counts is Map && counts['inProgress'] != null
        ? _asInt(counts['inProgress'])
        : tasks.length - doneCount;

    return ProjectTasksResult(
      tasks: tasks,
      inProgressCount: inProgressCount,
      doneCount: doneCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'data': tasks.map((task) => task.toJson()).toList(growable: false),
    'counts': {'inProgress': inProgressCount, 'done': doneCount},
  };
}

bool _isCompletedProjectTask(ProjectTask task) {
  final status = task.status.toLowerCase();
  return status == 'done' ||
      status == 'completed' ||
      status == 'pass' ||
      status == 'failed' ||
      status == 'selesai';
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectAttachment {
  const ProjectAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    required this.mimeType,
  });

  final String id;
  final String name;
  final String url;
  final String size;
  final String mimeType;

  factory ProjectAttachment.fromJson(
    Map<String, dynamic> json, {
    String? urlPrefix,
  }) {
    final rawUrl = _asString(
      json['url'] ??
          json['fileUrl'] ??
          json['path'] ??
          json['file_path'] ??
          json['downloadUrl'],
    );
    final url = rawUrl.startsWith('http') || urlPrefix == null
        ? rawUrl
        : '$urlPrefix${rawUrl.replaceFirst(RegExp(r'^/+'), '')}';
    final name = _asString(
      json['name'] ??
          json['fileName'] ??
          json['file_name'] ??
          json['filename'] ??
          json['title'],
    );

    return ProjectAttachment(
      id: _asString(json['id'] ?? json['uuid']),
      name: name.isNotEmpty
          ? name
          : (url.isNotEmpty ? url.split('/').last : '-'),
      url: url,
      size: _formatFileSize(
        json['size'] ?? json['fileSize'] ?? json['file_size'],
      ),
      mimeType: _asString(
        json['mimeType'] ?? json['mime_type'] ?? json['type'],
      ),
    );
  }
  Map<String, dynamic> toJson() => _$ProjectAttachmentToJson(this);
}

class ProjectTaskHistoryEntry {
  const ProjectTaskHistoryEntry({
    required this.projectTaskId,
    required this.actor,
    required this.note,
    required this.completedVolume,
    required this.targetVolume,
    required this.uom,
    required this.documents,
    required this.recordedAt,
    required this.event,
    required this.eventLabel,
    this.decision,
  });

  final String projectTaskId;
  final ProjectReference actor;
  final String note;
  final double? completedVolume;
  final double? targetVolume;
  final String uom;
  final List<ProjectTaskHistoryDocument> documents;
  final String? recordedAt;
  final String event;
  final String eventLabel;
  final ProjectTaskHistoryDecision? decision;

  factory ProjectTaskHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ProjectTaskHistoryEntry(
      projectTaskId: _asString(json['projectTaskId']),
      actor: json['actor'] is Map<String, dynamic>
          ? ProjectReference.fromJson(json['actor'] as Map<String, dynamic>)
          : const ProjectReference(id: '', name: ''),
      note: _asString(json['note']),
      completedVolume: json['completedVolume'] == null
          ? null
          : _asDouble(json['completedVolume']),
      targetVolume: json['targetVolume'] == null
          ? null
          : _asDouble(json['targetVolume']),
      uom: _asString(json['uom']),
      documents: _objectList(
        json['documents'],
        ProjectTaskHistoryDocument.fromJson,
      ),
      recordedAt: json['recordedAt'] as String?,
      event: _asString(json['event']),
      eventLabel: _asString(json['eventLabel']),
      decision: json['decision'] is Map<String, dynamic>
          ? ProjectTaskHistoryDecision.fromJson(
              json['decision'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ProjectTaskHistoryDecision {
  const ProjectTaskHistoryDecision({required this.value, required this.label});

  final String value;
  final String label;

  factory ProjectTaskHistoryDecision.fromJson(Map<String, dynamic> json) {
    return ProjectTaskHistoryDecision(
      value: _asString(json['value']),
      label: _asString(json['label']),
    );
  }
}

class ProjectTaskHistoryDocument {
  const ProjectTaskHistoryDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    required this.url,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedAt,
  });

  final String id;
  final ProjectDocumentType documentType;
  final String fileName;
  final String filePath;
  final String url;
  final int fileSize;
  final String mimeType;
  final String? uploadedAt;

  String get formattedFileSize => _formatFileSize(fileSize);

  factory ProjectTaskHistoryDocument.fromJson(Map<String, dynamic> json) {
    return ProjectTaskHistoryDocument(
      id: _asString(json['id']),
      documentType: json['documentType'] is Map<String, dynamic>
          ? ProjectDocumentType.fromJson(
              json['documentType'] as Map<String, dynamic>,
            )
          : const ProjectDocumentType(id: '', code: '', name: ''),
      fileName: _asString(json['fileName']),
      filePath: _asString(json['filePath']),
      url: _asString(json['url']),
      fileSize: _asInt(json['fileSize']),
      mimeType: _asString(json['mimeType']),
      uploadedAt: json['uploadedAt'] as String?,
    );
  }
}

class ProjectDocumentType {
  const ProjectDocumentType({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory ProjectDocumentType.fromJson(Map<String, dynamic> json) {
    return ProjectDocumentType(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
    );
  }
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class ProjectBreakdownOption {
  const ProjectBreakdownOption({
    required this.id,
    required this.code,
    required this.title,
    required this.isSelected,
    this.alreadyBrokenDown = false,
  });

  final String id;
  final String code;
  final String title;
  final bool isSelected;
  final bool alreadyBrokenDown;

  factory ProjectBreakdownOption.fromJson(Map<String, dynamic> json) {
    return ProjectBreakdownOption(
      id: _asString(json['id'] ?? json['boqItemId'] ?? json['uuid']),
      code: _asString(json['code'] ?? json['itemCode'] ?? json['boqCode']),
      title: _asString(json['title'] ?? json['name'] ?? json['itemName']),
      isSelected: json['isSelected'] == true || json['selected'] == true,
      alreadyBrokenDown: json['alreadyBrokenDown'] == true,
    );
  }
  Map<String, dynamic> toJson() => _$ProjectBreakdownOptionToJson(this);

  static List<ProjectBreakdownOption> listFromPayload(Object? payload) {
    final items = _extractList(
      payload,
      keys: const ['options', 'boqItems', 'items', 'data'],
    );

    return items
        .whereType<Map<String, dynamic>>()
        .map(ProjectBreakdownOption.fromJson)
        .toList(growable: false);
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

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<String>().toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool? _asNullableBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
    }
  }
  return null;
}

String _asString(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

String? _nullableString(Object? value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}

ProjectReference? _reference(Object? value) {
  if (value is Map<String, dynamic>) {
    return ProjectReference.fromJson(value);
  }
  if (value is String && value.isNotEmpty) {
    return ProjectReference(id: '', name: value);
  }
  return null;
}

ProjectTaskUom? _taskUom(Object? value) {
  if (value is Map<String, dynamic>) {
    return ProjectTaskUom.fromJson(value);
  }
  final name = _asString(value).trim();
  if (name.isEmpty) return null;
  return ProjectTaskUom(id: '', code: '', name: name);
}

String _qcManpowerName(
  Map<String, dynamic> json,
  Map<String, dynamic> workTask,
) {
  final explicitName = _asString(
    json['manpowerName'] ?? workTask['manpowerName'],
  ).trim();
  if (explicitName.isNotEmpty) return explicitName;

  return (_reference(json['manpower']) ??
              _reference(workTask['manpower']) ??
              _reference(workTask['assignee']))
          ?.name
          .trim() ??
      '';
}

List<ProjectReference> _referenceList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(ProjectReference.fromJson)
      .toList(growable: false);
}

List<ProjectTaskManpower> _manpowerList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(ProjectTaskManpower.fromJson)
      .toList(growable: false);
}

List<ProjectTaskManpowerPerson> _manpowerPeople(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(ProjectTaskManpowerPerson.fromJson)
      .toList(growable: false);
}

List<ProjectAttachment> _attachments(Object? value, {String? urlPrefix}) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map((json) => ProjectAttachment.fromJson(json, urlPrefix: urlPrefix))
      .toList(growable: false);
}

String? _storageBaseUrl(List<ProjectAttachment> attachments) {
  for (final attachment in attachments) {
    final marker = '/storage/';
    final index = attachment.url.indexOf(marker);
    if (index >= 0) {
      return attachment.url.substring(0, index + marker.length);
    }
  }
  return null;
}

List<Object?> _extractList(Object? payload, {required List<String> keys}) {
  if (payload is List) {
    return payload;
  }

  if (payload is Map<String, dynamic>) {
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        return value;
      }
      if (value is Map<String, dynamic>) {
        final nested = _extractList(value, keys: keys);
        if (nested.isNotEmpty) return nested;
      }
    }
  }

  return const [];
}

String _formatFileSize(Object? value) {
  if (value == null) return '-';
  if (value is String) return value.isEmpty ? '-' : value;
  final bytes = _asInt(value);
  if (bytes <= 0) return '-';
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}
