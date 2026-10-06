import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_names.dart';
import '../modules/auth/presentation/login_page.dart';
import '../modules/auth/presentation/login_controller.dart';
import '../modules/dashboard/presentation/dashboard_page.dart';
import '../modules/dashboard/dashboard_providers.dart';
import '../modules/expense/presentation/expense_management_page.dart';
import '../modules/expense/presentation/expense_page_controllers.dart';
import '../modules/expense/presentation/expense_reimbursement_create_page.dart';
import '../modules/expense/presentation/expense_reimbursement_non_project_page.dart';
import '../modules/expense/presentation/expense_reimbursement_detail_page.dart';
import '../modules/logistic/presentation/inbound/inbound_detail_page.dart';
import '../modules/logistic/presentation/inbound/inbound_page.dart';
import '../modules/logistic/presentation/logistic_page_controllers.dart';
import '../modules/logistic/presentation/loading/loading_page.dart';
import '../modules/logistic/presentation/loading/loading_detail_page.dart';
import '../modules/logistic/presentation/outbound/outbound_detail_page.dart';
import '../modules/logistic/presentation/outbound/outbound_page.dart';
import '../modules/logistic/presentation/pickup/pickup_page.dart';
import '../modules/logistic/presentation/pickup/pickup_detail_page.dart';
import '../modules/inventory/presentation/inventory_detail_page.dart';
import '../modules/inventory/presentation/inventory_adjustment_history_page.dart';
import '../modules/inventory/presentation/inventory_equipment_detail_page.dart';
import '../modules/inventory/presentation/inventory_page.dart';
import '../modules/inventory/presentation/inventory_page_controllers.dart';
import '../modules/meeting/presentation/controllers/meeting_page_controllers.dart';
import '../modules/meeting/presentation/pages/detail/quality_meeting_review_page.dart';
import '../modules/meeting/presentation/pages/detail/task_meeting_detail_page.dart';
import '../modules/meeting/presentation/pages/meeting/meeting_detail_page.dart';
import '../modules/meeting/presentation/pages/meeting/meeting_list_page.dart';
import '../modules/meeting/presentation/pages/meeting/meeting_overview_page.dart';
import '../modules/meeting/presentation/pages/task/meeting_assignee_picker_page.dart';
import '../modules/meeting/presentation/pages/task/meeting_task_list_page.dart';
import '../modules/project/presentation/pages/project/project_detail_page.dart';
import '../modules/project/presentation/pages/task/project_assignee_picker_page.dart';
import '../modules/project/presentation/pages/task/project_qc_assignment_picker_page.dart';
import '../modules/project/presentation/pages/task/project_sub_task_picker_page.dart';
import '../modules/project/presentation/pages/project/project_overview_page.dart';
import '../modules/project/presentation/controllers/project_page_controllers.dart';
import '../modules/project/presentation/pages/detail/project_quality_review_page.dart';
import '../modules/project/presentation/pages/project/project_list_page.dart';
import '../modules/project/presentation/pages/detail/project_task_detail_page.dart';
import '../modules/project/presentation/pages/detail/project_manpower_report_page.dart';
import '../modules/project/presentation/pages/task/project_task_list_page.dart';
import '../modules/prospect/presentation/prospect_create_page.dart';
import '../modules/prospect/presentation/prospect_detail/prospect_detail_page.dart';
import '../modules/prospect/presentation/prospect_kanban_page.dart';
import '../modules/prospect/presentation/prospect_page_controllers.dart';
import '../modules/profile/presentation/controllers/profile_page_controllers.dart';
import '../modules/profile/presentation/pages/change_password_page.dart';
import '../modules/profile/presentation/pages/faq_page.dart';
import '../modules/profile/presentation/pages/profile_page.dart';
import '../modules/profile/presentation/pages/term_condition_page.dart';
import '../modules/splash/splash_controller.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/workforce/presentation/workforce_attendance_detail_page.dart';
import '../modules/workforce/presentation/workforce_management_page.dart';
import '../modules/workforce/presentation/workforce_attendance_selfie_page.dart';
import '../modules/workforce/presentation/workforce_leave_detail_page.dart';
import '../modules/workforce/presentation/workforce_leave_request_page.dart';
import '../modules/workforce/presentation/workforce_overtime_detail_page.dart';
import '../modules/workforce/presentation/workforce_overtime_request_page.dart';
import '../modules/workforce/presentation/workforce_page_controllers.dart';
import '../shared/widgets/page_open_refresh_scope.dart';

class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: splashControllerProvider,
            deferChildUntilRefresh: false,
            child: const SplashScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: loginControllerProvider,
            child: const LoginPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: dashboardPageControllerProvider,
            child: const DashboardPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: profilePageControllerProvider,
            child: const ProfilePage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.profileFaq,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: profileFaqPageControllerProvider,
            child: const FaqPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.profileTermCondition,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: profileTermConditionPageControllerProvider,
            child: const TermConditionPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.profileChangePassword,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: profileChangePasswordPageControllerProvider,
            child: const ChangePasswordPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.expenseManagement,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: expenseManagementPageControllerProvider,
            child: const ExpenseManagementPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.expenseReimbursementCreate,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider:
                expenseReimbursementCreatePageControllerProvider,
            child: const ExpenseReimbursementCreatePage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.expenseReimbursementNonProject,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider:
                expenseReimbursementNonProjectPageControllerProvider,
            child: const ExpenseReimbursementNonProjectPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.expenseReimbursementDetail,
        pageBuilder: (context, state) {
          final costRequestId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider:
                  expenseReimbursementDetailPageControllerProvider(
                    costRequestId,
                  ),
              child: ExpenseReimbursementDetailPage(
                costRequestId: costRequestId,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.loading,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: loadingPageControllerProvider,
            child: const LoadingPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.loadingDetail,
        pageBuilder: (context, state) {
          final loadingOrderId = state.extra is String
              ? state.extra! as String
              : '';
          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: loadingDetailPageControllerProvider(
                loadingOrderId,
              ),
              child: LoadingDetailPage(loadingOrderId: loadingOrderId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.inboundOutbound,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: inboundPageControllerProvider,
            child: const InboundPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.pickup,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: pickupPageControllerProvider,
            child: const PickupPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.pickupDetail,
        pageBuilder: (context, state) {
          final pickupOrderId = state.extra is String
              ? state.extra! as String
              : '';
          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: pickupDetailPageControllerProvider(
                pickupOrderId,
              ),
              child: PickupDetailPage(pickupOrderId: pickupOrderId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.inboundDetail,
        pageBuilder: (context, state) {
          final deliveryOrderId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: inboundDetailPageControllerProvider(
                deliveryOrderId,
              ),
              child: InboundDetailPage(deliveryOrderId: deliveryOrderId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.outbound,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: outboundPageControllerProvider,
            child: const OutboundPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.outboundDetail,
        pageBuilder: (context, state) {
          final deliveryOrderId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: outboundDetailPageControllerProvider(
                deliveryOrderId,
              ),
              child: OutboundDetailPage(deliveryOrderId: deliveryOrderId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.inventory,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: inventoryPageControllerProvider,
            child: const InventoryPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.inventoryDetail,
        pageBuilder: (context, state) {
          final itemCatalogId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: inventoryDetailPageControllerProvider(
                itemCatalogId,
              ),
              child: InventoryDetailPage(itemCatalogId: itemCatalogId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.inventoryAdjustmentHistory,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider:
                inventoryAdjustmentHistoryPageControllerProvider,
            child: const InventoryAdjustmentHistoryPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.inventoryEquipmentDetail,
        pageBuilder: (context, state) {
          final resourceUnitId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider:
                  inventoryEquipmentDetailPageControllerProvider(
                    resourceUnitId,
                  ),
              child: InventoryEquipmentDetailPage(
                resourceUnitId: resourceUnitId,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.project,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: projectListPageControllerProvider,
            child: ProjectListPage(
              title: state.extra is String ? state.extra! as String : 'Project',
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.meetingTask,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: meetingListPageControllerProvider,
            child: const MeetingListPage(type: MeetingListType.task),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.meetingQuality,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: meetingListPageControllerProvider,
            child: const MeetingListPage(type: MeetingListType.quality),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.meetingMenu,
        pageBuilder: (context, state) {
          final data = state.extra is MeetingOverviewData
              ? state.extra! as MeetingOverviewData
              : MeetingOverviewData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: meetingOverviewPageControllerProvider(data),
              child: MeetingOverviewPage(data: data),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.meetingTaskList,
        pageBuilder: (context, state) {
          final args = state.extra is MeetingTaskListPageArgs
              ? state.extra! as MeetingTaskListPageArgs
              : MeetingTaskListPageArgs.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: meetingTaskListPageControllerProvider(args),
              child: MeetingTaskListPage(args: args),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.meetingDetail,
        pageBuilder: (context, state) {
          final detail = state.extra is MeetingDetailData
              ? state.extra! as MeetingDetailData
              : MeetingDetailData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: meetingDetailPageControllerProvider(detail),
              child: MeetingDetailPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.meetingAssignee,
        pageBuilder: (context, state) {
          final args = state.extra is MeetingAssigneePickerArgs
              ? state.extra! as MeetingAssigneePickerArgs
              : const MeetingAssigneePickerArgs();
          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: meetingAssigneePageControllerProvider(args),
              child: MeetingAssigneePickerPage(args: args),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.meetingTaskAction,
        pageBuilder: (context, state) {
          final data = state.extra is MeetingTaskActionData
              ? state.extra! as MeetingTaskActionData
              : MeetingTaskActionData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: meetingTaskActionPageControllerProvider(data),
              child: data.isQualityMeeting
                  ? QualityMeetingReviewPage(data: data)
                  : TaskMeetingDetailPage(data: data),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectMenu,
        pageBuilder: (context, state) {
          final detail = state.extra is ProjectOverviewData
              ? state.extra! as ProjectOverviewData
              : ProjectOverviewData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectOverviewPageControllerProvider(detail),
              child: ProjectOverviewPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectTaskDetail,
        pageBuilder: (context, state) {
          final detail = state.extra is ProjectDetailData
              ? state.extra! as ProjectDetailData
              : ProjectDetailData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectDetailPageControllerProvider(detail),
              child: ProjectDetailPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectSubTask,
        pageBuilder: (context, state) {
          final args = state.extra is ProjectTaskListPageArgs
              ? state.extra! as ProjectTaskListPageArgs
              : ProjectTaskListPageArgs(
                  detail: state.extra is ProjectDetailData
                      ? state.extra! as ProjectDetailData
                      : ProjectDetailData.fallback(),
                );

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectTaskListPageControllerProvider(args),
              child: ProjectTaskListPage(
                detail: args.detail,
                title: args.title,
                parentTaskId: args.parentTaskId,
                parentTaskCode: args.parentTaskCode,
                initialTabIndex: args.initialTabIndex,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectSubTaskDetail,
        pageBuilder: (context, state) {
          final detail = state.extra is ProjectTaskDetailData
              ? state.extra! as ProjectTaskDetailData
              : ProjectTaskDetailData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectTaskDetailPageControllerProvider(
                detail,
              ),
              child: ProjectTaskDetailPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectManpowerReport,
        pageBuilder: (context, state) {
          final args = state.extra is ProjectManpowerReportArgs
              ? state.extra! as ProjectManpowerReportArgs
              : ProjectManpowerReportArgs(
                  projectId: '',
                  taskId: '',
                  manpowerName: state.extra is String
                      ? state.extra! as String
                      : 'Manpower',
                );

          return _buildSlideTransitionPage(
            state: state,
            child: ProjectManpowerReportPage(
              manpowerName: args.manpowerName,
              projectId: args.projectId,
              taskId: args.taskId,
              canSubmit: args.canSubmit,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectTaskBreakdown,
        pageBuilder: (context, state) {
          final detail = state.extra is ProjectSubTaskPickerData
              ? state.extra! as ProjectSubTaskPickerData
              : ProjectSubTaskPickerData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectSubTaskPickerPageControllerProvider(
                detail,
              ),
              child: ProjectSubTaskPickerPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectQcAssignmentPicker,
        pageBuilder: (context, state) {
          final args = state.extra as ProjectQcAssignmentPickerArgs;
          return _buildSlideTransitionPage(
            state: state,
            child: ProjectQcAssignmentPickerPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectAssignee,
        pageBuilder: (context, state) {
          final args = state.extra is ProjectAssigneePickerArgs
              ? state.extra! as ProjectAssigneePickerArgs
              : const ProjectAssigneePickerArgs();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectAssigneePickerPageControllerProvider(
                args,
              ),
              child: ProjectAssigneePickerPage(args: args),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.projectQualityControl,
        pageBuilder: (context, state) {
          final detail = state.extra is ProjectTaskDetailData
              ? state.extra! as ProjectTaskDetailData
              : ProjectTaskDetailData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: projectQualityReviewPageControllerProvider(
                detail,
              ),
              child: ProjectQualityReviewPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.prospect,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: prospectKanbanPageControllerProvider,
            child: const ProspectKanbanPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.prospectCreate,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: prospectCreatePageControllerProvider,
            child: const ProspectCreatePage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.prospectDetail,
        pageBuilder: (context, state) {
          final detail = state.extra is ProspectDetailData
              ? state.extra! as ProspectDetailData
              : ProspectDetailData.fallback();

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: prospectDetailPageControllerProvider(detail),
              child: ProspectDetailPage(detail: detail),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.workforce,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: workforceManagementPageControllerProvider,
            child: const WorkforceManagementPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.workforceAttendanceDetail,
        pageBuilder: (context, state) {
          final attendanceId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider:
                  workforceAttendanceDetailPageControllerProvider(attendanceId),
              child: WorkforceAttendanceDetailPage(attendanceId: attendanceId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.workforceAttendanceSelfie,
        pageBuilder: (context, state) {
          final request = state.extra is AttendanceSelfieRequest
              ? state.extra! as AttendanceSelfieRequest
              : const AttendanceSelfieRequest(
                  presenceType: AttendancePresenceType.regular,
                  action: AttendanceSelfieAction.checkIn,
                );

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider:
                  workforceAttendanceSelfiePageControllerProvider,
              child: WorkforceAttendanceSelfiePage(request: request),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.workforceOvertimeDetail,
        pageBuilder: (context, state) {
          final overtimeId = state.extra is String
              ? state.extra! as String
              : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: workforceOvertimeDetailPageControllerProvider(
                overtimeId,
              ),
              child: WorkforceOvertimeDetailPage(overtimeId: overtimeId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.workforceOvertimeRequest,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: workforceOvertimeRequestPageControllerProvider,
            child: const WorkforceOvertimeRequestPage(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.workforceLeaveDetail,
        pageBuilder: (context, state) {
          final leaveId = state.extra is String ? state.extra! as String : '';

          return _buildSlideTransitionPage(
            state: state,
            child: _withController(
              controllerProvider: workforceLeaveDetailPageControllerProvider(
                leaveId,
              ),
              child: WorkforceLeaveDetailPage(leaveId: leaveId),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.workforceLeaveRequest,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          state: state,
          child: _withController(
            controllerProvider: workforceLeaveRequestPageControllerProvider,
            child: const WorkforceLeaveRequestPage(),
          ),
        ),
      ),
    ],
  );

  static Widget _withController<T extends PageOpenRefreshController>({
    required ProviderListenable<T> controllerProvider,
    required Widget child,
    bool deferChildUntilRefresh = true,
  }) {
    return PageOpenRefreshScope<T>(
      controllerProvider: controllerProvider,
      deferChildUntilRefresh: deferChildUntilRefresh,
      child: child,
    );
  }

  static CustomTransitionPage<void> _buildFadeTransitionPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(opacity: curvedAnimation, child: child);
      },
    );
  }

  static CustomTransitionPage<void> _buildSlideTransitionPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
    );
  }
}
