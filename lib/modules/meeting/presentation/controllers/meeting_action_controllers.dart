import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/server_refresh_delay.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/forms/form_submit_result.dart';
import '../../../../shared/utils/upload_file_picker.dart';
import '../../data/meeting_repository.dart';
import '../../meeting_providers.dart';

final meetingTaskDoneControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MeetingTaskDoneController, MeetingTaskQuery>((ref, query) {
      return MeetingTaskDoneController(ref, query);
    });

final meetingQualityDecisionControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<MeetingQualityDecisionController, MeetingTaskQuery>((ref, query) {
      return MeetingQualityDecisionController(ref, query);
    });

final meetingAssigneeActionControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<MeetingAssigneeActionController, MeetingTaskQuery>((ref, query) {
      return MeetingAssigneeActionController(ref, query);
    });

class MeetingTaskDoneController extends ChangeNotifier {
  MeetingTaskDoneController(this._ref, this.query);

  final Ref _ref;
  final MeetingTaskQuery query;
  final List<MeetingSelectedFile> evidence = [];
  bool isSubmitting = false;
  bool hasSubmitted = false;
  String? evidenceError;

  Future<void> pickEvidence(BuildContext context) async {
    final files = await _pickFiles(context);
    addEvidence(files);
  }

  void addEvidence(Iterable<MeetingSelectedFile> files) {
    if (files.isEmpty) return;
    evidence.addAll(files);
    if (hasSubmitted) evidenceError = _validateEvidence();
    notifyListeners();
  }

  void removeEvidenceAt(int index) {
    evidence.removeAt(index);
    if (hasSubmitted) evidenceError = _validateEvidence();
    notifyListeners();
  }

  Future<FormSubmitResult> submit() async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    evidenceError = _validateEvidence();
    notifyListeners();
    if (evidenceError != null) return const FormSubmitInvalid();

    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(meetingRepositoryProvider)
          .submitTaskDone(
            meetingId: query.meetingId,
            taskId: query.taskId,
            files: evidence.map((file) => file.toUpload()).toList(),
            companyId: _ref.read(meetingCompanyIdProvider),
          );
      await waitForServerRefresh();
      _ref.invalidate(meetingTasksProvider);
      _ref.invalidate(meetingTaskDetailProvider(query));
      return FormSubmitSuccess(message ?? 'Task berhasil diajukan ke QC.');
    } on AppException catch (error) {
      if (_applyServerErrors(error.details)) {
        notifyListeners();
        return const FormSubmitInvalid();
      }
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }

  String? _validateEvidence() =>
      evidence.isEmpty ? 'Bukti wajib diunggah.' : null;

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      if (const {'files', 'files[]', 'evidence'}.contains(parsed.field)) {
        evidenceError = _joinError(evidenceError, parsed.message);
        applied = true;
      }
    }
    return applied;
  }
}

class MeetingQualityDecisionController extends ChangeNotifier {
  MeetingQualityDecisionController(this._ref, this.query) {
    noteController.addListener(_onNoteChanged);
  }

  final Ref _ref;
  final MeetingTaskQuery query;
  final noteController = TextEditingController();
  final List<MeetingSelectedFile> evidence = [];
  bool isSubmitting = false;
  String? submittingDecision;
  bool hasSubmitted = false;
  String? noteError;
  String? evidenceError;

  Future<void> pickEvidence(BuildContext context) async {
    final files = await _pickFiles(context);
    addEvidence(files);
  }

  void addEvidence(Iterable<MeetingSelectedFile> files) {
    if (files.isEmpty) return;
    evidence.addAll(files);
    if (hasSubmitted) evidenceError = _validateEvidence();
    notifyListeners();
  }

  void removeEvidenceAt(int index) {
    evidence.removeAt(index);
    if (hasSubmitted) evidenceError = _validateEvidence();
    notifyListeners();
  }

  Future<FormSubmitResult> submit(String decision) async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    noteError = _validateNote();
    evidenceError = _validateEvidence();
    notifyListeners();
    if (noteError != null || evidenceError != null) {
      return const FormSubmitInvalid();
    }

    isSubmitting = true;
    submittingDecision = decision;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(meetingRepositoryProvider)
          .submitQcDecision(
            meetingId: query.meetingId,
            qcTaskId: query.taskId,
            decision: decision,
            note: noteController.text.trim(),
            files: evidence.map((file) => file.toUpload()).toList(),
            companyId: _ref.read(meetingCompanyIdProvider),
          );
      await waitForServerRefresh();
      _ref.invalidate(meetingTasksProvider);
      _ref.invalidate(meetingTaskDetailProvider(query));
      return FormSubmitSuccess(
        message ?? (decision == 'pass' ? 'Task disetujui.' : 'Task ditolak.'),
      );
    } on AppException catch (error) {
      if (_applyServerErrors(error.details)) {
        notifyListeners();
        return const FormSubmitInvalid();
      }
      rethrow;
    } finally {
      isSubmitting = false;
      submittingDecision = null;
      notifyListeners();
      keepAlive.close();
    }
  }

  void _onNoteChanged() {
    if (!hasSubmitted) return;
    noteError = _validateNote();
    notifyListeners();
  }

  String? _validateNote() =>
      Validators.requiredText(noteController.text, 'Catatan QC wajib diisi.');

  String? _validateEvidence() =>
      evidence.isEmpty ? 'Bukti QC wajib diunggah.' : null;

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      switch (parsed.field) {
        case 'note':
          noteError = _joinError(noteError, parsed.message);
          applied = true;
        case 'files' || 'files[]' || 'evidence':
          evidenceError = _joinError(evidenceError, parsed.message);
          applied = true;
      }
    }
    return applied;
  }

  @override
  void dispose() {
    noteController
      ..removeListener(_onNoteChanged)
      ..dispose();
    super.dispose();
  }
}

class MeetingAssigneeActionController extends ChangeNotifier {
  MeetingAssigneeActionController(this._ref, this.query) {
    searchController.addListener(_onSearchChanged);
  }

  final Ref _ref;
  final MeetingTaskQuery query;
  final searchController = TextEditingController();
  Timer? _debounce;
  String search = '';
  bool isSubmitting = false;

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      search = searchController.text.trim();
      notifyListeners();
    });
  }

  Future<FormSubmitResult> assign(String employeeId) async {
    if (isSubmitting) return const FormSubmitIgnored();
    isSubmitting = true;
    notifyListeners();
    final keepAlive = _ref.keepAlive();
    try {
      final message = await _ref
          .read(meetingRepositoryProvider)
          .assignTask(
            meetingId: query.meetingId,
            taskId: query.taskId,
            employeeId: employeeId,
            companyId: _ref.read(meetingCompanyIdProvider),
          );
      await waitForServerRefresh();
      _ref.invalidate(meetingTasksProvider);
      _ref.invalidate(meetingTaskDetailProvider(query));
      return FormSubmitSuccess(message ?? 'Assignee berhasil diperbarui.');
    } finally {
      isSubmitting = false;
      notifyListeners();
      keepAlive.close();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }
}

class MeetingSelectedFile {
  const MeetingSelectedFile({
    required this.name,
    required this.path,
    required this.size,
  });

  final String name;
  final String path;
  final int size;

  MeetingFileUpload toUpload() => MeetingFileUpload(name: name, path: path);
}

Future<List<MeetingSelectedFile>> _pickFiles(BuildContext context) async {
  final selected = await UploadFilePicker.pick(context);
  final files = selected
      .where((file) => file.path != null && file.path!.isNotEmpty)
      .map(
        (file) => MeetingSelectedFile(
          name: file.name,
          path: file.path!,
          size: file.size,
        ),
      )
      .toList(growable: false);
  if (files.isEmpty && selected.isNotEmpty) {
    throw const AppException('File tidak dapat dibaca.');
  }
  return files;
}

String _joinError(String? current, String message) {
  if (current == null || current.isEmpty) return message;
  return '$current\n$message';
}
