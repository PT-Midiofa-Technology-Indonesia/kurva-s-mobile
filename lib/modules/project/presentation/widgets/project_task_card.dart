import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';
import 'project_target_icon.dart';

class ProjectTaskCard extends StatelessWidget {
  const ProjectTaskCard({required this.task, this.onTap, super.key});

  static const _fontFamily = AppFonts.geist;
  static const _teal = AppColors.dashboardTeal;
  static const _orange = AppColors.orange;
  static const _cardBorderColor = AppColors.taskCardBorder;

  final ProjectMenuTaskData task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: _cardBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${task.code}  ${task.title}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: _fontFamily,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  task.assignees.isEmpty
                      ? const _UnassignedAvatar()
                      : _AssigneeStack(assignees: task.assignees),
                  const SizedBox(width: 14),
                  _PersonnelBadge(
                    name: task.assignees.length > 1
                        ? '${task.assignees.length} Personil'
                        : task.assigneeName,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: _cardBorderColor),
              const SizedBox(height: 16),
              if (task.isQualityProject)
                _QualityProjectMetrics(task: task)
              else
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ProcessBadge(status: task.status),
                    if (task.childCount > 0)
                      _ChildCount(count: task.childCount)
                    else ...[
                      _TaskProgressMetric(label: task.progress),
                      _LastUpdatedMetric(label: task.lastUpdatedDate),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectMenuTaskData {
  const ProjectMenuTaskData({
    required this.code,
    required this.title,
    required this.assignees,
    required this.assigneeName,
    required this.childCount,
    required this.status,
    required this.type,
    this.taskInfo = 'Dalam Proses',
    this.progress = '0/10 m³',
    this.lastUpdatedDate = '19 Sep 2026',
    this.manpowerName = '-',
    this.target = '-',
    this.note = '-',
    this.retryCount = 0,
  });

  final String code;
  final String title;
  final List<ProjectMenuAssigneeData> assignees;
  final String assigneeName;
  final int childCount;
  final String status;
  final String type;
  final String taskInfo;
  final String progress;
  final String lastUpdatedDate;
  final String manpowerName;
  final String target;
  final String note;
  final int retryCount;

  bool get isQualityProject => type == 'Quality Project';
}

class _QualityProjectMetrics extends StatelessWidget {
  const _QualityProjectMetrics({required this.task});

  final ProjectMenuTaskData task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ProcessBadge(status: task.status),
            _QualityMetric(
              icon: const Icon(
                Icons.account_circle_outlined,
                size: 18,
                color: ProjectTaskCard._teal,
              ),
              label: task.manpowerName,
            ),
            _QualityMetric(
              icon: const ProjectTargetIcon(key: Key('qc-target-icon')),
              label: task.target,
            ),
            _QualityMetric(
              icon: const Icon(
                Icons.sync,
                size: 18,
                color: ProjectTaskCard._teal,
              ),
              label: '${task.retryCount}x',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _QualityMetric(
            icon: const Icon(
              Icons.description_outlined,
              size: 18,
              color: ProjectTaskCard._teal,
            ),
            label: task.note,
          ),
        ),
      ],
    );
  }
}

class _QualityMetric extends StatelessWidget {
  const _QualityMetric({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label.isEmpty ? '-' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: ProjectTaskCard._fontFamily,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class ProjectMenuAssigneeData {
  const ProjectMenuAssigneeData({required this.initials, required this.color});

  final String initials;
  final Color color;
}

class _AssigneeStack extends StatelessWidget {
  const _AssigneeStack({required this.assignees});

  final List<ProjectMenuAssigneeData> assignees;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40 + ((assignees.length - 1).clamp(0, 8) * 28),
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < assignees.length; index++)
            Positioned(
              left: index * 28,
              child: _AssigneeAvatar(assignee: assignees[index]),
            ),
        ],
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({required this.assignee});

  final ProjectMenuAssigneeData assignee;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: assignee.color,
      child: Text(
        assignee.initials,
        style: const TextStyle(
          color: AppColors.white,
          fontFamily: ProjectTaskCard._fontFamily,
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _UnassignedAvatar extends StatelessWidget {
  const _UnassignedAvatar();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.avatarPlaceholder,
      child: Icon(
        Icons.person,
        color: AppColors.avatarPlaceholderIcon,
        size: 28,
      ),
    );
  }
}

class _PersonnelBadge extends StatelessWidget {
  const _PersonnelBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softLine, width: 1.5),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: ProjectTaskCard._fontFamily,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ProcessBadge extends StatelessWidget {
  const _ProcessBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('task-status-badge'),
      height: 20,
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: ProjectTaskCard._orange, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 16,
            color: ProjectTaskCard._orange,
          ),
          SizedBox(width: 6),
          Text(
            status.isNotEmpty ? status : '-',
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: ProjectTaskCard._fontFamily,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildCount extends StatelessWidget {
  const _ChildCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_tree_outlined,
          size: 16,
          color: ProjectTaskCard._teal,
        ),
        const SizedBox(width: 8),
        Container(
          height: 20,
          width: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.softLine, width: 1.5),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: ProjectTaskCard._fontFamily,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskProgressMetric extends StatelessWidget {
  const _TaskProgressMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ProjectTargetIcon(key: Key('task-progress-target-icon')),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: ProjectTaskCard._fontFamily,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LastUpdatedMetric extends StatelessWidget {
  const _LastUpdatedMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_month_outlined,
          size: 18,
          color: ProjectTaskCard._teal,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: ProjectTaskCard._fontFamily,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
