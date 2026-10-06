import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline_first_providers.dart';
import '../auth/auth_providers.dart';
import 'data/meeting_repository.dart';
import 'data/models/meeting_models.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(dioClient: ref.watch(dioClientProvider));
});

final meetingCompanyIdProvider = Provider<String?>((ref) {
  return ref.watch(syncScopeProvider)?.companyId;
});

final meetingListProvider = FutureProvider.autoDispose
    .family<MeetingListResult, MeetingListQuery>((ref, query) async {
      final repository = ref.watch(meetingRepositoryProvider);
      return repository.fetchMeetings(
        companyId: ref.watch(meetingCompanyIdProvider),
        search: query.search,
        year: query.year,
        perPage: query.perPage,
        page: query.page,
      );
    });

final meetingPaginatedListProvider = AsyncNotifierProvider.autoDispose
    .family<MeetingListController, MeetingListState, MeetingListQuery>(
      MeetingListController.new,
    );

class MeetingListState {
  const MeetingListState({
    required this.result,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final MeetingListResult result;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => result.currentPage < result.lastPage;
}

class MeetingListController
    extends AutoDisposeFamilyAsyncNotifier<MeetingListState, MeetingListQuery> {
  late MeetingListQuery _query;

  @override
  Future<MeetingListState> build(MeetingListQuery query) async {
    _query = query;
    final result = await ref.watch(meetingListProvider(query).future);
    return MeetingListState(result: result);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(
      MeetingListState(result: current.result, isLoadingMore: true),
    );
    try {
      final next = await ref.read(
        meetingListProvider(
          _query.copyWith(page: current.result.currentPage + 1),
        ).future,
      );
      final meetingsById = {
        for (final meeting in current.result.meetings) meeting.id: meeting,
        for (final meeting in next.meetings) meeting.id: meeting,
      };
      state = AsyncData(
        MeetingListState(
          result: MeetingListResult(
            meetings: meetingsById.values.toList(growable: false),
            currentPage: next.currentPage,
            lastPage: next.lastPage,
          ),
        ),
      );
    } catch (error) {
      state = AsyncData(
        MeetingListState(result: current.result, loadMoreError: error),
      );
    }
  }
}

final meetingDetailProvider = FutureProvider.autoDispose
    .family<MeetingDetail, String>((ref, meetingId) {
      return ref
          .watch(meetingRepositoryProvider)
          .fetchMeetingDetail(
            meetingId: meetingId,
            companyId: ref.watch(meetingCompanyIdProvider),
          );
    });

final meetingTasksProvider = FutureProvider.autoDispose
    .family<List<MeetingTask>, MeetingTasksQuery>((ref, query) async {
      final repository = ref.watch(meetingRepositoryProvider);
      final companyId = ref.watch(meetingCompanyIdProvider);
      if (!query.isQuality) {
        return repository.fetchTasks(
          meetingId: query.meetingId,
          tab: query.tab,
          companyId: companyId,
        );
      }

      return repository.fetchQcTasks(
        meetingId: query.meetingId,
        tab: query.tab,
        companyId: companyId,
      );
    });

final meetingOverviewTasksProvider = FutureProvider.autoDispose
    .family<MeetingTasksResult, MeetingTasksQuery>((ref, query) {
      final repository = ref.watch(meetingRepositoryProvider);
      final companyId = ref.watch(meetingCompanyIdProvider);
      return query.isQuality
          ? repository.fetchQcTasksResult(
              meetingId: query.meetingId,
              tab: query.tab,
              companyId: companyId,
            )
          : repository.fetchTasksResult(
              meetingId: query.meetingId,
              tab: query.tab,
              companyId: companyId,
            );
    });

final meetingTaskDetailProvider = FutureProvider.autoDispose
    .family<MeetingTask, MeetingTaskQuery>((ref, query) {
      final repository = ref.watch(meetingRepositoryProvider);
      final companyId = ref.watch(meetingCompanyIdProvider);
      return query.isQuality
          ? repository.fetchQcTaskDetail(
              meetingId: query.meetingId,
              qcTaskId: query.taskId,
              companyId: companyId,
            )
          : repository.fetchTaskDetail(
              meetingId: query.meetingId,
              taskId: query.taskId,
              companyId: companyId,
            );
    });

final meetingAssigneeCandidatesProvider = FutureProvider.autoDispose
    .family<List<MeetingReference>, MeetingAssigneeQuery>((ref, query) {
      return ref
          .watch(meetingRepositoryProvider)
          .fetchAssigneeCandidates(
            meetingId: query.meetingId,
            taskId: query.taskId,
            search: query.search,
            companyId: ref.watch(meetingCompanyIdProvider),
          );
    });

class MeetingListQuery {
  const MeetingListQuery({
    this.search,
    this.year,
    this.perPage = 20,
    this.page = 1,
  });

  final String? search;
  final String? year;
  final int perPage;
  final int page;

  MeetingListQuery copyWith({
    String? search,
    String? year,
    int? perPage,
    int? page,
  }) {
    return MeetingListQuery(
      search: search ?? this.search,
      year: year ?? this.year,
      perPage: perPage ?? this.perPage,
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MeetingListQuery &&
      other.search == search &&
      other.year == year &&
      other.perPage == perPage &&
      other.page == page;

  @override
  int get hashCode => Object.hash(search, year, perPage, page);
}

class MeetingTasksQuery {
  const MeetingTasksQuery({
    required this.meetingId,
    required this.isQuality,
    this.tab = 'open',
  });

  final String meetingId;
  final bool isQuality;
  final String tab;

  @override
  bool operator ==(Object other) =>
      other is MeetingTasksQuery &&
      other.meetingId == meetingId &&
      other.isQuality == isQuality &&
      other.tab == tab;

  @override
  int get hashCode => Object.hash(meetingId, isQuality, tab);
}

class MeetingTaskQuery {
  const MeetingTaskQuery({
    required this.meetingId,
    required this.taskId,
    required this.isQuality,
  });

  final String meetingId;
  final String taskId;
  final bool isQuality;

  @override
  bool operator ==(Object other) =>
      other is MeetingTaskQuery &&
      other.meetingId == meetingId &&
      other.taskId == taskId &&
      other.isQuality == isQuality;

  @override
  int get hashCode => Object.hash(meetingId, taskId, isQuality);
}

class MeetingAssigneeQuery {
  const MeetingAssigneeQuery({
    required this.meetingId,
    required this.taskId,
    this.search,
  });

  final String meetingId;
  final String taskId;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is MeetingAssigneeQuery &&
      other.meetingId == meetingId &&
      other.taskId == taskId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(meetingId, taskId, search);
}
