import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/server_refresh_delay.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_assignee_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_sub_task_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';

final projectTaskActionControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ProjectTaskActionController, ProjectTaskDetailData>((ref, detail) {
      return ProjectTaskActionController(ref, detail);
    });

final projectQualityActionControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<ProjectQualityActionController, ProjectTaskDetailData>((
      ref,
      detail,
    ) {
      return ProjectQualityActionController(ref, detail);
    });

final projectBreakdownActionControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<ProjectBreakdownActionController, ProjectSubTaskPickerData>((
      ref,
      detail,
    ) {
      return ProjectBreakdownActionController(ref, detail);
    });

final projectAssigneeActionControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<ProjectAssigneeActionController, ProjectAssigneePickerArgs>((
      ref,
      args,
    ) {
      return ProjectAssigneeActionController(ref, args);
    });

class ProjectTaskActionController extends ChangeNotifier {
  ProjectTaskActionController(this._ref, this.initialDetail);

  final Ref _ref;
  final ProjectTaskDetailData initialDetail;
  final selectedEvidence = <ProjectFileUpload>[];
  ProjectTaskDetailData? loadedDetail;
  bool isSubmitting = false;
  String? _clientEventId;

  ProjectTaskDetailData get actionDetail => loadedDetail ?? initialDetail;

  void setLoadedDetail(ProjectTaskDetailData value) {
    if (loadedDetail?.statusKey == value.statusKey &&
        loadedDetail?.taskId == value.taskId &&
        loadedDetail?.version == value.version) {
      return;
    }
    loadedDetail = value;
    notifyListeners();
  }

  void addEvidence(Iterable<ProjectFileUpload> files) {
    selectedEvidence.addAll(files);
    notifyListeners();
  }

  void removeEvidenceAt(int index) {
    selectedEvidence.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitDone() async {
    if (isSubmitting) return false;
    final detail = actionDetail;
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final repository = _ref.read(projectRepositoryProvider);
      final canQueue = _ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.projectTaskDone);
      final isOffline =
          _ref.read(connectivityStateProvider).valueOrNull?.isOffline ?? false;
      final shouldQueue = canQueue && isOffline;
      if (!shouldQueue) {
        try {
          await repository.submitTaskDone(
            projectId: detail.projectId,
            taskId: detail.taskId,
            files: List.unmodifiable(selectedEvidence),
            clientEventId: _clientEventId ??= const Uuid().v4(),
          );
        } on ProjectNetworkException {
          if (!canQueue) rethrow;
          return await _enqueueOffline(repository);
        }
        _clientEventId = null;
        selectedEvidence.clear();
        await waitForServerRefresh();
        _ref.invalidate(
          projectTaskDetailProvider(
            ProjectTaskQuery(
              projectId: detail.projectId,
              taskId: detail.taskId,
            ),
          ),
        );
        _ref
          ..invalidate(projectTasksProvider)
          ..invalidate(projectTaskChildrenProvider)
          ..invalidate(projectQcTasksProvider)
          ..invalidate(projectDetailProvider(detail.projectId));
        return false;
      }
      return await _enqueueOffline(repository);
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }

  Future<bool> _enqueueOffline(ProjectRepository repository) async {
    final detail = actionDetail;
    final result = await repository.enqueueTaskDone(
      ProjectTaskDoneCommand(
        projectId: detail.projectId,
        taskId: detail.taskId,
        expectedVersion: detail.version,
        clientEventId: _clientEventId ??= const Uuid().v4(),
        files: List.unmodifiable(selectedEvidence),
      ),
    );
    if (result is ProjectOperationStoreFailed) {
      throw AppException(result.message);
    }
    _clientEventId = null;
    selectedEvidence.clear();
    return true;
  }
}

class ProjectQualityActionController extends ChangeNotifier {
  ProjectQualityActionController(this._ref, this.initialDetail);

  final Ref _ref;
  final ProjectTaskDetailData initialDetail;
  final selectedEvidence = <ProjectFileUpload>[];
  ProjectTaskDetailData? loadedDetail;
  bool isSubmitting = false;
  String? submittingDecision;
  String? _clientEventId;
  bool isQcCompleted = true;

  ProjectTaskDetailData get actionDetail => loadedDetail ?? initialDetail;

  void setLoadedDetail(ProjectTaskDetailData value) {
    if (loadedDetail?.version == value.version &&
        loadedDetail?.taskId == value.taskId &&
        loadedDetail?.statusKey == value.statusKey &&
        loadedDetail?.canSubmitFromApi == value.canSubmitFromApi &&
        loadedDetail?.qcOwnerId == value.qcOwnerId &&
        loadedDetail?.qcOwnerName == value.qcOwnerName) {
      return;
    }
    loadedDetail = value;
    notifyListeners();
  }

  void setQcCompleted(bool value) {
    if (isQcCompleted == value) return;
    isQcCompleted = value;
    notifyListeners();
  }

  void addEvidence(Iterable<ProjectFileUpload> files) {
    selectedEvidence.addAll(files);
    notifyListeners();
  }

  void removeEvidenceAt(int index) {
    selectedEvidence.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitDecision({
    required String decision,
    required String note,
  }) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    submittingDecision = decision;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final detail = actionDetail;
      final repository = _ref.read(projectRepositoryProvider);
      final accountName = _ref.read(currentAccountNameProvider);
      final queued = _ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.qcTaskDecision);
      final isOffline =
          _ref.read(connectivityStateProvider).valueOrNull?.isOffline ?? false;
      final shouldQueue = queued && isOffline;
      if (shouldQueue && !detail.isQcOwnedByName(accountName)) {
        throw const AppException(
          'QC task harus sudah di-claim atau ditugaskan kepada Anda sebelum keputusan dapat disimpan offline.',
        );
      }
      if (!shouldQueue) {
        try {
          await repository.submitQcDecision(
            projectId: detail.projectId,
            qcTaskId: detail.taskId,
            decision: decision,
            note: note,
            files: List.unmodifiable(selectedEvidence),
            clientEventId: _clientEventId ??= const Uuid().v4(),
          );
        } on ProjectNetworkException {
          if (!queued) rethrow;
          return await _enqueueOffline(
            repository,
            accountName,
            decision: decision,
            note: note,
          );
        }
        _clientEventId = null;
        selectedEvidence.clear();
        await waitForServerRefresh();
        _ref.invalidate(projectQcTasksProvider);
        _ref.invalidate(
          projectQcTaskDetailProvider(
            ProjectTaskQuery(
              projectId: detail.projectId,
              taskId: detail.taskId,
            ),
          ),
        );
        return false;
      }
      return await _enqueueOffline(
        repository,
        accountName,
        decision: decision,
        note: note,
      );
    } finally {
      isSubmitting = false;
      submittingDecision = null;
      notifyListeners();
      keepAlive.close();
    }
  }

  Future<bool> _enqueueOffline(
    ProjectRepository repository,
    String? accountName, {
    required String decision,
    required String note,
  }) async {
    final detail = actionDetail;
    if (!detail.isQcOwnedByName(accountName)) {
      throw const AppException(
        'QC task harus sudah di-claim atau ditugaskan kepada Anda sebelum keputusan dapat disimpan offline.',
      );
    }
    final result = await repository.enqueueQcDecision(
      ProjectQcDecisionCommand(
        projectId: detail.projectId,
        qcTaskId: detail.taskId,
        decision: decision,
        note: note,
        expectedVersion: detail.version,
        clientEventId: _clientEventId ??= const Uuid().v4(),
        files: List.unmodifiable(selectedEvidence),
      ),
    );
    if (result is ProjectOperationStoreFailed) {
      throw AppException(result.message);
    }
    _clientEventId = null;
    selectedEvidence.clear();
    return true;
  }
}

class ProjectBreakdownActionController extends ChangeNotifier {
  ProjectBreakdownActionController(this._ref, this.detail)
    : selectedCodes = detail.tasks
          .where((task) => task.isSelected && !task.alreadyBrokenDown)
          .map((task) => task.selectionId)
          .toSet();

  final Ref _ref;
  final ProjectSubTaskPickerData detail;
  final Set<String> selectedCodes;
  bool isSubmitting = false;
  bool _didApplyApiSelection = false;

  void applyApiSelection(List<ProjectSubTaskPickerItemData> tasks) {
    if (_didApplyApiSelection) return;
    selectedCodes
      ..clear()
      ..addAll(
        tasks
            .where((task) => task.isSelected && !task.alreadyBrokenDown)
            .map((task) => task.selectionId),
      );
    _didApplyApiSelection = true;
  }

  void toggle(ProjectSubTaskPickerItemData task) {
    if (task.alreadyBrokenDown) return;

    if (!selectedCodes.remove(task.selectionId)) {
      selectedCodes.add(task.selectionId);
    }
    notifyListeners();
  }

  Future<void> submit() async {
    if (isSubmitting) return;
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      await _ref
          .read(projectRepositoryProvider)
          .submitTaskBreakdown(
            projectId: detail.projectId,
            taskId: detail.taskId,
            boqItemIds: selectedCodes.toList(growable: false),
          );
      await waitForServerRefresh();
      final query = ProjectTaskQuery(
        projectId: detail.projectId,
        taskId: detail.taskId,
      );
      _ref
        ..invalidate(projectBreakdownOptionsProvider(query))
        ..invalidate(projectTaskDetailProvider(query))
        ..invalidate(projectTasksProvider)
        ..invalidate(projectTaskChildrenProvider)
        ..invalidate(projectDetailProvider(detail.projectId));
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }
}

class ProjectAssigneeActionController extends ChangeNotifier {
  ProjectAssigneeActionController(this._ref, this.args);

  final Ref _ref;
  final ProjectAssigneePickerArgs args;
  bool isSubmitting = false;

  Future<void> assign(String employeeId) async {
    if (isSubmitting || !args.canLoadFromApi || employeeId.isEmpty) return;
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final repository = _ref.read(projectRepositoryProvider);
      if (args.qcTaskIds.isNotEmpty) {
        await repository.bulkAssignQcTasks(
          projectId: args.projectId,
          taskIds: args.qcTaskIds,
          employeeId: employeeId,
        );
      } else {
        await repository.assignTask(
          projectId: args.projectId,
          taskId: args.taskId,
          employeeId: employeeId,
        );
      }
      await waitForServerRefresh();
      if (args.qcTaskIds.isNotEmpty) {
        _ref.invalidate(projectQcTasksProvider);
      } else {
        _ref.invalidate(projectTasksProvider);
      }
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }
}
