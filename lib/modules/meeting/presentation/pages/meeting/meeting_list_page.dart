import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/asset_paths.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/meeting/meeting_detail_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/meeting/meeting_overview_page.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';
import 'package:curva_mobile/shared/widgets/selection_bottom_sheet.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';

enum MeetingListType {
  task('Task Meeting'),
  quality('Quality Meeting');

  const MeetingListType(this.label);

  final String label;
}

class MeetingListPage extends ConsumerStatefulWidget {
  const MeetingListPage({required this.type, super.key});

  final MeetingListType type;

  @override
  ConsumerState<MeetingListPage> createState() => _MeetingListPageState();
}

class _MeetingListPageState extends ConsumerState<MeetingListPage> {
  static const _backgroundColor = AppColors.cardBackground;
  static const _cardBorderColor = AppColors.tabBorder;

  String? _year;

  Future<void> _showSearch(AsyncValue<MeetingListState> meetingsState) async {
    final meetings =
        meetingsState.valueOrNull?.result.meetings ?? const <Meeting>[];

    if (meetings.isEmpty) {
      AppToast.info(
        context,
        meetingsState.isLoading
            ? 'Daftar meeting sedang dimuat.'
            : 'Data meeting belum tersedia.',
      );
      return;
    }

    final selectedMeeting = await FullPageSearchBottomSheet.show<Meeting>(
      context,
      title: 'Pencarian',
      options: meetings,
      labelBuilder: (meeting) => meeting.title.isEmpty ? '-' : meeting.title,
      searchTextBuilder: (meeting) => [
        meeting.title,
        meeting.description,
        meeting.projectName,
        meeting.status,
      ].join(' '),
    );

    if (!mounted || selectedMeeting == null) return;

    context.push(
      RouteNames.meetingDetail,
      extra: MeetingDetailData(meetingId: selectedMeeting.id),
    );
  }

  Future<void> _showFilter() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => (currentYear - index).toString());
    final options = ['Semua', ...years];
    final selected = await SelectionBottomSheet.show<String>(
      context,
      title: 'Filter Tahun',
      options: options,
      selectedOption: _year ?? 'Semua',
      labelBuilder: (option) => option,
    );

    if (!mounted || selected == null) return;
    setState(() => _year = selected == 'Semua' ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final query = MeetingListQuery(year: _year);
    final meetingsState = ref.watch(meetingPaginatedListProvider(query));
    final visibleMeetings = meetingsState.valueOrNull == null
        ? const <_MeetingData>[]
        : meetingsState.valueOrNull!.result.meetings
              .map(_MeetingData.fromMeeting)
              .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: _backgroundColor,
          child: Column(
            children: [
              AppHeader(
                title: 'Meeting',
                onBackPressed: () => context.pop(),
                actions: [
                  AppHeaderAction(
                    icon: Icons.search,
                    tooltip: 'Cari',
                    onPressed: () => _showSearch(meetingsState),
                  ),
                  AppHeaderAction(
                    assetPath: AssetPaths.iconFilter,
                    tooltip: 'Filter',
                    badge: _year == null ? null : '1',
                    onPressed: _showFilter,
                  ),
                ],
              ),
              Expanded(
                child: meetingsState.when(
                  loading: () => const AppSkeletonListView(
                    variant: AppSkeletonListVariant.detailed,
                    itemCount: 4,
                  ),
                  error: (error, _) => NetworkAwareErrorView(
                    error: error,
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(meetingPaginatedListProvider(query)),
                  ),
                  data: (state) {
                    final sections = _groupByYear(visibleMeetings);
                    if (sections.isEmpty) {
                      return const EmptyView(
                        message: 'Meeting belum tersedia.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(
                        meetingPaginatedListProvider(query).future,
                      ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 160) {
                            ref
                                .read(
                                  meetingPaginatedListProvider(query).notifier,
                                )
                                .loadNextPage();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            24,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          itemCount:
                              sections.length +
                              (state.isLoadingMore ||
                                      state.loadMoreError != null
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xl),
                          itemBuilder: (context, index) {
                            if (index == sections.length) {
                              return _MeetingPaginationFooter(
                                state: state,
                                onRetry: () => ref
                                    .read(
                                      meetingPaginatedListProvider(
                                        query,
                                      ).notifier,
                                    )
                                    .loadNextPage(),
                              );
                            }
                            return _MeetingYearSection(
                              section: sections[index],
                              type: widget.type,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingPaginationFooter extends StatelessWidget {
  const _MeetingPaginationFooter({required this.state, required this.onRetry});

  final MeetingListState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Gagal memuat data. Coba lagi'),
      ),
    );
  }
}

class _MeetingYearSection extends StatelessWidget {
  const _MeetingYearSection({required this.section, required this.type});

  final _MeetingYearData section;
  final MeetingListType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            section.year,
            style: const TextStyle(
              color: AppColors.strongText,
              fontFamily: AppFonts.inter,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...section.meetings.map(
          (meeting) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _MeetingCard(meeting: meeting, type: type),
          ),
        ),
      ],
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting, required this.type});

  final _MeetingData meeting;
  final MeetingListType type;

  static const _menuOptions = [
    _MeetingCardMenu.openMenu,
    _MeetingCardMenu.detail,
  ];

  Future<void> _showActionMenu(BuildContext context) async {
    final selectedAction = await SelectionBottomSheet.show<_MeetingCardMenu>(
      context,
      title: 'Pilih Aksi Selanjutnya',
      options: _menuOptions,
      selectedOption: null,
      labelBuilder: (option) => option.label,
    );

    if (!context.mounted || selectedAction == null) return;

    switch (selectedAction) {
      case _MeetingCardMenu.openMenu:
        context.push(
          RouteNames.meetingMenu,
          extra: MeetingOverviewData(
            meetingId: meeting.id,
            title: type.label,
            isQualityMeeting: type == MeetingListType.quality,
          ),
        );
      case _MeetingCardMenu.detail:
        context.push(
          RouteNames.meetingDetail,
          extra: MeetingDetailData(meetingId: meeting.id),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showActionMenu(context),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: _MeetingListPageState._cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: AppFonts.geist,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                meeting.description,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: AppFonts.geist,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(
                height: 1,
                color: _MeetingListPageState._cardBorderColor,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MeetingBadge(
                    label: meeting.status,
                    icon: Icons.edit_calendar_outlined,
                    borderColor: AppColors.orange,
                  ),
                  _MeetingBadge(
                    label: meeting.dateRange,
                    icon: Icons.access_time,
                    borderColor: AppColors.dashboardTeal,
                    backgroundColor: AppColors.workforceIconBackground,
                  ),
                  _MeetingMetric(
                    label: meeting.duration,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _MeetingParticipantMetric(value: meeting.participantCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MeetingCardMenu {
  openMenu('Buka menu'),
  detail('Detail');

  const _MeetingCardMenu(this.label);

  final String label;
}

class _MeetingBadge extends StatelessWidget {
  const _MeetingBadge({
    required this.label,
    required this.icon,
    required this.borderColor,
    this.backgroundColor = AppColors.white,
  });

  final String label;
  final IconData icon;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: borderColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.geist,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingMetric extends StatelessWidget {
  const _MeetingMetric({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.dashboardTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.geist,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingParticipantMetric extends StatelessWidget {
  const _MeetingParticipantMetric({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            size: 16,
            color: AppColors.dashboardTeal,
          ),
          const SizedBox(width: 4),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.geist,
                fontSize: 12,
                height: 1.33,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingYearData {
  const _MeetingYearData({required this.year, required this.meetings});

  final String year;
  final List<_MeetingData> meetings;
}

class _MeetingData {
  const _MeetingData({
    required this.id,
    required this.year,
    required this.title,
    required this.description,
    required this.status,
    required this.dateRange,
    required this.duration,
    required this.participantCount,
  });

  final String id;
  final String year;
  final String title;
  final String description;
  final String status;
  final String dateRange;
  final String duration;
  final String participantCount;

  factory _MeetingData.fromMeeting(Meeting meeting) {
    final start = parseApiDateTime(meeting.startDate);
    final end = parseApiDateTime(meeting.endDate);
    final year = (start ?? end)?.year.toString() ?? '-';
    final dateRange = end == null
        ? formatIndonesianDate(meeting.startDate, shortMonth: true)
        : '${formatIndonesianDate(meeting.startDate, shortMonth: true)} - '
              '${formatIndonesianDate(meeting.endDate, shortMonth: true)}';
    return _MeetingData(
      id: meeting.id,
      year: year,
      title: meeting.title.isEmpty ? '-' : meeting.title,
      description: meeting.description.isEmpty
          ? meeting.projectName
          : meeting.description,
      status: meeting.status.isEmpty ? '-' : meeting.status,
      dateRange: dateRange,
      duration: '${meeting.durationDays} d',
      participantCount: meeting.taskCount.toString(),
    );
  }
}

List<_MeetingYearData> _groupByYear(List<_MeetingData> meetings) {
  final grouped = <String, List<_MeetingData>>{};
  for (final meeting in meetings) {
    grouped.putIfAbsent(meeting.year, () => []).add(meeting);
  }
  final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return years
      .map((year) => _MeetingYearData(year: year, meetings: grouped[year]!))
      .toList(growable: false);
}
