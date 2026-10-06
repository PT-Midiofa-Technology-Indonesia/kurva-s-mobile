import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/meeting/data/meeting_repository.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/controllers/meeting_action_controllers.dart';
import 'package:curva_mobile/shared/forms/form_submit_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test(
    'task done controller validates evidence before repository call',
    () async {
      final repository = _FakeMeetingRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      const query = MeetingTaskQuery(
        meetingId: 'meeting-1',
        taskId: 'task-1',
        isQuality: false,
      );
      final controller = container.read(
        meetingTaskDoneControllerProvider(query),
      );

      final invalid = await controller.submit();

      expect(invalid, isA<FormSubmitInvalid>());
      expect(controller.evidenceError, 'Bukti wajib diunggah.');
      expect(repository.taskDoneCalls, 0);

      controller.addEvidence(const [
        MeetingSelectedFile(name: 'proof.jpg', path: '/tmp/proof.jpg', size: 3),
      ]);
      expect(controller.evidenceError, isNull);

      final success = await controller.submit();

      expect(success, isA<FormSubmitSuccess>());
      expect(repository.taskDoneCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
    },
  );

  test(
    'QC controller revalidates fields and maps backend field errors',
    () async {
      final repository = _FakeMeetingRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      const query = MeetingTaskQuery(
        meetingId: 'meeting-1',
        taskId: 'qc-1',
        isQuality: true,
      );
      final controller = container.read(
        meetingQualityDecisionControllerProvider(query),
      );

      final invalid = await controller.submit('pass');

      expect(invalid, isA<FormSubmitInvalid>());
      expect(controller.noteError, 'Catatan QC wajib diisi.');
      expect(controller.evidenceError, 'Bukti QC wajib diunggah.');

      controller.noteController.text = 'Looks good';
      controller.addEvidence(const [
        MeetingSelectedFile(name: 'proof.jpg', path: '/tmp/proof.jpg', size: 3),
      ]);
      expect(controller.noteError, isNull);
      expect(controller.evidenceError, isNull);

      repository.qcError = const AppException(
        'Invalid',
        details: ['note: Catatan terlalu pendek.'],
      );
      final serverInvalid = await controller.submit('pass');

      expect(serverInvalid, isA<FormSubmitInvalid>());
      expect(controller.noteError, 'Catatan terlalu pendek.');
    },
  );

  test('QC history propagates close tab to QC requests', () async {
    final repository = _FakeMeetingRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    const query = MeetingTasksQuery(
      meetingId: 'meeting-1',
      isQuality: true,
      tab: 'close',
    );

    final tasks = await container.read(meetingTasksProvider(query).future);

    expect(tasks.single.id, 'qc-1');
    expect(repository.qcTaskTab, 'close');
  });

  test('meeting overview propagates selected tab to task requests', () async {
    final repository = _FakeMeetingRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    const query = MeetingTasksQuery(
      meetingId: 'meeting-1',
      isQuality: false,
      tab: 'history',
    );

    final result = await container.read(
      meetingOverviewTasksProvider(query).future,
    );

    expect(result.tasks.single.id, 'overview-task-1');
    expect(repository.overviewTaskTab, 'history');
  });

  test('assignee controller returns explicit success result', () async {
    final repository = _FakeMeetingRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    const query = MeetingTaskQuery(
      meetingId: 'meeting-1',
      taskId: 'task-1',
      isQuality: false,
    );
    final controller = container.read(
      meetingAssigneeActionControllerProvider(query),
    );

    final result = await controller.assign('employee-1');

    expect(result, isA<FormSubmitSuccess>());
    expect(repository.assignedEmployeeId, 'employee-1');
  });
}

ProviderContainer _container(_FakeMeetingRepository repository) {
  return ProviderContainer(
    overrides: [
      meetingRepositoryProvider.overrideWithValue(repository),
      meetingCompanyIdProvider.overrideWithValue('company-1'),
    ],
  );
}

class _FakeMeetingRepository extends MeetingRepository {
  _FakeMeetingRepository()
    : super(dioClient: DioClient(secureStorage: _FakeSecureStorage()));

  int taskDoneCalls = 0;
  String? lastCompanyId;
  AppException? qcError;
  String? sourceTaskTab;
  String? qcTaskTab;
  String? overviewTaskTab;
  String? assignedEmployeeId;

  @override
  Future<String?> submitTaskDone({
    required String meetingId,
    required String taskId,
    required List<MeetingFileUpload> files,
    String note = '',
    String? companyId,
  }) async {
    taskDoneCalls++;
    lastCompanyId = companyId;
    return 'Submitted';
  }

  @override
  Future<String?> submitQcDecision({
    required String meetingId,
    required String qcTaskId,
    required String decision,
    required String note,
    required List<MeetingFileUpload> files,
    String? companyId,
  }) async {
    final error = qcError;
    if (error != null) throw error;
    return 'Approved';
  }

  @override
  Future<String?> assignTask({
    required String meetingId,
    required String taskId,
    required String employeeId,
    String? companyId,
  }) async {
    assignedEmployeeId = employeeId;
    return 'Assigned';
  }

  @override
  Future<List<MeetingTask>> fetchTasks({
    required String meetingId,
    String tab = 'open',
    String? companyId,
  }) async {
    sourceTaskTab = tab;
    return [_task(id: 'task-1')];
  }

  @override
  Future<List<MeetingTask>> fetchQcTasks({
    required String meetingId,
    String tab = 'open',
    String? companyId,
  }) async {
    qcTaskTab = tab;
    return [_task(id: 'qc-1')];
  }

  @override
  Future<MeetingTasksResult> fetchTasksResult({
    required String meetingId,
    String? tab,
    String? companyId,
  }) async {
    overviewTaskTab = tab;
    return MeetingTasksResult(
      tasks: [_task(id: 'overview-task-1')],
      inProgressCount: 1,
      doneCount: 0,
    );
  }
}

MeetingTask _task({required String id}) {
  return MeetingTask(
    id: id,
    meetingId: 'meeting-1',
    code: 'A.1',
    title: 'Task',
    projectName: 'Project',
    status: 'done',
    creator: null,
    assignee: null,
    assignees: const [],
    createdAt: null,
    updatedAt: null,
    previousEvidence: const [],
  );
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => null;
}
