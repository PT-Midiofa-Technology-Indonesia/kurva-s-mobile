import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/project_search_field.dart';

class ProjectManpowerAssignee {
  const ProjectManpowerAssignee({
    required this.id,
    required this.initials,
    required this.name,
    required this.color,
  });

  final String id;
  final String initials;
  final String name;
  final Color color;

  factory ProjectManpowerAssignee.fromReference(ProjectReference reference) {
    return ProjectManpowerAssignee(
      id: reference.id,
      initials: reference.initials,
      name: reference.name,
      color: _avatarColor(reference.id + reference.name),
    );
  }
}

class ProjectManpowerAssigneePickerPage extends ConsumerStatefulWidget {
  const ProjectManpowerAssigneePickerPage({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<ProjectManpowerAssigneePickerPage> createState() =>
      _ProjectManpowerAssigneePickerPageState();
}

class _ProjectManpowerAssigneePickerPageState
    extends ConsumerState<ProjectManpowerAssigneePickerPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final assigneesState = ref.watch(
      projectSubordinatesProvider(widget.projectId),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Add Manpower',
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            ProjectSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              height: 88,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              onChanged: (value) => setState(() => _query = value),
            ),
            Expanded(
              child: assigneesState.when(
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
                    projectSubordinatesProvider(widget.projectId),
                  ),
                ),
                data: (subordinates) {
                  final assignees = subordinates
                      .map(ProjectManpowerAssignee.fromReference)
                      .where(
                        (assignee) =>
                            assignee.name.toLowerCase().contains(query),
                      )
                      .toList(growable: false);
                  if (assignees.isEmpty) {
                    return const EmptyView(
                      message: 'Manpower tidak ditemukan.',
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: assignees.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.line,
                    ),
                    itemBuilder: (context, index) {
                      final assignee = assignees[index];
                      return Material(
                        color: AppColors.white,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(assignee),
                          child: SizedBox(
                            height: 64,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: assignee.color,
                                    child: Text(
                                      assignee.initials,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontFamily: AppFonts.inter,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      assignee.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontFamily: AppFonts.inter,
                                        fontSize: 16,
                                        height: 1.25,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
