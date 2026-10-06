import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/controllers/meeting_action_controllers.dart';
import 'package:curva_mobile/shared/forms/form_submit_result.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/project_search_field.dart';

class MeetingAssigneePickerPage extends ConsumerStatefulWidget {
  const MeetingAssigneePickerPage({required this.args, super.key});

  final MeetingAssigneePickerArgs args;

  @override
  ConsumerState<MeetingAssigneePickerPage> createState() =>
      _MeetingAssigneePickerPageState();
}

class _MeetingAssigneePickerPageState
    extends ConsumerState<MeetingAssigneePickerPage> {
  final _searchFocusNode = FocusNode();

  MeetingTaskQuery get _target => MeetingTaskQuery(
    meetingId: widget.args.meetingId,
    taskId: widget.args.taskId,
    isQuality: false,
  );

  @override
  Widget build(BuildContext context) {
    final actionController = ref.watch(
      meetingAssigneeActionControllerProvider(_target),
    );
    final query = MeetingAssigneeQuery(
      meetingId: widget.args.meetingId,
      taskId: widget.args.taskId,
      search: actionController.search,
    );
    final assigneesState = widget.args.canLoadFromApi
        ? ref.watch(meetingAssigneeCandidatesProvider(query))
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(
              title: 'Assignee',
              onBackPressed: () => context.pop(),
              actions: [
                AppHeaderAction(
                  icon: Icons.search,
                  tooltip: 'Cari assignee',
                  onPressed: () =>
                      FocusScope.of(context).requestFocus(_searchFocusNode),
                ),
                AppHeaderAction(
                  icon: Icons.more_vert,
                  tooltip: 'Menu lainnya',
                  onPressed: () =>
                      AppToast.info(context, 'Menu belum tersedia.'),
                ),
              ],
            ),
            ProjectSearchField(
              controller: actionController.searchController,
              focusNode: _searchFocusNode,
              hintText: 'Cari nama...',
            ),
            Expanded(
              child: assigneesState == null
                  ? const EmptyView(message: 'Data task tidak valid.')
                  : assigneesState.when(
                      loading: () => const AppSkeletonListView(
                        variant: AppSkeletonListVariant.compact,
                        showSectionHeader: false,
                        padding: EdgeInsets.zero,
                      ),
                      error: (error, _) => NetworkAwareErrorView(
                        error: error,
                        message: error.toString(),
                        onRetry: () => ref.invalidate(
                          meetingAssigneeCandidatesProvider(query),
                        ),
                      ),
                      data: (values) {
                        final assignees = values
                            .map(_MeetingAssigneeOption.fromReference)
                            .toList(growable: false);
                        if (assignees.isEmpty) {
                          return const EmptyView(
                            message: 'Assignee tidak ditemukan.',
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: assignees.length,
                          itemBuilder: (context, index) => _AssigneeListTile(
                            assignee: assignees[index],
                            onTap: actionController.isSubmitting
                                ? () {}
                                : () => _assign(assignees[index]),
                          ),
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.line,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assign(_MeetingAssigneeOption assignee) async {
    try {
      final result = await ref
          .read(meetingAssigneeActionControllerProvider(_target))
          .assign(assignee.id);
      if (!mounted) return;
      switch (result) {
        case FormSubmitSuccess():
          AppToast.success(context, result.message);
          context.pop(true);
        case FormSubmitInvalid():
          AppToast.warning(context, 'Assignee tidak valid.');
        case FormSubmitIgnored():
      }
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }
}

class _AssigneeListTile extends StatelessWidget {
  const _AssigneeListTile({required this.assignee, required this.onTap});

  final _MeetingAssigneeOption assignee;
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
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
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
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      height: 1.2,
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
  }
}

class _MeetingAssigneeOption {
  const _MeetingAssigneeOption({
    required this.id,
    required this.initials,
    required this.name,
    required this.color,
  });

  final String id;
  final String initials;
  final String name;
  final Color color;

  factory _MeetingAssigneeOption.fromReference(MeetingReference reference) {
    return _MeetingAssigneeOption(
      id: reference.id,
      initials: reference.initials,
      name: reference.name,
      color: _avatarColor(reference.id + reference.name),
    );
  }
}

class MeetingAssigneePickerArgs {
  const MeetingAssigneePickerArgs({this.meetingId = '', this.taskId = ''});

  final String meetingId;
  final String taskId;

  bool get canLoadFromApi => meetingId.isNotEmpty && taskId.isNotEmpty;
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
