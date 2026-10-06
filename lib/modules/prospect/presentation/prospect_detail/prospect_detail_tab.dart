import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/image_preview.dart';
import '../../../../shared/widgets/upload_image_list.dart';
import '../../../../shared/utils/upload_file_picker.dart';
import 'prospect_detail_models.dart';
import 'prospect_detail_shared_widgets.dart';

class ProspectDetailTab extends StatelessWidget {
  const ProspectDetailTab({
    required this.detail,
    required this.onUploadDocument,
    required this.onDeleteDocument,
    super.key,
  });

  final ProspectDetailData detail;
  final Future<void> Function(
    ProspectDocumentData document,
    List<PlatformFile> files,
  )
  onUploadDocument;
  final Future<void> Function(
    ProspectDocumentData document,
    ProspectUploadedDocumentData uploadedDocument,
  )
  onDeleteDocument;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _ProspectInfoSection(detail: detail),
        if (detail.documents.isEmpty)
          const _DocumentSection(
            document: ProspectDocumentData(title: 'Dokumen prospect'),
          )
        else
          for (final document in detail.documents)
            _DocumentSection(
              document: document,
              onUploadDocument: onUploadDocument,
              onDeleteDocument: onDeleteDocument,
            ),
      ],
    );
  }
}

class _ProspectInfoSection extends StatelessWidget {
  const _ProspectInfoSection({required this.detail});

  final ProspectDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoField(label: 'Prospek', value: detail.title),
          const SizedBox(height: AppSpacing.lg),
          _InfoField(label: 'Klien', value: detail.client),
          const SizedBox(height: AppSpacing.lg),
          _InfoField(label: 'Nilai proyek', value: detail.projectValue),
          const SizedBox(height: AppSpacing.lg),
          _InfoField(label: 'Periode', value: detail.dateRange),
          const SizedBox(height: AppSpacing.lg),
          _InfoField(label: 'Deskripsi', value: detail.description),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: prospectDetailFontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
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
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.document,
    this.onUploadDocument,
    this.onDeleteDocument,
  });

  final ProspectDocumentData document;
  final Future<void> Function(
    ProspectDocumentData document,
    List<PlatformFile> files,
  )?
  onUploadDocument;
  final Future<void> Function(
    ProspectDocumentData document,
    ProspectUploadedDocumentData uploadedDocument,
  )?
  onDeleteDocument;

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: prospectDetailFontFamily,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (document.isMandatory)
                const Text(
                  'Wajib',
                  style: TextStyle(
                    color: prospectDetailAccentColor,
                    fontFamily: prospectDetailFontFamily,
                    fontSize: 12,
                    height: 1.33,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (document.uploadedDocuments.isEmpty)
            ProspectDetailUploadPlaceholder(
              onAddPressed: onUploadDocument == null
                  ? null
                  : () => _pickAndUpload(context),
            )
          else
            Column(
              children: [
                for (final uploadedDocument in document.uploadedDocuments) ...[
                  _UploadedDocument(
                    document: uploadedDocument,
                    onDelete: onDeleteDocument == null
                        ? null
                        : () => onDeleteDocument!(document, uploadedDocument),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                ProspectDetailUploadPlaceholder(
                  height: 72,
                  showEmptyMessage: false,
                  onAddPressed: onUploadDocument == null
                      ? null
                      : () => _pickAndUpload(context),
                ),
              ],
            ),
          if (_fileTypeSupportText(document.allowedFileTypes)
              case final supportText?) ...[
            const SizedBox(height: AppSpacing.md),
            UploadFileSupportText(text: supportText),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final allowedExtensions = _allowedExtensions(document.allowedFileTypes);
    final selected = await UploadFilePicker.pick(
      context,
      dialogTitle: 'Pilih satu atau lebih dokumen',
      type: FileType.any,
      allowMultiple: true,
      withData: false,
    );
    if (!context.mounted || selected.isEmpty) {
      return;
    }

    final readableFiles = selected
        .where((file) => file.path != null && file.path!.isNotEmpty)
        .toList(growable: false);
    final validFiles = allowedExtensions == null
        ? readableFiles
        : readableFiles
              .where(
                (file) => allowedExtensions.contains(_extension(file.name)),
              )
              .toList(growable: false);

    if (!context.mounted) return;

    if (readableFiles.length != selected.length) {
      AppToast.warning(context, 'Beberapa file tidak dapat dibaca.');
    }
    if (validFiles.length != readableFiles.length) {
      AppToast.warning(
        context,
        'Beberapa file memiliki format yang tidak diizinkan.',
      );
    }
    if (validFiles.isEmpty) return;

    await onUploadDocument?.call(document, validFiles);
  }
}

class _UploadedDocument extends StatelessWidget {
  const _UploadedDocument({required this.document, required this.onDelete});

  final ProspectUploadedDocumentData document;
  final VoidCallback? onDelete;

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
          _DocumentThumbnail(document: document),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              document.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: prospectDetailFontFamily,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _fileSize(document.size),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontFamily: prospectDetailFontFamily,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox.square(
            dimension: 28,
            child: IconButton(
              tooltip: 'Hapus dokumen',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              iconSize: 16,
              alignment: Alignment.center,
              icon: const Icon(Icons.close),
              color: AppColors.ink,
              style: IconButton.styleFrom(
                side: const BorderSide(color: AppColors.line, width: 1.5),
                shape: const CircleBorder(),
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.document});

  final ProspectUploadedDocumentData document;

  @override
  Widget build(BuildContext context) {
    final url = document.url;
    final isImage = _isImageFile(document.name) && url.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 40,
        child: isImage
            ? ImagePreview.network(
                url: url,
                title: document.name,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _DocumentFallbackThumbnail(),
                ),
              )
            : const _DocumentFallbackThumbnail(),
      ),
    );
  }
}

class _DocumentFallbackThumbnail extends StatelessWidget {
  const _DocumentFallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.line,
      alignment: Alignment.center,
      child: const Icon(
        Icons.insert_drive_file_outlined,
        color: AppColors.muted,
        size: 28,
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: child,
    );
  }
}

String _fileSize(int bytes) {
  if (bytes <= 0) {
    return '0 KB';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

List<String>? _allowedExtensions(String allowedFileTypes) {
  final extensions = allowedFileTypes
      .split(',')
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty && value != '*')
      .toList(growable: false);

  return extensions.isEmpty ? null : extensions;
}

String? _fileTypeSupportText(String allowedFileTypes) {
  final extensions = _allowedExtensions(allowedFileTypes);
  if (extensions == null) return null;

  final labels = extensions
      .map((extension) => extension.toUpperCase())
      .join(', ');
  return 'Format yang diizinkan: $labels';
}

String _extension(String fileName) {
  final separatorIndex = fileName.lastIndexOf('.');
  if (separatorIndex < 0 || separatorIndex == fileName.length - 1) {
    return '';
  }

  return fileName.substring(separatorIndex + 1).toLowerCase();
}

bool _isImageFile(String? fileName) {
  final extension = fileName == null ? '' : _extension(fileName);
  return extension == 'jpg' ||
      extension == 'jpeg' ||
      extension == 'png' ||
      extension == 'webp';
}
