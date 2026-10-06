import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/server_refresh_delay.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/upload_source_bottom_sheet.dart';
import '../../project/data/models/project_models.dart';
import '../data/expense_repository.dart';
import '../expense_providers.dart';

final expenseReimbursementFormControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<ExpenseReimbursementCreateController, bool>((ref, isProject) {
      return ExpenseReimbursementCreateController(ref, isProject);
    });

class ExpenseReimbursementCreateController extends ChangeNotifier {
  ExpenseReimbursementCreateController(this._ref, this.isProject) {
    purposeController.addListener(_onPurposeChanged);
    _listenToItem(items.first);
  }

  final Ref _ref;
  final bool isProject;
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  final _imagePicker = ImagePicker();
  final purposeController = TextEditingController();
  final List<ExpenseReimbursementItemEntry> items = [
    ExpenseReimbursementItemEntry(),
  ];
  final List<ExpenseItemFormError> itemErrors = [ExpenseItemFormError()];

  DateTime? deadline;
  Project? selectedProject;
  String selectedPaymentRequest = '';
  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool hasServerErrors = false;
  String? purposeError;
  String? deadlineError;
  String? projectError;
  String? paymentRequestError;
  String? itemsError;

  String get selectedProjectName => selectedProject?.name ?? '';

  String get deadlineValue {
    final selectedDeadline = deadline;
    if (selectedDeadline == null) return '';

    return '${selectedDeadline.day} '
        '${_monthNames[selectedDeadline.month - 1]} '
        '${selectedDeadline.year}';
  }

  void setDeadline(DateTime value) {
    deadline = value;
    if (hasSubmitted) deadlineError = _validateDeadline();
    notifyListeners();
  }

  void setProject(Project value) {
    selectedProject = value;
    if (hasSubmitted) projectError = _validateProject();
    notifyListeners();
  }

  void setPaymentRequest(String value) {
    selectedPaymentRequest = value;
    if (hasSubmitted) paymentRequestError = _validatePaymentRequest();
    notifyListeners();
  }

  Future<List<ExpenseProofAttachment>> pickProofs(UploadSource source) {
    return switch (source) {
      UploadSource.camera => _pickCameraProof(),
      UploadSource.file => _pickFileProofs(),
    };
  }

  Future<List<ExpenseProofAttachment>> _pickCameraProof() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (file == null) return [];

    return [
      ExpenseProofAttachment(
        name: _fileName(file),
        size: await _readFileSize(file),
        imageFile: file,
      ),
    ];
  }

  Future<List<ExpenseProofAttachment>> _pickFileProofs() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return [];

    return result.files
        .map(
          (file) => ExpenseProofAttachment(
            name: file.name,
            size: file.size,
            pickedFile: file,
          ),
        )
        .toList();
  }

  String _fileName(XFile file) {
    final trimmedName = file.name.trim();
    if (trimmedName.isNotEmpty) return trimmedName;

    final segments = file.path.split('/');
    return segments.isEmpty ? 'bukti' : segments.last;
  }

  Future<int?> _readFileSize(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  void addProofs(int itemIndex, List<ExpenseProofAttachment> proofs) {
    items[itemIndex].proofs.addAll(proofs);
    if (hasSubmitted) {
      itemErrors[itemIndex].proofError = _validateProofs(items[itemIndex]);
    }
    notifyListeners();
  }

  void removeProof(int itemIndex, int proofIndex) {
    items[itemIndex].proofs.removeAt(proofIndex);
    if (hasSubmitted) {
      itemErrors[itemIndex].proofError = _validateProofs(items[itemIndex]);
    }
    notifyListeners();
  }

  void addItem() {
    final item = ExpenseReimbursementItemEntry();
    final error = ExpenseItemFormError();
    _listenToItem(item);
    items.add(item);
    if (hasSubmitted) {
      error.receiptNumberError = _validateReceiptNumber(item);
      error.itemNameError = _validateItemName(item);
      error.amountError = _validateAmount(item);
      error.proofError = _validateProofs(item);
    }
    itemErrors.add(error);
    itemsError = null;
    notifyListeners();
  }

  void removeItem(int index) {
    final item = items[index];
    items.removeAt(index);
    item.dispose();
    itemErrors.removeAt(index);
    notifyListeners();
  }

  Future<FormSubmitResult> submit() async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    hasServerErrors = false;
    itemsError = null;
    final request = _buildRequest();
    if (request == null) return const FormSubmitInvalid();
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(expenseRepositoryProvider)
          .createCostRequest(
            request: request,
            companyId: _ref.read(expenseCompanyIdProvider),
          );
      await waitForServerRefresh();
      _ref.invalidate(costRequestListProvider);
      return FormSubmitSuccess(message ?? 'Reimbursement berhasil diajukan.');
    } on AppException catch (error) {
      if (_applyServerErrors(error.details)) {
        return const FormSubmitInvalid();
      }
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }

  ExpenseCostRequest? _buildRequest() {
    final reason = purposeController.text.trim();
    final errors = <ExpenseItemFormError>[];
    purposeError = _validatePurpose();
    deadlineError = _validateDeadline();
    projectError = _validateProject();
    paymentRequestError = _validatePaymentRequest();

    for (final item in items) {
      final error = ExpenseItemFormError();
      error.receiptNumberError = _validateReceiptNumber(item);
      error.itemNameError = _validateItemName(item);
      error.amountError = _validateAmount(item);
      error.proofError = _validateProofs(item);
      errors.add(error);
    }
    itemErrors
      ..clear()
      ..addAll(errors);
    notifyListeners();
    if (purposeError != null ||
        deadlineError != null ||
        projectError != null ||
        paymentRequestError != null ||
        errors.any((error) => error.hasError)) {
      return null;
    }

    return ExpenseCostRequest(
      requestType: isProject ? 'project' : 'non_project',
      reason: reason,
      dueDate: formatDateParam(deadline!)!,
      paymentMethod: _paymentMethodValue(selectedPaymentRequest),
      projectId: isProject ? selectedProject!.id : null,
      notes: '',
      items: items
          .map((item) {
            return ExpenseCostRequestItem(
              receiptNumber: item.receiptNumberController.text.trim(),
              description: item.itemNameController.text.trim(),
              amount: _normalizedAmount(item.amountController.text),
              notes: '',
              proofs: item.proofs
                  .map(
                    (proof) => ExpenseProofUpload(
                      name: proof.name,
                      path: proof.path,
                      bytes: proof.bytes,
                    ),
                  )
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  String? _validatePurpose() =>
      Validators.requiredText(purposeController.text, 'Keperluan wajib diisi.');
  String? _validateDeadline() =>
      deadline == null ? 'Tenggat waktu wajib dipilih.' : null;
  String? _validateProject() =>
      isProject && (selectedProject == null || selectedProject!.id.isEmpty)
      ? 'Proyek wajib dipilih.'
      : null;
  String? _validatePaymentRequest() =>
      selectedPaymentRequest.isEmpty ? 'Payment request wajib dipilih.' : null;
  String? _validateReceiptNumber(ExpenseReimbursementItemEntry item) =>
      Validators.requiredText(
        item.receiptNumberController.text,
        'No nota wajib diisi.',
      );
  String? _validateItemName(ExpenseReimbursementItemEntry item) =>
      Validators.requiredText(
        item.itemNameController.text,
        'Nama item wajib diisi.',
      );
  String? _validateAmount(ExpenseReimbursementItemEntry item) =>
      Validators.digitsOnly(
        item.amountController.text,
        requiredMessage: 'Nominal wajib diisi.',
        invalidMessage: 'Nominal wajib diisi angka.',
      );
  String? _validateProofs(ExpenseReimbursementItemEntry item) =>
      item.proofs.isEmpty ? 'Bukti nota wajib diunggah.' : null;

  void _listenToItem(ExpenseReimbursementItemEntry item) {
    item.receiptNumberController.addListener(
      () => _onReceiptNumberChanged(item),
    );
    item.itemNameController.addListener(() => _onItemNameChanged(item));
    item.amountController.addListener(() => _onAmountChanged(item));
  }

  void _onPurposeChanged() {
    if (!hasSubmitted) return;
    purposeError = _validatePurpose();
    notifyListeners();
  }

  ExpenseItemFormError? _errorFor(ExpenseReimbursementItemEntry item) {
    if (!hasSubmitted) return null;
    final index = items.indexOf(item);
    return index < 0 ? null : itemErrors[index];
  }

  void _onReceiptNumberChanged(ExpenseReimbursementItemEntry item) {
    final error = _errorFor(item);
    if (error == null) return;
    error.receiptNumberError = _validateReceiptNumber(item);
    notifyListeners();
  }

  void _onItemNameChanged(ExpenseReimbursementItemEntry item) {
    final error = _errorFor(item);
    if (error == null) return;
    error.itemNameError = _validateItemName(item);
    notifyListeners();
  }

  void _onAmountChanged(ExpenseReimbursementItemEntry item) {
    final error = _errorFor(item);
    if (error == null) return;
    error.amountError = _validateAmount(item);
    notifyListeners();
  }

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      final field = parsed.field;
      final message = parsed.message;
      switch (field) {
        case 'reason':
          purposeError = _joinError(purposeError, message);
          applied = true;
        case 'dueDate':
        case 'due_date':
          deadlineError = _joinError(deadlineError, message);
          applied = true;
        case 'projectId':
        case 'project_id':
          projectError = _joinError(projectError, message);
          applied = true;
        case 'paymentMethod':
        case 'payment_method':
          paymentRequestError = _joinError(paymentRequestError, message);
          applied = true;
        case 'items':
          itemsError = _joinError(itemsError, message);
          applied = true;
        default:
          final match = RegExp(
            r'^items\.(\d+)\.(receiptNumber|receipt_number|description|amount|proofs|files)$',
          ).firstMatch(field);
          if (match == null) continue;
          final index = int.tryParse(match.group(1)!);
          if (index == null || index >= itemErrors.length) continue;
          final error = itemErrors[index];
          switch (match.group(2)) {
            case 'receiptNumber' || 'receipt_number':
              error.receiptNumberError = _joinError(
                error.receiptNumberError,
                message,
              );
            case 'description':
              error.itemNameError = _joinError(error.itemNameError, message);
            case 'amount':
              error.amountError = _joinError(error.amountError, message);
            case 'proofs' || 'files':
              error.proofError = _joinError(error.proofError, message);
          }
          applied = true;
      }
    }
    if (applied) {
      hasServerErrors = true;
      notifyListeners();
    }
    return applied;
  }

  String _joinError(String? current, String next) =>
      current == null || current.isEmpty ? next : '$current\n$next';

  String _normalizedAmount(String value) => value.trim();
  String _paymentMethodValue(String value) => switch (value) {
    'Transfer' => 'transfer',
    'Check' => 'check',
    _ => 'cash',
  };

  @override
  void dispose() {
    purposeController.removeListener(_onPurposeChanged);
    purposeController.dispose();
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }
}

class ExpenseItemFormError {
  String? receiptNumberError;
  String? itemNameError;
  String? amountError;
  String? proofError;

  bool get hasError =>
      receiptNumberError != null ||
      itemNameError != null ||
      amountError != null ||
      proofError != null;
}

class ExpenseReimbursementItemEntry {
  final receiptNumberController = TextEditingController();
  final itemNameController = TextEditingController();
  final amountController = TextEditingController();
  final List<ExpenseProofAttachment> proofs = [];

  void dispose() {
    receiptNumberController.dispose();
    itemNameController.dispose();
    amountController.dispose();
  }
}

class ExpenseProofAttachment {
  const ExpenseProofAttachment({
    required this.name,
    required this.size,
    this.imageFile,
    this.pickedFile,
  });

  final String name;
  final int? size;
  final XFile? imageFile;
  final PlatformFile? pickedFile;

  String? get path => imageFile?.path ?? pickedFile?.path;

  Uint8List? get bytes => pickedFile?.bytes;

  String get sizeLabel => size == null ? '-' : _formatFileSize(size!);

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
