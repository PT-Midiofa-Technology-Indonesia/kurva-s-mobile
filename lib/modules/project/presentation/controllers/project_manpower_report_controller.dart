import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline_first_providers.dart';
import '../../../../core/sync/sync_models.dart';
import '../../data/project_repository.dart';
import '../../project_providers.dart';

final projectManpowerReportControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<ProjectManpowerReportController, ProjectTaskQuery>((ref, query) {
      return ProjectManpowerReportController(ref, query);
    });

class ProjectManpowerReportController extends ChangeNotifier {
  ProjectManpowerReportController(this._ref, this.query);

  final Ref _ref;
  final ProjectTaskQuery query;
  bool isSubmitting = false;
  String? _clientEventId;

  Future<bool> submit({
    required double completedVolume,
    required String note,
    required List<ProjectFileUpload> files,
  }) async {
    if (isSubmitting) throw const AppException('Laporan sedang dikirim.');
    if (!completedVolume.isFinite || completedVolume <= 0 || files.isEmpty) {
      throw const AppException('Volume dan bukti laporan wajib diisi.');
    }
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    final eventId = _clientEventId ??= const Uuid().v4();
    try {
      final repository = _ref.read(projectRepositoryProvider);
      final canQueue = _ref
          .read(syncPolicyProvider)
          .canQueue(SyncOperationType.projectTaskDone);
      final offline =
          _ref.read(connectivityStateProvider).valueOrNull?.isOffline ?? false;
      if (!canQueue || !offline) {
        try {
          await repository.submitManpowerDailyReport(
            projectId: query.projectId,
            manpowerTaskId: query.taskId,
            completedVolume: completedVolume,
            note: note,
            files: files,
            clientEventId: eventId,
          );
          _clientEventId = null;
          return false;
        } on ProjectNetworkException {
          if (!canQueue) rethrow;
        }
      }
      final result = await repository.enqueueTaskDone(
        ProjectTaskDoneCommand(
          projectId: query.projectId,
          taskId: query.taskId,
          expectedVersion: 0,
          completedVolume: completedVolume,
          note: note,
          files: files,
          clientEventId: eventId,
        ),
      );
      if (result is ProjectOperationStoreFailed) {
        throw AppException(result.message);
      }
      _clientEventId = null;
      return true;
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }
}
