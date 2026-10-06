import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/database/app_database.dart';
import '../../../core/offline_first_providers.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/utils/name_acronym.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_underline_tabs.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../../../shared/widgets/selection_bottom_sheet.dart';
import '../../auth/auth_providers.dart';
import '../../workforce/data/models/attendance_operation_payload.dart';
import '../../workforce/data/models/effective_today_attendance.dart';
import '../../workforce/data/models/today_attendance.dart';
import '../../workforce/presentation/workforce_attendance_selfie_page.dart';
import '../../workforce/workforce_providers.dart';
import '../data/models/dashboard_summary.dart';
import '../dashboard_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  static const _fontFamily = AppFonts.inter;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  var _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _ProfileHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    const _AttendanceHero(),
                    const SizedBox(height: 12),
                    const _DashboardMenu(),
                    AppUnderlineTabs(
                      items: const [
                        AppUnderlineTabItem(label: 'Presensi', width: 96),
                        AppUnderlineTabItem(label: 'Cuti', width: 96),
                      ],
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: (index) {
                        setState(() => _selectedTabIndex = index);
                      },
                      fontFamily: DashboardPage._fontFamily,
                      inactiveColor: AppColors.muted,
                    ),
                    ref
                        .watch(dashboardSummaryProvider)
                        .when(
                          data: (summary) => _DashboardTabContent(
                            selectedIndex: _selectedTabIndex,
                            summary: summary,
                          ),
                          loading: () => isOffline
                              ? const SizedBox(
                                  height: 212,
                                  child: _OfflineUnavailable(
                                    message:
                                        'Ringkasan hanya tersedia dalam mode online.',
                                  ),
                                )
                              : const AppSkeletonMetricGrid(),
                          error: (error, _) => SizedBox(
                            height: 212,
                            child: NetworkAwareErrorView(
                              error: error,
                              message: _errorMessage(error),
                              onRetry: () {
                                ref.invalidate(dashboardSummaryProvider);
                              },
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      ref.refresh(authControllerProvider.future),
      ref.refresh(dashboardSummaryProvider.future),
      ref.read(attendanceRefreshControllerProvider.notifier).refresh(),
    ]);
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message.isEmpty ? 'Gagal memuat data dashboard.' : message;
  }
}

class _DashboardTabContent extends StatelessWidget {
  const _DashboardTabContent({
    required this.selectedIndex,
    required this.summary,
  });

  final int selectedIndex;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return switch (selectedIndex) {
      1 => _LeaveMetricGrid(leave: summary.leave),
      _ => _MetricGrid(attendance: summary.attendance),
    };
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileName = ref
        .watch(authControllerProvider)
        .maybeWhen(
          data: (state) {
            final name = state.user?.name.trim();
            return name == null || name.isEmpty ? 'Pengguna' : name;
          },
          loading: () => 'Memuat profil...',
          orElse: () => 'Pengguna',
        );

    return AppHeader(
      title: profileName,
      horizontalPadding: 20,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.avatarGradientStart,
              AppColors.avatarGradientEnd,
            ],
          ),
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          nameAcronym(profileName),
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: DashboardPage._fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      titleWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: DashboardPage._fontFamily,
              fontSize: 18,
              height: 1.22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Pengaturan profile',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontFamily: DashboardPage._fontFamily,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      onTap: () => context.push(RouteNames.profile),
    );
  }
}

class _AttendanceHero extends ConsumerWidget {
  const _AttendanceHero();

  static const _regularPresenceType = AttendancePresenceType.regular;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(effectiveTodayAttendanceProvider)
        .when(
          data: (attendance) => _AttendanceHeroContent(
            attendance: attendance,
            onPressed: _hasAttendanceAction(attendance)
                ? () => _handlePresencePressed(context, ref)
                : null,
          ),
          loading: () => const AppSkeletonHeroView(height: 142),
          error: (error, _) => SizedBox(
            height: 142,
            child: NetworkAwareErrorView(
              error: error,
              cacheFeatureKey: 'attendanceCacheRead',
              message: _todayAttendanceErrorMessage(error),
              onRetry: () => ref.invalidate(effectiveTodayAttendanceProvider),
            ),
          ),
        );
  }

  Future<void> _handlePresencePressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final request = await _resolvePresenceRequest(context, ref);
    if (!context.mounted || request == null) return;

    await _openSelfieFlow(
      context,
      ref,
      request.presenceType,
      action: request.action,
      overtimeId: request.overtimeId,
      overtimeLabel: request.overtimeLabel,
      session: request.session,
    );
  }

  Future<_AttendanceSubmitRequest?> _resolvePresenceRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final attendance = ref.read(effectiveTodayAttendanceProvider).valueOrNull;
    if (attendance == null) return null;

    if (attendance.openPresence case final open?) {
      return _AttendanceSubmitRequest(
        presenceType: open.type == AttendanceType.regular
            ? _regularPresenceType
            : AttendancePresenceType.overtime,
        action: AttendanceSelfieAction.checkOut,
        overtimeId: open.overtimeId,
        session: open,
      );
    }
    if (attendance.hasCompletedOvertime) return null;

    final availableTypes = <AttendancePresenceType>[
      if (attendance.regular.canCheckIn) _regularPresenceType,
      if (attendance.referenceState == AttendanceReferenceState.available)
        AttendancePresenceType.overtime,
    ];

    if (availableTypes.isEmpty) return null;

    final selectedType = availableTypes.length == 1
        ? availableTypes.first
        : await SelectionBottomSheet.show<AttendancePresenceType>(
            context,
            title: 'Jenis Presensi',
            options: availableTypes,
            selectedOption: null,
            labelBuilder: (option) => option.label,
          );

    if (selectedType == null) return null;

    final todayOvertime = attendance.snapshot?.overtime;
    AttendanceOvertimeReference? overtimeReference;
    String? overtimeId;
    String? overtimeLabel;
    if (selectedType == AttendancePresenceType.overtime) {
      if (todayOvertime?.canCheckIn == true) {
        overtimeId = todayOvertime!.overtimeId;
        overtimeLabel = todayOvertime.reason ?? todayOvertime.workplace?.name;
      } else {
        final references = await ref.read(
          approvedOvertimeReferencesProvider(DateTime.now()).future,
        );
        if (!context.mounted) return null;
        if (references.isEmpty) {
          AppToast.error(
            context,
            'Jadwal lembur approved belum tersedia di perangkat.',
          );
          return null;
        }
        overtimeReference = references.length == 1
            ? references.single
            : await SelectionBottomSheet.show<AttendanceOvertimeReference>(
                context,
                title: 'Pilih Jadwal Lembur',
                options: references,
                selectedOption: null,
                labelBuilder: (item) =>
                    '${_clock(item.startTime)}-${_clock(item.endTime)} · '
                    '${item.locationName ?? item.title ?? 'Lembur'}',
              );
        if (!context.mounted || overtimeReference == null) return null;
        overtimeId = overtimeReference.overtimeId;
        overtimeLabel =
            overtimeReference.title ?? overtimeReference.locationName;
      }
    }

    return _AttendanceSubmitRequest(
      presenceType: selectedType,
      action: AttendanceSelfieAction.checkIn,
      overtimeId: overtimeId,
      overtimeLabel: overtimeLabel,
    );
  }

  bool _hasAttendanceAction(EffectiveTodayAttendance attendance) {
    if (attendance.openPresence != null) return true;
    if (attendance.hasCompletedOvertime) return false;
    return attendance.regular.canCheckIn ||
        attendance.referenceState == AttendanceReferenceState.available;
  }

  Future<void> _openSelfieFlow(
    BuildContext context,
    WidgetRef ref,
    AttendancePresenceType presenceType, {
    required AttendanceSelfieAction action,
    String? overtimeId,
    String? overtimeLabel,
    EffectivePresence? session,
  }) async {
    final result = await context.push<AttendanceSelfieResult>(
      RouteNames.workforceAttendanceSelfie,
      extra: AttendanceSelfieRequest(
        presenceType: presenceType,
        action: action,
        workplace: _workplaceFor(presenceType, ref),
        overtimeId: overtimeId,
        overtimeLabel: overtimeLabel,
        session: session,
      ),
    );

    if (!context.mounted || result == null) return;
    ref.invalidate(todayAttendanceProvider);
    ref.invalidate(effectiveTodayAttendanceProvider);
    ref.invalidate(attendanceListControllerProvider);
    ref.invalidate(dashboardSummaryProvider);
    AppToast.success(
      context,
      'Presensi tersimpan di perangkat dan sedang disinkronkan.',
    );
  }

  AttendanceWorkplace? _workplaceFor(
    AttendancePresenceType presenceType,
    WidgetRef ref,
  ) {
    final snapshot = ref
        .read(effectiveTodayAttendanceProvider)
        .valueOrNull
        ?.snapshot;
    return switch (presenceType) {
      AttendancePresenceType.regular => snapshot?.regular.workplace,
      AttendancePresenceType.overtime => snapshot?.overtime.workplace,
    };
  }

  String _todayAttendanceErrorMessage(Object error) {
    final message = error.toString();
    return message.isEmpty ? 'Gagal memuat data presensi hari ini.' : message;
  }

  String _clock(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class _OfflineUnavailable extends StatelessWidget {
  const _OfflineUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 24,
              color: AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSubmitRequest {
  const _AttendanceSubmitRequest({
    required this.presenceType,
    required this.action,
    this.overtimeId,
    this.overtimeLabel,
    this.session,
  });

  final AttendancePresenceType presenceType;
  final AttendanceSelfieAction action;
  final String? overtimeId;
  final String? overtimeLabel;
  final EffectivePresence? session;
}

class _AttendanceButtonState {
  const _AttendanceButtonState({required this.label, required this.variant});

  final String label;
  final AppButtonVariant variant;

  factory _AttendanceButtonState.fromAttendance(
    EffectiveTodayAttendance attendance,
  ) {
    if (attendance.openPresence != null) {
      return const _AttendanceButtonState(
        label: 'Check out',
        variant: AppButtonVariant.danger,
      );
    }

    if (attendance.hasCompletedOvertime) {
      return const _AttendanceButtonState(
        label: 'Selesai',
        variant: AppButtonVariant.primary,
      );
    }

    if (attendance.regular.canCheckIn) {
      return const _AttendanceButtonState(
        label: 'Check in',
        variant: AppButtonVariant.primary,
      );
    }

    if (attendance.referenceState == AttendanceReferenceState.available) {
      return const _AttendanceButtonState(
        label: 'Check in',
        variant: AppButtonVariant.primary,
      );
    }

    return const _AttendanceButtonState(
      label: 'Selesai',
      variant: AppButtonVariant.primary,
    );
  }
}

class _AttendanceHeroContent extends StatelessWidget {
  const _AttendanceHeroContent({
    required this.attendance,
    required this.onPressed,
  });

  final EffectiveTodayAttendance attendance;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonState = _AttendanceButtonState.fromAttendance(attendance);
    final now = DateTime.now();
    final snapshot = attendance.snapshot;

    return Container(
      height: 142,
      padding: const EdgeInsets.fromLTRB(0, 40, 39, AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.attendanceGradientStart,
            AppColors.attendanceGradientMiddle,
            AppColors.attendanceGradientEnd,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatIndonesianDate(snapshot?.date ?? now.toIso8601String()),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: DashboardPage._fontFamily,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatTime(snapshot?.serverTime ?? now.toIso8601String()),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: AppFonts.geist,
                    fontSize: 36,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 121,
            height: 36,
            child: AppButton(
              label: buttonState.label,
              variant: buttonState.variant,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontFamily: DashboardPage._fontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String value) {
    final fallbackDate = parseApiDateTime(value);
    if (fallbackDate != null) {
      return '${fallbackDate.hour.toString().padLeft(2, '0')}:${fallbackDate.minute.toString().padLeft(2, '0')}';
    }

    if (RegExp(r'^\d{2}:\d{2}').hasMatch(value)) {
      return value.substring(0, 5);
    }

    return value;
  }
}

class _DashboardMenu extends StatelessWidget {
  const _DashboardMenu();

  static const _items = [
    _MenuItemData(
      'Workforce',
      AssetPaths.iconWorkforce,
      routeName: RouteNames.workforce,
    ),
    _MenuItemData(
      'Prospect',
      AssetPaths.iconProspect,
      routeName: RouteNames.prospect,
    ),
    _MenuItemData(
      'Project',
      AssetPaths.iconProject,
      action: _DashboardMenuAction.project,
    ),
    _MenuItemData(
      'Meeting',
      AssetPaths.imageMeeting,
      action: _DashboardMenuAction.meeting,
    ),
    _MenuItemData(
      'Expense Manag...',
      AssetPaths.imageExpense,
      routeName: RouteNames.expenseManagement,
    ),
    _MenuItemData(
      'Inventory',
      AssetPaths.iconInventory,
      routeName: RouteNames.inventory,
    ),
    _MenuItemData(
      'Logistic',
      AssetPaths.iconLogistic,
      action: _DashboardMenuAction.logistic,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        20,
      ),
      decoration: const BoxDecoration(color: AppColors.white),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 92,
          mainAxisSpacing: 20,
          crossAxisSpacing: AppSpacing.sm,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _MenuTile(
            item: item,
            onTap: switch (item.action) {
              _DashboardMenuAction.project => () => _showProjectMenu(context),
              _DashboardMenuAction.meeting => () => _showMeetingMenu(context),
              _DashboardMenuAction.logistic => () => _showLogisticMenu(context),
              null => null,
            },
          );
        },
      ),
    );
  }

  Future<void> _showProjectMenu(BuildContext context) async {
    final selectedMenu = await SelectionBottomSheet.show<_ProjectMenuOption>(
      context,
      title: 'Project',
      options: _ProjectMenuOption.values,
      selectedOption: null,
      labelBuilder: (option) => option.label,
    );

    if (selectedMenu?.routeName == null || !context.mounted) return;

    context.push(selectedMenu!.routeName, extra: selectedMenu.label);
  }

  Future<void> _showMeetingMenu(BuildContext context) async {
    final selectedMenu = await SelectionBottomSheet.show<_MeetingMenuOption>(
      context,
      title: 'Meeting',
      options: _MeetingMenuOption.values,
      selectedOption: null,
      labelBuilder: (option) => option.label,
    );

    if (selectedMenu?.routeName == null || !context.mounted) return;

    context.push(selectedMenu!.routeName, extra: selectedMenu.label);
  }

  Future<void> _showLogisticMenu(BuildContext context) async {
    final selectedMenu = await SelectionBottomSheet.show<_LogisticMenuOption>(
      context,
      title: 'Logistic',
      options: _LogisticMenuOption.values,
      selectedOption: null,
      labelBuilder: (option) => option.label,
    );

    if (selectedMenu?.routeName == null || !context.mounted) return;

    context.push(selectedMenu!.routeName!);
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, this.onTap});

  final _MenuItemData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap:
            onTap ??
            (item.routeName == null
                ? null
                : () {
                    context.push(item.routeName!);
                  }),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Image.asset(
                  item.iconAsset,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontFamily: DashboardPage._fontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.attendance});

  final DashboardAttendance attendance;

  List<_MetricData> get _metrics {
    return [
      _MetricData('Hadir', attendance.present.toString(), AppColors.green),
      _MetricData('Tidak Hadir', attendance.absent.toString(), AppColors.rose),
      _MetricData('Terlambat', attendance.late.toString(), AppColors.rose),
      _MetricData('Izin', attendance.leave.toString(), AppColors.orange),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _metrics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 90,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        itemBuilder: (context, index) {
          return _MetricCard(metric: _metrics[index]);
        },
      ),
    );
  }
}

class _LeaveMetricGrid extends StatelessWidget {
  const _LeaveMetricGrid({required this.leave});

  final DashboardLeave leave;

  List<_MetricData> get _metrics {
    return [
      _MetricData(
        'Total pengajuan',
        leave.totalSubmission.toString(),
        AppColors.green,
      ),
      _MetricData('Diterima', leave.approvedDays.toString(), AppColors.green),
      _MetricData('Ditolak', leave.rejectedDays.toString(), AppColors.rose),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _metrics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 90,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        itemBuilder: (context, index) {
          return _MetricCard(metric: _metrics[index]);
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontFamily: DashboardPage._fontFamily,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            metric.value,
            style: TextStyle(
              color: metric.color,
              fontFamily: DashboardPage._fontFamily,
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData(
    this.label,
    this.iconAsset, {
    this.routeName,
    this.action,
  });

  final String label;
  final String iconAsset;
  final String? routeName;
  final _DashboardMenuAction? action;
}

enum _DashboardMenuAction { project, meeting, logistic }

enum _ProjectMenuOption {
  taskProject('Task Project', RouteNames.project),
  qualityProject('Quality Project', RouteNames.project);

  const _ProjectMenuOption(this.label, this.routeName);

  final String label;
  final String routeName;
}

enum _MeetingMenuOption {
  taskMeeting('Task Meeting', RouteNames.meetingTask),
  qualityMeeting('Quality Meeting', RouteNames.meetingQuality);

  const _MeetingMenuOption(this.label, this.routeName);

  final String label;
  final String routeName;
}

enum _LogisticMenuOption {
  loading('Loading', RouteNames.loading),
  pickup('Pickup', RouteNames.pickup),
  inbound('Inbound', RouteNames.inboundOutbound),
  outbound('Outbound', RouteNames.outbound);

  const _LogisticMenuOption(this.label, [this.routeName]);

  final String label;
  final String? routeName;
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}
