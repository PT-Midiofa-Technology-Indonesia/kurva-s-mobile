import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/server_refresh_delay.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../data/models/leave.dart';
import '../../project/data/models/project_models.dart';
import '../data/models/location.dart';
import '../data/models/overtime.dart';
import '../workforce_providers.dart';

final leaveRequestFormControllerProvider =
    ChangeNotifierProvider.autoDispose<LeaveRequestFormController>((ref) {
      return LeaveRequestFormController(ref);
    });

final overtimeRequestFormControllerProvider =
    ChangeNotifierProvider.autoDispose<OvertimeRequestFormController>((ref) {
      return OvertimeRequestFormController(ref);
    });

class LeaveRequestFormController extends ChangeNotifier {
  LeaveRequestFormController(this._ref) {
    reasonController.addListener(_clearReasonError);
  }

  static const _months = [
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
  final reasonController = TextEditingController();
  LeaveType? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;
  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool hasServerErrors = false;
  String? leaveTypeError;
  String? reasonError;
  String? startDateError;
  String? endDateError;

  String get startDateValue => _formatDate(startDate);
  String get endDateValue => _formatDate(endDate);
  String get quotaNotice {
    final balance = selectedLeaveType?.balance;
    return balance == null
        ? 'Pilih jenis cuti untuk melihat sisa kuota'
        : 'Sisa kuota saat ini ${balance.remaining} hari';
  }

  void setLeaveType(LeaveType value) {
    selectedLeaveType = value;
    if (hasSubmitted) leaveTypeError = _validateLeaveType();
    notifyListeners();
  }

  void setStartDate(DateTime value) {
    startDate = value;
    if (hasSubmitted) startDateError = _validateStartDate();
    if (endDate != null && endDate!.isBefore(value)) endDate = value;
    if (hasSubmitted) endDateError = _validateEndDate();
    notifyListeners();
  }

  void setEndDate(DateTime value) {
    endDate = value;
    if (hasSubmitted) endDateError = _validateEndDate();
    notifyListeners();
  }

  Future<FormSubmitResult> submit() async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    hasServerErrors = false;
    if (!_validate()) return const FormSubmitInvalid();
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(workforceRepositoryProvider)
          .submitLeave(
            LeaveRequestInput(
              leaveTypeId: selectedLeaveType!.id,
              reason: reasonController.text.trim(),
              startDate: startDate!,
              endDate: endDate!,
            ),
          );
      await waitForServerRefresh();
      _ref
        ..invalidate(leaveListControllerProvider)
        ..invalidate(leaveTypeListProvider);
      return FormSubmitSuccess(message ?? 'Pengajuan cuti berhasil dikirim.');
    } on AppException catch (error) {
      if (_applyServerErrors(error.details)) {
        return const FormSubmitInvalid();
      }
      if (error.hasErrors) {
        return FormSubmitInvalid(_validationWarning(error));
      }
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }

  bool _validate() {
    leaveTypeError = _validateLeaveType();
    reasonError = _validateReason();
    startDateError = _validateStartDate();
    endDateError = _validateEndDate();
    notifyListeners();
    return leaveTypeError == null &&
        reasonError == null &&
        startDateError == null &&
        endDateError == null;
  }

  String _formatDate(DateTime? value) => value == null
      ? ''
      : '${value.day} ${_months[value.month - 1]} ${value.year}';

  void _clearReasonError() {
    if (!hasSubmitted) return;
    reasonError = _validateReason();
    notifyListeners();
  }

  String? _validateLeaveType() =>
      selectedLeaveType == null ? 'Jenis cuti wajib dipilih.' : null;
  String? _validateReason() => Validators.requiredText(
    reasonController.text,
    'Keperluan cuti wajib diisi.',
  );
  String? _validateStartDate() =>
      startDate == null ? 'Tanggal mulai wajib dipilih.' : null;
  String? _validateEndDate() {
    if (endDate == null) return 'Tanggal berakhir wajib dipilih.';
    if (startDate != null && endDate!.isBefore(startDate!)) {
      return 'Tanggal berakhir tidak boleh sebelum tanggal mulai.';
    }
    return null;
  }

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      switch (parsed.field) {
        case 'leaveTypeId':
        case 'leave_type_id':
          leaveTypeError = _joinError(leaveTypeError, parsed.message);
        case 'reason':
          reasonError = _joinError(reasonError, parsed.message);
        case 'startDate':
        case 'start_date':
          startDateError = _joinError(startDateError, parsed.message);
        case 'endDate':
        case 'end_date':
          endDateError = _joinError(endDateError, parsed.message);
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

  String _validationWarning(AppException error) {
    final messages = error.details
        .map((detail) => Validators.validationDetail(detail)?.message ?? detail)
        .where((message) => message.trim().isNotEmpty)
        .toList(growable: false);
    return messages.isEmpty ? error.message : messages.join('\n');
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}

class OvertimeRequestFormController extends ChangeNotifier {
  OvertimeRequestFormController(this._ref) {
    reasonController.addListener(_clearReasonError);
  }

  static const locationTypes = ['Warehouse', 'Office'];
  static const _months = [
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
  final reasonController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String selectedLocationType = '';
  WorkforceLocation? selectedLocation;
  Project? selectedProject;
  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool hasServerErrors = false;
  String? dateError;
  String? startTimeError;
  String? endTimeError;
  String? locationTypeError;
  String? locationError;
  String? reasonError;

  String get dateValue => selectedDate == null
      ? ''
      : '${selectedDate!.day} ${_months[selectedDate!.month - 1]} ${selectedDate!.year}';
  String get startTimeValue => startTime == null ? '' : _formatTime(startTime!);
  String get endTimeValue => endTime == null ? '' : _formatTime(endTime!);
  String get locationValue => selectedLocation?.name ?? '';
  String get projectValue => selectedProject?.name ?? '';

  void setDate(DateTime value) {
    selectedDate = value;
    if (hasSubmitted) dateError = _validateDate();
    notifyListeners();
  }

  void setStartTime(TimeOfDay value) {
    startTime = value;
    if (hasSubmitted) {
      startTimeError = _validateStartTime();
      endTimeError = _validateEndTime();
    }
    notifyListeners();
  }

  void setEndTime(TimeOfDay value) {
    endTime = value;
    if (hasSubmitted) endTimeError = _validateEndTime();
    notifyListeners();
  }

  void setLocationType(String value) {
    selectedLocationType = value;
    selectedLocation = null;
    if (hasSubmitted) {
      locationTypeError = _validateLocationType();
      locationError = _validateLocation();
    }
    notifyListeners();
  }

  void setLocation(WorkforceLocation value) {
    selectedLocation = value;
    if (hasSubmitted) locationError = _validateLocation();
    notifyListeners();
  }

  void setProject(Project value) {
    selectedProject = value;
    notifyListeners();
  }

  Future<FormSubmitResult> submit() async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    hasServerErrors = false;
    if (!_validate()) return const FormSubmitInvalid();
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(workforceRepositoryProvider)
          .submitOvertime(
            OvertimeRequestInput(
              overtimeDate: selectedDate!,
              startTime: _formatTime(startTime!),
              endTime: _formatTime(endTime!),
              locationType: selectedLocationType,
              locationId: selectedLocation!.id,
              projectId: selectedProject?.id,
              reason: reasonController.text.trim(),
            ),
          );
      await waitForServerRefresh();
      _ref.invalidate(overtimeListControllerProvider);
      return FormSubmitSuccess(message ?? 'Pengajuan lembur berhasil dikirim.');
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

  bool _validate() {
    dateError = _validateDate();
    startTimeError = _validateStartTime();
    endTimeError = _validateEndTime();
    locationTypeError = _validateLocationType();
    locationError = _validateLocation();
    reasonError = _validateReason();
    notifyListeners();
    return [
      dateError,
      startTimeError,
      endTimeError,
      locationTypeError,
      locationError,
      reasonError,
    ].every((error) => error == null);
  }

  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;
  String _formatTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  void _clearReasonError() {
    if (!hasSubmitted) return;
    reasonError = _validateReason();
    notifyListeners();
  }

  String? _validateDate() =>
      selectedDate == null ? 'Tanggal wajib dipilih.' : null;
  String? _validateStartTime() =>
      startTime == null ? 'Jam mulai wajib dipilih.' : null;
  String? _validateEndTime() {
    if (endTime == null) return 'Jam berakhir wajib dipilih.';
    if (startTime != null && _minutes(endTime!) <= _minutes(startTime!)) {
      return 'Jam berakhir harus setelah jam mulai.';
    }
    return null;
  }

  String? _validateLocationType() =>
      selectedLocationType.isEmpty ? 'Tipe lokasi wajib dipilih.' : null;
  String? _validateLocation() =>
      selectedLocation == null ? 'Lokasi wajib dipilih.' : null;
  String? _validateReason() => Validators.requiredText(
    reasonController.text,
    'Alasan lembur wajib diisi.',
  );

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      switch (parsed.field) {
        case 'overtimeDate':
        case 'overtime_date':
          dateError = _joinError(dateError, parsed.message);
        case 'startTime':
        case 'start_time':
          startTimeError = _joinError(startTimeError, parsed.message);
        case 'endTime':
        case 'end_time':
          endTimeError = _joinError(endTimeError, parsed.message);
        case 'locationType':
        case 'location_type':
          locationTypeError = _joinError(locationTypeError, parsed.message);
        case 'locationId':
        case 'location_id':
          locationError = _joinError(locationError, parsed.message);
        case 'reason':
          reasonError = _joinError(reasonError, parsed.message);
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
    reasonController.dispose();
    super.dispose();
  }
}
