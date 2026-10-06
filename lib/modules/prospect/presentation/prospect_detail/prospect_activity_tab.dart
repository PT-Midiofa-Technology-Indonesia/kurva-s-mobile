import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/input_multiline_with_border.dart';
import '../../../../shared/widgets/upload_image_list.dart';
import '../../../../shared/utils/upload_file_picker.dart';
import 'prospect_detail_models.dart';
import 'prospect_detail_shared_widgets.dart';

class ProspectActivityTab extends StatefulWidget {
  const ProspectActivityTab({
    required this.detail,
    required this.onSaveActivity,
    super.key,
  });

  final ProspectDetailData detail;
  final Future<void> Function(
    String description,
    List<PlatformFile> files,
    List<StageDocumentData> deletedDocuments,
  )
  onSaveActivity;

  @override
  State<ProspectActivityTab> createState() => _ProspectActivityTabState();
}

class _ProspectActivityTabState extends State<ProspectActivityTab> {
  static const _maxFileSize = 5 * 1024 * 1024;

  late final TextEditingController _descriptionController;
  final List<PlatformFile> _selectedFiles = [];
  final List<StageDocumentData> _deletedDocuments = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.detail.activityDescription ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ProspectActivityTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextDescription = widget.detail.activityDescription ?? '';
    if (oldWidget.detail.activityDescription != nextDescription &&
        _descriptionController.text != nextDescription) {
      _descriptionController.text = nextDescription;
    }

    final currentDocumentIds = widget.detail.activityDocuments
        .map((document) => document.id)
        .toSet();
    _deletedDocuments.removeWhere(
      (document) => !currentDocumentIds.contains(document.id),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSaveActivity(
        description,
        List.unmodifiable(_selectedFiles),
        List.unmodifiable(_deletedDocuments),
      );
      if (mounted) {
        setState(() {
          _selectedFiles.clear();
          _deletedDocuments.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActivityDescriptionField(controller: _descriptionController),
                _ActivityAttachmentSection(
                  documents: _visibleActivityDocuments,
                  selectedFiles: _selectedFiles,
                  onAddFiles: _addFiles,
                  onRemoveSelectedFile: _removeSelectedFile,
                  onDeleteDocument: _markDocumentForDeletion,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white),
            child: AppButton(
              label: _isSaving ? 'Menyimpan...' : 'Simpan',
              isLoading: _isSaving,
              backgroundColor: prospectDetailAccentColor,
              elevation: 4,
              shadowColor: AppColors.softShadow,
              textStyle: const TextStyle(
                fontFamily: prospectDetailFontFamily,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              onPressed: _isSaving ? null : _save,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addFiles() async {
    const maxFiles = _ActivityAttachmentSection.maxFiles;
    final remainingSlots =
        maxFiles - _visibleActivityDocuments.length - _selectedFiles.length;
    if (remainingSlots <= 0) {
      return;
    }

    final selected = await UploadFilePicker.pick(
      context,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
      allowMultiple: true,
      withData: false,
    );
    if (!mounted || selected.isEmpty) {
      return;
    }

    final readableFiles = selected.where(
      (file) => file.path != null && file.path!.isNotEmpty,
    );
    final validFiles = readableFiles
        .where((file) => file.size <= _maxFileSize)
        .take(remainingSlots)
        .toList(growable: false);
    final hasInvalidSize = selected.any((file) => file.size > _maxFileSize);
    final hasUnreadableFile = selected.any(
      (file) => file.path == null || file.path!.isEmpty,
    );

    if (hasInvalidSize) {
      AppToast.warning(context, 'Ukuran file maksimal 5 MB.');
    }
    if (hasUnreadableFile) {
      AppToast.warning(context, 'Beberapa file tidak dapat dibaca.');
    }

    if (validFiles.isEmpty) {
      return;
    }

    setState(() {
      _selectedFiles.addAll(validFiles);
    });
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  List<StageDocumentData> get _visibleActivityDocuments {
    final deletedIds = _deletedDocuments.map((document) => document.id).toSet();
    return [
      for (final document in widget.detail.activityDocuments)
        if (!deletedIds.contains(document.id)) document,
    ];
  }

  void _markDocumentForDeletion(StageDocumentData document) {
    if (document.id.isEmpty) {
      return;
    }

    setState(() {
      _deletedDocuments.add(document);
    });
  }
}

class _ActivityDescriptionField extends StatelessWidget {
  const _ActivityDescriptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _ActivitySection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RequiredFieldLabel(label: 'Detail aktivitas'),
          const SizedBox(height: AppSpacing.sm),
          InputMultilineWithBorder(
            controller: controller,
            hintText: 'Masukkan deskripsi...',
          ),
        ],
      ),
    );
  }
}

class _ActivityAttachmentSection extends StatelessWidget {
  const _ActivityAttachmentSection({
    required this.documents,
    required this.selectedFiles,
    required this.onAddFiles,
    required this.onRemoveSelectedFile,
    required this.onDeleteDocument,
  });

  static const maxFiles = 5;

  final List<StageDocumentData> documents;
  final List<PlatformFile> selectedFiles;
  final VoidCallback onAddFiles;
  final ValueChanged<int> onRemoveSelectedFile;
  final ValueChanged<StageDocumentData> onDeleteDocument;

  @override
  Widget build(BuildContext context) {
    final totalFiles = documents.length + selectedFiles.length;
    final canAddMore = totalFiles < maxFiles;
    final attachmentItems = [
      for (final document in documents)
        UploadImageItem(
          name: document.name,
          path: document.fileUrl ?? '',
          size: document.sizeBytes,
        ),
      for (final file in selectedFiles)
        UploadImageItem(name: file.name, path: file.path!, size: file.size),
    ];

    return _ActivitySection(
      verticalPadding: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(label: 'Lampiran'),
          const SizedBox(height: AppSpacing.md),
          UploadImageList(
            items: attachmentItems,
            emptyMessage: 'Belum ada lampiran diunggah',
            addLabel: '+ Tambah',
            removeTooltip: 'Hapus lampiran',
            supportText:
                'Format yang diizinkan: IMAGE/*, PDF, DOC, DOCX, XLS, XLSX\n'
                'Maksimal 5 file, masing-masing hingga 5 MB',
            onAddPressed: canAddMore ? onAddFiles : null,
            onRemovePressed: (index) {
              if (index < documents.length) {
                onDeleteDocument(documents[index]);
                return;
              }

              onRemoveSelectedFile(index - documents.length);
            },
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.child,
    this.verticalPadding = AppSpacing.sm + AppSpacing.xs,
  });

  final Widget child;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: verticalPadding,
      ),
      decoration: const BoxDecoration(color: AppColors.white),
      child: child,
    );
  }
}

class _RequiredFieldLabel extends StatelessWidget {
  const _RequiredFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: AppColors.error),
          ),
        ],
      ),
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: prospectDetailSupportFontFamily,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: prospectDetailSupportFontFamily,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}
