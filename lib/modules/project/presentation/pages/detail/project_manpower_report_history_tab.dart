import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/offline_image.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';

class ProjectManpowerReportHistoryTab extends ConsumerStatefulWidget {
  const ProjectManpowerReportHistoryTab({
    required this.manpowerName,
    this.projectId = '',
    this.manpowerTaskId = '',
    super.key,
  });

  final String manpowerName;
  final String projectId;
  final String manpowerTaskId;

  @override
  ConsumerState<ProjectManpowerReportHistoryTab> createState() =>
      _ProjectManpowerReportHistoryTabState();
}

class _ProjectManpowerReportHistoryTabState
    extends ConsumerState<ProjectManpowerReportHistoryTab> {
  final Set<String> _collapsedEntries = {};

  ProjectTaskQuery get _query => ProjectTaskQuery(
    projectId: widget.projectId,
    taskId: widget.manpowerTaskId,
  );

  void _invalidateHistoryStatus() {
    ref.invalidate(
      projectManpowerHistoryHasUnreadProvider((
        projectId: widget.projectId,
        manpowerTaskId: widget.manpowerTaskId,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projectId.isEmpty || widget.manpowerTaskId.isEmpty) {
      return const EmptyView(
        title: 'Riwayat Belum Tersedia',
        message: 'Project atau task untuk laporan ini tidak ditemukan.',
      );
    }

    final historyState = ref.watch(projectTaskHistoryProvider(_query));
    return historyState.when(
      loading: () => const _HistorySkeleton(),
      error: (error, stackTrace) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'projectCacheRead',
        message: error is AppException ? error.message : error.toString(),
        onRetry: () {
          _invalidateHistoryStatus();
          ref.invalidate(projectTaskHistoryProvider(_query));
        },
      ),
      data: _buildHistory,
    );
  }

  Widget _buildHistory(List<ProjectTaskHistoryEntry> entries) {
    if (entries.isEmpty) {
      return const EmptyView(
        message: 'Belum ada aktivitas laporan untuk task ini.',
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _invalidateHistoryStatus();
        return ref.refresh(projectTaskHistoryProvider(_query).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
        children: [
          const SizedBox(
            height: 52,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Laporan',
                style: TextStyle(
                  color: AppColors.ink,
                  fontFamily: AppFonts.geist,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          for (var index = 0; index < entries.length; index++)
            _HistoryItem(
              entry: entries[index],
              manpowerName: widget.manpowerName,
              isCurrent: index == 0,
              isLast: index == entries.length - 1,
              expanded: !_collapsedEntries.contains(
                _entryKey(entries[index], index),
              ),
              onToggle: () => setState(() {
                final key = _entryKey(entries[index], index);
                if (!_collapsedEntries.add(key)) {
                  _collapsedEntries.remove(key);
                }
              }),
            ),
        ],
      ),
    );
  }

  String _entryKey(ProjectTaskHistoryEntry entry, int index) =>
      '${entry.projectTaskId}:${entry.recordedAt}:$index';
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      semanticLabel: 'Memuat riwayat laporan',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
        children: [
          const SizedBox(
            height: 52,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppSkeletonBox(width: 128, height: 16),
            ),
          ),
          for (var index = 0; index < 3; index++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 40,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        if (index < 2)
                          const Positioned(
                            top: 26,
                            bottom: -26,
                            child: AppSkeletonBox(width: 1, height: 0),
                          ),
                        Positioned(
                          top: index == 0 ? 18 : 22,
                          child: AppSkeletonBox(
                            width: index == 0 ? 16 : 8,
                            height: index == 0 ? 16 : 8,
                            borderRadius: AppRadius.xl,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 52,
                          child: Row(
                            children: [
                              Expanded(child: AppSkeletonBox(height: 16)),
                              SizedBox(width: AppSpacing.md),
                              AppSkeletonBox(width: 72, height: 12),
                              SizedBox(width: AppSpacing.sm),
                              AppSkeletonBox(width: 24, height: 24),
                            ],
                          ),
                        ),
                        _RecordCard(
                          minHeight: 52,
                          child: AppSkeletonBox(width: 120, height: 16),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _RecordCard(
                          minHeight: 76,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSkeletonBox(width: 144, height: 16),
                              SizedBox(height: AppSpacing.sm),
                              AppSkeletonBox(height: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.entry,
    required this.manpowerName,
    required this.isCurrent,
    required this.isLast,
    required this.expanded,
    required this.onToggle,
  });

  final ProjectTaskHistoryEntry entry;
  final String manpowerName;
  final bool isCurrent;
  final bool isLast;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final markerColor = _isRejectedEvent(entry)
        ? AppColors.error
        : AppColors.dashboardTeal;
    final title = entry.eventLabel.isNotEmpty ? entry.eventLabel : entry.event;
    final actorName = entry.actor.name.isNotEmpty
        ? entry.actor.name
        : manpowerName;
    final hasVolume =
        entry.completedVolume != null || entry.targetVolume != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (!isLast)
                  const Positioned(
                    top: 26,
                    bottom: -26,
                    child: ColoredBox(
                      color: AppColors.line,
                      child: SizedBox(width: 1),
                    ),
                  ),
                Positioned(
                  top: isCurrent ? 18 : 22,
                  child: Container(
                    width: isCurrent ? 16 : 8,
                    height: isCurrent ? 16 : 8,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.white : markerColor,
                      shape: BoxShape.circle,
                      border: isCurrent ? Border.all(color: markerColor) : null,
                    ),
                    alignment: Alignment.center,
                    child: isCurrent
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: expanded,
                  child: InkWell(
                    onTap: onToggle,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.isEmpty ? '-' : title,
                              style: _bodyStyle.copyWith(
                                color: isCurrent
                                    ? AppColors.ink
                                    : AppColors.secondaryText,
                                fontWeight: isCurrent
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatIndonesianDate(
                              entry.recordedAt,
                              shortMonth: true,
                            ),
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.ink
                                  : AppColors.inputBorder,
                              fontFamily: AppFonts.geist,
                              fontSize: 12,
                              height: 1.33,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.ink,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (expanded) ...[
                  _RecordCard(
                    minHeight: 52,
                    child: Text(actorName, style: _bodyStyle),
                  ),
                  if (hasVolume) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _RecordCard(
                      minHeight: 76,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kuantitas Diselesaikan',
                            style: _bodyStyle.copyWith(
                              fontFamily: AppFonts.geist,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _volumeDescription(entry),
                            style: _bodyStyle.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _RecordCard(
                    minHeight: 76,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Kegiatan',
                          style: _bodyStyle.copyWith(
                            fontFamily: AppFonts.geist,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          entry.note.isEmpty ? '-' : entry.note,
                          style: _bodyStyle.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  for (final document in entry.documents) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _DocumentCard(document: document),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final ProjectTaskHistoryDocument document;

  @override
  Widget build(BuildContext context) {
    return _RecordCard(
      minHeight: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox.square(
              dimension: 40,
              child: document.url.isEmpty
                  ? const _DocumentPlaceholder()
                  : OfflineImage(
                      document.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _DocumentPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              document.fileName.isEmpty ? '-' : document.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            document.formattedFileSize,
            style: const TextStyle(
              color: AppColors.inputBorder,
              fontFamily: AppFonts.geist,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.line,
      child: Icon(
        Icons.insert_photo_outlined,
        color: AppColors.muted,
        size: 26,
      ),
    );
  }
}

bool _isRejectedEvent(ProjectTaskHistoryEntry entry) {
  final event = entry.event.toLowerCase();
  final decision = entry.decision?.value.toLowerCase() ?? '';
  return event.contains('fail') ||
      event.contains('reject') ||
      event.contains('revision') ||
      decision == 'fail' ||
      decision == 'failed' ||
      decision == 'reject' ||
      decision == 'rejected';
}

String _volumeDescription(ProjectTaskHistoryEntry entry) {
  final completed = _formatVolume(entry.completedVolume);
  final target = _formatVolume(entry.targetVolume);
  final unit = entry.uom.trim();
  final unitSuffix = unit.isEmpty ? '' : ' $unit';

  if (entry.targetVolume == null) return '$completed$unitSuffix';
  return '$completed$unitSuffix dari target $target$unitSuffix';
}

String _formatVolume(double? value) {
  if (value == null) return '-';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

const _bodyStyle = TextStyle(
  color: AppColors.ink,
  fontFamily: AppFonts.inter,
  fontSize: 14,
  height: 1.43,
  fontWeight: FontWeight.w400,
);

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.child,
    required this.minHeight,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final double minHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.softLine),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}
