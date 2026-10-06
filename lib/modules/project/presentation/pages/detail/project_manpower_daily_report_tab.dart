import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/utils/upload_file_picker.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/input_multiline_with_border.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';

typedef ProjectManpowerDailyReportSubmitCallback =
    Future<void> Function({
      required double completedVolume,
      required String note,
      required List<ProjectFileUpload> files,
    });

class ProjectManpowerDailyReportTab extends StatefulWidget {
  const ProjectManpowerDailyReportTab({
    this.onSubmit,
    this.canSubmit = true,
    super.key,
  });

  final ProjectManpowerDailyReportSubmitCallback? onSubmit;
  final bool canSubmit;

  @override
  State<ProjectManpowerDailyReportTab> createState() =>
      _ProjectManpowerDailyReportTabState();
}

class _ProjectManpowerDailyReportTabState
    extends State<ProjectManpowerDailyReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _completedVolumeController = TextEditingController();
  final _noteController = TextEditingController();
  final List<UploadImageItem> _evidence = [];

  final DateTime _reportDate = DateTime.now();
  bool _hasSubmitted = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _completedVolumeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final files = await UploadFilePicker.pick(
      context,
      sourceTitle: 'Pilih sumber bukti',
      dialogTitle: 'Pilih bukti laporan',
      type: FileType.image,
    );
    if (!mounted || files.isEmpty) return;

    setState(() {
      _evidence.addAll(
        files
            .where((file) => file.path != null)
            .map(
              (file) => UploadImageItem(
                name: file.name,
                path: file.path!,
                size: file.size,
              ),
            ),
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _hasSubmitted = true);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _evidence.isEmpty) return;

    final completedVolume = double.parse(
      _completedVolumeController.text.trim().replaceAll(',', '.'),
    );
    final onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      setState(() => _isSubmitting = true);
      try {
        await onSubmit(
          completedVolume: completedVolume,
          note: _noteController.text.trim(),
          files: _evidence
              .map(
                (file) => ProjectFileUpload(name: file.name, path: file.path),
              )
              .toList(growable: false),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    if (!mounted) return;
    AppToast.info(context, 'Laporan disimpan sementara. Belum dikirim ke API.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildDailyReport()),
        if (widget.canSubmit)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: _isSubmitting ? 'Mengajukan...' : 'Ajukan ke QC',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDailyReport() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _FormFieldSection(
            label: 'Tanggal Laporan',
            child: Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.errorBackground,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                formatIndonesianDate(
                  formatDateParam(_reportDate),
                  shortMonth: true,
                ),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          _FormFieldSection(
            label: 'Input Capaian',
            child: TextFormField(
              controller: _completedVolumeController,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.43,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: _inputDecoration(
                hintText: 'Input Capaian',
                suffixText: 'm³',
              ),
              validator: (value) {
                final completedVolume = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (completedVolume == null || completedVolume <= 0) {
                  return 'Masukkan target lebih dari 0';
                }
                return null;
              },
            ),
          ),
          _FormFieldSection(
            label: 'Catatan Kegiatan',
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: FormField<String>(
              initialValue: _noteController.text,
              validator: (_) => _noteController.text.trim().isEmpty
                  ? 'Catatan kegiatan wajib diisi'
                  : null,
              builder: (field) => InputMultilineWithBorder(
                controller: _noteController,
                hintText: 'Tuliskan catatan kegiatan',
                borderColor: AppColors.line,
                errorText: field.errorText,
                onChanged: field.didChange,
              ),
            ),
          ),
          _FormFieldSection(
            label: 'Update bukti',
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UploadImageList(
                  items: _evidence,
                  showEmptyMessage: false,
                  addLabel: '+ Tambah',
                  onAddPressed: _pickEvidence,
                  onRemovePressed: (index) =>
                      setState(() => _evidence.removeAt(index)),
                ),
                if (_hasSubmitted && _evidence.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Bukti laporan wajib ditambahkan',
                      style: TextStyle(
                        color: AppColors.error,
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

class _FormFieldSection extends StatelessWidget {
  const _FormFieldSection({
    required this.label,
    required this.child,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  final String label;
  final Widget child;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text.rich(
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
              fontFamily: AppFonts.inter,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(padding: contentPadding, child: child),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  String? suffixText,
  Color focusedBorderColor = AppColors.dashboardTeal,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: color),
  );

  return InputDecoration(
    hintText: hintText,
    suffixText: suffixText,
    isDense: true,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    hintStyle: const TextStyle(
      color: AppColors.secondaryText,
      fontFamily: AppFonts.inter,
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w400,
    ),
    suffixStyle: const TextStyle(
      color: AppColors.secondaryText,
      fontFamily: AppFonts.inter,
      fontSize: 14,
      height: 1.43,
    ),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(focusedBorderColor),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error),
  );
}
