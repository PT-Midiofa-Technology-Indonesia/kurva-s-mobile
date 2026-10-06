import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/input_multiline_text_field.dart';
import '../../../shared/widgets/input_picker_field.dart';
import '../../../shared/widgets/input_single_line_text_field.dart';
import '../../../shared/widgets/searchable_selection_bottom_sheet.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../data/models/prospect_models.dart';
import '../prospect_providers.dart';
import 'prospect_create_controller.dart';

class ProspectCreatePage extends ConsumerStatefulWidget {
  const ProspectCreatePage({super.key});

  static const _fontFamily = AppFonts.inter;

  @override
  ConsumerState<ProspectCreatePage> createState() => _ProspectCreatePageState();
}

class _ProspectCreatePageState extends ConsumerState<ProspectCreatePage> {
  final _titleKey = GlobalKey();
  final _clientKey = GlobalKey();
  final _projectTypeKey = GlobalKey();
  final _estimatedValueKey = GlobalKey();
  final _startPeriodKey = GlobalKey();
  final _endPeriodKey = GlobalKey();
  final _tenderDeadlineKey = GlobalKey();

  ProspectCreateController get _form =>
      ref.read(prospectCreateControllerProvider);

  Future<void> _pickStartPeriod() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _form.startPeriod ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _form.setStartPeriod(pickedDate);
  }

  Future<void> _pickEndPeriod() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _form.endPeriod ?? _form.startPeriod ?? DateTime.now(),
      firstDate: _form.startPeriod ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _form.setEndPeriod(pickedDate);
  }

  Future<void> _pickProjectType() async {
    final projectTypesState = ref.read(prospectProjectTypesProvider);
    final projectTypes =
        projectTypesState.valueOrNull
            ?.where((type) => type.isActive)
            .toList() ??
        const <ProspectProjectType>[];

    if (projectTypes.isEmpty) {
      AppToast.info(
        context,
        projectTypesState.isLoading
            ? 'Daftar tipe proyek sedang dimuat.'
            : _errorMessage(
                projectTypesState.error ?? 'Daftar tipe proyek belum tersedia.',
              ),
      );
      return;
    }

    final selectedProjectType =
        await SearchableSelectionBottomSheet.show<ProspectProjectType>(
          context,
          title: 'Pilih Tipe Proyek',
          options: projectTypes,
          selectedOption: _form.selectedProjectType,
          labelBuilder: _form.projectTypeLabel,
        );

    if (selectedProjectType == null || !mounted) return;

    _form.setProjectType(selectedProjectType);
  }

  Future<void> _pickTenderSubmissionDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _form.tenderSubmissionDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _form.setTenderDeadline(pickedDate);
  }

  Future<void> _submit() async {
    try {
      final result = await _form.submit();
      if (!mounted) return;
      if (result case FormSubmitInvalid(:final message)) {
        if (message != null) AppToast.warning(context, message);
        _scrollToFirstInvalid();
        return;
      }
      if (result case FormSubmitSuccess(:final message)) {
        AppToast.success(context, message);
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    }
  }

  String _errorMessage(Object error) {
    if (error is AppException) return error.detailedMessage;

    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.isEmpty) {
      return 'Prospect gagal dibuat. Coba lagi.';
    }
    return message;
  }

  void _scrollToFirstInvalid() {
    final form = _form;
    final key = form.titleError != null
        ? _titleKey
        : form.clientError != null
        ? _clientKey
        : form.projectTypeError != null
        ? _projectTypeKey
        : form.estimatedValueError != null
        ? _estimatedValueKey
        : form.startPeriodError != null
        ? _startPeriodKey
        : form.endPeriodError != null
        ? _endPeriodKey
        : form.tenderSubmissionDeadlineError != null
        ? _tenderDeadlineKey
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fieldContext = key?.currentContext;
      if (fieldContext == null) return;
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prospectProjectTypesProvider);
    final controller = ref.watch(prospectCreateControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Tambah Prospect',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  KeyedSubtree(
                    key: _titleKey,
                    child: InputSingleLineTextField(
                      label: 'Judul prospek',
                      controller: controller.titleController,
                      isRequired: true,
                      errorText: controller.titleError,
                    ),
                  ),
                  KeyedSubtree(
                    key: _clientKey,
                    child: InputSingleLineTextField(
                      label: 'Klien',
                      controller: controller.clientController,
                      isRequired: true,
                      errorText: controller.clientError,
                    ),
                  ),
                  KeyedSubtree(
                    key: _projectTypeKey,
                    child: InputPickerField(
                      label: 'Tipe proyek',
                      value: controller.selectedProjectTypeValue,
                      isRequired: true,
                      errorText: controller.projectTypeError,
                      onTap: _pickProjectType,
                    ),
                  ),
                  KeyedSubtree(
                    key: _estimatedValueKey,
                    child: InputSingleLineTextField(
                      label: 'Estimasi nilai proyek',
                      controller: controller.estimatedValueController,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      errorText: controller.estimatedValueError,
                    ),
                  ),
                  KeyedSubtree(
                    key: _startPeriodKey,
                    child: InputPickerField(
                      label: 'Periode awal',
                      value: controller.startPeriodValue,
                      isRequired: true,
                      errorText: controller.startPeriodError,
                      onTap: _pickStartPeriod,
                    ),
                  ),
                  KeyedSubtree(
                    key: _endPeriodKey,
                    child: InputPickerField(
                      label: 'Periode akhir',
                      value: controller.endPeriodValue,
                      isRequired: true,
                      errorText: controller.endPeriodError,
                      onTap: _pickEndPeriod,
                    ),
                  ),
                  KeyedSubtree(
                    key: _tenderDeadlineKey,
                    child: InputPickerField(
                      label: 'Deadline submit tender',
                      value: controller.tenderDeadlineValue,
                      isRequired: true,
                      errorText: controller.tenderSubmissionDeadlineError,
                      onTap: _pickTenderSubmissionDeadline,
                    ),
                  ),
                  InputMultilineTextField(
                    label: 'Deskripsi',
                    controller: controller.descriptionController,
                    minLines: 3,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: _SubmitActionBar(
                isSubmitting: controller.isSubmitting,
                onSubmit: controller.isSubmitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitActionBar extends StatelessWidget {
  const _SubmitActionBar({required this.onSubmit, required this.isSubmitting});

  final VoidCallback? onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: AppButton(
        label: isSubmitting ? 'Menyimpan...' : 'Simpan',
        isLoading: isSubmitting,
        backgroundColor: AppColors.dashboardTeal,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.1),
        textStyle: const TextStyle(
          fontFamily: ProspectCreatePage._fontFamily,
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        onPressed: onSubmit,
      ),
    );
  }
}
