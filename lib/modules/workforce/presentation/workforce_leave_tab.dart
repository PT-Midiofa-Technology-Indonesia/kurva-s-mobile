import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/offline_first_providers.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/leave.dart';
import '../workforce_providers.dart';
import 'widgets/workforce_history_sections.dart';
import 'workforce_overtime_tab.dart' show WorkforceRequestFooter;

class WorkforceLeaveTab extends ConsumerWidget {
  const WorkforceLeaveTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveListControllerProvider);
    final offline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    return Stack(
      children: [
        Positioned.fill(child: _list(context, ref, state)),
        WorkforceRequestFooter(
          label: 'Ajukan cuti',
          enabled: !offline,
          onPressed: () async {
            if (await context.push<bool>(RouteNames.workforceLeaveRequest) ==
                true) {
              ref.invalidate(leaveListControllerProvider);
            }
          },
        ),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LeaveListState> state,
  ) => state.when(
    loading: () => const AppSkeletonListView(
      itemCount: 4,
      padding: EdgeInsets.only(bottom: 104),
    ),
    error: (error, _) => NetworkAwareErrorView(
      error: error,
      message: _message(error),
      onRetry: () => ref.invalidate(leaveListControllerProvider),
    ),
    data: (data) => RefreshIndicator(
      onRefresh: () =>
          ref.refresh(leaveListControllerProvider.future).then<void>((_) {}),
      child: NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.metrics.pixels >= event.metrics.maxScrollExtent - 160) {
            ref.read(leaveListControllerProvider.notifier).loadNextPage();
          }
          return false;
        },
        child: LeaveHistory(
          records: data.records,
          isLoadingMore: data.isLoadingMore,
          loadMoreError: data.loadMoreError,
          onLoadMore: () =>
              ref.read(leaveListControllerProvider.notifier).loadNextPage(),
        ),
      ),
    ),
  );

  String _message(Object error) =>
      error.toString().isEmpty ? 'Gagal memuat data cuti.' : error.toString();
}
