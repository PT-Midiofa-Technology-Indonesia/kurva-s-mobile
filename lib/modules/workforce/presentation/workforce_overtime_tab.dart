import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/offline_first_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/overtime.dart';
import '../workforce_providers.dart';
import 'widgets/workforce_history_sections.dart';

class WorkforceOvertimeTab extends ConsumerWidget {
  const WorkforceOvertimeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(overtimeListControllerProvider);
    final offline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    return Stack(
      children: [
        Positioned.fill(child: _list(context, ref, state)),
        WorkforceRequestFooter(
          label: 'Ajukan lembur',
          enabled: !offline,
          onPressed: () async {
            if (await context.push<bool>(RouteNames.workforceOvertimeRequest) ==
                true) {
              ref.invalidate(overtimeListControllerProvider);
            }
          },
        ),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<OvertimeListState> state,
  ) => state.when(
    loading: () => const AppSkeletonListView(
      itemCount: 4,
      padding: EdgeInsets.only(bottom: 104),
    ),
    error: (error, _) => NetworkAwareErrorView(
      error: error,
      cacheFeatureKey: 'attendanceCacheRead',
      message: _message(error),
      onRetry: () => ref.invalidate(overtimeListControllerProvider),
    ),
    data: (data) => RefreshIndicator(
      onRefresh: () =>
          ref.refresh(overtimeListControllerProvider.future).then<void>((_) {}),
      child: NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.metrics.pixels >= event.metrics.maxScrollExtent - 160) {
            ref.read(overtimeListControllerProvider.notifier).loadNextPage();
          }
          return false;
        },
        child: OvertimeHistory(
          records: data.records,
          isLoadingMore: data.isLoadingMore,
          loadMoreError: data.loadMoreError,
          onLoadMore: () =>
              ref.read(overtimeListControllerProvider.notifier).loadNextPage(),
        ),
      ),
    ),
  );

  String _message(Object error) =>
      error.toString().isEmpty ? 'Gagal memuat data lembur.' : error.toString();
}

class WorkforceRequestFooter extends StatelessWidget {
  const WorkforceRequestFooter({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: AppButton(
          label: label,
          backgroundColor: AppColors.dashboardTeal,
          elevation: 4,
          shadowColor: AppColors.black.withValues(alpha: .1),
          textStyle: const TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          onPressed: enabled ? onPressed : null,
        ),
      ),
    ),
  );
}
