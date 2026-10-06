import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:curva_mobile/shared/widgets/page_open_refresh_scope.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/detail/task_meeting_detail_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/meeting/meeting_detail_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/meeting/meeting_overview_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/task/meeting_assignee_picker_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/task/meeting_task_list_page.dart';

final meetingListPageControllerProvider =
    Provider.autoDispose<MeetingListPageController>((ref) {
      return MeetingListPageController(ref);
    });

class MeetingListPageController implements PageOpenRefreshController {
  const MeetingListPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(
      meetingPaginatedListProvider(const MeetingListQuery()),
    );
  }
}

final meetingDetailPageControllerProvider = Provider.autoDispose
    .family<MeetingDetailPageController, MeetingDetailData>((ref, detail) {
      return MeetingDetailPageController(ref, detail);
    });

class MeetingDetailPageController implements PageOpenRefreshController {
  const MeetingDetailPageController(this._ref, this._detail);

  final Ref _ref;
  final MeetingDetailData _detail;

  @override
  void refresh() {
    if (_detail.meetingId.isEmpty) return;
    _ref.invalidateIfExists(meetingDetailProvider(_detail.meetingId));
  }
}

final meetingOverviewPageControllerProvider = Provider.autoDispose
    .family<MeetingOverviewPageController, MeetingOverviewData>((ref, data) {
      return MeetingOverviewPageController(ref, data);
    });

class MeetingOverviewPageController implements PageOpenRefreshController {
  const MeetingOverviewPageController(this._ref, this._data);

  final Ref _ref;
  final MeetingOverviewData _data;

  @override
  void refresh() {
    if (_data.meetingId.isEmpty) return;
    for (final tab in const ['open', 'history']) {
      _ref.invalidateIfExists(
        meetingOverviewTasksProvider(
          MeetingTasksQuery(
            meetingId: _data.meetingId,
            isQuality: _data.isQualityMeeting,
            tab: tab,
          ),
        ),
      );
    }
  }
}

final meetingTaskListPageControllerProvider = Provider.autoDispose
    .family<MeetingTaskListPageController, MeetingTaskListPageArgs>((
      ref,
      args,
    ) {
      return MeetingTaskListPageController(ref, args);
    });

class MeetingTaskListPageController implements PageOpenRefreshController {
  const MeetingTaskListPageController(this._ref, this._args);

  final Ref _ref;
  final MeetingTaskListPageArgs _args;

  @override
  void refresh() {
    if (_args.meetingId.isEmpty) return;
    _ref.invalidateIfExists(
      meetingTasksProvider(
        MeetingTasksQuery(
          meetingId: _args.meetingId,
          isQuality: _args.isQualityMeeting,
        ),
      ),
    );
  }
}

final meetingTaskActionPageControllerProvider = Provider.autoDispose
    .family<MeetingTaskActionPageController, MeetingTaskActionData>(
      (ref, data) => MeetingTaskActionPageController(ref, data),
    );

class MeetingTaskActionPageController implements PageOpenRefreshController {
  const MeetingTaskActionPageController(this._ref, this._data);

  final Ref _ref;
  final MeetingTaskActionData _data;

  @override
  void refresh() {
    if (!_data.canLoadFromApi) return;
    _ref.invalidateIfExists(
      meetingTaskDetailProvider(
        MeetingTaskQuery(
          meetingId: _data.meetingId,
          taskId: _data.taskId,
          isQuality: _data.isQualityMeeting,
        ),
      ),
    );
  }
}

final meetingAssigneePageControllerProvider = Provider.autoDispose
    .family<MeetingAssigneePageController, MeetingAssigneePickerArgs>((
      ref,
      args,
    ) {
      return MeetingAssigneePageController(ref, args);
    });

class MeetingAssigneePageController implements PageOpenRefreshController {
  const MeetingAssigneePageController(this._ref, this._args);

  final Ref _ref;
  final MeetingAssigneePickerArgs _args;

  @override
  void refresh() {
    if (!_args.canLoadFromApi) return;
    _ref.invalidateIfExists(
      meetingAssigneeCandidatesProvider(
        MeetingAssigneeQuery(
          meetingId: _args.meetingId,
          taskId: _args.taskId,
          search: '',
        ),
      ),
    );
  }
}
