import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_open_refresh_scope.dart';
import '../../project/project_providers.dart';
import '../workforce_providers.dart';

final workforceManagementPageControllerProvider =
    Provider.autoDispose<WorkforceManagementPageController>((ref) {
      return WorkforceManagementPageController(ref);
    });

final workforceAttendanceDetailPageControllerProvider = Provider.autoDispose
    .family<WorkforceAttendanceDetailPageController, String>((ref, id) {
      return WorkforceAttendanceDetailPageController(ref, id);
    });

final workforceAttendanceSelfiePageControllerProvider =
    Provider.autoDispose<WorkforceStaticPageController>((ref) {
      return const WorkforceStaticPageController();
    });

final workforceOvertimeDetailPageControllerProvider = Provider.autoDispose
    .family<WorkforceOvertimeDetailPageController, String>((ref, id) {
      return WorkforceOvertimeDetailPageController(ref, id);
    });

final workforceOvertimeRequestPageControllerProvider =
    Provider.autoDispose<WorkforceOvertimeRequestPageController>((ref) {
      return WorkforceOvertimeRequestPageController(ref);
    });

final workforceLeaveDetailPageControllerProvider = Provider.autoDispose
    .family<WorkforceLeaveDetailPageController, String>((ref, id) {
      return WorkforceLeaveDetailPageController(ref, id);
    });

final workforceLeaveRequestPageControllerProvider =
    Provider.autoDispose<WorkforceLeaveRequestPageController>((ref) {
      return WorkforceLeaveRequestPageController(ref);
    });

class WorkforceManagementPageController implements PageOpenRefreshController {
  const WorkforceManagementPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    unawaited(
      _ref.read(attendanceRefreshControllerProvider.notifier).refresh(),
    );
    _ref.invalidateIfExists(attendanceListControllerProvider);
    _ref.invalidateIfExists(overtimeListControllerProvider);
    _ref.invalidateIfExists(leaveListControllerProvider);
  }
}

class WorkforceAttendanceDetailPageController
    implements PageOpenRefreshController {
  const WorkforceAttendanceDetailPageController(this._ref, this._id);

  final Ref _ref;
  final String _id;

  @override
  void refresh() {
    if (_id.isEmpty) return;
    _ref.invalidateIfExists(attendanceDetailProvider(_id));
  }
}

class WorkforceOvertimeDetailPageController
    implements PageOpenRefreshController {
  const WorkforceOvertimeDetailPageController(this._ref, this._id);

  final Ref _ref;
  final String _id;

  @override
  void refresh() {
    if (_id.isEmpty) return;
    _ref.invalidateIfExists(overtimeDetailProvider(_id));
  }
}

class WorkforceOvertimeRequestPageController
    implements PageOpenRefreshController {
  const WorkforceOvertimeRequestPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(projectListProvider);
  }
}

class WorkforceLeaveDetailPageController implements PageOpenRefreshController {
  const WorkforceLeaveDetailPageController(this._ref, this._id);

  final Ref _ref;
  final String _id;

  @override
  void refresh() {
    if (_id.isEmpty) return;
    _ref.invalidateIfExists(leaveDetailProvider(_id));
  }
}

class WorkforceLeaveRequestPageController implements PageOpenRefreshController {
  const WorkforceLeaveRequestPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(leaveTypeListProvider);
  }
}

class WorkforceStaticPageController implements PageOpenRefreshController {
  const WorkforceStaticPageController();

  @override
  void refresh() {}
}
