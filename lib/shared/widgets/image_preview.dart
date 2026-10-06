import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Opens the full-resolution source without reusing the thumbnail's decode size.
class ImagePreview extends StatelessWidget {
  const ImagePreview({
    required this.child,
    required this.previewBuilder,
    this.title = 'Pratinjau gambar',
    super.key,
  });

  factory ImagePreview.file({
    required String path,
    required Widget child,
    String title = 'Pratinjau gambar',
  }) => ImagePreview(
    title: title,
    previewBuilder: (_) =>
        Image.file(File(path), fit: BoxFit.contain, errorBuilder: _imageError),
    child: child,
  );

  factory ImagePreview.network({
    required String url,
    required Widget child,
    String title = 'Pratinjau gambar',
  }) => ImagePreview(
    title: title,
    previewBuilder: (_) => Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: _imageError,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
    ),
    child: child,
  );

  final Widget child;
  final WidgetBuilder previewBuilder;
  final String title;

  static Widget _imageError(
    BuildContext context,
    Object error,
    StackTrace? stack,
  ) => const Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Text(
      'Gambar tidak dapat ditampilkan.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.white),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Buka pratinjau gambar',
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) =>
            _ImagePreviewDialog(title: title, imageBuilder: previewBuilder),
      ),
      child: child,
    ),
  );
}

class _ImagePreviewDialog extends StatefulWidget {
  const _ImagePreviewDialog({required this.title, required this.imageBuilder});

  final String title;
  final WidgetBuilder imageBuilder;

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  final _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Reset ukuran',
            icon: const Icon(Icons.fit_screen),
            onPressed: () => _transformation.value = Matrix4.identity(),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ColoredBox(
        color: AppColors.black,
        child: InteractiveViewer(
          transformationController: _transformation,
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: Center(child: widget.imageBuilder(context)),
          ),
        ),
      ),
    ),
  );
}
