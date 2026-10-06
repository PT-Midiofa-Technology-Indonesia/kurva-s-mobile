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
import '../../../shared/widgets/input_picker_field.dart';
import '../../../shared/widgets/input_multiline_text_field.dart';
import '../../../shared/widgets/selection_bottom_sheet.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../data/models/leave.dart';
import '../workforce_providers.dart';
import 'workforce_request_form_controllers.dart';

class WorkforceLeaveRequestPage extends ConsumerStatefulWidget {
  const WorkforceLeaveRequestPage({super.key});

  static const _fontFamily = AppFonts.inter;

  @override
  ConsumerState<WorkforceLeaveRequestPage> createState() =>
      _WorkforceLeaveRequestPageState();
}

class _WorkforceLeaveRequestPageState
    extends ConsumerState<WorkforceLeaveRequestPage> {
  final _leaveTypeKey = GlobalKey();
  final _reasonKey = GlobalKey();
  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();

  LeaveRequestFormController get _form =>
      ref.read(leaveRequestFormControllerProvider);

  Future<void> _pickLeaveType(List<LeaveType> leaveTypes) async {
    if (leaveTypes.isEmpty) {
      _showMessage('Jenis cuti belum tersedia.');
      return;
    }

    final selected = await SelectionBottomSheet.show<LeaveType>(
      context,
      title: 'Jenis cuti',
      options: leaveTypes,
      selectedOption: _form.selectedLeaveType,
      labelBuilder: (option) => option.name,
    );

    if (selected == null || !mounted) return;

    _form.setLeaveType(selected);
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _form.startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _form.setStartDate(pickedDate);
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _form.endDate ?? _form.startDate ?? DateTime.now(),
      firstDate: _form.startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _form.setEndDate(pickedDate);
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
        context.pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      if (error case AppException(hasErrors: true)) return;
      AppToast.error(context, error);
    }
  }

  void _showMessage(String message, {AppToastType type = AppToastType.error}) {
    AppToast.show(context, message: message, type: type);
  }

  void _scrollToFirstInvalid() {
    final form = _form;
    final key = form.leaveTypeError != null
        ? _leaveTypeKey
        : form.reasonError != null
        ? _reasonKey
        : form.startDateError != null
        ? _startDateKey
        : form.endDateError != null
        ? _endDateKey
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
    final leaveTypesAsync = ref.watch(leaveTypeListProvider);
    final controller = ref.watch(leaveRequestFormControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Pengajuan Cuti',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  KeyedSubtree(
                    key: _leaveTypeKey,
                    child: leaveTypesAsync.when(
                      data: (leaveTypes) => InputPickerField(
                        label: 'Jenis cuti',
                        value: controller.selectedLeaveType?.name ?? '',
                        isRequired: true,
                        errorText: controller.leaveTypeError,
                        onTap: () => _pickLeaveType(leaveTypes),
                      ),
                      loading: () => const InputPickerField(
                        label: 'Jenis cuti',
                        value: 'Memuat jenis cuti...',
                        isRequired: true,
                      ),
                      error: (error, _) => InputPickerField(
                        label: 'Jenis cuti',
                        value: 'Gagal memuat jenis cuti',
                        isRequired: true,
                        onTap: () => ref.invalidate(leaveTypeListProvider),
                      ),
                    ),
                  ),
                  KeyedSubtree(
                    key: _reasonKey,
                    child: InputMultilineTextField(
                      label: 'Keperluan cuti',
                      controller: controller.reasonController,
                      isRequired: true,
                      errorText: controller.reasonError,
                    ),
                  ),
                  _QuotaNotice(value: controller.quotaNotice),
                  KeyedSubtree(
                    key: _startDateKey,
                    child: InputPickerField(
                      label: 'Tanggal mulai',
                      value: controller.startDateValue,
                      isRequired: true,
                      errorText: controller.startDateError,
                      onTap: _pickStartDate,
                    ),
                  ),
                  KeyedSubtree(
                    key: _endDateKey,
                    child: InputPickerField(
                      label: 'Tanggal berakhir',
                      value: controller.endDateValue,
                      isRequired: true,
                      errorText: controller.endDateError,
                      onTap: _pickEndDate,
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: _SubmitActionBar(
                isLoading: controller.isSubmitting,
                onSubmit: controller.isSubmitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaNotice extends StatelessWidget {
  const _QuotaNotice({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.orange,
          fontFamily: WorkforceLeaveRequestPage._fontFamily,
          fontSize: 14,
          height: 1.43,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SubmitActionBar extends StatelessWidget {
  const _SubmitActionBar({required this.onSubmit, required this.isLoading});

  final VoidCallback? onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: isLoading ? 'Mengirim...' : 'Ajukan cuti',
              isLoading: isLoading,
              backgroundColor: AppColors.dashboardTeal,
              elevation: 4,
              shadowColor: AppColors.black.withValues(alpha: 0.1),
              textStyle: const TextStyle(
                fontFamily: WorkforceLeaveRequestPage._fontFamily,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              onPressed: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
