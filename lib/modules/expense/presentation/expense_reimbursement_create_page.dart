import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/input_picker_field.dart';
import '../../../shared/widgets/input_single_line_text_field.dart';
import '../../../shared/widgets/searchable_selection_bottom_sheet.dart';
import '../../../shared/widgets/selection_bottom_sheet.dart';
import '../../../shared/widgets/upload_source_bottom_sheet.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../../project/data/models/project_models.dart';
import '../../project/project_providers.dart';
import 'expense_reimbursement_create_controller.dart';

class ExpenseReimbursementCreatePage extends ConsumerStatefulWidget {
  const ExpenseReimbursementCreatePage({super.key, this.isProject = true});

  final bool isProject;

  static const _fontFamily = AppFonts.inter;

  @override
  ConsumerState<ExpenseReimbursementCreatePage> createState() =>
      _ExpenseReimbursementCreatePageState();
}

class _ExpenseReimbursementCreatePageState
    extends ConsumerState<ExpenseReimbursementCreatePage> {
  static const _paymentRequests = ['Cash', 'Transfer', 'Check'];
  final _purposeKey = GlobalKey();
  final _deadlineKey = GlobalKey();
  final _projectKey = GlobalKey();
  final _paymentRequestKey = GlobalKey();
  final _itemsKey = GlobalKey();
  final _itemFieldKeys = Expando<_ExpenseItemFieldKeys>();

  ExpenseReimbursementCreateController get _controller =>
      ref.read(expenseReimbursementFormControllerProvider(widget.isProject));

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _controller.deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _controller.setDeadline(pickedDate);
  }

  Future<void> _pickProject() async {
    final projectState = ref.read(projectListProvider);
    final projects =
        projectState.valueOrNull?.result.projects ?? const <Project>[];

    if (projects.isEmpty) {
      AppToast.info(
        context,
        projectState.isLoading
            ? 'Daftar proyek sedang dimuat.'
            : _errorMessage(
                projectState.error ?? 'Daftar proyek belum tersedia.',
              ),
      );
      return;
    }

    final selectedProject = await SearchableSelectionBottomSheet.show<Project>(
      context,
      title: 'Pilih Proyek',
      options: projects,
      selectedOption: _controller.selectedProject,
      labelBuilder: (project) => project.name,
    );

    if (selectedProject == null || !mounted) return;

    _controller.setProject(selectedProject);
  }

  Future<void> _pickPaymentRequest() async {
    final selectedPaymentRequest = await SelectionBottomSheet.show<String>(
      context,
      title: 'Payment request',
      options: _paymentRequests,
      selectedOption: _controller.selectedPaymentRequest,
      labelBuilder: (paymentRequest) => paymentRequest,
    );

    if (selectedPaymentRequest == null || !mounted) return;

    _controller.setPaymentRequest(selectedPaymentRequest);
  }

  Future<void> _addProof(int itemIndex) async {
    final source = await UploadSourceBottomSheet.show(context);

    if (source == null || !mounted) return;

    try {
      final proofs = await _controller.pickProofs(source);

      if (!mounted || proofs.isEmpty) return;

      _controller.addProofs(itemIndex, proofs);
    } catch (_) {
      if (!mounted) return;

      AppToast.warning(
        context,
        'Bukti tidak dapat dipilih. Periksa izin akses.',
      );
    }
  }

  void _removeProof(int itemIndex, int proofIndex) {
    _controller.removeProof(itemIndex, proofIndex);
  }

  void _addItem() {
    _controller.addItem();
  }

  void _removeItem(int index) {
    _controller.removeItem(index);
  }

  Future<void> _submit() async {
    try {
      final result = await _controller.submit();

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
      return 'Reimbursement gagal diajukan. Coba lagi.';
    }
    return message;
  }

  void _scrollToFirstInvalid() {
    final form = _controller;
    GlobalKey? key;
    if (form.purposeError != null) {
      key = _purposeKey;
    } else if (form.deadlineError != null) {
      key = _deadlineKey;
    } else if (form.projectError != null) {
      key = _projectKey;
    } else if (form.paymentRequestError != null) {
      key = _paymentRequestKey;
    } else if (form.itemsError != null) {
      key = _itemsKey;
    } else {
      for (var index = 0; index < form.itemErrors.length; index++) {
        final error = form.itemErrors[index];
        if (!error.hasError) continue;
        final keys = _keysFor(form.items[index]);
        key = error.receiptNumberError != null
            ? keys.receiptNumber
            : error.itemNameError != null
            ? keys.itemName
            : error.amountError != null
            ? keys.amount
            : keys.proof;
        break;
      }
    }
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

  _ExpenseItemFieldKeys _keysFor(ExpenseReimbursementItemEntry item) =>
      _itemFieldKeys[item] ??= _ExpenseItemFieldKeys();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      expenseReimbursementFormControllerProvider(widget.isProject),
    );
    if (widget.isProject) {
      ref.watch(projectListProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Buat Reimbursement',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  const _SectionTitle(title: 'Keterangan'),
                  KeyedSubtree(
                    key: _purposeKey,
                    child: InputSingleLineTextField(
                      label: 'Keperluan',
                      controller: controller.purposeController,
                      isRequired: true,
                      errorText: controller.purposeError,
                    ),
                  ),
                  KeyedSubtree(
                    key: _deadlineKey,
                    child: InputPickerField(
                      label: 'Tenggat Waktu',
                      value: _controller.deadlineValue,
                      isRequired: true,
                      errorText: controller.deadlineError,
                      onTap: _pickDeadline,
                    ),
                  ),
                  if (widget.isProject)
                    KeyedSubtree(
                      key: _projectKey,
                      child: InputPickerField(
                        label: 'Pilih proyek',
                        value: _controller.selectedProjectName,
                        isRequired: true,
                        errorText: controller.projectError,
                        onTap: _pickProject,
                      ),
                    ),
                  KeyedSubtree(
                    key: _paymentRequestKey,
                    child: InputPickerField(
                      label: 'Payment request',
                      value: _controller.selectedPaymentRequest,
                      isRequired: true,
                      errorText: controller.paymentRequestError,
                      onTap: _pickPaymentRequest,
                    ),
                  ),
                  if (controller.itemsError case final itemsError?)
                    KeyedSubtree(
                      key: _itemsKey,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: Text(
                          itemsError,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ...List.generate(_controller.items.length, (index) {
                    final item = _controller.items[index];
                    final itemError = controller.itemErrors[index];
                    final fieldKeys = _keysFor(item);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        0,
                      ),
                      child: _ExpenseItemForm(
                        title: 'Nota ${index + 1}',
                        receiptNumberController: item.receiptNumberController,
                        itemNameController: item.itemNameController,
                        amountController: item.amountController,
                        proofs: item.proofs,
                        receiptNumberError: itemError.receiptNumberError,
                        itemNameError: itemError.itemNameError,
                        amountError: itemError.amountError,
                        proofError: itemError.proofError,
                        fieldKeys: fieldKeys,
                        canRemove: _controller.items.length > 1,
                        onRemovePressed: () => _removeItem(index),
                        onAddProofPressed: () => _addProof(index),
                        onRemoveProofPressed: (proofIndex) {
                          _removeProof(index, proofIndex);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),
                  _AddItemButton(onPressed: _addItem),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: ExpenseReimbursementCreatePage._fontFamily,
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ExpenseItemForm extends StatelessWidget {
  const _ExpenseItemForm({
    required this.title,
    required this.receiptNumberController,
    required this.itemNameController,
    required this.amountController,
    required this.proofs,
    required this.receiptNumberError,
    required this.itemNameError,
    required this.amountError,
    required this.proofError,
    required this.fieldKeys,
    required this.canRemove,
    required this.onRemovePressed,
    required this.onAddProofPressed,
    required this.onRemoveProofPressed,
  });

  final String title;
  final TextEditingController receiptNumberController;
  final TextEditingController itemNameController;
  final TextEditingController amountController;
  final List<ExpenseProofAttachment> proofs;
  final String? receiptNumberError;
  final String? itemNameError;
  final String? amountError;
  final String? proofError;
  final _ExpenseItemFieldKeys fieldKeys;
  final bool canRemove;
  final VoidCallback onRemovePressed;
  final VoidCallback onAddProofPressed;
  final ValueChanged<int> onRemoveProofPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontFamily: ExpenseReimbursementCreatePage._fontFamily,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: 'Hapus nota',
                    color: AppColors.error,
                    icon: const Icon(Icons.delete_outline, size: 22),
                    onPressed: onRemovePressed,
                  ),
              ],
            ),
          ),
          KeyedSubtree(
            key: fieldKeys.receiptNumber,
            child: InputSingleLineTextField(
              label: 'No nota',
              controller: receiptNumberController,
              isRequired: true,
              errorText: receiptNumberError,
            ),
          ),
          KeyedSubtree(
            key: fieldKeys.itemName,
            child: InputSingleLineTextField(
              label: 'Nama item',
              controller: itemNameController,
              isRequired: true,
              errorText: itemNameError,
            ),
          ),
          KeyedSubtree(
            key: fieldKeys.amount,
            child: InputSingleLineTextField(
              label: 'Nominal',
              controller: amountController,
              isRequired: true,
              keyboardType: TextInputType.number,
              errorText: amountError,
            ),
          ),
          KeyedSubtree(
            key: fieldKeys.proof,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _UploadProofBox(
                proofs: proofs,
                errorText: proofError,
                onPressed: onAddProofPressed,
                onRemoveProofPressed: onRemoveProofPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseItemFieldKeys {
  final receiptNumber = GlobalKey();
  final itemName = GlobalKey();
  final amount = GlobalKey();
  final proof = GlobalKey();
}

class _UploadProofBox extends StatelessWidget {
  const _UploadProofBox({
    required this.proofs,
    required this.errorText,
    required this.onPressed,
    required this.onRemoveProofPressed,
  });

  final List<ExpenseProofAttachment> proofs;
  final String? errorText;
  final VoidCallback onPressed;
  final ValueChanged<int> onRemoveProofPressed;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText?.isNotEmpty ?? false;
    final borderColor = hasError ? AppColors.error : AppColors.inputBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onPressed,
            child: Ink(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: CustomPaint(
                  painter: _DashedRoundedBorderPainter(
                    color: borderColor,
                    radius: AppRadius.lg,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: proofs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Belum ada bukti di unggah',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontFamily: ExpenseReimbursementCreatePage
                                        ._fontFamily,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  '+ Tambah',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.dashboardTeal,
                                    fontFamily: ExpenseReimbursementCreatePage
                                        ._fontFamily,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ...List.generate(proofs.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == proofs.length - 1
                                        ? AppSpacing.md
                                        : AppSpacing.sm,
                                  ),
                                  child: _ProofTile(
                                    proof: proofs[index],
                                    onRemovePressed: () =>
                                        onRemoveProofPressed(index),
                                  ),
                                );
                              }),
                              const Text(
                                '+ Tambah bukti lain',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.dashboardTeal,
                                  fontFamily: ExpenseReimbursementCreatePage
                                      ._fontFamily,
                                  fontSize: 16,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontFamily: ExpenseReimbursementCreatePage._fontFamily,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.proof, required this.onRemovePressed});

  final ExpenseProofAttachment proof;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softLine),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              proof.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: ExpenseReimbursementCreatePage._fontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            proof.sizeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.inputBorder,
              fontFamily: ExpenseReimbursementCreatePage._fontFamily,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Hapus bukti',
            visualDensity: VisualDensity.compact,
            color: AppColors.error,
            icon: const Icon(Icons.close, size: 20),
            onPressed: onRemovePressed,
          ),
        ],
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashGap = 6.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(paint.strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: const Text(
          '+ Tambah Item',
          style: TextStyle(
            color: AppColors.dashboardTeal,
            fontFamily: ExpenseReimbursementCreatePage._fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
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
      decoration: const BoxDecoration(color: AppColors.white),
      child: AppButton(
        label: isSubmitting ? 'Mengajukan...' : 'Ajukan reimburse',
        isLoading: isSubmitting,
        backgroundColor: AppColors.dashboardTeal,
        borderRadius: AppRadius.md,
        textStyle: const TextStyle(
          fontFamily: ExpenseReimbursementCreatePage._fontFamily,
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
