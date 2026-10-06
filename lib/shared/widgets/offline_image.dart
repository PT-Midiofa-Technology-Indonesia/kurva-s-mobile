import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/offline_image_providers.dart';
import '../../core/offline_first_providers.dart';
import 'image_preview.dart';

/// Shared disk source for both thumbnails and full-size images.
class OfflineImage extends ConsumerWidget {
  const OfflineImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.cacheWidth,
    this.errorBuilder,
    this.loadingBuilder,
    this.enablePreview = true,
  });

  final bool enablePreview;
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? cacheWidth;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = _buildImage(context, ref);
    if (!enablePreview) return child;
    return ImagePreview(
      previewBuilder: (_) =>
          OfflineImage(url, fit: BoxFit.contain, enablePreview: false),
      child: child,
    );
  }

  Widget _buildError(BuildContext context, Object error, StackTrace? stack) {
    return errorBuilder?.call(context, error, stack) ??
        const Center(
          child: Text(
            'Gambar tidak dapat ditampilkan.',
            textAlign: TextAlign.center,
          ),
        );
  }

  Widget _buildLoading(
    BuildContext context,
    Widget child,
    ImageChunkEvent? progress,
  ) {
    return loadingBuilder?.call(context, child, progress) ??
        (progress == null
            ? child
            : const Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ));
  }

  Widget _buildImage(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(offlineImagesEnabledProvider);
    if (!enabled) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: _buildError,
        loadingBuilder: _buildLoading,
      );
    }
    final offline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    final result = ref.watch(offlineImageFileProvider(url));
    final file = result.isLoading ? null : result.asData?.value;
    if (file != null) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: _buildError,
      );
    }
    if (result.isLoading) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final message = offline
        ? 'Gambar belum tersedia offline. Hubungkan internet untuk mengunduh.'
        : 'Gambar gagal dimuat. Ketuk untuk mencoba lagi.';
    final placeholder = Semantics(
      label: message,
      button: !offline,
      child: Tooltip(
        message: message,
        child: GestureDetector(
          onTap: offline
              ? null
              : () => ref.invalidate(offlineImageFileProvider(url)),
          child: SizedBox(
            width: width,
            height: height,
            child:
                errorBuilder?.call(context, StateError(message), null) ??
                Center(
                  child: enablePreview
                      ? const Icon(Icons.image_not_supported_outlined)
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(message, textAlign: TextAlign.center),
                        ),
                ),
          ),
        ),
      ),
    );
    if (!offline) {
      // A full disk or unsupported cache response must not break online viewing.
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        loadingBuilder: _buildLoading,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    return placeholder;
  }
}
