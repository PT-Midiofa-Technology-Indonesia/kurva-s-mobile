import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../modules/project/data/models/project_models.dart';
import '../../../modules/project/project_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/input_picker_field.dart';
import '../../../shared/widgets/input_multiline_text_field.dart';
import '../../../shared/widgets/searchable_selection_bottom_sheet.dart';
import '../../../shared/widgets/selection_bottom_sheet.dart';
import '../../../shared/forms/form_submit_result.dart';
import '../data/models/location.dart';
import '../workforce_providers.dart';
import 'workforce_request_form_controllers.dart';

class WorkforceOvertimeRequestPage extends ConsumerStatefulWidget {
  const WorkforceOvertimeRequestPage({super.key});

  static const _fontFamily = AppFonts.inter;

  @override
  ConsumerState<WorkforceOvertimeRequestPage> createState() =>
      _WorkforceOvertimeRequestPageState();
}

class _WorkforceOvertimeRequestPageState
    extends ConsumerState<WorkforceOvertimeRequestPage> {
  final _dateKey = GlobalKey();
  final _startTimeKey = GlobalKey();
  final _endTimeKey = GlobalKey();
  final _locationTypeKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _reasonKey = GlobalKey();
  bool _isLoadingLocations = false;
  bool _isLoadingProjects = false;
  List<WorkforceLocation>? _locations;
  int _locationRequestGeneration = 0;
  String? _locationLoadError;
  String? _projectLoadError;

  OvertimeRequestFormController get _form =>
      ref.read(overtimeRequestFormControllerProvider);

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _form.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    _form.setDate(pickedDate);
  }

  Future<void> _pickStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _form.startTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime == null || !mounted) return;

    _form.setStartTime(pickedTime);
  }

  Future<void> _pickEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _form.endTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime == null || !mounted) return;

    _form.setEndTime(pickedTime);
  }

  Future<void> _pickLocationType() async {
    final selectedLocationType = await SelectionBottomSheet.show<String>(
      context,
      title: 'Pilih Tipe Lokasi',
      options: OvertimeRequestFormController.locationTypes,
      selectedOption: _form.selectedLocationType,
      labelBuilder: (locationType) => locationType,
    );

    if (selectedLocationType == null || !mounted) return;

    if (selectedLocationType == _form.selectedLocationType) {
      if (_locations == null && !_isLoadingLocations) {
        unawaited(_loadLocations(selectedLocationType));
      }
      return;
    }

    _form.setLocationType(selectedLocationType);
    unawaited(_loadLocations(selectedLocationType));
  }

  Future<void> _pickLocation() async {
    if (_isLoadingLocations) return;
    if (_form.selectedLocationType.isEmpty) {
      _showToast('Pilih tipe lokasi terlebih dahulu.', type: AppToastType.info);
      return;
    }

    final locations =
        _locations ?? await _loadLocations(_form.selectedLocationType);
    if (!mounted || locations == null) return;

    final selectedLocation =
        await SearchableSelectionBottomSheet.show<WorkforceLocation>(
          context,
          title: 'Pilih Lokasi',
          options: locations,
          selectedOption: _form.selectedLocation,
          labelBuilder: (location) => location.name,
        );

    if (selectedLocation == null || !mounted) return;

    _form.setLocation(selectedLocation);
    setState(() => _locationLoadError = null);
  }

  Future<void> _pickProject() async {
    if (_isLoadingProjects) return;
    final projects = await _loadProjects();
    if (!mounted || projects == null) return;

    final selectedProject = await SearchableSelectionBottomSheet.show<Project>(
      context,
      title: 'Pilih Proyek',
      options: projects,
      selectedOption: _form.selectedProject,
      labelBuilder: (project) => project.name,
    );

    if (selectedProject == null || !mounted) return;

    _form.setProject(selectedProject);
    setState(() => _projectLoadError = null);
  }

  Future<List<WorkforceLocation>?> _loadLocations(String requestedType) async {
    final requestGeneration = ++_locationRequestGeneration;
    final shouldRetry = _locationLoadError != null;
    setState(() {
      _isLoadingLocations = true;
      _locations = null;
      _locationLoadError = null;
    });
    if (shouldRetry) ref.invalidate(locationListProvider(requestedType));
    try {
      final locations = await ref.read(
        locationListProvider(requestedType).future,
      );
      if (!mounted ||
          requestGeneration != _locationRequestGeneration ||
          _form.selectedLocationType != requestedType) {
        return null;
      }

      if (locations.isEmpty) {
        setState(() => _locationLoadError = 'Lokasi tidak tersedia.');
        return null;
      }

      setState(() => _locations = locations);
      return locations;
    } catch (error) {
      if (!mounted ||
          requestGeneration != _locationRequestGeneration ||
          _form.selectedLocationType != requestedType) {
        return null;
      }
      setState(() => _locationLoadError = _errorMessage(error));
      return null;
    } finally {
      if (mounted && requestGeneration == _locationRequestGeneration) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<List<Project>?> _loadProjects() async {
    final shouldRetry = _projectLoadError != null;
    setState(() {
      _isLoadingProjects = true;
      _projectLoadError = null;
    });
    if (shouldRetry) ref.invalidate(projectListProvider);
    try {
      final result = await ref.read(projectListProvider.future);
      if (!mounted) return null;

      if (result.result.projects.isEmpty) {
        setState(() => _projectLoadError = 'Proyek tidak tersedia.');
        return null;
      }

      return result.result.projects;
    } catch (error) {
      if (!mounted) return null;
      setState(() => _projectLoadError = _errorMessage(error));
      return null;
    } finally {
      if (mounted) setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _submit() async {
    try {
      final result = await _form.submit();
      if (!mounted) return;
      if (result case FormSubmitInvalid(:final message)) {
        if (message != null) {
          _showToast(message, type: AppToastType.warning);
        }
        _scrollToFirstInvalid();
        return;
      }
      if (result case FormSubmitSuccess(:final message)) {
        _showToast(message, type: AppToastType.success);
        context.pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      if (error case AppException(hasErrors: true)) return;
      _showToast(_errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(overtimeRequestFormControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Pengajuan Lembur',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  KeyedSubtree(
                    key: _dateKey,
                    child: InputPickerField(
                      label: 'Tanggal',
                      value: controller.dateValue,
                      isRequired: true,
                      errorText: controller.dateError,
                      onTap: _pickDate,
                    ),
                  ),
                  KeyedSubtree(
                    key: _startTimeKey,
                    child: InputPickerField(
                      label: 'Mulai',
                      value: controller.startTimeValue,
                      isRequired: true,
                      errorText: controller.startTimeError,
                      onTap: _pickStartTime,
                    ),
                  ),
                  KeyedSubtree(
                    key: _endTimeKey,
                    child: InputPickerField(
                      label: 'Berakhir',
                      value: controller.endTimeValue,
                      isRequired: true,
                      errorText: controller.endTimeError,
                      onTap: _pickEndTime,
                    ),
                  ),
                  KeyedSubtree(
                    key: _locationTypeKey,
                    child: InputPickerField(
                      label: 'Pilih tipe lokasi',
                      value: controller.selectedLocationType,
                      isRequired: true,
                      errorText: controller.locationTypeError,
                      onTap: _pickLocationType,
                    ),
                  ),
                  KeyedSubtree(
                    key: _locationKey,
                    child: InputPickerField(
                      label: 'Pilih lokasi',
                      value: controller.locationValue,
                      isRequired: true,
                      isLoading: _isLoadingLocations,
                      loadingText: 'Memuat lokasi...',
                      errorText: _locationLoadError ?? controller.locationError,
                      onTap: _pickLocation,
                    ),
                  ),
                  InputPickerField(
                    label: 'Pilih proyek',
                    value: controller.projectValue,
                    isLoading: _isLoadingProjects,
                    loadingText: 'Memuat proyek...',
                    errorText: _projectLoadError,
                    onTap: _pickProject,
                  ),
                  KeyedSubtree(
                    key: _reasonKey,
                    child: InputMultilineTextField(
                      label: 'Alasan lembur',
                      controller: controller.reasonController,
                      isRequired: true,
                      errorText: controller.reasonError,
                    ),
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

  void _showToast(String message, {AppToastType type = AppToastType.error}) {
    AppToast.show(context, message: message, type: type);
  }

  void _scrollToFirstInvalid() {
    final form = _form;
    final key = form.dateError != null
        ? _dateKey
        : form.startTimeError != null
        ? _startTimeKey
        : form.endTimeError != null
        ? _endTimeKey
        : form.locationTypeError != null
        ? _locationTypeKey
        : form.locationError != null
        ? _locationKey
        : form.reasonError != null
        ? _reasonKey
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

  String _errorMessage(Object error) {
    if (error is AppException) return error.message;
    final message = error.toString();
    return message.isEmpty ? 'Pengajuan lembur gagal. Coba lagi.' : message;
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
        label: isSubmitting ? 'Mengirim...' : 'Ajukan lembur',
        isLoading: isSubmitting,
        backgroundColor: AppColors.dashboardTeal,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.1),
        textStyle: const TextStyle(
          fontFamily: WorkforceOvertimeRequestPage._fontFamily,
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
