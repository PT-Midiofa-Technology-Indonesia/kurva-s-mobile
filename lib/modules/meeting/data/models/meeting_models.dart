import 'package:json_annotation/json_annotation.dart';

part 'meeting_models.g.dart';

@JsonSerializable(createToJson: false)
class MeetingListResult {
  const MeetingListResult({
    required this.meetings,
    required this.currentPage,
    required this.lastPage,
  });

  @JsonKey(readValue: _readMeetingItems, fromJson: _meetingListFromJson)
  final List<Meeting> meetings;

  @JsonKey(readValue: _readCurrentPage, fromJson: _intWithOneFallback)
  final int currentPage;

  @JsonKey(readValue: _readLastPage, fromJson: _intWithOneFallback)
  final int lastPage;

  factory MeetingListResult.fromJson(Map<String, dynamic> json) =>
      _$MeetingListResultFromJson(json);
}

@JsonSerializable(createToJson: false)
class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.projectName,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.taskCount,
  });

  @JsonKey(readValue: _readMeetingId, fromJson: _stringFromJson)
  final String id;

  @JsonKey(readValue: _readMeetingTitle, fromJson: _stringFromJson)
  final String title;

  @JsonKey(readValue: _readMeetingDescription, fromJson: _stringFromJson)
  final String description;

  @JsonKey(readValue: _readStatus, fromJson: _stringFromJson)
  final String status;

  @JsonKey(readValue: _readProjectName, fromJson: _stringFromJson)
  final String projectName;

  @JsonKey(readValue: _readMeetingStartDate, fromJson: _nullableStringFromJson)
  final String? startDate;

  @JsonKey(readValue: _readMeetingEndDate, fromJson: _nullableStringFromJson)
  final String? endDate;

  @JsonKey(readValue: _readDurationDays, fromJson: _intFromJson)
  final int durationDays;

  @JsonKey(readValue: _readTaskCount, fromJson: _intFromJson)
  final int taskCount;

  factory Meeting.fromJson(Map<String, dynamic> json) =>
      _$MeetingFromJson(json);
}

@JsonSerializable(createToJson: false)
class MeetingDetail {
  const MeetingDetail({
    required this.id,
    required this.companyName,
    required this.title,
    required this.status,
    required this.projectName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.topic,
    required this.decision,
    required this.location,
    required this.toDos,
  });

  @JsonKey(readValue: _readMeetingId, fromJson: _stringFromJson)
  final String id;

  @JsonKey(readValue: _readCompanyName, fromJson: _stringFromJson)
  final String companyName;

  @JsonKey(readValue: _readMeetingTitle, fromJson: _stringFromJson)
  final String title;

  @JsonKey(readValue: _readStatus, fromJson: _stringFromJson)
  final String status;

  @JsonKey(readValue: _readProjectName, fromJson: _stringFromJson)
  final String projectName;

  @JsonKey(readValue: _readDetailDate, fromJson: _nullableStringFromJson)
  final String? date;

  @JsonKey(readValue: _readStartTime, fromJson: _stringFromJson)
  final String startTime;

  @JsonKey(readValue: _readEndTime, fromJson: _stringFromJson)
  final String endTime;

  @JsonKey(readValue: _readParticipants, fromJson: _referenceListFromJson)
  final List<MeetingReference> participants;

  @JsonKey(readValue: _readTopic, fromJson: _stringFromJson)
  final String topic;

  @JsonKey(readValue: _readDecision, fromJson: _stringFromJson)
  final String decision;

  @JsonKey(readValue: _readLocation, fromJson: _stringFromJson)
  final String location;

  @JsonKey(readValue: _readToDos, fromJson: _taskListFromJson)
  final List<MeetingTask> toDos;

  factory MeetingDetail.fromJson(Map<String, dynamic> json) =>
      _$MeetingDetailFromJson(json);
}

@JsonSerializable(createToJson: false)
class MeetingTask {
  const MeetingTask({
    required this.id,
    required this.meetingId,
    required this.code,
    required this.title,
    required this.projectName,
    required this.status,
    required this.creator,
    required this.assignee,
    required this.assignees,
    required this.createdAt,
    required this.updatedAt,
    required this.previousEvidence,
    this.taskType = '',
    this.statusLabel = '',
    this.kindBadge = '',
    this.retryCount = 0,
    this.participantsPreview = const [],
    this.participantsCount = 0,
    this.decision,
    this.doneAt,
    this.qcNote,
    this.canSubmit = true,
    this.canAssign = false,
    this.qcEvidence = const [],
    this.downstreamQc,
  });

  @JsonKey(readValue: _readTaskId, fromJson: _stringFromJson)
  final String id;

  @JsonKey(readValue: _readTaskMeetingId, fromJson: _stringFromJson)
  final String meetingId;

  @JsonKey(readValue: _readTaskCode, fromJson: _stringFromJson)
  final String code;

  @JsonKey(readValue: _readTaskTitle, fromJson: _stringFromJson)
  final String title;

  @JsonKey(readValue: _readProjectName, fromJson: _stringFromJson)
  final String projectName;

  @JsonKey(readValue: _readStatus, fromJson: _stringFromJson)
  final String status;

  @JsonKey(readValue: _readCreator, fromJson: _referenceFromJson)
  final MeetingReference? creator;

  @JsonKey(readValue: _readAssignee, fromJson: _referenceFromJson)
  final MeetingReference? assignee;

  @JsonKey(readValue: _readAssignees, fromJson: _referenceListFromJson)
  final List<MeetingReference> assignees;

  @JsonKey(readValue: _readCreatedAt, fromJson: _nullableStringFromJson)
  final String? createdAt;

  @JsonKey(readValue: _readUpdatedAt, fromJson: _nullableStringFromJson)
  final String? updatedAt;

  @JsonKey(readValue: _readEvidence, fromJson: _attachmentListFromJson)
  final List<MeetingAttachment> previousEvidence;

  @JsonKey(fromJson: _stringFromJson)
  final String taskType;

  @JsonKey(fromJson: _stringFromJson)
  final String statusLabel;

  @JsonKey(fromJson: _stringFromJson)
  final String kindBadge;

  @JsonKey(fromJson: _intFromJson)
  final int retryCount;

  @JsonKey(fromJson: _referenceListFromJson)
  final List<MeetingReference> participantsPreview;

  @JsonKey(fromJson: _intFromJson)
  final int participantsCount;

  @JsonKey(fromJson: _nullableStringFromJson)
  final String? decision;

  @JsonKey(fromJson: _nullableStringFromJson)
  final String? doneAt;

  @JsonKey(fromJson: _nullableStringFromJson)
  final String? qcNote;

  @JsonKey(fromJson: _boolWithTrueFallback)
  final bool canSubmit;

  @JsonKey(fromJson: _boolWithFalseFallback)
  final bool canAssign;

  @JsonKey(fromJson: _attachmentListFromJson)
  final List<MeetingAttachment> qcEvidence;

  @JsonKey(fromJson: _downstreamQcFromJson)
  final DownstreamQc? downstreamQc;

  factory MeetingTask.fromJson(Map<String, dynamic> json) {
    final task = _$MeetingTaskFromJson(json);
    if (task.assignees.isNotEmpty || task.assignee == null) return task;
    return MeetingTask(
      id: task.id,
      meetingId: task.meetingId,
      code: task.code,
      title: task.title,
      projectName: task.projectName,
      status: task.status,
      creator: task.creator,
      assignee: task.assignee,
      assignees: [task.assignee!],
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      previousEvidence: task.previousEvidence,
      taskType: task.taskType,
      statusLabel: task.statusLabel,
      kindBadge: task.kindBadge,
      retryCount: task.retryCount,
      participantsPreview: task.participantsPreview,
      participantsCount: task.participantsCount,
      decision: task.decision,
      doneAt: task.doneAt,
      qcNote: task.qcNote,
      canSubmit: task.canSubmit,
      canAssign: task.canAssign,
      qcEvidence: task.qcEvidence,
      downstreamQc: task.downstreamQc,
    );
  }

  static List<MeetingTask> listFromPayload(Object? payload) =>
      _taskListFromJson(payload);
}

@JsonSerializable(createToJson: false)
class MeetingTasksResult {
  const MeetingTasksResult({
    required this.tasks,
    required this.inProgressCount,
    required this.doneCount,
  });

  @JsonKey(readValue: _readMeetingTasks, fromJson: _taskListFromJson)
  final List<MeetingTask> tasks;

  @JsonKey(readValue: _readInProgressCount, fromJson: _intFromJson)
  final int inProgressCount;

  @JsonKey(readValue: _readDoneCount, fromJson: _intFromJson)
  final int doneCount;

  factory MeetingTasksResult.fromJson(Map<String, dynamic> json) =>
      _$MeetingTasksResultFromJson(json);
}

@JsonSerializable(createToJson: false)
class MeetingReference {
  const MeetingReference({
    required this.id,
    required this.name,
    this.apiInitials = '',
    this.colorHex = '',
  });

  @JsonKey(readValue: _readReferenceId, fromJson: _stringFromJson)
  final String id;

  @JsonKey(readValue: _readReferenceName, fromJson: _stringFromJson)
  final String name;

  @JsonKey(name: 'initials', fromJson: _stringFromJson)
  final String apiInitials;

  @JsonKey(fromJson: _stringFromJson)
  final String colorHex;

  String get initials {
    if (apiInitials.isNotEmpty) return apiInitials;
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '-';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  factory MeetingReference.fromJson(Map<String, dynamic> json) =>
      _$MeetingReferenceFromJson(json);
}

@JsonSerializable(createToJson: false)
class MeetingAttachment {
  const MeetingAttachment({
    required this.name,
    required this.path,
    required this.size,
  });

  @JsonKey(readValue: _readAttachmentName, fromJson: _stringFromJson)
  final String name;

  @JsonKey(readValue: _readAttachmentPath, fromJson: _stringFromJson)
  final String path;

  @JsonKey(readValue: _readAttachmentSize, fromJson: _intFromJson)
  final int size;

  factory MeetingAttachment.fromJson(Map<String, dynamic> json) {
    final attachment = _$MeetingAttachmentFromJson(json);
    if (attachment.name.isNotEmpty) return attachment;
    return MeetingAttachment(
      name: attachment.path.isEmpty ? '-' : attachment.path.split('/').last,
      path: attachment.path,
      size: attachment.size,
    );
  }
}

Object? _readMeetingItems(Map<dynamic, dynamic> json, String _) => _extractList(
  json['data'] ?? json,
  keys: const ['meetings', 'items', 'data'],
);

Object? _readMeetingTasks(Map<dynamic, dynamic> json, String _) => json;

Object? _readInProgressCount(Map<dynamic, dynamic> json, String _) {
  final counts = json['counts'];
  if (counts is Map) return counts['inProgress'];
  final tasks = _taskListFromJson(json);
  return tasks.length - _completedTaskCount(tasks);
}

Object? _readDoneCount(Map<dynamic, dynamic> json, String _) {
  final counts = json['counts'];
  if (counts is Map) return counts['done'];
  return _completedTaskCount(_taskListFromJson(json));
}

int _completedTaskCount(List<MeetingTask> tasks) {
  return tasks.where((task) {
    final status = task.status.toLowerCase();
    return status == 'done' ||
        status == 'completed' ||
        status == 'pass' ||
        status == 'failed' ||
        status == 'selesai';
  }).length;
}

Object? _readCurrentPage(Map<dynamic, dynamic> json, String _) =>
    _metaValue(json, 'currentPage', 'current_page');

Object? _readLastPage(Map<dynamic, dynamic> json, String _) =>
    _metaValue(json, 'lastPage', 'last_page');

Object? _metaValue(
  Map<dynamic, dynamic> json,
  String camelCase,
  String snakeCase,
) {
  final payload = json['data'];
  final meta = json['meta'] is Map
      ? json['meta'] as Map
      : payload is Map && payload['meta'] is Map
      ? payload['meta'] as Map
      : const {};
  return meta[camelCase] ?? meta[snakeCase];
}

Object? _readMeetingId(Map<dynamic, dynamic> json, String _) =>
    json['id'] ?? json['meetingId'] ?? json['uuid'];

Object? _readMeetingTitle(Map<dynamic, dynamic> json, String _) =>
    json['title'] ?? json['name'] ?? json['meetingTitle'] ?? json['topic'];

Object? _readMeetingDescription(Map<dynamic, dynamic> json, String _) =>
    json['topicSnippet'] ??
    json['description'] ??
    json['projectDescription'] ??
    json['agenda'];

Object? _readStatus(Map<dynamic, dynamic> json, String _) =>
    json['status'] ?? json['state'] ?? json['qcStatus'];

Object? _readProjectName(Map<dynamic, dynamic> json, String _) {
  final projects = json['projects'];
  final firstProject = projects is List && projects.isNotEmpty
      ? projects.first
      : null;
  return _referenceName(json['project']) ??
      _referenceName(firstProject) ??
      (json['project'] is Map ? (json['project'] as Map)['name'] : null) ??
      json['projectName'] ??
      json['project_title'];
}

Object? _readMeetingStartDate(Map<dynamic, dynamic> json, String _) =>
    json['startAt'] ??
    json['startDate'] ??
    json['meetingDate'] ??
    json['date'] ??
    json['scheduledAt'];

Object? _readMeetingEndDate(Map<dynamic, dynamic> json, String _) =>
    json['endAt'] ?? json['endDate'] ?? json['finishedAt'];

Object? _readDurationDays(Map<dynamic, dynamic> json, String _) =>
    json['durationDays'] ?? json['duration'];

Object? _readTaskCount(Map<dynamic, dynamic> json, String _) {
  final summary = json['summary'] is Map ? json['summary'] as Map : const {};
  return json['participantCount'] ??
      json['taskCount'] ??
      json['tasksCount'] ??
      json['todosCount'] ??
      summary['taskMeeting'] ??
      summary['tasks'];
}

Object? _readCompanyName(Map<dynamic, dynamic> json, String _) =>
    _referenceName(json['company']) ?? json['companyName'];

Object? _readDetailDate(Map<dynamic, dynamic> json, String _) =>
    json['date'] ??
    json['meetingDate'] ??
    json['startAt'] ??
    json['scheduledAt'];

Object? _readStartTime(Map<dynamic, dynamic> json, String _) =>
    json['startTime'] ?? json['startAt'] ?? json['scheduledAt'];

Object? _readEndTime(Map<dynamic, dynamic> json, String _) =>
    json['endTime'] ?? json['endAt'] ?? json['finishedAt'];

Object? _readParticipants(Map<dynamic, dynamic> json, String _) =>
    json['participants'] ??
    json['attendees'] ??
    json['employees'] ??
    json['members'];

Object? _readTopic(Map<dynamic, dynamic> json, String _) =>
    json['topic'] ?? json['agenda'] ?? json['description'];

Object? _readDecision(Map<dynamic, dynamic> json, String _) =>
    json['decision'] ?? json['result'] ?? json['conclusion'];

Object? _readLocation(Map<dynamic, dynamic> json, String _) =>
    json['location'] ?? json['place'] ?? json['venue'];

Object? _readToDos(Map<dynamic, dynamic> json, String _) =>
    json['todo'] ??
    json['toDos'] ??
    json['todos'] ??
    json['tasks'] ??
    json['items'];

Object? _readTaskId(Map<dynamic, dynamic> json, String _) =>
    json['id'] ?? json['taskId'] ?? json['qcTaskId'] ?? json['uuid'];

Object? _readTaskMeetingId(Map<dynamic, dynamic> json, String _) =>
    json['meetingId'] ??
    (json['meeting'] is Map ? (json['meeting'] as Map)['id'] : null) ??
    (json['data'] is Map && json['data']['meeting'] is Map
        ? (json['data']['meeting'] as Map)['id']
        : null);

Object? _readTaskCode(Map<dynamic, dynamic> json, String _) =>
    json['code'] ?? json['taskCode'] ?? json['wbsCode'];

Object? _readTaskTitle(Map<dynamic, dynamic> json, String _) =>
    json['title'] ?? json['name'] ?? json['task'] ?? json['taskName'];

Object? _readCreator(Map<dynamic, dynamic> json, String _) =>
    json['creator'] ?? json['createdBy'] ?? json['user'];

Object? _readAssignee(Map<dynamic, dynamic> json, String _) =>
    json['assignee'] ?? json['assignedTo'] ?? json['employee'] ?? json['pic'];

Object? _readAssignees(Map<dynamic, dynamic> json, String _) =>
    json['assignees'] ??
    json['participantsPreview'] ??
    json['employees'] ??
    json['members'];

Object? _readCreatedAt(Map<dynamic, dynamic> json, String _) =>
    json['createdAt'] ?? json['createdDate'];

Object? _readUpdatedAt(Map<dynamic, dynamic> json, String _) =>
    json['updatedAt'] ??
    json['updatedDate'] ??
    json['submittedAt'] ??
    json['doneAt'];

Object? _readEvidence(Map<dynamic, dynamic> json, String _) =>
    (json['sourceWorkTask'] is Map
        ? (json['sourceWorkTask'] as Map)['evidence']
        : null) ??
    json['evidence'] ??
    json['previousEvidence'] ??
    json['evidences'] ??
    json['attachments'] ??
    json['files'] ??
    json['proofs'];

Object? _readReferenceId(Map<dynamic, dynamic> json, String _) =>
    json['id'] ?? json['employeeId'] ?? json['uuid'];

Object? _readReferenceName(Map<dynamic, dynamic> json, String _) =>
    json['name'] ??
    json['fullName'] ??
    json['employeeName'] ??
    json['title'] ??
    json['label'];

Object? _readAttachmentPath(Map<dynamic, dynamic> json, String _) =>
    json['url'] ?? json['fileUrl'] ?? json['path'] ?? json['downloadUrl'];

Object? _readAttachmentName(Map<dynamic, dynamic> json, String _) =>
    json['fileName'] ?? json['name'] ?? json['filename'];

Object? _readAttachmentSize(Map<dynamic, dynamic> json, String _) =>
    json['fileSizeBytes'] ??
    json['size'] ??
    json['fileSize'] ??
    json['file_size'];

List<Meeting> _meetingListFromJson(Object? value) =>
    _mapList(value, Meeting.fromJson);

List<MeetingTask> _taskListFromJson(Object? value) => _mapList(
  _extractList(
    value,
    keys: const [
      'tasks',
      'qcTasks',
      'qualityControls',
      'toDos',
      'todos',
      'items',
      'data',
    ],
  ),
  MeetingTask.fromJson,
);

List<MeetingReference> _referenceListFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map(_referenceFromJson)
      .whereType<MeetingReference>()
      .toList(growable: false);
}

MeetingReference? _referenceFromJson(Object? value) {
  if (value is Map<String, dynamic>) return MeetingReference.fromJson(value);
  if (value is Map) {
    return MeetingReference.fromJson(Map<String, dynamic>.from(value));
  }
  if (value is String && value.isNotEmpty) {
    return MeetingReference(id: '', name: value);
  }
  return null;
}

List<MeetingAttachment> _attachmentListFromJson(Object? value) =>
    _mapList(value, MeetingAttachment.fromJson);

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

List<Object?> _extractList(Object? payload, {required List<String> keys}) {
  if (payload is List) return payload;
  if (payload is Map) {
    for (final key in keys) {
      final value = payload[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = _extractList(value, keys: keys);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}

String? _referenceName(Object? value) {
  if (value is String) return value;
  if (value is Map) {
    return _stringFromJson(
      value['name'] ??
          value['fullName'] ??
          value['employeeName'] ??
          value['title'],
    );
  }
  return null;
}

String _stringFromJson(Object? value) => value?.toString() ?? '';

String? _nullableStringFromJson(Object? value) {
  final text = _stringFromJson(value).trim();
  return text.isEmpty ? null : text;
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int _intWithOneFallback(Object? value) {
  final parsed = _intFromJson(value);
  return parsed < 1 ? 1 : parsed;
}

bool _boolWithTrueFallback(Object? value) => value is bool ? value : true;

bool _boolWithFalseFallback(Object? value) => value is bool ? value : false;

DownstreamQc? _downstreamQcFromJson(Object? value) {
  if (value is Map<String, dynamic>) return DownstreamQc.fromJson(value);
  if (value is Map) {
    return DownstreamQc.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

@JsonSerializable(createToJson: false)
class DownstreamQc {
  const DownstreamQc({
    required this.id,
    required this.status,
    this.assignee,
    this.decision,
    this.qcNote,
    this.evidence = const [],
  });

  @JsonKey(fromJson: _stringFromJson)
  final String id;

  @JsonKey(fromJson: _stringFromJson)
  final String status;

  @JsonKey(fromJson: _referenceFromJson)
  final MeetingReference? assignee;

  @JsonKey(fromJson: _nullableStringFromJson)
  final String? decision;

  @JsonKey(fromJson: _nullableStringFromJson)
  final String? qcNote;

  @JsonKey(fromJson: _attachmentListFromJson)
  final List<MeetingAttachment> evidence;

  factory DownstreamQc.fromJson(Map<String, dynamic> json) =>
      _$DownstreamQcFromJson(json);
}
