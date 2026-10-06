import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:curva_mobile/shared/widgets/page_open_refresh_scope.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_assignee_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_overview_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_sub_task_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';

final projectListPageControllerProvider =
    Provider.autoDispose<ProjectListPageController>((ref) {
      return ProjectListPageController(ref);
    });

final projectOverviewPageControllerProvider = Provider.autoDispose
    .family<ProjectOverviewPageController, ProjectOverviewData>((ref, detail) {
      return ProjectOverviewPageController(ref, detail);
    });

final projectDetailPageControllerProvider = Provider.autoDispose
    .family<ProjectDetailPageController, ProjectDetailData>((ref, detail) {
      return ProjectDetailPageController(ref, detail);
    });

final projectTaskListPageControllerProvider = Provider.autoDispose
    .family<ProjectTaskListPageController, ProjectTaskListPageArgs>((
      ref,
      args,
    ) {
      return ProjectTaskListPageController(ref, args);
    });

final projectTaskDetailPageControllerProvider = Provider.autoDispose
    .family<ProjectTaskDetailPageController, ProjectTaskDetailData>((
      ref,
      detail,
    ) {
      return ProjectTaskDetailPageController(ref, detail);
    });

final projectSubTaskPickerPageControllerProvider = Provider.autoDispose
    .family<ProjectSubTaskPickerPageController, ProjectSubTaskPickerData>((
      ref,
      detail,
    ) {
      return ProjectSubTaskPickerPageController(ref, detail);
    });

final projectAssigneePickerPageControllerProvider = Provider.autoDispose
    .family<ProjectAssigneePickerPageController, ProjectAssigneePickerArgs>((
      ref,
      args,
    ) {
      return ProjectAssigneePickerPageController(ref, args);
    });

final projectQualityReviewPageControllerProvider = Provider.autoDispose
    .family<ProjectQualityReviewPageController, ProjectTaskDetailData>((
      ref,
      detail,
    ) {
      return ProjectQualityReviewPageController(ref, detail);
    });

class ProjectListPageController implements PageOpenRefreshController {
  const ProjectListPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(projectListProvider);
  }
}

class ProjectOverviewPageController implements PageOpenRefreshController {
  const ProjectOverviewPageController(this._ref, this._detail);

  final Ref _ref;
  final ProjectOverviewData _detail;

  @override
  void refresh() {
    if (_detail.projectId.isEmpty) return;
    for (final tab in const ['open', 'history']) {
      final tasksQuery = ProjectTasksQuery(
        projectId: _detail.projectId,
        tab: tab,
      );
      _ref.invalidateIfExists(
        _detail.title == ProjectTaskListPage.qualityProjectTitle
            ? projectQcTasksProvider(tasksQuery)
            : projectTasksProvider(tasksQuery),
      );
    }
    if (_detail.title == ProjectTaskListPage.qualityProjectTitle) {
      _ref.invalidateIfExists(
        projectTasksProvider(
          ProjectTasksQuery(projectId: _detail.projectId, tab: 'open'),
        ),
      );
    }
  }
}

class ProjectDetailPageController implements PageOpenRefreshController {
  const ProjectDetailPageController(this._ref, this._detail);

  final Ref _ref;
  final ProjectDetailData _detail;

  @override
  void refresh() {
    if (_detail.projectId.isEmpty) return;
    _ref.invalidateIfExists(projectDetailProvider(_detail.projectId));
    _ref.invalidateIfExists(
      projectTasksProvider(
        ProjectTasksQuery(projectId: _detail.projectId, tab: 'open'),
      ),
    );
  }
}

class ProjectTaskListPageController implements PageOpenRefreshController {
  const ProjectTaskListPageController(this._ref, this._args);

  final Ref _ref;
  final ProjectTaskListPageArgs _args;

  @override
  void refresh() {
    final detail = _args.detail;
    if (detail.projectId.isEmpty) return;
    final tab = _args.initialTabIndex == 1 ? 'history' : 'open';

    if (_args.title == ProjectTaskListPage.qualityProjectTitle) {
      _ref.invalidateIfExists(
        projectQcTasksProvider(
          ProjectTasksQuery(projectId: detail.projectId, tab: tab),
        ),
      );
      return;
    }

    if (_args.parentTaskId.isNotEmpty) {
      _ref.invalidateIfExists(
        projectTaskChildrenProvider(
          ProjectTaskQuery(
            projectId: detail.projectId,
            taskId: _args.parentTaskId,
            tab: tab,
          ),
        ),
      );
      return;
    }

    _ref.invalidateIfExists(
      projectTasksProvider(
        ProjectTasksQuery(projectId: detail.projectId, tab: tab),
      ),
    );
  }
}

class ProjectTaskDetailPageController implements PageOpenRefreshController {
  const ProjectTaskDetailPageController(this._ref, this._detail);

  final Ref _ref;
  final ProjectTaskDetailData _detail;

  @override
  void refresh() {
    if (!_detail.canLoadFromApi) return;
    _ref.invalidateIfExists(
      projectTaskDetailProvider(
        ProjectTaskQuery(projectId: _detail.projectId, taskId: _detail.taskId),
      ),
    );
  }
}

class ProjectSubTaskPickerPageController implements PageOpenRefreshController {
  const ProjectSubTaskPickerPageController(this._ref, this._detail);

  final Ref _ref;
  final ProjectSubTaskPickerData _detail;

  @override
  void refresh() {
    if (!_detail.canLoadFromApi) return;
    final query = ProjectTaskQuery(
      projectId: _detail.projectId,
      taskId: _detail.taskId,
    );
    _ref.invalidateIfExists(projectBreakdownOptionsProvider(query));
    _ref.invalidateIfExists(projectTaskChildrenProvider(query));
  }
}

class ProjectAssigneePickerPageController implements PageOpenRefreshController {
  const ProjectAssigneePickerPageController(this._ref, this._args);

  final Ref _ref;
  final ProjectAssigneePickerArgs _args;

  @override
  void refresh() {
    if (!_args.canLoadFromApi) return;
    _ref.invalidateIfExists(projectSubordinatesProvider(_args.projectId));
  }
}

class ProjectQualityReviewPageController implements PageOpenRefreshController {
  const ProjectQualityReviewPageController(this._ref, this._detail);

  final Ref _ref;
  final ProjectTaskDetailData _detail;

  @override
  void refresh() {
    if (!_detail.canLoadFromApi) return;
    _ref.invalidateIfExists(
      projectQcTaskDetailProvider(
        ProjectTaskQuery(projectId: _detail.projectId, taskId: _detail.taskId),
      ),
    );
  }
}
