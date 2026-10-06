import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/project_search_field.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';

class ProjectAssigneePickerPage extends ConsumerStatefulWidget {
  const ProjectAssigneePickerPage({required this.args, super.key});

  final ProjectAssigneePickerArgs args;

  static const _fontFamily = AppFonts.inter;

  @override
  ConsumerState<ProjectAssigneePickerPage> createState() =>
      _ProjectAssigneePickerPageState();
}

class _ProjectAssigneePickerPageState
    extends ConsumerState<ProjectAssigneePickerPage> {
  final _searchController = TextEditingController();
  var _query = '';

  static const _assignees = [
    _ProjectAssigneeOption(
      initials: 'AG',
      name: 'Agung Prasetyo',
      color: AppColors.assigneePurple,
    ),
    _ProjectAssigneeOption(
      initials: 'AR',
      name: 'Arish Noah',
      color: AppColors.assigneeGreen,
    ),
    _ProjectAssigneeOption(
      initials: 'DI',
      name: 'Dimas Masdim',
      color: AppColors.assigneeMagenta,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(projectAssigneeActionControllerProvider(widget.args));
    final fallbackAssignees = _assignees
        .where(
          (assignee) =>
              assignee.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final assigneesState = widget.args.canLoadFromApi
        ? ref.watch(projectSubordinatesProvider(widget.args.projectId))
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: 'Assignee', onBackPressed: () => context.pop()),
            ProjectSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            Expanded(
              child: assigneesState == null
                  ? _AssigneeList(
                      assignees: fallbackAssignees,
                      onSelected: (_) {},
                    )
                  : assigneesState.when(
                      loading: () => const AppSkeletonListView(
                        variant: AppSkeletonListVariant.compact,
                        showSectionHeader: false,
                        padding: EdgeInsets.zero,
                      ),
                      error: (error, _) => NetworkAwareErrorView(
                        error: error,
                        cacheFeatureKey: 'projectCacheRead',
                        message: error.toString(),
                        onRetry: () => ref.invalidate(
                          projectSubordinatesProvider(widget.args.projectId),
                        ),
                      ),
                      data: (employees) {
                        final assignees = employees
                            .map(_ProjectAssigneeOption.fromReference)
                            .where(
                              (assignee) => assignee.name
                                  .toLowerCase()
                                  .contains(_query.toLowerCase()),
                            )
                            .toList(growable: false);

                        return _AssigneeList(
                          assignees: assignees,
                          onSelected: _assignEmployee,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignEmployee(_ProjectAssigneeOption assignee) async {
    try {
      await ref
          .read(projectAssigneeActionControllerProvider(widget.args))
          .assign(assignee.id);
      if (mounted) {
        AppToast.success(context, 'Assignee berhasil diperbarui.');
        context.pop(true);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, error);
      }
    }
  }
}

class _AssigneeList extends StatelessWidget {
  const _AssigneeList({required this.assignees, required this.onSelected});

  final List<_ProjectAssigneeOption> assignees;
  final ValueChanged<_ProjectAssigneeOption> onSelected;

  @override
  Widget build(BuildContext context) {
    if (assignees.isEmpty) {
      return const EmptyView(message: 'Assignee tidak ditemukan.');
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return _AssigneeListTile(
          assignee: assignees[index],
          onTap: () => onSelected(assignees[index]),
        );
      },
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: AppColors.line),
      itemCount: assignees.length,
    );
  }
}

class _AssigneeListTile extends StatelessWidget {
  const _AssigneeListTile({required this.assignee, required this.onTap});

  final _ProjectAssigneeOption assignee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: assignee.color,
                  child: Text(
                    assignee.initials,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: ProjectAssigneePickerPage._fontFamily,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    assignee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontFamily: ProjectAssigneePickerPage._fontFamily,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectAssigneePickerArgs {
  const ProjectAssigneePickerArgs({
    this.projectId = '',
    this.taskId = '',
    this.qcTaskIds = const [],
  });

  final String projectId;
  final String taskId;
  final List<String> qcTaskIds;

  bool get canLoadFromApi =>
      projectId.isNotEmpty && (taskId.isNotEmpty || qcTaskIds.isNotEmpty);
}

class _ProjectAssigneeOption {
  const _ProjectAssigneeOption({
    this.id = '',
    required this.initials,
    required this.name,
    required this.color,
  });

  final String id;
  final String initials;
  final String name;
  final Color color;

  factory _ProjectAssigneeOption.fromReference(ProjectReference reference) {
    return _ProjectAssigneeOption(
      id: reference.id,
      initials: reference.initials,
      name: reference.name,
      color: _avatarColor(reference.id + reference.name),
    );
  }
}

Color _avatarColor(String value) {
  const colors = [
    AppColors.assigneePurple,
    AppColors.assigneeGreen,
    AppColors.assigneeMagenta,
  ];
  if (value.isEmpty) return colors.first;

  return colors[value.codeUnits.fold<int>(0, (sum, code) => sum + code) %
      colors.length];
}
