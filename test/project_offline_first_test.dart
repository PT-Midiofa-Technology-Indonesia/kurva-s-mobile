import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/sync/retry_policy.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/project/data/local/project_local_data_source.dart';
import 'package:curva_mobile/modules/project/data/models/project_operation_payload.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';

void main() {
  const scope = SyncScope(accountId: 'account-1', companyId: 'company-1');

  test('project operation types have stable persisted names', () {
    expect(
      SyncOperationType.projectTaskDone.storageName,
      'project.task.done.v1',
    );
    expect(
      SyncOperationType.qcTaskDecision.storageName,
      'project.qc.decision.v1',
    );
  });

  test('task done payload round-trips occurrence time as UTC', () {
    final payload = ProjectTaskDonePayload(
      projectId: 'project-1',
      taskId: 'task-1',
      expectedVersion: 12,
      clientOccurredAt: DateTime.parse('2026-07-22T10:15:20+07:00'),
    );

    final json = payload.toJson();
    final restored = ProjectTaskDonePayload.fromJson(json);

    expect(json['schemaVersion'], 1);
    expect(json['clientOccurredAt'], '2026-07-22T03:15:20.000Z');
    expect(restored.expectedVersion, 12);
    expect(restored.completedVolume, isNull);
    expect(json, isNot(contains('completedVolume')));
    expect(restored.clientOccurredAt.isUtc, isTrue);
  });

  test('project payload supports legacy API responses without version', () {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'status': 'reopened',
      'retryCount': 1,
    });
    final payload = ProjectTaskDonePayload(
      projectId: 'project-1',
      taskId: task.id,
      expectedVersion: task.version,
      clientOccurredAt: DateTime.utc(2026, 7, 22),
    ).toJson();

    expect(task.version, 0);
    expect(payload, isNot(contains('expectedVersion')));
  });

  test('QC task maps canClaim from the API and defaults it to false', () {
    final claimableTask = ProjectTask.fromJson({
      'id': 'qc-claimable',
      'canClaim': true,
    });
    final taskWithoutPermission = ProjectTask.fromJson({
      'id': 'qc-not-claimable',
    });

    expect(claimableTask.canClaim, isTrue);
    expect(taskWithoutPermission.canClaim, isFalse);
  });

  test('project task result reads overview counts from the API response', () {
    final result = ProjectTasksResult.fromPayload({
      'data': [
        {'id': 'task-1', 'status': 'created'},
      ],
      'counts': {'inProgress': 4, 'done': 2},
    });

    expect(result.tasks.single.id, 'task-1');
    expect(result.inProgressCount, 4);
    expect(result.doneCount, 2);
  });

  test('project task maps the task project list response fields', () {
    final task = ProjectTask.fromJson({
      'id': 'task-1',
      'taskType': 'work',
      'volumeBoq': 250,
      'currentProgress': 0,
      'maxTargetVolume': 0,
      'uom': {'id': 'uom-1', 'code': 'M2', 'name': 'Meter Persegi'},
      'durationDays': 11,
      'assignDate': '2026-09-23',
      'targetVolume': '250.0000',
      'completedVolume': '30.5000',
      'helpersCount': 2,
      'helpers': [
        {'id': 'helper-1', 'name': 'Budi Santoso'},
        {'id': 'helper-2', 'name': 'Andi Wijaya'},
      ],
      'assignee': {'id': 'assignee-1', 'name': 'Siti Rahayu'},
      'retryCount': 1,
      'doneAt': null,
    });

    expect(task.type, 'work');
    expect(task.volumeBoq, 250);
    expect(task.uom?.code, 'M2');
    expect(task.durationDays, 11);
    expect(task.assignDate, '2026-09-23');
    expect(task.targetVolume, 250);
    expect(task.completedVolume, 30.5);
    expect(task.helpersCount, 2);
    expect(task.helpers.map((helper) => helper.name), [
      'Budi Santoso',
      'Andi Wijaya',
    ]);
    expect(task.assignees.map((helper) => helper.name), [
      'Budi Santoso',
      'Andi Wijaya',
    ]);
    expect(task.assignee?.name, 'Siti Rahayu');
    expect(task.retryCount, 1);
  });

  test('project task detail maps the current mobile API response', () {
    final task = ProjectTask.fromJson({
      'id': '01a0d119-6c83-7364-bbed-54a52bd7e671',
      'code': 'C.01',
      'title': 'Pasangan Dinding Bata Ringan Lt 1',
      'status': 'created',
      'statusLabel': 'Created',
      'canSubmit': false,
      'canBreakdown': false,
      'canAssign': true,
      'canAssignDraft': true,
      'taskType': 'work',
      'isFinalLevel': true,
      'volumeBoq': 150,
      'currentProgress': 0,
      'maxTargetVolume': 140,
      'uom': {
        'id': '019f89cd-42e1-7173-af32-1b1c19d9a4be',
        'code': 'M2',
        'name': 'Meter Persegi',
      },
      'durationDays': 11,
      'assignDate': null,
      'targetVolume': null,
      'completedVolume': null,
      'manpower': [
        {
          'id': '01a0d14e-2c62-7366-b801-87fbce8cfe55',
          'employee': {
            'id': '01a0cc6d-c3aa-733d-96f5-0507d9853a93',
            'name': 'Andi Wijaya',
            'code': 'EMP-MOBILE-04',
          },
          'helpers': [
            {
              'id': '01a0cc6d-c2ae-718f-ba3c-300f8f08327f',
              'name': 'Budi Santoso',
              'code': 'EMP-MOBILE-03',
            },
          ],
          'targetVolume': 10,
          'completedVolume': 0,
          'status': 'created',
          'statusLabel': 'Created',
          'isRevision': false,
          'canDelete': true,
          'canSubmit': false,
          'note': 'tes',
          'assignDate': '2026-09-24',
        },
      ],
      'helpersCount': 0,
      'helpers': <Object?>[],
      'assignee': null,
      'childCount': 0,
      'retryCount': 0,
      'createdBy': 'Mobile Staff',
      'createdAt': '2026-09-24T01:48:19+00:00',
      'doneAt': null,
      'evidences': <Object?>[],
    });
    final detail = ProjectTaskDetailData.fromTask(task);

    expect(task.isFinalLevel, isTrue);
    expect(task.manpower, hasLength(1));
    expect(task.manpower.single.employee?.name, 'Andi Wijaya');
    expect(task.manpower.single.employee?.code, 'EMP-MOBILE-04');
    expect(task.manpower.single.helpers.single.name, 'Budi Santoso');
    expect(task.manpower.single.targetVolume, 10);
    expect(task.manpower.single.completedVolume, 0);
    expect(task.manpower.single.statusLabel, 'Created');
    expect(task.manpower.single.canDelete, isTrue);
    expect(task.manpower.single.canSubmit, isFalse);
    expect(task.manpower.single.note, 'tes');
    expect(detail.jobItem, 'C.01 · Pasangan Dinding Bata Ringan Lt 1');
    expect(detail.status, 'Created');
    expect(detail.duration, '11 hari');
    expect(detail.boqVolume, '150 M2');
    expect(detail.currentProgress, '0/150 M2');
    expect(detail.manpower, hasLength(1));
    expect(detail.creator, 'Mobile Staff');
    expect(detail.assignee, '-');
    expect(detail.canAssign, isTrue);
    expect(detail.canAssignDraft, isTrue);
    expect(detail.isLeaf, isTrue);
    expect(detail.isApiDetail, isTrue);
  });

  test('project task reads child count only from childCount', () {
    final task = ProjectTask.fromJson({
      'childCount': 3,
      'processCount': 8,
      'childrenCount': 5,
    });
    final taskWithoutChildCount = ProjectTask.fromJson({
      'processCount': 8,
      'childrenCount': 5,
    });

    expect(task.childCount, 3);
    expect(taskWithoutChildCount.childCount, 0);
  });

  test('assigned QC task recognizes the user by assignee name only', () {
    final task = ProjectTask.fromJson({
      'id': 'qc-1',
      'status': 'created',
      'assignee': {'id': 'employee-1', 'name': 'Mobile Admin'},
    });
    final detail = ProjectTaskDetailData.fromTask(task, isQc: true);

    expect(detail.qcOwnerId, 'employee-1');
    expect(detail.qcOwnerName, 'Mobile Admin');
    expect(detail.isQcOwnedByName(' mobile admin '), isTrue);
    expect(detail.isQcOwnedByName('Other User'), isFalse);
    expect(detail.isQcOwnedByName(null), isFalse);
  });

  test('task assignee does not fall back to workTask assignee', () {
    final task = ProjectTask.fromJson({
      'id': 'qc-1',
      'workTask': {
        'assignee': {'id': 'employee-1', 'name': 'Work Assignee'},
      },
    });

    expect(task.assignee, isNull);
    expect(task.assignees, isEmpty);
  });

  test('QC detail displays creator and assignee from workTask only', () {
    final task = ProjectTask.fromJson({
      'id': 'qc-1',
      'createdBy': 'QC Creator',
      'assignee': {'id': 'qc-owner-1', 'name': 'QC Owner'},
      'decidedBy': 'QC Approver',
      'doneAt': '2026-08-27T03:57:01+00:00',
      'qcDecision': 'fail',
      'qcNote': 'Perlu diperbaiki',
      'qcEvidences': [
        {
          'id': 'evidence-1',
          'fileName': 'qc-result.jpg',
          'url': 'https://example.com/qc-result.jpg',
        },
      ],
      'workTask': {
        'createdBy': 'Work Task Creator',
        'assignee': 'Work Task Assignee',
      },
    }, useWorkTaskPeople: true);
    final detail = ProjectTaskDetailData.fromTask(task, isQc: true);

    expect(detail.creator, 'Work Task Creator');
    expect(detail.assignee, 'Work Task Assignee');
    expect(detail.qcOwnerId, 'qc-owner-1');
    expect(detail.qcOwnerName, 'QC Owner');
    expect(detail.qcApproval, 'QC Approver');
    expect(detail.qcUpdateDate, isNot('-'));
    expect(detail.qcStatus, 'fail');
    expect(detail.qcNote, 'Perlu diperbaiki');
    expect(detail.qcEvidence.single.name, 'qc-result.jpg');
  });

  test(
    'QC detail parses manpower, target, unit, and note from new response',
    () {
      final task = ProjectTask.fromJson({
        'id': 'qc-1',
        'code': 'C.01',
        'title': 'Pasangan Dinding Bata Ringan Lt 1',
        'manpowerName': 'Budi Santoso',
        'manpower': {
          'id': 'employee-1',
          'name': 'Budi Santoso',
          'code': 'EMP-MOBILE-03',
        },
        'targetVolume': 100,
        'completedVolume': 5,
        'uom': 'Meter Persegi',
        'note': 'hgjgjgj',
        'helpers': [
          {'id': 'helper-1', 'name': 'Budi'},
          {'id': 'helper-2', 'name': 'Andi'},
          {'id': 'helper-3', 'name': 'Siti'},
        ],
        'workTask': {'assignee': 'Budi Santoso', 'createdBy': 'Mobile Staff'},
      }, useWorkTaskPeople: true);
      final detail = ProjectTaskDetailData.fromTask(task, isQc: true);

      expect(task.targetVolume, 100);
      expect(task.completedVolume, 5);
      expect(task.uom?.name, 'Meter Persegi');
      expect(detail.helperSummary, 'Budi +2');
      expect(detail.target, '100 Meter Persegi');
      expect(detail.note, 'hgjgjgj');

      final listItem = ProjectTaskListItemData.fromTask(
        task,
        fallbackProjectId: 'project-1',
        isQc: true,
      );
      final cardData = listItem.toProjectMenuTaskData(
        type: ProjectTaskListPage.qualityProjectTitle,
      );
      expect(cardData.manpowerName, 'Budi Santoso');
      expect(cardData.target, '100 m²');
      expect(cardData.note, 'hgjgjgj');
    },
  );

  test('QC detail does not fall back to top-level creator and assignee', () {
    final task = ProjectTask.fromJson({
      'id': 'qc-1',
      'createdBy': 'QC Creator',
      'assignee': {'id': 'qc-owner-1', 'name': 'QC Owner'},
      'workTask': <String, dynamic>{},
    }, useWorkTaskPeople: true);
    final detail = ProjectTaskDetailData.fromTask(task, isQc: true);

    expect(detail.creator, '-');
    expect(detail.assignee, '-');
    expect(detail.qcOwnerName, 'QC Owner');
  });

  test('QC payload only accepts pass or fail', () {
    expect(
      () => ProjectQcDecisionPayload.fromJson({
        'schemaVersion': 1,
        'projectId': 'project-1',
        'qcTaskId': 'qc-1',
        'decision': 'maybe',
        'note': 'note',
        'expectedVersion': 7,
        'clientOccurredAt': '2026-07-22T03:20:10.000Z',
      }),
      throwsFormatException,
    );
  });

  test(
    'project cache survives repository recreation and stays scoped',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final first = ProjectLocalDataSource(database: database);
      final task = _taskJson();

      await first.putTaskDetail(
        scope: scope,
        projectId: 'project-1',
        task: _projectTask(task),
      );

      final recreated = ProjectLocalDataSource(database: database);
      final cached = await recreated
          .watchTaskDetail(
            scope: scope,
            projectId: 'project-1',
            taskId: 'task-1',
          )
          .first;
      final otherAccount = await recreated
          .watchTaskDetail(
            scope: const SyncScope(
              accountId: 'account-2',
              companyId: 'company-1',
            ),
            projectId: 'project-1',
            taskId: 'task-1',
          )
          .first;

      expect(cached?.value.id, 'task-1');
      expect(cached?.value.version, 12);
      expect(otherAccount, isNull);
    },
  );

  test('project list and detail cache are available offline', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = ProjectLocalDataSource(database: database);
    final project = Project.fromJson({
      'id': 'project-1',
      'code': 'PRJ-001',
      'name': 'Project Offline',
      'status': 'active',
      'createdAt': '2026-07-22T00:00:00.000Z',
    });
    final result = ProjectListResult(
      projects: [project],
      meta: ProjectPaginationMeta.fromJson({
        'currentPage': 1,
        'perPage': 15,
        'total': 1,
        'lastPage': 1,
        'from': 1,
        'to': 1,
      }),
      links: ProjectPaginationLinks.fromJson(const {}),
    );

    await local.putProjects(scope: scope, result: result);
    await local.putProjectDetail(scope: scope, project: project);

    final cachedList = await local.watchProjects(scope: scope).first;
    final cachedDetail = await local
        .watchProjectDetail(scope: scope, projectId: project.id)
        .first;

    expect(cachedList?.value.projects.single.name, 'Project Offline');
    expect(cachedDetail?.value.code, 'PRJ-001');
  });

  test('project task overview counts are available offline', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = ProjectLocalDataSource(database: database);
    final result = ProjectTasksResult(
      tasks: [_projectTask(_taskJson())],
      inProgressCount: 7,
      doneCount: 3,
    );

    await local.putTaskResult(
      scope: scope,
      projectId: 'project-1',
      tab: 'open',
      result: result,
    );
    final cached = await local
        .watchTaskResult(scope: scope, projectId: 'project-1', tab: 'open')
        .first;

    expect(cached?.value.tasks.single.id, 'task-1');
    expect(cached?.value.inProgressCount, 7);
    expect(cached?.value.doneCount, 3);
  });

  test('breakdown options and subordinates are cached offline', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = ProjectLocalDataSource(database: database);
    const option = ProjectBreakdownOption(
      id: 'boq-1',
      code: 'A.1',
      title: 'Pekerjaan sipil',
      isSelected: true,
    );
    const subordinate = ProjectReference(id: 'user-1', name: 'Budi');

    await local.putBreakdownOptions(
      scope: scope,
      projectId: 'project-1',
      taskId: 'task-1',
      options: const [option],
    );
    await local.putSubordinates(
      scope: scope,
      projectId: 'project-1',
      subordinates: const [subordinate],
    );

    final cachedOptions = await local
        .watchBreakdownOptions(
          scope: scope,
          projectId: 'project-1',
          taskId: 'task-1',
        )
        .first;
    final cachedSubordinates = await local
        .watchSubordinates(scope: scope, projectId: 'project-1')
        .first;

    expect(cachedOptions?.value.single.id, option.id);
    expect(cachedOptions?.value.single.isSelected, isTrue);
    expect(cachedSubordinates?.value.single.name, subordinate.name);
  });

  test('failed project operation blocks a replacement operation', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now().toUtc();
    OutboxOperationsCompanion operation(String id) =>
        OutboxOperationsCompanion.insert(
          operationId: id,
          idempotencyKey: id,
          accountId: scope.accountId,
          companyId: scope.companyId,
          operationType: SyncOperationType.projectTaskDone.storageName,
          targetResourceKey: 'project:p:task:t',
          endpoint: '/done',
          payloadJson: '{}',
          state: Value(OutboxState.failed.name),
          createdAt: now,
          updatedAt: now,
        );

    await database.enqueueOperation(operation('first'), const []);
    await expectLater(
      database.enqueueOperation(operation('second'), const []),
      throwsStateError,
    );
  });

  test('project retry policy follows the short foreground schedule', () {
    final policy = RetryPolicy();
    expect(
      policy.projectDelayForAttempt(1),
      greaterThanOrEqualTo(const Duration(seconds: 5)),
    );
    expect(
      policy.projectDelayForAttempt(5),
      greaterThanOrEqualTo(const Duration(minutes: 15)),
    );
  });
}

ProjectTask _projectTask(Map<String, dynamic> json) {
  // Keep the fixture focused on serialization behavior while allowing the
  // production parser to supply defaults for optional server fields.
  return ProjectTask.fromJson(json);
}

Map<String, dynamic> _taskJson() => {
  'id': 'task-1',
  'projectId': 'project-1',
  'title': 'Pasang dinding',
  'status': 'created',
  'version': 12,
};
