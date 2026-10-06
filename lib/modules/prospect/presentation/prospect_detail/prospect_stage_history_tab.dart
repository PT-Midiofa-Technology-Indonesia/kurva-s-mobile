import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import 'prospect_detail_models.dart';
import 'prospect_detail_shared_widgets.dart';

class ProspectStageHistoryTab extends StatefulWidget {
  const ProspectStageHistoryTab({required this.history, super.key});

  final List<StageHistoryData> history;

  @override
  State<ProspectStageHistoryTab> createState() =>
      _ProspectStageHistoryTabState();
}

class _ProspectStageHistoryTabState extends State<ProspectStageHistoryTab> {
  late List<bool> _expandedItems;

  @override
  void initState() {
    super.initState();
    _expandedItems = List<bool>.filled(widget.history.length, true);
  }

  @override
  void didUpdateWidget(covariant ProspectStageHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.history.length == widget.history.length) return;

    _expandedItems = List<bool>.generate(
      widget.history.length,
      (index) => index < _expandedItems.length ? _expandedItems[index] : true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        const SizedBox(
          height: 52,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Detail Stage',
                style: TextStyle(
                  color: AppColors.ink,
                  fontFamily: prospectDetailSupportFontFamily,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        if (widget.history.isEmpty)
          const ProspectDetailEmptyTab(label: 'Belum ada riwayat stage')
        else
          for (var index = 0; index < widget.history.length; index++)
            _StageTimelineItem(
              item: widget.history[index],
              isExpanded: _expandedItems[index],
              isLast: index == widget.history.length - 1,
              onToggle: () {
                setState(() {
                  _expandedItems[index] = !_expandedItems[index];
                });
              },
            ),
      ],
    );
  }
}

class _StageTimelineItem extends StatelessWidget {
  const _StageTimelineItem({
    required this.item,
    required this.isExpanded,
    required this.isLast,
    required this.onToggle,
  });

  final StageHistoryData item;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onToggle;

  static const _trackWidth = 32.0;
  static const _headerHeight = 52.0;
  static const _markerCenterY = 26.0;

  @override
  Widget build(BuildContext context) {
    final muted = item.isCurrent ? AppColors.ink : AppColors.inputBorder;

    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _trackWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast)
                    const Positioned(
                      top: _markerCenterY,
                      bottom: -_markerCenterY,
                      child: _StageTimelineLine(),
                    ),
                  Positioned(
                    top: _markerCenterY,
                    child: _StageMarker(isCurrent: item.isCurrent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: onToggle,
                      child: SizedBox(
                        height: _headerHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.stage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: muted,
                                  fontFamily: prospectDetailFontFamily,
                                  fontSize: 14,
                                  height: 1.43,
                                  fontWeight: item.isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              item.date,
                              style: TextStyle(
                                color: item.isCurrent
                                    ? AppColors.ink
                                    : AppColors.inputBorder,
                                fontFamily: prospectDetailSupportFontFamily,
                                fontSize: 12,
                                height: 1.33,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: item.isCurrent
                                  ? AppColors.ink
                                  : AppColors.inputBorder,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : AppSpacing.sm,
                      ),
                      child: _StageRecords(item: item),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on StageHistoryData {
  bool get hasRecords =>
      documents.isNotEmpty ||
      activityDocuments.isNotEmpty ||
      activity != null ||
      image != null;
}

class _StageTimelineLine extends StatelessWidget {
  const _StageTimelineLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      decoration: const BoxDecoration(color: AppColors.line),
    );
  }
}

class _StageMarker extends StatelessWidget {
  const _StageMarker({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (!isCurrent) {
      return Container(
        width: 8,
        height: 8,
        transform: Matrix4.translationValues(0, -4, 0),
        decoration: const BoxDecoration(
          color: prospectDetailAccentColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      width: 16,
      height: 16,
      transform: Matrix4.translationValues(0, -8, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: prospectDetailAccentColor, width: 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: prospectDetailAccentColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StageRecords extends StatelessWidget {
  const _StageRecords({required this.item});

  final StageHistoryData item;

  @override
  Widget build(BuildContext context) {
    if (!item.hasRecords) {
      return const _EmptyStageRecord();
    }

    return Column(
      spacing: AppSpacing.sm,
      children: [
        for (final document in item.documents)
          _StageFileCard(document: document),
        if (item.activity != null) _StageActivityCard(activity: item.activity!),
        for (final document in item.activityDocuments)
          _StageFileCard(document: document),
        if (item.image != null) _StageFileCard(document: item.image!),
      ],
    );
  }
}

class _EmptyStageRecord extends StatelessWidget {
  const _EmptyStageRecord();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const ProspectDetailDashedBorderPainter(
        color: AppColors.inputBorder,
        radius: AppRadius.md,
      ),
      child: const SizedBox(
        width: double.infinity,
        height: 76,
        child: Center(
          child: Text(
            'Belum ada stage record',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontFamily: prospectDetailFontFamily,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StageFileCard extends StatelessWidget {
  const _StageFileCard({required this.document});

  final StageDocumentData document;

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = document.thumbnailPath;

    return Container(
      constraints: BoxConstraints(minHeight: thumbnailPath == null ? 52 : 60),
      padding: EdgeInsets.fromLTRB(
        thumbnailPath == null ? AppSpacing.md : AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.softLine),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          if (thumbnailPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                thumbnailPath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: prospectDetailFontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            document.size,
            style: const TextStyle(
              color: AppColors.inputBorder,
              fontFamily: prospectDetailSupportFontFamily,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageActivityCard extends StatelessWidget {
  const _StageActivityCard({required this.activity});

  final String activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.softLine),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas',
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: prospectDetailSupportFontFamily,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            activity,
            style: const TextStyle(
              color: AppColors.muted,
              fontFamily: prospectDetailFontFamily,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
