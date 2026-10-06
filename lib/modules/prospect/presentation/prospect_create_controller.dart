import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/server_refresh_delay.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../../../shared/utils/date_formatter.dart';
import '../data/models/prospect_models.dart';
import '../data/prospect_repository.dart';
import '../prospect_providers.dart';

final prospectCreateControllerProvider =
    ChangeNotifierProvider.autoDispose<ProspectCreateController>((ref) {
      return ProspectCreateController(ref);
    });

class ProspectCreateController extends ChangeNotifier {
  ProspectCreateController(this._ref) {
    titleController.addListener(_clearTitleError);
    clientController.addListener(_clearClientError);
    estimatedValueController.addListener(_clearEstimatedValueError);
  }

  static const monthNames = [
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

  final Ref _ref;
  final titleController = TextEditingController();
  final clientController = TextEditingController();
  final estimatedValueController = TextEditingController();
  final descriptionController = TextEditingController();

  ProspectProjectType? selectedProjectType;
  DateTime? startPeriod;
  DateTime? endPeriod;
  DateTime? tenderSubmissionDeadline;
  String? titleError;
  String? clientError;
  String? projectTypeError;
  String? estimatedValueError;
  String? startPeriodError;
  String? endPeriodError;
  String? tenderSubmissionDeadlineError;
  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool hasServerErrors = false;

  String get startPeriodValue => formatDate(startPeriod);
  String get endPeriodValue => formatDate(endPeriod);
  String get tenderDeadlineValue => formatDate(tenderSubmissionDeadline);
  String get selectedProjectTypeValue {
    final value = selectedProjectType;
    if (value == null) return '';
    return value.code.isEmpty ? value.name : '${value.code} - ${value.name}';
  }

  String projectTypeLabel(ProspectProjectType value) =>
      value.code.isEmpty ? value.name : '${value.code} - ${value.name}';

  void setStartPeriod(DateTime value) {
    startPeriod = value;
    if (hasSubmitted) startPeriodError = _validateStartPeriod();
    if (endPeriod != null && endPeriod!.isBefore(value)) endPeriod = value;
    if (hasSubmitted) endPeriodError = _validateEndPeriod();
    notifyListeners();
  }

  void setEndPeriod(DateTime value) {
    endPeriod = value;
    if (hasSubmitted) endPeriodError = _validateEndPeriod();
    notifyListeners();
  }

  void setProjectType(ProspectProjectType value) {
    selectedProjectType = value;
    if (hasSubmitted) projectTypeError = _validateProjectType();
    notifyListeners();
  }

  void setTenderDeadline(DateTime value) {
    tenderSubmissionDeadline = value;
    if (hasSubmitted) {
      tenderSubmissionDeadlineError = _validateTenderDeadline();
    }
    notifyListeners();
  }

  Future<FormSubmitResult> submit() async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    hasServerErrors = false;
    final request = _buildRequest();
    if (request == null) return const FormSubmitInvalid();
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(prospectRepositoryProvider)
          .createProspect(
            request: request,
            companyId: _ref.read(prospectCompanyIdProvider),
          );
      await waitForServerRefresh();
      _ref.invalidate(prospectPipelineProvider);
      return FormSubmitSuccess(message ?? 'Prospect berhasil dibuat.');
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

  ProspectCreateRequest? _buildRequest() {
    final title = titleController.text.trim();
    final client = clientController.text.trim();
    final type = selectedProjectType;
    final estimatedValue = _estimatedValue();

    titleError = _validateTitle();
    clientError = _validateClient();
    projectTypeError = _validateProjectType();
    estimatedValueError = _validateEstimatedValue();
    startPeriodError = _validateStartPeriod();
    endPeriodError = _validateEndPeriod();
    tenderSubmissionDeadlineError = _validateTenderDeadline();
    notifyListeners();

    if ([
      titleError,
      clientError,
      projectTypeError,
      estimatedValueError,
      startPeriodError,
      endPeriodError,
      tenderSubmissionDeadlineError,
    ].any((error) => error != null)) {
      return null;
    }

    return ProspectCreateRequest(
      clientName: client,
      title: title,
      projectTypeId: type!.id,
      description: descriptionController.text.trim(),
      estimatedValue: estimatedValue!,
      projectStartDate: formatDateParam(startPeriod!)!,
      projectEndDate: formatDateParam(endPeriod!)!,
      tenderSubmissionDeadline: formatDateParam(tenderSubmissionDeadline!)!,
    );
  }

  int? _estimatedValue() {
    final value = estimatedValueController.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  String formatDate(DateTime? date) => date == null
      ? ''
      : '${date.day} ${monthNames[date.month - 1]} ${date.year}';

  void _clearTitleError() {
    if (!hasSubmitted) return;
    titleError = _validateTitle();
    notifyListeners();
  }

  void _clearClientError() {
    if (!hasSubmitted) return;
    clientError = _validateClient();
    notifyListeners();
  }

  void _clearEstimatedValueError() {
    if (!hasSubmitted) return;
    estimatedValueError = _validateEstimatedValue();
    notifyListeners();
  }

  String? _validateTitle() => Validators.requiredText(
    titleController.text,
    'Judul prospek wajib diisi.',
  );
  String? _validateClient() =>
      Validators.requiredText(clientController.text, 'Klien wajib diisi.');
  String? _validateProjectType() {
    final type = selectedProjectType;
    return type == null || type.id.isEmpty
        ? 'Tipe proyek wajib dipilih.'
        : null;
  }

  String? _validateEstimatedValue() => Validators.digitsOnly(
    estimatedValueController.text,
    requiredMessage: 'Estimasi nilai proyek wajib diisi.',
    invalidMessage: 'Estimasi nilai proyek wajib diisi angka.',
  );
  String? _validateStartPeriod() =>
      startPeriod == null ? 'Periode awal wajib dipilih.' : null;
  String? _validateEndPeriod() {
    if (endPeriod == null) return 'Periode akhir wajib dipilih.';
    if (startPeriod != null && endPeriod!.isBefore(startPeriod!)) {
      return 'Periode akhir tidak boleh sebelum periode awal.';
    }
    return null;
  }

  String? _validateTenderDeadline() => tenderSubmissionDeadline == null
      ? 'Deadline submit tender wajib dipilih.'
      : null;

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      switch (parsed.field) {
        case 'title':
          titleError = _joinError(titleError, parsed.message);
        case 'clientName':
        case 'client_name':
          clientError = _joinError(clientError, parsed.message);
        case 'projectTypeId':
        case 'project_type_id':
          projectTypeError = _joinError(projectTypeError, parsed.message);
        case 'estimatedValue':
        case 'estimated_value':
          estimatedValueError = _joinError(estimatedValueError, parsed.message);
        case 'projectStartDate':
        case 'project_start_date':
          startPeriodError = _joinError(startPeriodError, parsed.message);
        case 'projectEndDate':
        case 'project_end_date':
          endPeriodError = _joinError(endPeriodError, parsed.message);
        case 'tenderSubmissionDeadline':
        case 'tender_submission_deadline':
          tenderSubmissionDeadlineError = _joinError(
            tenderSubmissionDeadlineError,
            parsed.message,
          );
        default:
          continue;
      }
      applied = true;
    }
    if (applied) {
      hasServerErrors = true;
      notifyListeners();
    }
    return applied;
  }

  String _joinError(String? current, String next) =>
      current == null || current.isEmpty ? next : '$current\n$next';

  @override
  void dispose() {
    titleController.dispose();
    clientController.dispose();
    estimatedValueController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
