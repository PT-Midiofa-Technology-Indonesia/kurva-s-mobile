import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_target_icon.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_popup_menu_button.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/project_search_field.dart';

import 'project_assignee_picker_page.dart';

class ProjectQcAssignmentPickerArgs {
  const ProjectQcAssignmentPickerArgs({
    required this.projectId,
    required this.initialTaskId,
  });

  final String projectId;
  final String initialTaskId;
}

class ProjectQcAssignmentPickerPage extends ConsumerStatefulWidget {
  const ProjectQcAssignmentPickerPage({required this.args, super.key});

  final ProjectQcAssignmentPickerArgs args;

  @override
  ConsumerState<ProjectQcAssignmentPickerPage> createState() =>
      _ProjectQcAssignmentPickerPageState();
}

class _ProjectQcAssignmentPickerPageState
    extends ConsumerState<ProjectQcAssignmentPickerPage> {
  final _searchController = TextEditingController();
  late final Set<String> _selectedIds = {
    if (widget.args.initialTaskId.isNotEmpty) widget.args.initialTaskId,
  };
  bool _showSearch = false;
  bool _openingAssignee = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Future<void> _openAssignee(List<String> ids) async {
    if (_openingAssignee || ids.isEmpty) return;
    setState(() => _openingAssignee = true);
    try {
      final updated = await context.push<bool>(
        RouteNames.projectAssignee,
        extra: ProjectAssigneePickerArgs(
          projectId: widget.args.projectId,
          qcTaskIds: List.unmodifiable(ids),
        ),
      );
      if (mounted && updated == true) context.pop(true);
    } finally {
      if (mounted) setState(() => _openingAssignee = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ProjectTasksQuery(
      projectId: widget.args.projectId,
      tab: 'open',
    );
    final state = ref.watch(projectQcTasksProvider(query));
    final tasks = (state.valueOrNull ?? const <ProjectTask>[])
        .where((task) => task.canClaim && task.id.isNotEmpty)
        .toList(growable: false);
    final selected = tasks
        .where((task) => _selectedIds.contains(task.id))
        .map((task) => task.id)
        .toSet()
        .toList(growable: false);
    final search = _searchController.text.trim().toLowerCase();
    final visible = tasks
        .where((task) {
          return '${task.code} ${task.title} ${task.assignee?.name ?? ''} ${task.description ?? ''}'
              .toLowerCase()
              .contains(search);
        })
        .toList(growable: false);
    final offline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Assignee Terpilih',
              titleSpacing: 4,
              leadingSize: 36,
              titleFontSize: 18,
              onBackPressed: () => context.pop(),
              actions: [
                AppHeaderAction(
                  icon: Icons.search,
                  tooltip: 'Cari task',
                  onPressed: () => setState(() => _showSearch = !_showSearch),
                ),
              ],
              actionWidgets: [
                AppPopupMenuButton<bool>(
                  items: const [true, false],
                  labelBuilder: (all) =>
                      all ? 'Pilih semua' : 'Batalkan pilihan',
                  onSelected: (all) async {
                    setState(() {
                      if (all) {
                        _selectedIds.addAll(visible.map((task) => task.id));
                      } else {
                        _selectedIds.clear();
                      }
                    });
                  },
                  iconColor: AppColors.dashboardTeal,
                  fontFamily: AppFonts.inter,
                ),
              ],
            ),
            if (_showSearch)
              ProjectSearchField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            Expanded(
              child: state.when(
                skipError: tasks.isNotEmpty,
                loading: () => const AppSkeletonListView(
                  variant: AppSkeletonListVariant.detailed,
                  showSectionHeader: false,
                ),
                error: (error, _) => NetworkAwareErrorView(
                  error: error,
                  cacheFeatureKey: 'projectCacheRead',
                  message: error.toString(),
                  onRetry: () => ref.invalidate(projectQcTasksProvider(query)),
                ),
                data: (_) => visible.isEmpty
                    ? EmptyView(
                        message: search.isEmpty
                            ? 'Belum ada task yang dapat di-assign.'
                            : 'Task tidak ditemukan.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final task = visible[index];
                          return _SelectableTaskCard(
                            task: task,
                            selected: _selectedIds.contains(task.id),
                            onTap: () => _toggle(task.id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: AppColors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: 'Assign (${selected.length})',
              backgroundColor: AppColors.dashboardTeal,
              isLoading: _openingAssignee,
              onPressed: selected.isEmpty || offline || state.isLoading
                  ? null
                  : () => _openAssignee(selected),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableTaskCard extends StatelessWidget {
  const _SelectableTaskCard({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final ProjectTask task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.taskCardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: AppFonts.geist,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${task.code}  ${task.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.taskCardBorder),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              border: Border.all(
                                color: AppColors.secondaryText,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(task.statusLabel),
                          ),
                          _TaskMetric(
                            icon: Icons.account_circle_outlined,
                            label: task.manpowerName.trim().isEmpty
                                ? '-'
                                : task.manpowerName.trim(),
                          ),
                          _TaskMetric(
                            iconWidget: const ProjectTargetIcon(
                              key: Key('qc-target-icon'),
                            ),
                            label: _taskTarget(task),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TaskMetric(
                        icon: Icons.description_outlined,
                        label: task.description?.trim().isNotEmpty ?? false
                            ? task.description!.trim()
                            : '-',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Checkbox(
            value: selected,
            onChanged: (_) => onTap(),
            activeColor: AppColors.dashboardTeal,
            semanticLabel: 'Pilih ${task.code} ${task.title}',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskMetric extends StatelessWidget {
  const _TaskMetric({this.icon, this.iconWidget, required this.label})
    : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget ?? Icon(icon, size: 18, color: AppColors.dashboardTeal),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label.isEmpty ? '-' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

String _taskTarget(ProjectTask task) {
  final rawUnit = task.uom?.code.trim().isNotEmpty ?? false
      ? task.uom!.code.trim()
      : task.uom?.name.trim() ?? '';
  final unit = switch (rawUnit.toLowerCase().replaceAll(' ', '')) {
    'm2' || 'meterpersegi' => 'm²',
    'm3' || 'meterkubik' => 'm³',
    _ => rawUnit,
  };
  final suffix = unit.isEmpty ? '' : ' $unit';
  return '${_formatVolume(task.targetVolume)}$suffix';
}

String _formatVolume(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
