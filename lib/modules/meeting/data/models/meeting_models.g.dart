// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetingListResult _$MeetingListResultFromJson(Map<String, dynamic> json) =>
    MeetingListResult(
      meetings: _meetingListFromJson(_readMeetingItems(json, 'meetings')),
      currentPage: _intWithOneFallback(_readCurrentPage(json, 'currentPage')),
      lastPage: _intWithOneFallback(_readLastPage(json, 'lastPage')),
    );

Meeting _$MeetingFromJson(Map<String, dynamic> json) => Meeting(
  id: _stringFromJson(_readMeetingId(json, 'id')),
  title: _stringFromJson(_readMeetingTitle(json, 'title')),
  description: _stringFromJson(_readMeetingDescription(json, 'description')),
  status: _stringFromJson(_readStatus(json, 'status')),
  projectName: _stringFromJson(_readProjectName(json, 'projectName')),
  startDate: _nullableStringFromJson(_readMeetingStartDate(json, 'startDate')),
  endDate: _nullableStringFromJson(_readMeetingEndDate(json, 'endDate')),
  durationDays: _intFromJson(_readDurationDays(json, 'durationDays')),
  taskCount: _intFromJson(_readTaskCount(json, 'taskCount')),
);

MeetingDetail _$MeetingDetailFromJson(Map<String, dynamic> json) =>
    MeetingDetail(
      id: _stringFromJson(_readMeetingId(json, 'id')),
      companyName: _stringFromJson(_readCompanyName(json, 'companyName')),
      title: _stringFromJson(_readMeetingTitle(json, 'title')),
      status: _stringFromJson(_readStatus(json, 'status')),
      projectName: _stringFromJson(_readProjectName(json, 'projectName')),
      date: _nullableStringFromJson(_readDetailDate(json, 'date')),
      startTime: _stringFromJson(_readStartTime(json, 'startTime')),
      endTime: _stringFromJson(_readEndTime(json, 'endTime')),
      participants: _referenceListFromJson(
        _readParticipants(json, 'participants'),
      ),
      topic: _stringFromJson(_readTopic(json, 'topic')),
      decision: _stringFromJson(_readDecision(json, 'decision')),
      location: _stringFromJson(_readLocation(json, 'location')),
      toDos: _taskListFromJson(_readToDos(json, 'toDos')),
    );

MeetingTask _$MeetingTaskFromJson(Map<String, dynamic> json) => MeetingTask(
  id: _stringFromJson(_readTaskId(json, 'id')),
  meetingId: _stringFromJson(_readTaskMeetingId(json, 'meetingId')),
  code: _stringFromJson(_readTaskCode(json, 'code')),
  title: _stringFromJson(_readTaskTitle(json, 'title')),
  projectName: _stringFromJson(_readProjectName(json, 'projectName')),
  status: _stringFromJson(_readStatus(json, 'status')),
  creator: _referenceFromJson(_readCreator(json, 'creator')),
  assignee: _referenceFromJson(_readAssignee(json, 'assignee')),
  assignees: _referenceListFromJson(_readAssignees(json, 'assignees')),
  createdAt: _nullableStringFromJson(_readCreatedAt(json, 'createdAt')),
  updatedAt: _nullableStringFromJson(_readUpdatedAt(json, 'updatedAt')),
  previousEvidence: _attachmentListFromJson(
    _readEvidence(json, 'previousEvidence'),
  ),
  taskType: json['taskType'] == null ? '' : _stringFromJson(json['taskType']),
  statusLabel: json['statusLabel'] == null
      ? ''
      : _stringFromJson(json['statusLabel']),
  kindBadge: json['kindBadge'] == null
      ? ''
      : _stringFromJson(json['kindBadge']),
  retryCount: json['retryCount'] == null ? 0 : _intFromJson(json['retryCount']),
  participantsPreview: json['participantsPreview'] == null
      ? const []
      : _referenceListFromJson(json['participantsPreview']),
  participantsCount: json['participantsCount'] == null
      ? 0
      : _intFromJson(json['participantsCount']),
  decision: _nullableStringFromJson(json['decision']),
  doneAt: _nullableStringFromJson(json['doneAt']),
  qcNote: _nullableStringFromJson(json['qcNote']),
  canSubmit: json['canSubmit'] == null
      ? true
      : _boolWithTrueFallback(json['canSubmit']),
  canAssign: json['canAssign'] == null
      ? false
      : _boolWithFalseFallback(json['canAssign']),
  qcEvidence: json['qcEvidence'] == null
      ? const []
      : _attachmentListFromJson(json['qcEvidence']),
  downstreamQc: _downstreamQcFromJson(json['downstreamQc']),
);

MeetingTasksResult _$MeetingTasksResultFromJson(Map<String, dynamic> json) =>
    MeetingTasksResult(
      tasks: _taskListFromJson(_readMeetingTasks(json, 'tasks')),
      inProgressCount: _intFromJson(
        _readInProgressCount(json, 'inProgressCount'),
      ),
      doneCount: _intFromJson(_readDoneCount(json, 'doneCount')),
    );

MeetingReference _$MeetingReferenceFromJson(Map<String, dynamic> json) =>
    MeetingReference(
      id: _stringFromJson(_readReferenceId(json, 'id')),
      name: _stringFromJson(_readReferenceName(json, 'name')),
      apiInitials: json['initials'] == null
          ? ''
          : _stringFromJson(json['initials']),
      colorHex: json['colorHex'] == null
          ? ''
          : _stringFromJson(json['colorHex']),
    );

MeetingAttachment _$MeetingAttachmentFromJson(Map<String, dynamic> json) =>
    MeetingAttachment(
      name: _stringFromJson(_readAttachmentName(json, 'name')),
      path: _stringFromJson(_readAttachmentPath(json, 'path')),
      size: _intFromJson(_readAttachmentSize(json, 'size')),
    );

DownstreamQc _$DownstreamQcFromJson(Map<String, dynamic> json) => DownstreamQc(
  id: _stringFromJson(json['id']),
  status: _stringFromJson(json['status']),
  assignee: _referenceFromJson(json['assignee']),
  decision: _nullableStringFromJson(json['decision']),
  qcNote: _nullableStringFromJson(json['qcNote']),
  evidence: json['evidence'] == null
      ? const []
      : _attachmentListFromJson(json['evidence']),
);
