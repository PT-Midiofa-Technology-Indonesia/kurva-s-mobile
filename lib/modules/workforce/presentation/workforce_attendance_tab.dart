import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline_first_providers.dart';
import '../../../core/sync/sync_models.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/local_attendance_record.dart';
import '../workforce_providers.dart';
import 'widgets/attendance_hero.dart';
import 'widgets/workforce_history_sections.dart';

class WorkforceAttendanceTab extends ConsumerStatefulWidget {
  const WorkforceAttendanceTab({super.key});

  @override
  ConsumerState<WorkforceAttendanceTab> createState() =>
      _WorkforceAttendanceTabState();
}

class _WorkforceAttendanceTabState
    extends ConsumerState<WorkforceAttendanceTab> {
  @override
  Widget build(BuildContext context) {
    ref.listen(syncStatusProvider, (previous, next) {
      final before = previous?.valueOrNull;
      final after = next.valueOrNull;
      if (after == null ||
          after.state != SyncRunState.completed ||
          after.completedCount == 0 ||
          before?.lastSyncedAt == after.lastSyncedAt) {
        return;
      }
      ref.invalidate(attendanceListControllerProvider);
      unawaited(
        ref.read(attendanceRefreshControllerProvider.notifier).refresh(),
      );
    });

    final state = ref.watch(attendanceListControllerProvider);
    final local =
        ref.watch(localAttendanceRecordsProvider).valueOrNull ?? const [];
    final offline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    return state.when(
      loading: () => _AttendanceList(
        localRecords: local,
        isOffline: offline,
        body: const SizedBox(
          height: 360,
          child: AppSkeletonListView(itemCount: 2),
        ),
      ),
      error: (error, _) => _AttendanceList(
        localRecords: local,
        isOffline: offline,
        body: local.isEmpty
            ? SizedBox(
                height: 260,
                child: NetworkAwareErrorView(
                  error: error,
                  cacheFeatureKey: 'attendanceCacheRead',
                  message: _errorMessage(error),
                  onRetry: () =>
                      ref.invalidate(attendanceListControllerProvider),
                ),
              )
            : null,
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(attendanceRefreshControllerProvider.notifier).refresh(),
            ref.refresh(attendanceListControllerProvider.future),
          ]);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (event) {
            if (event.metrics.pixels >= event.metrics.maxScrollExtent - 160) {
              ref
                  .read(attendanceListControllerProvider.notifier)
                  .loadNextPage();
            }
            return false;
          },
          child: _AttendanceList(
            localRecords: local,
            isOffline: offline,
            body: AttendanceHistory(
              records: data.records,
              showEmptyState: local.isEmpty,
              isLoadingMore: data.isLoadingMore,
              loadMoreError: data.loadMoreError,
              onLoadMore: () => ref
                  .read(attendanceListControllerProvider.notifier)
                  .loadNextPage(),
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object error) => error.toString().isEmpty
      ? 'Gagal memuat data presensi.'
      : error.toString();
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({
    required this.localRecords,
    required this.isOffline,
    this.body,
  });
  final List<LocalAttendanceRecord> localRecords;
  final bool isOffline;
  final Widget? body;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    children: [
      const TodayAttendanceHero(),
      if (localRecords.isNotEmpty)
        LocalAttendanceHistory(records: localRecords, isOffline: isOffline),
      if (body != null) body!,
    ],
  );
}
