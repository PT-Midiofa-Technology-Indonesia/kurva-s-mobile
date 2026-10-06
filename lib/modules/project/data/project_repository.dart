import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/outbox_service.dart';
import '../../../core/sync/sync_models.dart';
import 'local/project_local_data_source.dart';
import 'models/project_operation_payload.dart';
import 'models/project_models.dart';

class ProjectRepository {
  const ProjectRepository({
    required DioClient dioClient,
    ProjectLocalDataSource? localDataSource,
    OutboxService? outboxService,
    SyncScope? scope,
    void Function(String historyPath)? onHistoryRead,
    bool cacheReadEnabled = false,
  }) : _cacheReadEnabled = cacheReadEnabled,
       _dioClient = dioClient,
       _localDataSource = localDataSource,
       _outboxService = outboxService,
       _scope = scope,
       _onHistoryRead = onHistoryRead;

  final void Function(String historyPath)? _onHistoryRead;

  final bool _cacheReadEnabled;
  final DioClient _dioClient;
  final ProjectLocalDataSource? _localDataSource;
  final OutboxService? _outboxService;
  final SyncScope? _scope;

  Future<ProjectListResult> fetchProjects({
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    String? year,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects',
        queryParameters: _queryParameters({
          'search': search,
          'status': status,
          'startDate': startDate,
          'endDate': endDate,
          'year': year,
          'sortOrder': sortOrder,
          'perPage': perPage,
          'page': page,
        }),
      );
      final result = ProjectListResult.fromJson(_responseData(response));
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putProjects(
          scope: scope,
          result: result,
          query: projectListCacheQuery(
            search: search,
            status: status,
            startDate: startDate,
            endDate: endDate,
            year: year,
            sortOrder: sortOrder,
            perPage: perPage,
            page: page,
          ),
        );
      }
      return result;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Project> fetchProjectDetail(String projectId) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId',
      );
      final data = _responseData(response);

      final project = ApiResponse.fromJson<Project>(
        data,
        (json) => Project.fromJson(json as Map<String, dynamic>),
      ).data;
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putProjectDetail(
          scope: scope,
          project: project,
        );
      }
      return project;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<bool> fetchHistoryHasUnread(
    String projectId, {
    required bool isQc,
  }) async {
    try {
      final taskType = isQc ? 'qc-tasks' : 'tasks';
      // Resolve from the host so a base URL ending in /api does not duplicate it.
      final uri = Uri.parse(
        _dioClient.dio.options.baseUrl,
      ).resolve('/api/v1/mobile/projects/$projectId/$taskType/history-status');
      final response = await _dioClient.dio.get<Object?>(uri.toString());
      return _responseObject(response)['hasUnread'] == true;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<bool> fetchTaskChildrenHistoryHasUnread({
    required String projectId,
    required String parentTaskId,
  }) async {
    try {
      final uri = Uri.parse(_dioClient.dio.options.baseUrl).resolve(
        '/api/v1/mobile/projects/$projectId/tasks/$parentTaskId/children/history-status',
      );
      final response = await _dioClient.dio.get<Object?>(uri.toString());
      return _responseObject(response)['hasUnread'] == true;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<ProjectTasksResult> fetchProjectTasks(
    String projectId, {
    String? tab,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/tasks',
        queryParameters: _queryParameters({'tab': tab}),
      );

      final result = ProjectTasksResult.fromPayload(_responseData(response));
      if (tab == 'history') _onHistoryRead?.call('$projectId/tasks');
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putTaskResult(
          scope: scope,
          projectId: projectId,
          tab: tab,
          result: result,
        );
      }
      return result;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProjectTask>> fetchTaskChildren({
    required String projectId,
    required String taskId,
    String? tab,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/children',
        queryParameters: _queryParameters({'tab': tab}),
      );

      final tasks = ProjectTask.listFromPayload(_responsePayload(response));
      if (tab == 'history') {
        _onHistoryRead?.call('$projectId/tasks/$taskId/children');
      }
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putTasks(
          scope: scope,
          projectId: projectId,
          taskId: taskId,
          tab: tab,
          children: true,
          tasks: tasks,
        );
      }
      return tasks;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<ProjectTask> fetchTaskDetail({
    required String projectId,
    required String taskId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId',
      );

      final task = ProjectTask.fromJson(_responseObject(response));
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putTaskDetail(
          scope: scope,
          projectId: projectId,
          task: task,
        );
      }
      return task;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<bool> fetchManpowerHistoryHasUnread({
    required String projectId,
    required String manpowerTaskId,
  }) async {
    try {
      final uri = Uri.parse(_dioClient.dio.options.baseUrl).resolve(
        '/api/v1/mobile/projects/$projectId/tasks/$manpowerTaskId/history/history-status',
      );
      final response = await _dioClient.dio.get<Object?>(uri.toString());
      return _responseObject(response)['hasUnread'] == true;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProjectTaskHistoryEntry>> fetchTaskHistory({
    required String projectId,
    required String manpowerTaskId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$manpowerTaskId/history',
      );
      _onHistoryRead?.call('$projectId/tasks/$manpowerTaskId/history');
      final items = _responseList(
        response,
        keys: const ['history', 'items', 'data'],
      );

      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putHistory(
          scope: scope,
          projectId: projectId,
          taskId: manpowerTaskId,
          qc: false,
          items: items,
        );
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProjectTaskHistoryEntry.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      final scope = _scope;
      if (_cacheReadEnabled &&
          scope != null &&
          error.response?.statusCode != 401 &&
          error.response?.statusCode != 403) {
        final cached = await _localDataSource?.readHistory(
          scope: scope,
          projectId: projectId,
          taskId: manpowerTaskId,
          qc: false,
        );
        if (cached != null) return cached;
      }
      throw _mapDioException(error);
    }
  }

  Future<bool> fetchQcHistoryHasUnread({
    required String projectId,
    required String qcTaskId,
  }) async {
    try {
      final uri = Uri.parse(_dioClient.dio.options.baseUrl).resolve(
        '/api/v1/mobile/projects/$projectId/qc-tasks/$qcTaskId/history/history-status',
      );
      final response = await _dioClient.dio.get<Object?>(uri.toString());
      return _responseObject(response)['hasUnread'] == true;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProjectTaskHistoryEntry>> fetchQcTaskHistory({
    required String projectId,
    required String qcTaskId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/qc-tasks/$qcTaskId/history',
      );
      _onHistoryRead?.call('$projectId/qc-tasks/$qcTaskId/history');
      final items = _responseList(
        response,
        keys: const ['history', 'items', 'data'],
      );

      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putHistory(
          scope: scope,
          projectId: projectId,
          taskId: qcTaskId,
          qc: true,
          items: items,
        );
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProjectTaskHistoryEntry.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      final scope = _scope;
      if (_cacheReadEnabled &&
          scope != null &&
          error.response?.statusCode != 401 &&
          error.response?.statusCode != 403) {
        final cached = await _localDataSource?.readHistory(
          scope: scope,
          projectId: projectId,
          taskId: qcTaskId,
          qc: true,
        );
        if (cached != null) return cached;
      }
      throw _mapDioException(error);
    }
  }

  Future<String?> submitTaskDone({
    required String projectId,
    required String taskId,
    String note = '',
    List<ProjectFileUpload> files = const [],
    String? clientEventId,
  }) async {
    final eventId = clientEventId ?? const Uuid().v4();
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/done',
        options: Options(headers: {'Idempotency-Key': eventId}),
        data: await _taskDoneFormData(
          note: note,
          files: files,
          clientEventId: eventId,
        ),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitManpowerDailyReport({
    required String projectId,
    required String manpowerTaskId,
    required double completedVolume,
    required String note,
    required List<ProjectFileUpload> files,
    String? clientEventId,
  }) async {
    final eventId = clientEventId ?? const Uuid().v4();
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$manpowerTaskId/done',
        options: Options(headers: {'Idempotency-Key': eventId}),
        data: await _taskDoneFormData(
          note: note,
          files: files,
          completedVolume: completedVolume,
          clientEventId: eventId,
        ),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<ProjectOperationEnqueueResult> enqueueTaskDone(
    ProjectTaskDoneCommand command,
  ) async {
    final outbox = _requireOutbox();
    final scope = _requireScope();
    if (command.files.isEmpty) {
      return const ProjectOperationStoreFailed('Bukti task wajib diunggah.');
    }
    final target = 'project:${command.projectId}:task:${command.taskId}';
    final existing = await outbox.activeOperationId(
      scope: scope,
      operationType: SyncOperationType.projectTaskDone,
      targetResourceKey: target,
    );
    if (existing != null) {
      return ProjectOperationAlreadyPending(existing);
    }
    try {
      final occurredAt = DateTime.now().toUtc();
      final operationId = await outbox.enqueue(
        EnqueueOperationInput(
          scope: scope,
          operationType: SyncOperationType.projectTaskDone,
          clientEventId: command.clientEventId,
          targetResourceKey: target,
          endpoint:
              '/v1/mobile/projects/${command.projectId}/tasks/${command.taskId}/done',
          payload: ProjectTaskDonePayload(
            projectId: command.projectId,
            taskId: command.taskId,
            note: command.note,
            completedVolume: command.completedVolume,
            expectedVersion: command.expectedVersion,
            clientOccurredAt: occurredAt,
          ).toJson(),
          attachments: command.files.map(_attachmentInput).toList(),
        ),
      );
      return ProjectOperationStored(operationId);
    } catch (error) {
      return ProjectOperationStoreFailed(_safeStoreMessage(error));
    }
  }

  Future<List<ProjectBreakdownOption>> fetchBreakdownOptions({
    required String projectId,
    required String taskId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/breakdown-options',
      );

      final options = ProjectBreakdownOption.listFromPayload(
        _responsePayload(response),
      );
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putBreakdownOptions(
          scope: scope,
          projectId: projectId,
          taskId: taskId,
          options: options,
        );
      }
      return options;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitTaskBreakdown({
    required String projectId,
    required String taskId,
    required List<String> boqItemIds,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/breakdown',
        data: {'boqItemIds': boqItemIds},
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProjectReference>> fetchProjectSubordinates(
    String projectId,
  ) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/subordinates',
      );
      final items = _responseList(
        response,
        keys: const ['subordinates', 'employees', 'items', 'data'],
      );

      final subordinates = items
          .whereType<Map<String, dynamic>>()
          .map(ProjectReference.fromJson)
          .toList(growable: false);
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putSubordinates(
          scope: scope,
          projectId: projectId,
          subordinates: subordinates,
        );
      }
      return subordinates;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProjectHelper>> fetchProjectHelpers(String projectId) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/helpers',
      );
      final items = _responseList(response, keys: const ['helpers', 'data']);

      return items
          .whereType<Map<String, dynamic>>()
          .map(ProjectHelper.fromJson)
          .where((helper) => helper.id.isNotEmpty && helper.name.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitTaskManpower({
    required String projectId,
    required String taskId,
    required String employeeId,
    required double target,
    required List<String> helperEmployeeIds,
    required String note,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/manpower',
        data: {
          'employeeId': employeeId,
          'target': target,
          'helperEmployeeIds': helperEmployeeIds,
          'note': note,
        },
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> updateTaskManpower({
    required String projectId,
    required String taskId,
    required String manpowerTaskId,
    required String employeeId,
    required double target,
    required List<String> helperEmployeeIds,
    required String note,
  }) async {
    try {
      final response = await _dioClient.dio.put<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/manpower/$manpowerTaskId',
        data: {
          'employeeId': employeeId,
          'target': target,
          'helperEmployeeIds': helperEmployeeIds,
          'note': note,
        },
      );
      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> deleteTaskManpower({
    required String projectId,
    required String taskId,
    required String manpowerTaskId,
  }) async {
    try {
      final response = await _dioClient.dio.delete<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/manpower/$manpowerTaskId',
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> delegateFinalTask({
    required String projectId,
    required String taskId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/delegate-final',
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> assignTask({
    required String projectId,
    required String taskId,
    required String employeeId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/tasks/$taskId/assign',
        data: {'employeeId': employeeId},
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> bulkAssignQcTasks({
    required String projectId,
    required List<String> taskIds,
    required String employeeId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/qc-tasks/bulk-assign',
        data: {'taskIds': taskIds, 'employeeId': employeeId},
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<List<ProjectTask>> fetchQcTasks(
    String projectId, {
    String? tab,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/qc-tasks',
        queryParameters: _queryParameters({'tab': tab}),
      );
      if (tab == 'history') _onHistoryRead?.call('$projectId/qc-tasks');

      final tasks = ProjectTask.listFromPayload(_responsePayload(response));
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putTasks(
          scope: scope,
          projectId: projectId,
          tab: tab,
          qc: true,
          tasks: tasks,
        );
      }
      return tasks;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<ProjectTask> fetchQcTaskDetail({
    required String projectId,
    required String qcTaskId,
  }) async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        '/v1/mobile/projects/$projectId/qc-tasks/$qcTaskId',
      );

      final task = ProjectTask.fromJson(
        _responseObject(response),
        useWorkTaskPeople: true,
      );
      final scope = _scope;
      if (scope != null) {
        await _localDataSource?.putTaskDetail(
          scope: scope,
          projectId: projectId,
          task: task,
          qc: true,
        );
      }
      return task;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> claimQcTask({
    required String projectId,
    required String qcTaskId,
  }) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/qc-tasks/$qcTaskId/claim',
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<String?> submitQcDecision({
    required String projectId,
    required String qcTaskId,
    required String decision,
    String note = '',
    List<ProjectFileUpload> files = const [],
    String? clientEventId,
  }) async {
    final eventId = clientEventId ?? const Uuid().v4();
    try {
      final response = await _dioClient.dio.post<Object?>(
        '/v1/mobile/projects/$projectId/qc-tasks/$qcTaskId/decision',
        options: Options(headers: {'Idempotency-Key': eventId}),
        data: await _qcDecisionFormData(
          decision: decision,
          note: note,
          files: files,
          clientEventId: eventId,
        ),
      );

      return _responseMessage(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<ProjectOperationEnqueueResult> enqueueQcDecision(
    ProjectQcDecisionCommand command,
  ) async {
    if (command.decision != 'pass' && command.decision != 'fail') {
      return const ProjectOperationStoreFailed(
        'Keputusan QC harus lulus atau gagal.',
      );
    }
    if (command.note.trim().isEmpty) {
      return const ProjectOperationStoreFailed('Catatan QC wajib diisi.');
    }
    if (command.files.isEmpty) {
      return const ProjectOperationStoreFailed('Bukti QC wajib diunggah.');
    }
    final outbox = _requireOutbox();
    final scope = _requireScope();
    final target = 'project:${command.projectId}:qc-task:${command.qcTaskId}';
    final existing = await outbox.activeOperationId(
      scope: scope,
      operationType: SyncOperationType.qcTaskDecision,
      targetResourceKey: target,
    );
    if (existing != null) {
      return ProjectOperationAlreadyPending(existing);
    }
    try {
      final operationId = await outbox.enqueue(
        EnqueueOperationInput(
          scope: scope,
          operationType: SyncOperationType.qcTaskDecision,
          clientEventId: command.clientEventId,
          targetResourceKey: target,
          endpoint:
              '/v1/mobile/projects/${command.projectId}/qc-tasks/${command.qcTaskId}/decision',
          payload: ProjectQcDecisionPayload(
            projectId: command.projectId,
            qcTaskId: command.qcTaskId,
            decision: command.decision,
            note: command.note.trim(),
            expectedVersion: command.expectedVersion,
            clientOccurredAt: DateTime.now().toUtc(),
          ).toJson(),
          attachments: command.files.map(_attachmentInput).toList(),
        ),
      );
      return ProjectOperationStored(operationId);
    } catch (error) {
      return ProjectOperationStoreFailed(_safeStoreMessage(error));
    }
  }

  Stream<CachedReference<List<ProjectTask>>?> watchProjectTasks(
    String projectId, {
    String? tab,
    bool qc = false,
    bool children = false,
    String? taskId,
  }) {
    return _requireLocal().watchTasks(
      scope: _requireScope(),
      projectId: projectId,
      tab: tab,
      qc: qc,
      children: children,
      taskId: taskId,
    );
  }

  Stream<CachedReference<ProjectTasksResult>?> watchProjectTaskResult(
    String projectId, {
    String? tab,
  }) {
    return _requireLocal().watchTaskResult(
      scope: _requireScope(),
      projectId: projectId,
      tab: tab,
    );
  }

  Stream<CachedReference<ProjectListResult>?> watchProjects({
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    String? year,
    String? sortOrder,
    int? perPage,
    int? page,
  }) {
    return _requireLocal().watchProjects(
      scope: _requireScope(),
      query: projectListCacheQuery(
        search: search,
        status: status,
        startDate: startDate,
        endDate: endDate,
        year: year,
        sortOrder: sortOrder,
        perPage: perPage,
        page: page,
      ),
    );
  }

  Stream<CachedReference<Project>?> watchProjectDetail(String projectId) {
    return _requireLocal().watchProjectDetail(
      scope: _requireScope(),
      projectId: projectId,
    );
  }

  Stream<CachedReference<List<ProjectBreakdownOption>>?> watchBreakdownOptions({
    required String projectId,
    required String taskId,
  }) {
    return _requireLocal().watchBreakdownOptions(
      scope: _requireScope(),
      projectId: projectId,
      taskId: taskId,
    );
  }

  Stream<CachedReference<List<ProjectReference>>?> watchSubordinates(
    String projectId,
  ) {
    return _requireLocal().watchSubordinates(
      scope: _requireScope(),
      projectId: projectId,
    );
  }

  Map<String, Object?> projectListCacheQuery({
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    String? year,
    String? sortOrder,
    int? perPage,
    int? page,
  }) {
    return _queryParameters({
      'search': search,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'year': year,
      'sortOrder': sortOrder,
      'perPage': perPage,
      'page': page,
    });
  }

  Stream<CachedReference<ProjectTask>?> watchProjectTaskDetail({
    required String projectId,
    required String taskId,
    bool qc = false,
  }) {
    return _requireLocal().watchTaskDetail(
      scope: _requireScope(),
      projectId: projectId,
      taskId: taskId,
      qc: qc,
    );
  }

  ProjectLocalDataSource _requireLocal() {
    final local = _localDataSource;
    if (local == null) throw StateError('Cache project belum tersedia.');
    return local;
  }

  OutboxService _requireOutbox() {
    final outbox = _outboxService;
    if (outbox == null) throw StateError('Outbox project belum tersedia.');
    return outbox;
  }

  SyncScope _requireScope() {
    final scope = _scope;
    if (scope == null) throw StateError('Session aktif tidak tersedia.');
    return scope;
  }

  AttachmentInput _attachmentInput(ProjectFileUpload file) {
    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const AppException('File tidak dapat dibaca.');
    }
    return AttachmentInput(
      sourcePath: path,
      fieldName: 'files[]',
      mimeType: file.mimeType,
    );
  }

  String _safeStoreMessage(Object error) {
    if (error is AppException) return error.message;
    return error.toString().replaceFirst('Bad state: ', '');
  }

  Map<String, Object?> _queryParameters(Map<String, Object?> values) {
    return Map.fromEntries(
      values.entries.where((entry) {
        final value = entry.value;
        if (value == null) return false;
        if (value is String) return value.isNotEmpty;
        return true;
      }),
    );
  }

  Map<String, dynamic> _responseData(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const AppException('Format respons server tidak valid.');
  }

  Object? _responsePayload(Response<Object?> response) {
    final data = _responseData(response);
    return data['data'] ?? data;
  }

  Map<String, dynamic> _responseObject(Response<Object?> response) {
    final payload = _responsePayload(response);
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    throw const AppException('Format respons server tidak valid.');
  }

  List<Object?> _responseList(
    Response<Object?> response, {
    required List<String> keys,
  }) {
    return _extractList(_responsePayload(response), keys: keys);
  }

  String? _responseMessage(Response<Object?> response) {
    return _responseData(response)['message'] as String?;
  }

  Future<FormData> _taskDoneFormData({
    required String note,
    required List<ProjectFileUpload> files,
    double? completedVolume,
    required String clientEventId,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('clientEventId', clientEventId));
    formData.fields.add(MapEntry('note', note));
    if (completedVolume != null) {
      formData.fields.add(
        MapEntry('completedVolume', completedVolume.toString()),
      );
    }
    for (final file in files) {
      formData.files.add(MapEntry('files[]', await file.toMultipartFile()));
    }
    return formData;
  }

  Future<FormData> _qcDecisionFormData({
    required String decision,
    required String note,
    required List<ProjectFileUpload> files,
    required String clientEventId,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('clientEventId', clientEventId));
    formData.fields.add(MapEntry('decision', decision));
    formData.fields.add(MapEntry('note', note));
    for (final file in files) {
      formData.files.add(MapEntry('files[]', await file.toMultipartFile()));
    }
    return formData;
  }

  AppException _mapDioException(DioException error) {
    final mapped = ErrorMapper.fromDio(error);
    if (error.response == null &&
        const {
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.unknown,
        }.contains(error.type)) {
      return ProjectNetworkException(mapped.message);
    }
    return mapped;
  }
}

class ProjectFileUpload {
  const ProjectFileUpload({required this.name, required this.path});

  final String name;
  final String? path;

  String get mimeType {
    final extension = name.toLowerCase().split('.').last;
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  Future<MultipartFile> toMultipartFile() {
    final uploadPath = path;
    if (uploadPath != null && uploadPath.isNotEmpty) {
      return MultipartFile.fromFile(uploadPath, filename: name);
    }

    throw const AppException('File tidak dapat dibaca.');
  }
}

class ProjectTaskDoneCommand {
  const ProjectTaskDoneCommand({
    required this.projectId,
    required this.taskId,
    required this.expectedVersion,
    this.note = '',
    this.completedVolume,
    this.files = const [],
    this.clientEventId,
  });

  final String projectId;
  final String taskId;
  final int expectedVersion;
  final String note;
  final double? completedVolume;
  final List<ProjectFileUpload> files;
  final String? clientEventId;
}

class ProjectQcDecisionCommand {
  const ProjectQcDecisionCommand({
    required this.projectId,
    required this.qcTaskId,
    required this.decision,
    required this.note,
    required this.expectedVersion,
    this.files = const [],
    this.clientEventId,
  });

  final String projectId;
  final String qcTaskId;
  final String decision;
  final String note;
  final int expectedVersion;
  final List<ProjectFileUpload> files;
  final String? clientEventId;
}

sealed class ProjectOperationEnqueueResult {
  const ProjectOperationEnqueueResult();
}

class ProjectOperationStored extends ProjectOperationEnqueueResult {
  const ProjectOperationStored(this.operationId);
  final String operationId;
}

class ProjectOperationAlreadyPending extends ProjectOperationEnqueueResult {
  const ProjectOperationAlreadyPending(this.operationId);
  final String operationId;
}

class ProjectOperationStoreFailed extends ProjectOperationEnqueueResult {
  const ProjectOperationStoreFailed(this.message);
  final String message;
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

class ProjectNetworkException extends AppException {
  const ProjectNetworkException(super.message)
    : super(kind: AppExceptionKind.connection);
}
