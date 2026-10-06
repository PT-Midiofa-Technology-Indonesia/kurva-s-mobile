import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/files/durable_file_store.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/core/sync/outbox_service.dart';
import 'package:curva_mobile/core/sync/retry_policy.dart';
import 'package:curva_mobile/core/sync/sync_engine.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';
import 'package:curva_mobile/modules/project/data/local/project_local_data_source.dart';
import 'package:curva_mobile/modules/project/data/models/project_operation_payload.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_manpower_report_controller.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';

const _scope = SyncScope(accountId: 'account', companyId: 'company');
const _query = ProjectTaskQuery(projectId: 'project', taskId: 'manpower');
const _policy = SyncPolicy(
  writeCapabilities: {
    SyncOperationType.projectTaskDone: WriteCapability.queuedWrite,
    SyncOperationType.qcTaskDecision: WriteCapability.queuedWrite,
  },
);

void main() {
  late Directory root;
  late AppDatabase database;
  late DioClient client;
  late DurableFileStore files;
  late ProjectRepository repository;
  late File evidence;
  late List<RequestOptions> requests;
  late bool networkFails;
  late int statusCode;
  late Object response;

  setUp(() async {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
    root = await Directory.systemTemp.createTemp('project_offline_');
    database = AppDatabase(NativeDatabase(File('${root.path}/db.sqlite')));
    files = DurableFileStore(rootDirectory: () async => root);
    evidence = await File('${root.path}/evidence.jpg').writeAsBytes([1, 2, 3]);
    requests = [];
    networkFails = false;
    statusCode = 200;
    response = {'message': 'OK', 'data': <String, Object?>{}};
    client = DioClient(secureStorage: _Storage());
    client.dio.httpClientAdapter = _Adapter((options) async {
      requests.add(options);
      if (networkFails) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      }
      return ResponseBody.fromString(
        jsonEncode(response),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    repository = ProjectRepository(
      dioClient: client,
      scope: _scope,
      cacheReadEnabled: true,
      localDataSource: ProjectLocalDataSource(database: database),
      outboxService: OutboxService(
        database: database,
        fileStore: files,
        policy: _policy,
      ),
    );
  });
  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
    dotenv.clean();
  });

  Future<ProviderContainer> container({
    bool offline = false,
    bool queue = true,
  }) async {
    final value = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        syncPolicyProvider.overrideWithValue(
          queue ? _policy : const SyncPolicy(),
        ),
        connectivityStateProvider.overrideWith(
          (ref) => Stream.value(
            offline
                ? const ConnectivityState.offline()
                : const ConnectivityState.online(),
          ),
        ),
        currentAccountNameProvider.overrideWithValue('Reviewer'),
      ],
    );
    addTearDown(value.dispose);
    await value.read(connectivityStateProvider.future);
    return value;
  }

  List<ProjectFileUpload> uploads() => [
    ProjectFileUpload(name: 'evidence.jpg', path: evidence.path),
  ];

  test(
    'offline report persists volume, attachments and event ID across restart, then syncs',
    () async {
      final ref = await container(offline: true);
      final provider = projectManpowerReportControllerProvider(_query);
      final subscription = ref.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        await ref
            .read(provider)
            .submit(completedVolume: 2.5, note: 'Laporan', files: uploads()),
        isTrue,
      );
      expect(requests, isEmpty);
      var operations = await database.listOperations(_scope);
      expect(operations, hasLength(1));
      final operation = operations.single;
      expect(
        operation.endpoint,
        '/v1/mobile/projects/project/tasks/manpower/done',
      );
      final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      expect(ProjectTaskDonePayload.fromJson(payload).completedVolume, 2.5);
      expect(payload['clientEventId'], operation.idempotencyKey);
      expect(
        await database.listOperations(
          const SyncScope(accountId: 'other', companyId: 'company'),
        ),
        isEmpty,
      );
      await evidence.delete();
      await database.close();
      database = AppDatabase(NativeDatabase(File('${root.path}/db.sqlite')));
      final attachments = await database.attachmentsFor(operation.operationId);
      expect(await File(attachments.single.durablePath).readAsBytes(), [
        1,
        2,
        3,
      ]);
      final engine = SyncEngine(
        database: database,
        dioClient: client,
        fileStore: files,
        retryPolicy: RetryPolicy(),
      );
      networkFails = true;
      expect((await engine.pushPending(_scope)).completedCount, 0);
      operations = await database.listOperations(_scope);
      expect(operations.single.state, 'retry');
      expect(await File(attachments.single.durablePath).exists(), isTrue);
      networkFails = false;
      await engine.makeRetriesDueForAccount(_scope.accountId);
      expect((await engine.pushPending(_scope)).completedCount, 1);
      expect(
        requests.map((request) => request.headers['Idempotency-Key']).toSet(),
        {operation.idempotencyKey},
      );
      final form = requests.last.data as FormData;
      expect(
        form.fields.firstWhere((field) => field.key == 'completedVolume').value,
        '2.5',
      );
      expect(await File(attachments.single.durablePath).exists(), isFalse);
    },
  );

  test(
    'connected but unreachable report falls back with same event ID and prevents duplicate queue',
    () async {
      networkFails = true;
      final ref = await container();
      final provider = projectManpowerReportControllerProvider(_query);
      final subscription = ref.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        await ref
            .read(provider)
            .submit(completedVolume: 2, note: 'Report', files: uploads()),
        isTrue,
      );
      final operation = (await database.listOperations(_scope)).single;
      final direct = requests.single.data as FormData;
      final eventId = direct.fields
          .firstWhere((field) => field.key == 'clientEventId')
          .value;
      expect(operation.idempotencyKey, eventId);
      expect(jsonDecode(operation.payloadJson)['clientEventId'], eventId);
      final duplicate = await repository.enqueueTaskDone(
        ProjectTaskDoneCommand(
          projectId: 'project',
          taskId: 'manpower',
          expectedVersion: 0,
          completedVolume: 2,
          files: uploads(),
        ),
      );
      expect(duplicate, isA<ProjectOperationAlreadyPending>());
      expect(await database.listOperations(_scope), hasLength(1));
    },
  );

  test(
    'flag disabled keeps report online-only and preserves event ID on retry',
    () async {
      networkFails = true;
      final ref = await container(queue: false);
      final provider = projectManpowerReportControllerProvider(_query);
      final subscription = ref.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          ref
              .read(provider)
              .submit(completedVolume: 2, note: 'Report', files: uploads()),
          throwsA(isA<ProjectNetworkException>()),
        );
      }
      expect(await database.listOperations(_scope), isEmpty);
      expect(
        requests.map((request) => request.headers['Idempotency-Key']).toSet(),
        hasLength(1),
      );
    },
  );

  test('server rejection never enters offline queue', () async {
    statusCode = 422;
    response = {'message': 'Volume invalid'};
    final ref = await container();
    final provider = projectManpowerReportControllerProvider(_query);
    final subscription = ref.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await expectLater(
      ref
          .read(provider)
          .submit(completedVolume: 2, note: 'Report', files: uploads()),
      throwsA(isA<AppException>()),
    );
    expect(await database.listOperations(_scope), isEmpty);
  });

  test(
    'QC network failure queues only owned tasks with the original event ID',
    () async {
      networkFails = true;
      final ref = await container();
      final detail = ProjectTaskDetailData.fromTask(
        ProjectTask.fromJson({
          'id': 'qc-task',
          'projectId': 'project',
          'canSubmit': true,
          'qcOwner': {'id': 'reviewer', 'name': 'Reviewer'},
        }),
        isQc: true,
      );
      final provider = projectQualityActionControllerProvider(detail);
      final subscription = ref.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final controller = ref.read(provider)..addEvidence(uploads());
      expect(
        await controller.submitDecision(decision: 'pass', note: 'Approved'),
        isTrue,
      );
      final operation = (await database.listOperations(_scope)).single;
      expect(
        operation.operationType,
        SyncOperationType.qcTaskDecision.storageName,
      );
      expect(
        operation.idempotencyKey,
        requests.single.headers['Idempotency-Key'],
      );
    },
  );

  test('QC fallback refuses unowned tasks and preserves evidence', () async {
    networkFails = true;
    final ref = await container();
    final detail = ProjectTaskDetailData.fromTask(
      ProjectTask.fromJson({
        'id': 'qc-task',
        'projectId': 'project',
        'canSubmit': true,
        'qcOwner': {'id': 'other', 'name': 'Other reviewer'},
      }),
      isQc: true,
    );
    final provider = projectQualityActionControllerProvider(detail);
    final subscription = ref.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = ref.read(provider)..addEvidence(uploads());
    await expectLater(
      controller.submitDecision(decision: 'pass', note: 'Approved'),
      throwsA(isA<AppException>()),
    );
    expect(controller.selectedEvidence, hasLength(1));
    expect(await database.listOperations(_scope), isEmpty);
  });

  test(
    'QC canonical cache keeps work task people separate from QC owner',
    () async {
      await repository.enqueueQcDecision(
        ProjectQcDecisionCommand(
          projectId: 'project',
          qcTaskId: 'qc-task',
          decision: 'pass',
          note: 'Approved',
          expectedVersion: 0,
          files: uploads(),
        ),
      );
      response = {
        'data': {
          'qcTask': {
            'id': 'qc-task',
            'projectId': 'project',
            'status': 'qc_passed',
            'assignee': {'id': 'reviewer', 'name': 'Reviewer'},
            'workTask': {
              'assignee': {'id': 'worker', 'name': 'Worker'},
            },
          },
        },
      };
      final engine = SyncEngine(
        database: database,
        dioClient: client,
        fileStore: files,
        retryPolicy: RetryPolicy(),
      );
      expect((await engine.pushPending(_scope)).completedCount, 1);
      final cached = await ProjectLocalDataSource(database: database)
          .watchTaskDetail(
            scope: _scope,
            projectId: 'project',
            taskId: 'qc-task',
            qc: true,
          )
          .first;
      expect(cached?.value.assignee?.name, 'Worker');
      expect(cached?.value.qcOwner?.name, 'Reviewer');
      expect(cached?.value.status, 'qc_passed');
    },
  );

  for (final qc in [false, true]) {
    test(
      'history cache qc=$qc survives restart and respects scope and flag',
      () async {
        response = {
          'data': [
            {
              'projectTaskId': 'manpower',
              'note': 'Saved history',
              'event': 'done',
            },
          ],
        };
        Future<List<ProjectTaskHistoryEntry>> fetch(ProjectRepository repo) =>
            qc
            ? repo.fetchQcTaskHistory(
                projectId: 'project',
                qcTaskId: 'manpower',
              )
            : repo.fetchTaskHistory(
                projectId: 'project',
                manpowerTaskId: 'manpower',
              );
        expect((await fetch(repository)).single.note, 'Saved history');
        await database.close();
        database = AppDatabase(NativeDatabase(File('${root.path}/db.sqlite')));
        networkFails = true;
        ProjectRepository recreate({
          SyncScope scope = _scope,
          bool enabled = true,
        }) => ProjectRepository(
          dioClient: client,
          scope: scope,
          cacheReadEnabled: enabled,
          localDataSource: ProjectLocalDataSource(database: database),
        );
        expect((await fetch(recreate())).single.note, 'Saved history');
        await expectLater(
          fetch(recreate(enabled: false)),
          throwsA(isA<ProjectNetworkException>()),
        );
        await expectLater(
          fetch(
            recreate(
              scope: const SyncScope(accountId: 'other', companyId: 'company'),
            ),
          ),
          throwsA(isA<ProjectNetworkException>()),
        );
      },
    );
  }
}

class _Storage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.callback);
  final Future<ResponseBody> Function(RequestOptions) callback;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => callback(options);
  @override
  void close({bool force = false}) {}
}
