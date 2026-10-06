import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';

void main() {
  test(
    'meeting list generated parser supports wrapped aliases and pagination',
    () {
      final result = MeetingListResult.fromJson({
        'data': {
          'items': [
            {
              'meetingId': 'meeting-1',
              'meetingTitle': 'Weekly Meeting',
              'agenda': 'Progress review',
              'state': 'progress',
              'project': {'name': 'Project Alpha'},
              'meetingDate': '2026-07-20',
              'finishedAt': '2026-07-21',
              'duration': '2',
              'tasksCount': '3',
            },
          ],
          'meta': {'current_page': 2, 'last_page': 4},
        },
      });

      expect(result.currentPage, 2);
      expect(result.lastPage, 4);
      expect(result.meetings.single.id, 'meeting-1');
      expect(result.meetings.single.title, 'Weekly Meeting');
      expect(result.meetings.single.projectName, 'Project Alpha');
      expect(result.meetings.single.taskCount, 3);
    },
  );

  test('meeting list parser supports the current mobile API response', () {
    final result = MeetingListResult.fromJson({
      'success': true,
      'data': [
        {
          'id': 'meeting-1',
          'code': 'MOM/MOBILE-CO/2026/00001',
          'title': 'Diskusi persiapan pembangunan',
          'status': 'published',
          'startAt': '2026-07-26T10:30:00+00:00',
          'endAt': '2026-07-28T12:00:00+00:00',
          'topicSnippet': 'Persiapan pembangunan jembatan.',
          'durationDays': 3,
          'participantCount': 2,
          'projects': [
            {'id': 'project-1', 'name': 'Proyek Mobile Test'},
          ],
        },
      ],
      'meta': {'currentPage': 1, 'lastPage': 1},
    });

    final meeting = result.meetings.single;
    expect(meeting.description, 'Persiapan pembangunan jembatan.');
    expect(meeting.projectName, 'Proyek Mobile Test');
    expect(meeting.startDate, '2026-07-26T10:30:00+00:00');
    expect(meeting.endDate, '2026-07-28T12:00:00+00:00');
    expect(meeting.durationDays, 3);
    expect(meeting.taskCount, 2);
  });

  test('meeting detail generated parser preserves raw UTC time values', () {
    final detail = MeetingDetail.fromJson({
      'id': 'meeting-1',
      'company': {'name': 'Curva'},
      'title': 'Review',
      'status': 'progress',
      'projectName': 'Project Alpha',
      'date': '2026-07-20',
      'startAt': '2026-07-20T23:15:00Z',
      'endTime': '01:15',
      'participants': [
        {'employeeId': 'employee-1', 'fullName': 'Agung Prasetyo'},
      ],
      'agenda': 'Review progress',
      'conclusion': 'Continue',
      'venue': 'Meeting Room',
      'todos': [
        {'taskId': 'task-1', 'taskName': 'Follow up'},
      ],
    });

    expect(detail.startTime, '2026-07-20T23:15:00Z');
    expect(detail.endTime, '01:15');
    expect(detail.participants.single.name, 'Agung Prasetyo');
    expect(detail.toDos.single.id, 'task-1');
  });

  test('meeting detail parser supports current mobile response', () {
    final detail = MeetingDetail.fromJson({
      'id': 'meeting-1',
      'code': 'MOM/MOBILE-CO/2026/00001',
      'title': 'Diskusi persiapan pembangunan',
      'status': 'published',
      'startAt': '2026-07-26T10:30:00+00:00',
      'endAt': '2026-07-28T12:00:00+00:00',
      'projects': [
        {'id': 'project-1', 'name': 'Proyek Mobile Test'},
      ],
      'company': {'id': 'company-1', 'name': 'PT Curva Mobile'},
      'location': 'Gedung Garuda Lantai 4',
      'topic': 'Topik rapat',
      'decision': 'Keputusan rapat',
      'participants': [
        {
          'id': 'employee-1',
          'name': 'Mobile Admin',
          'initials': 'MA',
          'colorHex': '#9B4DCA',
        },
      ],
      'todo': [
        {
          'id': 'task-1',
          'code': 'A',
          'title': 'Follow up budget project',
          'status': 'done',
          'project': {'id': 'project-1', 'name': 'Proyek Mobile Test'},
          'assignedToMe': false,
        },
      ],
    });

    expect(detail.companyName, 'PT Curva Mobile');
    expect(detail.projectName, 'Proyek Mobile Test');
    expect(detail.date, '2026-07-26T10:30:00+00:00');
    expect(detail.startTime, '2026-07-26T10:30:00+00:00');
    expect(detail.endTime, '2026-07-28T12:00:00+00:00');
    expect(detail.participants.single.initials, 'MA');
    expect(detail.participants.single.colorHex, '#9B4DCA');
    expect(detail.toDos.single.title, 'Follow up budget project');
    expect(detail.toDos.single.projectName, 'Proyek Mobile Test');
  });

  test('meeting task parser supports the current overview response', () {
    final result = MeetingTasksResult.fromJson({
      'data': [
        {
          'id': 'task-1',
          'code': 'A',
          'title': 'Follow up budget project',
          'taskType': 'qc',
          'status': 'created',
          'statusLabel': 'Belum Dikerjakan',
          'kindBadge': 'quality_project',
          'retryCount': 0,
          'meeting': {'id': 'meeting-1', 'title': 'Diskusi persiapan'},
          'project': {'id': 'project-1', 'name': 'Proyek Mobile Test'},
          'assignee': {
            'id': 'employee-1',
            'name': 'Mobile Admin',
            'initials': 'MA',
            'colorHex': '#9B4DCA',
          },
          'participantsPreview': [
            {
              'id': 'employee-1',
              'name': 'Mobile Admin',
              'initials': 'MA',
              'colorHex': '#9B4DCA',
            },
          ],
          'participantsCount': 1,
          'decision': null,
          'doneAt': null,
          'canAssign': true,
        },
      ],
      'counts': {'inProgress': 4, 'done': 0},
    });

    final task = result.tasks.single;
    expect(result.inProgressCount, 4);
    expect(result.doneCount, 0);
    expect(task.meetingId, 'meeting-1');
    expect(task.projectName, 'Proyek Mobile Test');
    expect(task.taskType, 'qc');
    expect(task.statusLabel, 'Belum Dikerjakan');
    expect(task.kindBadge, 'quality_project');
    expect(task.retryCount, 0);
    expect(task.participantsCount, 1);
    expect(task.participantsPreview.single.initials, 'MA');
    expect(task.participantsPreview.single.colorHex, '#9B4DCA');
    expect(task.decision, isNull);
    expect(task.canAssign, isTrue);
  });

  test('meeting task parser denies assignment when canAssign is absent', () {
    final task = MeetingTask.fromJson({
      'id': 'task-1',
      'title': 'Follow up budget project',
    });

    expect(task.canAssign, isFalse);
  });

  test('meeting task parser supports submitted work task detail response', () {
    final task = MeetingTask.fromJson({
      'id': 'task-1',
      'code': 'A',
      'title': 'Follow up budget project',
      'taskType': 'work',
      'status': 'done',
      'statusLabel': 'Menunggu QC',
      'kindBadge': 'task_project',
      'retryCount': 0,
      'meeting': {
        'id': 'meeting-1',
        'title': 'Diskusi persiapan pembangunan',
        'code': 'MOM/MOBILE-CO/2026/00001',
      },
      'project': {'id': 'project-1', 'name': 'Proyek Mobile Test'},
      'assignee': {
        'id': 'employee-2',
        'name': 'Mobile Staff',
        'initials': 'MS',
        'colorHex': '#8A5A2B',
      },
      'participantsPreview': [
        {
          'id': 'employee-1',
          'name': 'Mobile Admin',
          'initials': 'MA',
          'colorHex': '#9B4DCA',
        },
        {
          'id': 'employee-2',
          'name': 'Mobile Staff',
          'initials': 'MS',
          'colorHex': '#8A5A2B',
        },
      ],
      'participantsCount': 2,
      'createdBy': 'Mobile Admin',
      'createdAt': '2026-07-26T10:38:16+00:00',
      'doneAt': '2026-07-28T15:07:42+00:00',
      'updatedAt': '2026-07-28T15:07:42+00:00',
      'canSubmit': false,
      'evidence': [
        {
          'documentId': 'document-1',
          'fileName': 'IMG_20260724_085047.jpg',
          'fileSizeBytes': 31329,
          'mimeType': 'image/jpeg',
          'url': 'http://example.com/evidence.jpg',
          'uploadedAt': '2026-07-28T15:07:42+00:00',
        },
      ],
      'downstreamQc': {
        'id': 'qc-1',
        'status': 'created',
        'assignee': null,
        'decision': null,
        'qcNote': 'Perbaiki hasil pekerjaan',
        'evidence': [
          {
            'documentId': 'qc-document-1',
            'fileName': 'qc-result.jpg',
            'fileSizeBytes': 870329,
            'mimeType': 'image/jpeg',
            'url': 'http://example.com/qc-result.jpg',
            'uploadedAt': '2026-07-28T15:08:42+00:00',
          },
        ],
      },
    });

    expect(task.meetingId, 'meeting-1');
    expect(task.projectName, 'Proyek Mobile Test');
    expect(task.creator?.name, 'Mobile Admin');
    expect(task.assignee?.name, 'Mobile Staff');
    expect(task.statusLabel, 'Menunggu QC');
    expect(task.canSubmit, isFalse);
    expect(task.previousEvidence, hasLength(1));
    expect(task.previousEvidence.single.name, 'IMG_20260724_085047.jpg');
    expect(task.previousEvidence.single.size, 31329);
    expect(
      task.previousEvidence.single.path,
      'http://example.com/evidence.jpg',
    );
    expect(task.downstreamQc?.qcNote, 'Perbaiki hasil pekerjaan');
    expect(task.downstreamQc?.evidence, hasLength(1));
    expect(task.downstreamQc?.evidence.single.name, 'qc-result.jpg');
    expect(task.downstreamQc?.evidence.single.size, 870329);
    expect(
      task.downstreamQc?.evidence.single.path,
      'http://example.com/qc-result.jpg',
    );
  });

  test('meeting task parser supports completed quality review detail', () {
    final task = MeetingTask.fromJson({
      'id': 'qc-task-1',
      'code': 'C',
      'title': 'Penataan bata dinding',
      'status': 'done',
      'statusLabel': 'Menunggu QC',
      'kindBadge': 'quality_project',
      'meeting': {
        'id': 'meeting-1',
        'title': 'Diskusi persiapan pembangunan',
        'code': 'MOM/MOBILE-CO/2026/00001',
      },
      'project': {'id': 'project-1', 'name': 'Proyek Mobile Test'},
      'createdBy': 'Mobile Admin',
      'assignee': {
        'id': 'employee-1',
        'name': 'Mobile Admin',
        'initials': 'MA',
        'colorHex': '#9B4DCA',
      },
      'createdAt': '2026-07-26T10:38:16+00:00',
      'updatedAt': '2026-07-28T15:09:55+00:00',
      'qcNote': 'ok',
      'decision': 'pass',
      'canSubmit': false,
      'qcEvidence': [
        {
          'documentId': 'document-1',
          'fileName': 'IMG_20260724_085047.jpg',
          'fileSizeBytes': 31329,
          'mimeType': 'image/jpeg',
          'url': 'http://example.com/qc-evidence.jpg',
          'uploadedAt': '2026-07-28T15:09:55+00:00',
        },
      ],
      'sourceWorkTask': {
        'id': 'work-task-1',
        'code': 'C',
        'title': 'Penataan bata dinding',
        'assignee': {
          'id': 'employee-1',
          'name': 'Mobile Admin',
          'initials': 'MA',
          'colorHex': '#9B4DCA',
        },
        'doneAt': '2026-07-26T10:38:16+00:00',
        'retryCount': 0,
        'evidence': <Object?>[],
      },
    });

    expect(task.id, 'qc-task-1');
    expect(task.meetingId, 'meeting-1');
    expect(task.projectName, 'Proyek Mobile Test');
    expect(task.creator?.name, 'Mobile Admin');
    expect(task.assignee?.name, 'Mobile Admin');
    expect(task.statusLabel, 'Menunggu QC');
    expect(task.qcNote, 'ok');
    expect(task.decision, 'pass');
    expect(task.canSubmit, isFalse);
    expect(task.previousEvidence, isEmpty);
    expect(task.qcEvidence, hasLength(1));
    expect(task.qcEvidence.single.name, 'IMG_20260724_085047.jpg');
    expect(task.qcEvidence.single.size, 31329);
    expect(task.qcEvidence.single.path, 'http://example.com/qc-evidence.jpg');
  });
}
