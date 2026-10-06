import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';

class MeetingTaskCard extends StatelessWidget {
  const MeetingTaskCard({required this.task, this.onTap, super.key});

  static const _fontFamily = AppFonts.geist;
  static const _teal = AppColors.dashboardTeal;
  static const _orange = AppColors.orange;
  static const _cardBorderColor = AppColors.taskCardBorder;

  final MeetingMenuTaskData task;
  final Future<void> Function()? onTap;

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
        onTap: onTap == null ? null : () async => onTap!.call(),
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
                  _PersonnelBadge(name: task.assigneeName),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: _cardBorderColor),
              const SizedBox(height: 16),
              Wrap(
                spacing: 18,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ProcessBadge(status: task.status),
                  _ProgressStatus(label: task.taskInfo),
                  _TaskTypeMetric(label: task.type),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeetingMenuTaskData {
  const MeetingMenuTaskData({
    required this.code,
    required this.title,
    required this.assignees,
    required this.assigneeName,
    required this.processCount,
    required this.status,
    required this.type,
    this.taskInfo = '',
  });

  final String code;
  final String title;
  final List<MeetingMenuAssigneeData> assignees;
  final String assigneeName;
  final int processCount;
  final String status;
  final String type;
  final String taskInfo;
}

class MeetingMenuAssigneeData {
  const MeetingMenuAssigneeData({required this.initials, required this.color});

  final String initials;
  final Color color;
}

class _AssigneeStack extends StatelessWidget {
  const _AssigneeStack({required this.assignees});

  final List<MeetingMenuAssigneeData> assignees;

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

  final MeetingMenuAssigneeData assignee;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: assignee.color,
      child: Text(
        assignee.initials,
        style: const TextStyle(
          color: AppColors.white,
          fontFamily: MeetingTaskCard._fontFamily,
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
          fontFamily: MeetingTaskCard._fontFamily,
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
      height: 20,
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: MeetingTaskCard._orange, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 16,
            color: MeetingTaskCard._orange,
          ),
          const SizedBox(width: 6),
          Text(
            status.isNotEmpty ? status : '-',
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: MeetingTaskCard._fontFamily,
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

class _ProgressStatus extends StatelessWidget {
  const _ProgressStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.watch_later_outlined,
          size: 16,
          color: MeetingTaskCard._teal,
        ),
        const SizedBox(width: 6),
        Text(
          label.isEmpty ? '-' : label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: MeetingTaskCard._fontFamily,
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

class _TaskTypeMetric extends StatelessWidget {
  const _TaskTypeMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.layers_outlined,
          size: 16,
          color: MeetingTaskCard._teal,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: MeetingTaskCard._fontFamily,
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
