import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/server_refresh_delay.dart';
import '../data/models/prospect_models.dart';
import '../prospect_providers.dart';

final prospectKanbanControllerProvider =
    ChangeNotifierProvider.autoDispose<ProspectKanbanController>((ref) {
      return ProspectKanbanController(ref);
    });

class ProspectKanbanController extends ChangeNotifier {
  ProspectKanbanController(this._ref);
  final Ref _ref;
  final mutatingProspectIds = <String>{};
  List<ProspectStage>? stages;
  String? _pipelineSignature;
  bool isRefreshing = false;
  bool get hasMutations => mutatingProspectIds.isNotEmpty;

  void syncPipeline(List<ProspectStage> value) {
    final signature = _signature(value);
    if (stages == null || (!hasMutations && _pipelineSignature != signature)) {
      stages = value;
      _pipelineSignature = signature;
    }
  }

  void clear() {
    stages = null;
    _pipelineSignature = null;
  }

  Future<void> refresh() async {
    if (isRefreshing) return;
    isRefreshing = true;
    clear();
    notifyListeners();
    try {
      syncPipeline(await _ref.refresh(prospectPipelineProvider.future));
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<String?> move(ProspectProject prospect, ProspectStage target) async {
    if (prospect.stage == target.stage ||
        mutatingProspectIds.contains(prospect.id)) {
      return null;
    }
    mutatingProspectIds.add(prospect.id);
    stages = _moveProject(stages ?? const [], prospect, target);
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(prospectRepositoryProvider)
          .updateStage(
            prospectId: prospect.id,
            stage: target.stage,
            companyId: _ref.read(prospectCompanyIdProvider),
          );
      await waitForServerRefresh();
      _ref
        ..invalidate(prospectPipelineProvider)
        ..invalidate(prospectDetailProvider(prospect.id))
        ..invalidate(prospectStageHistoryProvider(prospect.id));
      return message ?? 'Stage prospect berhasil diperbarui.';
    } catch (_) {
      clear();
      _ref.invalidate(prospectPipelineProvider);
      rethrow;
    } finally {
      mutatingProspectIds.remove(prospect.id);
      notifyListeners();
      keepAlive.close();
    }
  }

  String _signature(List<ProspectStage> value) => value
      .map(
        (stage) =>
            '${stage.stage}:${stage.projects.map((item) => item.id).join(',')}',
      )
      .join('|');

  List<ProspectStage> _moveProject(
    List<ProspectStage> source,
    ProspectProject prospect,
    ProspectStage target,
  ) => List.unmodifiable(
    source.map((stage) {
      final projects = stage.projects
          .where((item) => item.id != prospect.id)
          .toList();
      if (stage.stage == target.stage) {
        projects.insert(
          0,
          ProspectProject(
            id: prospect.id,
            code: prospect.code,
            name: prospect.name,
            description: prospect.description,
            stage: target.stage,
            stageName: target.stageName.isEmpty
                ? target.stage
                : target.stageName,
            client: prospect.client,
            estimatedValue: prospect.estimatedValue,
            projectStartDate: prospect.projectStartDate,
            projectEndDate: prospect.projectEndDate,
            tenderSubmissionDeadline: prospect.tenderSubmissionDeadline,
            totalDocumentRequirements: prospect.totalDocumentRequirements,
            totalUploadedDocuments: prospect.totalUploadedDocuments,
            isActive: prospect.isActive,
            createdAt: prospect.createdAt,
            updatedAt: prospect.updatedAt,
          ),
        );
      }
      return ProspectStage(
        stage: stage.stage,
        stageName: stage.stageName,
        totalProjects: projects.length,
        projects: List.unmodifiable(projects),
      );
    }),
  );
}
