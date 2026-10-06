import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/asset_paths.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/widgets/selection_bottom_sheet.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_overview_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_filter_bottom_sheet.dart';

class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({this.title = 'Project', super.key});

  final String title;
  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;
  static const _backgroundColor = AppColors.cardBackground;
  static const _cardBorderColor = AppColors.tabBorder;
  static const _lightTeal = AppColors.workforceIconBackground;
  static const _orange = AppColors.pendingApproval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProjectHeader(title: 'Project'),
            Expanded(
              child: ColoredBox(
                color: _backgroundColor,
                child: projectsState.when(
                  loading: () => const AppSkeletonListView(
                    variant: AppSkeletonListVariant.detailed,
                    itemCount: 4,
                  ),
                  error: (error, _) => NetworkAwareErrorView(
                    error: error,
                    cacheFeatureKey: 'projectCacheRead',
                    message: error.toString(),
                    onRetry: () => ref.invalidate(projectListProvider),
                  ),
                  data: (state) {
                    final result = state.result;
                    final sections = _groupProjectsByYear(result.projects);
                    if (sections.isEmpty) {
                      return const EmptyView(
                        message: 'Data project belum tersedia.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(projectListProvider.future),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 160) {
                            ref
                                .read(projectListProvider.notifier)
                                .loadNextPage();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          itemCount:
                              sections.length +
                              (state.isLoadingMore ||
                                      state.loadMoreError != null
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 44),
                          itemBuilder: (context, index) {
                            if (index == sections.length) {
                              return _ProjectPaginationFooter(state: state);
                            }
                            return _YearSection(
                              section: sections[index],
                              title: title,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectPaginationFooter extends ConsumerWidget {
  const _ProjectPaginationFooter({required this.state});

  final ProjectListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: TextButton.icon(
        onPressed: () => ref.read(projectListProvider.notifier).loadNextPage(),
        icon: const Icon(Icons.refresh),
        label: const Text('Gagal memuat data. Coba lagi'),
      ),
    );
  }
}

class _ProjectHeader extends ConsumerWidget {
  const _ProjectHeader({required this.title});

  final String title;

  Future<void> _showFilter(BuildContext context, WidgetRef ref) async {
    final selectedFilter = await ProjectFilterBottomSheet.show(
      context,
      initialFilter: ref.read(projectFilterProvider),
    );

    if (!context.mounted || selectedFilter == null) return;

    ref.read(projectFilterProvider.notifier).state = selectedFilter;
  }

  Future<void> _showSearch(BuildContext context, WidgetRef ref) async {
    final projectState = ref.read(projectListProvider);
    final projects =
        projectState.valueOrNull?.result.projects ?? const <Project>[];

    if (projects.isEmpty) {
      AppToast.info(
        context,
        projectState.isLoading
            ? 'Daftar project sedang dimuat.'
            : 'Data project belum tersedia.',
      );
      return;
    }

    final selectedProject = await FullPageSearchBottomSheet.show<Project>(
      context,
      title: 'Pencarian',
      options: projects,
      labelBuilder: (project) => project.name.isEmpty ? '-' : project.name,
      searchTextBuilder: (project) => [
        project.code,
        project.name,
        project.client?.name ?? '',
        project.description ?? '',
      ].join(' '),
    );

    if (!context.mounted || selectedProject == null) return;

    final project = _ProjectTaskData.fromProject(selectedProject);
    context.push(
      RouteNames.projectTaskDetail,
      extra: project.toDetailData(title: title),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = ref.watch(projectFilterProvider).activeCount;

    return AppHeader(
      title: title,
      onBackPressed: () => context.pop(),
      actions: [
        AppHeaderAction(
          icon: Icons.search,
          tooltip: 'Cari',
          onPressed: () => _showSearch(context, ref),
        ),
        AppHeaderAction(
          assetPath: AssetPaths.iconFilter,
          tooltip: 'Filter',
          badge: activeFilterCount == 0 ? null : activeFilterCount.toString(),
          onPressed: () => _showFilter(context, ref),
        ),
      ],
    );
  }
}

class _YearSection extends StatelessWidget {
  const _YearSection({required this.section, required this.title});

  final _ProjectYearSection section;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            section.year,
            style: const TextStyle(
              color: AppColors.strongText,
              fontFamily: ProjectListPage._fontFamily,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ...section.projects.map(
          (project) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ProjectCard(project: project, title: title),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.title});

  final _ProjectTaskData project;
  final String title;

  static const _menuOptions = [
    _ProjectCardMenu.openMenu,
    _ProjectCardMenu.detail,
  ];

  Future<void> _showActionMenu(BuildContext context) async {
    final selectedAction = await SelectionBottomSheet.show<_ProjectCardMenu>(
      context,
      title: 'Pilih Aksi Selanjutnya',
      options: _menuOptions,
      selectedOption: null,
      labelBuilder: (option) => option.label,
    );

    if (!context.mounted || selectedAction == null) return;

    switch (selectedAction) {
      case _ProjectCardMenu.openMenu:
        context.push(
          RouteNames.projectMenu,
          extra: project.toMenuData(title: title),
        );
      case _ProjectCardMenu.detail:
        context.push(
          RouteNames.projectTaskDetail,
          extra: project.toDetailData(title: title),
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
            border: Border.all(color: ProjectListPage._cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: ProjectListPage._accentFontFamily,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              if (project.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  project.description!,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: ProjectListPage._accentFontFamily,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1, color: ProjectListPage._cardBorderColor),
              const SizedBox(height: 14),
              Text(
                project.company,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: ProjectListPage._accentFontFamily,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ProjectBadge(
                    label: project.status,
                    icon: Icons.event_note,
                    borderColor: ProjectListPage._orange,
                  ),
                  _ProjectBadge(
                    label: project.dateRange,
                    icon: Icons.access_time,
                    borderColor: AppColors.dashboardTeal,
                    backgroundColor: ProjectListPage._lightTeal,
                  ),
                  _PlainMetric(
                    label: project.duration,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _StackMetric(value: project.stackCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProjectCardMenu {
  openMenu('Buka menu'),
  detail('Detail');

  const _ProjectCardMenu(this.label);

  final String label;
}

class _ProjectBadge extends StatelessWidget {
  const _ProjectBadge({
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
      height: 20,
      padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: borderColor),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: ProjectListPage._accentFontFamily,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainMetric extends StatelessWidget {
  const _PlainMetric({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.dashboardTeal),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: ProjectListPage._accentFontFamily,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackMetric extends StatelessWidget {
  const _StackMetric({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.layers_outlined,
            size: 14,
            color: AppColors.dashboardTeal,
          ),
          const SizedBox(width: 2),
          Container(
            height: 20,
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
                fontFamily: ProjectListPage._accentFontFamily,
                fontSize: 12,
                height: 1.33,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectYearSection {
  const _ProjectYearSection({required this.year, required this.projects});

  final String year;
  final List<_ProjectTaskData> projects;
}

class _ProjectTaskData {
  const _ProjectTaskData({
    required this.id,
    required this.title,
    required this.company,
    required this.dateRange,
    required this.duration,
    required this.stackCount,
    required this.status,
    required this.taskProject,
    required this.qualityControl,
    required this.taskMeeting,
    required this.qualityMeeting,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final String company;
  final String dateRange;
  final String duration;
  final String stackCount;
  final String status;
  final int taskProject;
  final int qualityControl;
  final int taskMeeting;
  final int qualityMeeting;

  factory _ProjectTaskData.fromProject(Project project) {
    final summary = project.summary;
    return _ProjectTaskData(
      id: project.id,
      title: project.name,
      description: project.description,
      company: project.client?.name ?? '-',
      dateRange: _formatDateRange(project.startDate, project.endDate),
      duration: project.durationDays > 0 ? '${project.durationDays} d' : '-',
      stackCount: project.nodesCount.toString(),
      status: project.status,
      taskProject: summary?.taskProject ?? project.nodesCount,
      qualityControl: summary?.qualityControl ?? 0,
      taskMeeting: summary?.taskMeeting ?? 0,
      qualityMeeting: summary?.qualityMeeting ?? 0,
    );
  }

  ProjectDetailData toDetailData({required String title}) {
    return ProjectDetailData(
      projectId: id,
      title: title,
      projectName: title,
      status: status,
      client: company,
      period: dateRange,
      description: description ?? '-',
      workingDays: duration,
      taskCount: stackCount,
    );
  }

  ProjectOverviewData toMenuData({required String title}) {
    return ProjectOverviewData(
      projectId: id,
      projectName: this.title,
      title: title,
      taskProject: taskProject,
      qualityControl: qualityControl,
      taskMeeting: taskMeeting,
      qualityMeeting: qualityMeeting,
    );
  }
}

List<_ProjectYearSection> _groupProjectsByYear(List<Project> projects) {
  final grouped = <String, List<_ProjectTaskData>>{};
  for (final project in projects) {
    final year = _projectYear(project);
    grouped
        .putIfAbsent(year, () => [])
        .add(_ProjectTaskData.fromProject(project));
  }

  final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return years
      .map((year) => _ProjectYearSection(year: year, projects: grouped[year]!))
      .toList(growable: false);
}

String _projectYear(Project project) {
  final date = parseApiDateTime(project.startDate);
  if (date != null) {
    return date.year.toString();
  }

  final createdAt = parseApiDateTime(project.createdAt);
  return createdAt?.year.toString() ?? '-';
}

String _formatDateRange(String? startDate, String? endDate) {
  final start = parseApiDateTime(startDate);
  final end = parseApiDateTime(endDate);
  if (start == null && end == null) {
    return '-';
  }
  if (start == null) {
    return _formatDate(end!);
  }
  if (end == null) {
    return _formatDate(start);
  }

  return '${_formatDate(start)} - ${_formatDate(end)}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
}
