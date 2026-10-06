import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/offline_first_providers.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/network_aware_error_view.dart';
import '../../../../shared/widgets/selection_bottom_sheet.dart';
import '../../data/models/attendance_list.dart';
import '../../data/models/attendance_operation_payload.dart';
import '../../data/models/effective_today_attendance.dart';
import '../../data/models/today_attendance.dart';
import '../../workforce_providers.dart';
import '../workforce_attendance_selfie_page.dart';

class TodayAttendanceHero extends ConsumerWidget {
  const TodayAttendanceHero({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(effectiveTodayAttendanceProvider)
      .when(
        data: (attendance) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AttendanceSyncBanner(attendance: attendance),
            _CheckoutHero(attendance: attendance),
          ],
        ),
        loading: () => const AppSkeletonHeroView(height: 216, stacked: true),
        error: (error, _) => SizedBox(
          height: 216,
          child: NetworkAwareErrorView(
            error: error,
            cacheFeatureKey: 'attendanceCacheRead',
            message: error.toString(),
            onRetry: () => ref.invalidate(effectiveTodayAttendanceProvider),
          ),
        ),
      );
}

class AttendanceSyncBanner extends ConsumerWidget {
  const AttendanceSyncBanner({super.key, required this.attendance});
  final EffectiveTodayAttendance attendance;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    final syncing =
        ref.watch(syncStatusProvider).valueOrNull?.state ==
        SyncRunState.syncing;
    final summary = attendance.syncSummary;
    final message = offline && summary.waiting + summary.needsAttention > 0
        ? '${summary.waiting + summary.needsAttention} presensi menunggu koneksi internet.'
        : summary.needsAttention > 0
        ? '${summary.needsAttention} presensi gagal disinkronkan.'
        : syncing && summary.waiting > 0
        ? 'Menyinkronkan presensi...'
        : summary.waiting > 0
        ? '${summary.waiting} presensi menunggu sinkronisasi.'
        : offline
        ? 'Anda sedang offline. Presensi tetap dapat dilakukan.'
        : null;
    if (message == null) return const SizedBox.shrink();
    final error = summary.needsAttention > 0 && !offline;
    return Material(
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              error
                  ? Icons.warning_amber_rounded
                  : offline
                  ? Icons.cloud_off_outlined
                  : Icons.sync,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHero extends ConsumerStatefulWidget {
  const _CheckoutHero({required this.attendance});
  final EffectiveTodayAttendance attendance;

  @override
  ConsumerState<_CheckoutHero> createState() => _CheckoutHeroState();
}

class _CheckoutHeroState extends ConsumerState<_CheckoutHero> {
  EffectivePresence? _optimisticOpenPresence;

  EffectiveTodayAttendance get _attendance {
    final optimistic = _optimisticOpenPresence;
    if (optimistic == null || widget.attendance.openPresence != null) {
      return widget.attendance;
    }

    return EffectiveTodayAttendance(
      regular: optimistic.type == AttendanceType.regular
          ? optimistic
          : widget.attendance.regular,
      overtimeSessions: optimistic.type == AttendanceType.overtime
          ? [...widget.attendance.overtimeSessions, optimistic]
          : widget.attendance.overtimeSessions,
      referenceState: widget.attendance.referenceState,
      syncSummary: widget.attendance.syncSummary,
      lastUpdatedAt: widget.attendance.lastUpdatedAt,
      snapshot: widget.attendance.snapshot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final attendance = _attendance;
    final snapshot = attendance.snapshot;
    final button = _ButtonState.from(attendance);
    return Container(
      height: 216,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.workforceHeroStart, AppColors.workforceHeroEnd],
        ),
      ),
      child: Column(
        children: [
          Text(
            formatIndonesianDate(snapshot?.date ?? now.toIso8601String()),
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.inter,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _displayTime(snapshot?.serverTime ?? now.toIso8601String()),
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.geist,
              fontSize: 36,
              height: 1.33,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          AppButton(
            label: button.label,
            variant: button.variant,
            onPressed: button.enabled ? () => _submit(context) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final request = await _request(context, ref);
    if (!context.mounted || request == null) return;
    final result = await context.push<AttendanceSelfieResult>(
      RouteNames.workforceAttendanceSelfie,
      extra: AttendanceSelfieRequest(
        presenceType: request.type,
        action: request.checkIn
            ? AttendanceSelfieAction.checkIn
            : AttendanceSelfieAction.checkOut,
        workplace: _workplaceFor(request.type),
        overtimeId: request.overtimeId,
        overtimeLabel: request.overtimeLabel,
        session: request.session,
      ),
    );
    if (!context.mounted || result == null) return;
    final stored = result.stored;
    if (request.checkIn) {
      setState(() {
        _optimisticOpenPresence = EffectivePresence(
          type: request.type == AttendancePresenceType.regular
              ? AttendanceType.regular
              : AttendanceType.overtime,
          clientSessionId: stored.clientSessionId,
          overtimeId: request.overtimeId,
          checkedIn: true,
          checkedOut: false,
          checkInOperationId: stored.operationId,
          state: OutboxState.pending,
        );
      });
    } else {
      setState(() => _optimisticOpenPresence = null);
    }
    ref.invalidate(todayAttendanceProvider);
    ref.invalidate(attendanceListControllerProvider);
    AppToast.success(
      context,
      'Presensi tersimpan di perangkat dan akan disinkronkan otomatis.',
    );
  }

  AttendanceWorkplace? _workplaceFor(AttendancePresenceType type) {
    final snapshot = _attendance.snapshot;
    return switch (type) {
      AttendancePresenceType.regular => snapshot?.regular.workplace,
      AttendancePresenceType.overtime => snapshot?.overtime.workplace,
    };
  }

  Future<_PresenceRequest?> _request(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final attendance = _attendance;
    final open = attendance.openPresence;
    if (open != null) {
      return _PresenceRequest(
        type: open.type == AttendanceType.regular
            ? AttendancePresenceType.regular
            : AttendancePresenceType.overtime,
        checkIn: false,
        session: _withSessionFallback(ref, open),
        overtimeId: open.overtimeId,
      );
    }
    if (attendance.hasCompletedOvertime) return null;
    final choices = <AttendancePresenceType>[
      if (attendance.regular.canCheckIn) AttendancePresenceType.regular,
      if (attendance.referenceState == AttendanceReferenceState.available)
        AttendancePresenceType.overtime,
    ];
    if (choices.isEmpty) return null;
    final type = choices.length == 1
        ? choices.single
        : await SelectionBottomSheet.show<AttendancePresenceType>(
            context,
            title: 'Jenis Presensi',
            options: choices,
            selectedOption: null,
            labelBuilder: (item) => item.label,
          );
    if (type == null) return null;
    final todayOvertime = attendance.snapshot?.overtime;
    AttendanceOvertimeReference? reference;
    String? overtimeId;
    String? overtimeLabel;
    if (type == AttendancePresenceType.overtime) {
      if (todayOvertime?.canCheckIn == true) {
        overtimeId = todayOvertime!.overtimeId;
        overtimeLabel = todayOvertime.reason ?? todayOvertime.workplace?.name;
      } else {
        final references = await ref.read(
          approvedOvertimeReferencesProvider(DateTime.now()).future,
        );
        if (!context.mounted || references.isEmpty) return null;
        reference = references.length == 1
            ? references.single
            : await SelectionBottomSheet.show<AttendanceOvertimeReference>(
                context,
                title: 'Pilih Jadwal Lembur',
                options: references,
                selectedOption: null,
                labelBuilder: (item) =>
                    '${_clock(item.startTime)}-${_clock(item.endTime)} · ${item.locationName ?? item.title ?? 'Lembur'}',
              );
        if (!context.mounted || reference == null) return null;
        overtimeId = reference.overtimeId;
        overtimeLabel = reference.title ?? reference.locationName;
      }
    }
    return _PresenceRequest(
      type: type,
      checkIn: true,
      overtimeId: overtimeId,
      overtimeLabel: overtimeLabel,
    );
  }

  EffectivePresence _withSessionFallback(
    WidgetRef ref,
    EffectivePresence session,
  ) {
    if (session.clientSessionId?.isNotEmpty == true) return session;
    final records =
        ref.read(attendanceListControllerProvider).valueOrNull?.records ??
        const <AttendanceRecord>[];
    final today = formatDateParam(DateTime.now());
    for (final item in records) {
      if (item.attendanceDate != today ||
          item.type != session.type.name ||
          (item.checkIn == null && item.checkInOccurredAt == null) ||
          (item.checkOut != null || item.checkOutOccurredAt != null) ||
          item.clientSessionId?.isEmpty != false) {
        continue;
      }
      return EffectivePresence(
        type: session.type,
        clientSessionId: item.clientSessionId,
        overtimeId: session.overtimeId,
        checkedIn: true,
        checkedOut: false,
        checkInOperationId: session.checkInOperationId,
        checkOutOperationId: session.checkOutOperationId,
        state: session.state,
      );
    }
    return session;
  }
}

class _PresenceRequest {
  const _PresenceRequest({
    required this.type,
    required this.checkIn,
    this.overtimeId,
    this.overtimeLabel,
    this.session,
  });
  final AttendancePresenceType type;
  final bool checkIn;
  final String? overtimeId, overtimeLabel;
  final EffectivePresence? session;
}

class _ButtonState {
  const _ButtonState(this.label, this.variant, this.enabled);
  final String label;
  final AppButtonVariant variant;
  final bool enabled;
  factory _ButtonState.from(EffectiveTodayAttendance attendance) {
    final open = attendance.openPresence;
    if (open != null) {
      return _ButtonState(
        open.type == AttendanceType.regular ? 'Check out' : 'Check out lembur',
        AppButtonVariant.danger,
        true,
      );
    }
    if (attendance.hasCompletedOvertime) {
      return const _ButtonState('Selesai', AppButtonVariant.primary, false);
    }
    if (attendance.regular.canCheckIn ||
        attendance.referenceState == AttendanceReferenceState.available) {
      return const _ButtonState('Check in', AppButtonVariant.primary, true);
    }
    if (attendance.regular.checkedOut) {
      return const _ButtonState('Selesai', AppButtonVariant.primary, false);
    }
    return const _ButtonState('Check in', AppButtonVariant.primary, true);
  }
}

String _displayTime(String value) {
  final date = parseApiDateTime(value);
  return date == null ? value : _clock('${date.hour}:${date.minute}');
}

String _clock(String value) {
  final parts = value.split(':');
  return parts.length < 2
      ? value
      : '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}
