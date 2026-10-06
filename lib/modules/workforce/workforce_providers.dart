import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/offline_first_providers.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_policy.dart';
import 'data/attendance_repository.dart';
import 'data/local/attendance_local_data_source.dart';
import 'data/local/workforce_get_cache.dart';
import 'data/models/effective_today_attendance.dart';
import 'data/models/attendance_list.dart';
import 'data/models/leave.dart';
import 'data/models/location.dart';
import 'data/models/local_attendance_record.dart';
import 'data/models/overtime.dart';
import 'data/models/today_attendance.dart';
import 'data/workforce_repository.dart';

final workforceRepositoryProvider = Provider<WorkforceRepository>((ref) {
  return WorkforceRepository(
    dioClient: ref.watch(dioClientProvider),
    getCache: ref.watch(workforceGetCacheProvider),
    attendanceLocalDataSource: ref.watch(attendanceLocalDataSourceProvider),
    scope: ref.watch(syncScopeProvider),
    cacheReadEnabled: ref.watch(attendanceCacheReadEnabledProvider),
  );
});

final attendanceCacheReadEnabledProvider = Provider<bool>((ref) {
  return ref.watch(syncPolicyProvider).readMode('attendanceCacheRead') ==
      ReadCapability.cacheRead;
});

final workforceGetCacheProvider = Provider<WorkforceGetCache>((ref) {
  return WorkforceGetCache(database: ref.watch(appDatabaseProvider));
});

final attendanceLocalDataSourceProvider = Provider<AttendanceLocalDataSource>((
  ref,
) {
  return AttendanceLocalDataSource(database: ref.watch(appDatabaseProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository?>((ref) {
  final scope = ref.watch(syncScopeProvider);
  if (scope == null) return null;
  return AttendanceRepository(
    scope: scope,
    remote: ref.watch(workforceRepositoryProvider),
    local: ref.watch(attendanceLocalDataSourceProvider),
    database: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxServiceProvider),
    coordinator: ref.watch(syncCoordinatorProvider),
    fileStore: ref.watch(durableFileStoreProvider),
  );
});

final attendanceWorkDateProvider = StreamProvider<DateTime>((ref) {
  Timer? timer;
  late final StreamController<DateTime> controller;

  void emitDateAndScheduleNext() {
    final now = DateTime.now();
    controller.add(DateTime(now.year, now.month, now.day));
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(nextDay.difference(now) + const Duration(seconds: 1), () {
      emitDateAndScheduleNext();
    });
  }

  controller = StreamController<DateTime>(
    onListen: emitDateAndScheduleNext,
    onCancel: () => timer?.cancel(),
  );
  ref.onDispose(() {
    timer?.cancel();
    if (!controller.isClosed) controller.close();
  });
  return controller.stream;
});

final effectiveTodayAttendanceProvider =
    StreamProvider<EffectiveTodayAttendance>((ref) {
      final repository = ref.watch(attendanceRepositoryProvider);
      if (repository == null) return const Stream.empty();
      if (!ref.watch(attendanceCacheReadEnabledProvider)) {
        return Stream.fromFuture(repository.fetchToday());
      }
      final now = DateTime.now();
      final workDate =
          ref.watch(attendanceWorkDateProvider).valueOrNull ??
          DateTime(now.year, now.month, now.day);
      return repository.watchToday(workDate);
    });

final localAttendanceRecordsProvider =
    StreamProvider<List<LocalAttendanceRecord>>((ref) {
      final scope = ref.watch(syncScopeProvider);
      if (scope == null) return Stream.value(const []);
      return ref
          .watch(attendanceLocalDataSourceProvider)
          .watchPendingRecords(scope);
    });

final approvedOvertimeReferencesProvider = StreamProvider.autoDispose
    .family<List<AttendanceOvertimeReference>, DateTime>((ref, workDate) {
      final repository = ref.watch(attendanceRepositoryProvider);
      if (repository == null) return Stream.value(const []);
      if (!ref.watch(attendanceCacheReadEnabledProvider)) {
        return Stream.value(const []);
      }
      return repository.watchApprovedOvertimeReferences(workDate);
    });

final attendanceRefreshControllerProvider =
    AsyncNotifierProvider<AttendanceRefreshController, void>(
      AttendanceRefreshController.new,
    );

class AttendanceRefreshController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> refresh() async {
    final repository = ref.read(attendanceRepositoryProvider);
    if (repository == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      Object? refreshError;
      StackTrace? refreshStack;
      try {
        await repository.refreshReferences();
      } catch (error, stack) {
        refreshError = error;
        refreshStack = stack;
      }
      await repository.requestSync();
      if (refreshError != null) {
        Error.throwWithStackTrace(refreshError, refreshStack!);
      }
    });
  }
}

final todayAttendanceProvider = FutureProvider<TodayAttendance>((ref) {
  return ref.watch(workforceRepositoryProvider).fetchTodayAttendance();
});

final attendanceFilterProvider = StateProvider<AttendanceListFilter>((ref) {
  return const AttendanceListFilter();
});

final attendanceListControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      AttendanceListController,
      AttendanceListState
    >(AttendanceListController.new);

final attendanceDetailProvider = FutureProvider.autoDispose
    .family<AttendanceRecord, String>((ref, attendanceId) {
      return ref
          .watch(workforceRepositoryProvider)
          .fetchAttendanceDetail(attendanceId);
    });

final overtimeFilterProvider = StateProvider<OvertimeListFilter>((ref) {
  return const OvertimeListFilter();
});

final overtimeListControllerProvider =
    AutoDisposeAsyncNotifierProvider<OvertimeListController, OvertimeListState>(
      OvertimeListController.new,
    );

final overtimeDetailProvider = FutureProvider.autoDispose
    .family<OvertimeRecord, String>((ref, overtimeId) {
      return ref
          .watch(workforceRepositoryProvider)
          .fetchOvertimeDetail(overtimeId);
    });

final leaveFilterProvider = StateProvider<LeaveListFilter>((ref) {
  return const LeaveListFilter();
});

final leaveListControllerProvider =
    AutoDisposeAsyncNotifierProvider<LeaveListController, LeaveListState>(
      LeaveListController.new,
    );

final leaveDetailProvider = FutureProvider.autoDispose
    .family<LeaveRecord, String>((ref, leaveId) {
      return ref.watch(workforceRepositoryProvider).fetchLeaveDetail(leaveId);
    });

final leaveTypeListProvider = FutureProvider.autoDispose<List<LeaveType>>((
  ref,
) {
  return ref.watch(workforceRepositoryProvider).fetchLeaveTypes();
});

final locationListProvider = FutureProvider.autoDispose
    .family<List<WorkforceLocation>, String>((ref, type) {
      if (type.isEmpty) {
        return const <WorkforceLocation>[];
      }

      return ref.watch(workforceRepositoryProvider).fetchLocations(type: type);
    });

class AttendanceListController
    extends AutoDisposeAsyncNotifier<AttendanceListState> {
  @override
  Future<AttendanceListState> build() async {
    final filter = ref.watch(attendanceFilterProvider);
    final result = await ref
        .watch(workforceRepositoryProvider)
        .fetchAttendanceList(filter: filter);
    return AttendanceListState(records: result.records, meta: result.meta);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final filter = ref.read(attendanceFilterProvider);
      final result = await ref
          .read(workforceRepositoryProvider)
          .fetchAttendanceList(
            filter: filter,
            page: current.meta.currentPage + 1,
          );

      state = AsyncData(
        AttendanceListState(
          records: [...current.records, ...result.records],
          meta: result.meta,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }
}

class OvertimeListController
    extends AutoDisposeAsyncNotifier<OvertimeListState> {
  @override
  Future<OvertimeListState> build() async {
    final filter = ref.watch(overtimeFilterProvider);
    final result = await ref
        .watch(workforceRepositoryProvider)
        .fetchOvertimeList(filter: filter);
    return OvertimeListState(records: result.records, meta: result.meta);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final filter = ref.read(overtimeFilterProvider);
      final result = await ref
          .read(workforceRepositoryProvider)
          .fetchOvertimeList(
            filter: filter,
            page: current.meta.currentPage + 1,
          );

      state = AsyncData(
        OvertimeListState(
          records: [...current.records, ...result.records],
          meta: result.meta,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }
}

class LeaveListController extends AutoDisposeAsyncNotifier<LeaveListState> {
  @override
  Future<LeaveListState> build() async {
    final filter = ref.watch(leaveFilterProvider);
    final result = await ref
        .watch(workforceRepositoryProvider)
        .fetchLeaveList(filter: filter);
    return LeaveListState(records: result.records, meta: result.meta);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final filter = ref.read(leaveFilterProvider);
      final result = await ref
          .read(workforceRepositoryProvider)
          .fetchLeaveList(filter: filter, page: current.meta.currentPage + 1);

      state = AsyncData(
        LeaveListState(
          records: [...current.records, ...result.records],
          meta: result.meta,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }
}
