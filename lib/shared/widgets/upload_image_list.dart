import 'dart:io';

import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/shared/widgets/offline_image.dart';
import 'package:curva_mobile/shared/widgets/image_preview.dart';

class UploadImageItem {
  const UploadImageItem({
    required this.name,
    required this.path,
    required this.size,
  });

  final String name;
  final String path;
  final int size;
}

class UploadImageList extends StatelessWidget {
  const UploadImageList({
    required this.items,
    this.onAddPressed,
    this.onRemovePressed,
    this.emptyMessage = 'Belum ada data di unggah',
    this.addLabel = '+ Tambah',
    this.removeTooltip = 'Hapus bukti',
    this.supportText,
    this.showEmptyMessage = true,
    this.showAddButton = true,
    super.key,
  });

  final List<UploadImageItem> items;
  final VoidCallback? onAddPressed;
  final ValueChanged<int>? onRemovePressed;
  final String emptyMessage;
  final String addLabel;
  final String removeTooltip;
  final String? supportText;
  final bool showEmptyMessage;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (items.isEmpty) {
      content = _UploadPlaceholder(
        emptyMessage: emptyMessage,
        showEmptyMessage: showEmptyMessage,
        addLabel: addLabel,
        onAddPressed: showAddButton ? onAddPressed : null,
        showAddButton: showAddButton,
      );
    } else {
      content = Column(
        children: [
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _UploadedImageTile(
                item: entry.value,
                removeTooltip: removeTooltip,
                onRemove: onRemovePressed == null
                    ? null
                    : () => onRemovePressed!(entry.key),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (showAddButton && onAddPressed != null)
            _UploadPlaceholder(
              height: 72,
              showEmptyMessage: false,
              addLabel: addLabel,
              onAddPressed: onAddPressed,
            ),
        ],
      );
    }

    final hint = supportText?.trim();
    if (hint == null || hint.isEmpty) return content;

    return Column(
      children: [
        content,
        const SizedBox(height: AppSpacing.md),
        UploadFileSupportText(text: hint),
      ],
    );
  }
}

class UploadFileSupportText extends StatelessWidget {
  const UploadFileSupportText({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.inputBorder,
        fontFamily: AppFonts.inter,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}

class _UploadedImageTile extends StatelessWidget {
  const _UploadedImageTile({
    required this.item,
    required this.removeTooltip,
    this.onRemove,
  });

  final UploadImageItem item;
  final String removeTooltip;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _ImageThumbnail(path: item.path),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _fileSize(item.size),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontFamily: AppFonts.inter,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox.square(
              dimension: 28,
              child: IconButton(
                tooltip: removeTooltip,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                iconSize: 16,
                alignment: Alignment.center,
                icon: const Icon(Icons.close),
                color: AppColors.ink,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.line, width: 1.5),
                  shape: const CircleBorder(),
                ),
                onPressed: onRemove,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(path);
    final isNetworkImage = uri?.scheme == 'http' || uri?.scheme == 'https';
    final localPath = uri != null && uri.scheme == 'file'
        ? uri.toFilePath()
        : path;
    final cacheSize = (40 * MediaQuery.devicePixelRatioOf(context)).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 40,
        child: isNetworkImage
            ? OfflineImage(
                path,
                cacheWidth: cacheSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _FallbackThumbnail(),
              )
            : ImagePreview.file(
                path: localPath,
                child: Image.file(
                  File(localPath),
                  cacheWidth: cacheSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _FallbackThumbnail(),
                ),
              ),
      ),
    );
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.line,
      alignment: Alignment.center,
      child: const Icon(
        Icons.insert_photo_outlined,
        color: AppColors.muted,
        size: 28,
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({
    required this.addLabel,
    this.height = 80,
    this.showEmptyMessage = true,
    this.emptyMessage,
    this.onAddPressed,
    this.showAddButton = true,
  });

  final double height;
  final bool showEmptyMessage;
  final String? emptyMessage;
  final String addLabel;
  final VoidCallback? onAddPressed;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedBorderPainter(),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showEmptyMessage) ...[
              Text(
                emptyMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (showAddButton)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.dashboardTeal,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                onPressed: onAddPressed,
                child: Text(
                  addLabel,
                  style: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inputBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + 6;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

String _fileSize(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
