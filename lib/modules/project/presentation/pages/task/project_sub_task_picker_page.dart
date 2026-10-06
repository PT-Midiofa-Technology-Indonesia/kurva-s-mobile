import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/project_search_field.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';

class ProjectSubTaskPickerPage extends ConsumerStatefulWidget {
  const ProjectSubTaskPickerPage({required this.detail, super.key});

  final ProjectSubTaskPickerData detail;

  @override
  ConsumerState<ProjectSubTaskPickerPage> createState() =>
      _ProjectSubTaskPickerPageState();
}

class _ProjectSubTaskPickerPageState
    extends ConsumerState<ProjectSubTaskPickerPage> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  List<ProjectSubTaskPickerItemData> get _filteredTasks {
    return _filterTasks(widget.detail.tasks);
  }

  List<ProjectSubTaskPickerItemData> _filterTasks(
    List<ProjectSubTaskPickerItemData> tasks,
  ) {
    if (_query.isEmpty) return tasks;

    return tasks.where((task) {
      return task.code.toLowerCase().contains(_query) ||
          task.title.toLowerCase().contains(_query);
    }).toList();
  }

  void _toggleTask(ProjectSubTaskPickerItemData task) {
    if (task.alreadyBrokenDown) return;

    ref
        .read(projectBreakdownActionControllerProvider(widget.detail))
        .toggle(task);
  }

  Future<void> _submitBreakdown() async {
    try {
      await ref
          .read(projectBreakdownActionControllerProvider(widget.detail))
          .submit();
      if (mounted) {
        AppToast.success(context, 'Task breakdown berhasil disimpan.');
        context.pop(true);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      projectBreakdownActionControllerProvider(widget.detail),
    );
    if (widget.detail.canLoadFromApi) {
      final optionsState = ref.watch(
        projectBreakdownOptionsProvider(
          ProjectTaskQuery(
            projectId: widget.detail.projectId,
            taskId: widget.detail.taskId,
          ),
        ),
      );

      return optionsState.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: 'Task Breakdown',
                  onBackPressed: () => context.pop(),
                ),
                const Expanded(
                  child: AppSkeletonListView(
                    variant: AppSkeletonListVariant.standard,
                    showSectionHeader: false,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: NetworkAwareErrorView(
              error: error,
              cacheFeatureKey: 'projectCacheRead',
              message: error.toString(),
            ),
          ),
        ),
        data: (options) {
          final tasks = options
              .map(ProjectSubTaskPickerItemData.fromBreakdownOption)
              .toList(growable: false);
          controller.applyApiSelection(tasks);

          return _buildScaffold(_filterTasks(tasks), _submitBreakdown);
        },
      );
    }

    return _buildScaffold(_filteredTasks, null);
  }

  Widget _buildScaffold(
    List<ProjectSubTaskPickerItemData> filteredTasks,
    Future<void> Function()? onSubmit,
  ) {
    final action = ref.watch(
      projectBreakdownActionControllerProvider(widget.detail),
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Task Breakdown',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                children: [
                  ProjectSearchField(controller: _searchController),
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? const EmptyView(message: 'Task tidak ditemukan.')
                        : ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final task in filteredTasks)
                                _TaskBreakdownTile(
                                  task: task,
                                  isSelected:
                                      task.alreadyBrokenDown ||
                                      action.selectedCodes.contains(
                                        task.selectionId,
                                      ),
                                  isDisabled: task.alreadyBrokenDown,
                                  onTap: () => _toggleTask(task),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: _BottomAction(
                isLoading: action.isSubmitting,
                onPressed:
                    onSubmit == null ||
                        action.selectedCodes.isEmpty ||
                        action.isSubmitting
                    ? null
                    : onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBreakdownTile extends StatelessWidget {
  const _TaskBreakdownTile({
    required this.task,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final ProjectSubTaskPickerItemData task;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1,
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${task.code} ${task.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _TaskCheckbox(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.dashboardTeal : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isSelected ? AppColors.dashboardTeal : AppColors.inputBorder,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: AppColors.white, size: 18)
          : null,
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppButton(
        label: isLoading ? 'Menyimpan...' : 'Choose sub task',
        isLoading: isLoading,
        borderRadius: AppRadius.md,
        textStyle: const TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 18,
          height: 1.33,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class ProjectSubTaskPickerData {
  const ProjectSubTaskPickerData({
    this.projectId = '',
    this.taskId = '',
    required this.tasks,
  });

  final String projectId;
  final String taskId;
  final List<ProjectSubTaskPickerItemData> tasks;

  bool get canLoadFromApi => projectId.isNotEmpty && taskId.isNotEmpty;

  factory ProjectSubTaskPickerData.sample({
    String firstCode = 'A.1.1',
    String firstTitle = 'Pekerjaan Civil',
  }) {
    return ProjectSubTaskPickerData(
      tasks: [
        ProjectSubTaskPickerItemData(
          code: firstCode,
          title: firstTitle,
          isSelected: true,
        ),
        const ProjectSubTaskPickerItemData(
          code: 'A.1.2',
          title: 'Pekerjaan Jaringan Gedung',
          isSelected: true,
        ),
        const ProjectSubTaskPickerItemData(
          code: 'A.1.3',
          title: 'Pekerjaan Lainnya',
        ),
      ],
    );
  }

  factory ProjectSubTaskPickerData.fallback() {
    return ProjectSubTaskPickerData.sample();
  }
}

class ProjectSubTaskPickerItemData {
  const ProjectSubTaskPickerItemData({
    this.id = '',
    required this.code,
    required this.title,
    this.isSelected = false,
    this.alreadyBrokenDown = false,
  });

  final String id;
  final String code;
  final String title;
  final bool isSelected;
  final bool alreadyBrokenDown;

  String get selectionId => id.isNotEmpty ? id : code;

  factory ProjectSubTaskPickerItemData.fromBreakdownOption(
    ProjectBreakdownOption option,
  ) {
    return ProjectSubTaskPickerItemData(
      id: option.id,
      code: option.code,
      title: option.title,
      isSelected: option.isSelected,
      alreadyBrokenDown: option.alreadyBrokenDown,
    );
  }
}
