import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/input_multiline_with_border.dart';
import '../../../../shared/widgets/selection_bottom_sheet.dart';
import '../../data/models/project_models.dart';
import '../../project_providers.dart';
import '../pages/detail/project_manpower_assignee_picker_page.dart';

class ProjectManpowerFormBottomSheet extends ConsumerStatefulWidget {
  const ProjectManpowerFormBottomSheet({
    required this.projectId,
    required this.taskId,
    required this.assignee,
    required this.maxTargetVolume,
    this.manpower,
    super.key,
  });

  final String projectId;
  final String taskId;
  final ProjectManpowerAssignee assignee;
  final double maxTargetVolume;
  final ProjectTaskManpower? manpower;

  static Future<String?> show(
    BuildContext context, {
    required String projectId,
    required String taskId,
    required ProjectManpowerAssignee assignee,
    required double maxTargetVolume,
    ProjectTaskManpower? manpower,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ProjectManpowerFormBottomSheet(
      projectId: projectId,
      taskId: taskId,
      assignee: assignee,
      maxTargetVolume: maxTargetVolume,
      manpower: manpower,
    ),
  );

  @override
  ConsumerState<ProjectManpowerFormBottomSheet> createState() =>
      _ProjectManpowerFormBottomSheetState();
}

class _ProjectManpowerFormBottomSheetState
    extends ConsumerState<ProjectManpowerFormBottomSheet> {
  static const _textStyle = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 14,
    height: 1.43,
    color: AppColors.ink,
  );
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _target;
  late final TextEditingController _note;
  final List<ProjectHelper> _helpers = [];
  bool _isSubmitting = false;
  String? _assigneeError;
  String? _targetError;
  String? _helpersError;
  String? _noteError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final manpower = widget.manpower;
    _target = TextEditingController(
      text: manpower == null ? '' : _formatTarget(manpower.targetVolume),
    );
    _note = TextEditingController(text: manpower?.note ?? '');
    _helpers.addAll([
      for (final helper in manpower?.helpers ?? <ProjectTaskManpowerPerson>[])
        ProjectHelper(id: helper.id, code: helper.code, name: helper.name),
    ]);
  }

  @override
  void dispose() {
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickHelper() async {
    FocusScope.of(context).unfocus();
    final helpersState = ref.read(projectHelpersProvider(widget.projectId));
    final helperOptions = helpersState.valueOrNull;
    if (helperOptions == null || helperOptions.isEmpty) return;
    final helper = await SelectionBottomSheet.show<ProjectHelper>(
      context,
      title: 'Pilih Helper',
      options: helperOptions,
      selectedOption: null,
      labelBuilder: (helper) =>
          _hasHelper(helper.id) ? '${helper.name} (dipilih)' : helper.name,
    );
    if (!mounted || helper == null || _hasHelper(helper.id)) return;
    setState(() {
      _helpers.add(helper);
      _helpersError = null;
      _formError = null;
    });
  }

  bool _hasHelper(String id) => _helpers.any((helper) => helper.id == id);

  Future<void> _save() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final target = double.parse(_target.text.trim().replaceAll(',', '.'));
    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(projectRepositoryProvider);
      final manpower = widget.manpower;
      final message = manpower != null
          ? await repository.updateTaskManpower(
              projectId: widget.projectId,
              taskId: widget.taskId,
              manpowerTaskId: manpower.id,
              employeeId: widget.assignee.id,
              target: target,
              helperEmployeeIds: _helpers.map((helper) => helper.id).toList(),
              note: _note.text.trim(),
            )
          : await repository.submitTaskManpower(
              projectId: widget.projectId,
              taskId: widget.taskId,
              employeeId: widget.assignee.id,
              target: target,
              helperEmployeeIds: _helpers
                  .map((helper) => helper.id)
                  .toList(growable: false),
              note: _note.text.trim(),
            );
      if (!mounted) return;
      Navigator.of(context).pop(
        message ??
            (manpower == null
                ? 'Manpower berhasil ditambahkan.'
                : 'Manpower berhasil diperbarui.'),
      );
    } catch (error) {
      if (!mounted) return;
      _applySubmitError(error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpersState = ref.watch(projectHelpersProvider(widget.projectId));
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.line),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: 'Lengkapi Data',
                  horizontalPadding: AppSpacing.md,
                  leading: const SizedBox(width: 40, height: 40),
                  leadingSize: 40,
                  titleSpacing: 0,
                  titleFontSize: 18,
                  titleHeight: 1.3,
                  titleFontWeight: FontWeight.w600,
                  titleWidget: const Text(
                    'Lengkapi Data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontFamily: AppFonts.inter,
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  actionWidgets: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        tooltip: 'Tutup',
                        padding: EdgeInsets.zero,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 32),
                        color: AppColors.dashboardTeal,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: widget.assignee.color,
                        child: Text(
                          widget.assignee.initials,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.assignee.name,
                          style: _textStyle.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_assigneeError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(_assigneeError!, style: _errorStyle),
                  ),
                const Divider(height: 1, color: AppColors.line),
                _field(
                  'Target',
                  TextFormField(
                    controller: _target,
                    style: _textStyle,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: 'Input Target',
                      hintStyle: _textStyle.copyWith(
                        color: const Color(0xFF67787C),
                      ),
                      suffixText: 'm³',
                      suffixStyle: _textStyle.copyWith(
                        color: const Color(0xFF67787C),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: const BorderSide(
                          color: AppColors.dashboardTeal,
                        ),
                      ),
                      errorText: _targetError,
                    ),
                    onChanged: (_) => _clearError(_ManpowerField.target),
                    validator: (value) {
                      if (_targetError != null) return _targetError;
                      final target = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      if (target == null || !target.isFinite || target <= 0) {
                        return 'Masukkan target lebih dari 0';
                      }
                      if (widget.maxTargetVolume > 0 &&
                          target > widget.maxTargetVolume) {
                        return 'Target maksimal ${_formatTarget(widget.maxTargetVolume)} m³';
                      }
                      return null;
                    },
                  ),
                ),
                _field(
                  'Helper',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: helpersState.valueOrNull?.isNotEmpty == true
                            ? _pickHelper
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  helpersState.when(
                                    loading: () => 'Memuat helper...',
                                    error: (_, _) => 'Gagal memuat helper',
                                    data: (helpers) => helpers.isEmpty
                                        ? 'Helper tidak tersedia'
                                        : 'Pilih Helper',
                                  ),
                                  style: _textStyle.copyWith(
                                    color: const Color(0xFF67787C),
                                  ),
                                ),
                              ),
                              if (helpersState.isLoading)
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else if (helpersState.hasError)
                                IconButton(
                                  tooltip: 'Muat ulang helper',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => ref.invalidate(
                                    projectHelpersProvider(widget.projectId),
                                  ),
                                  icon: const Icon(Icons.refresh, size: 22),
                                )
                              else
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.ink,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_helpers.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final helper in _helpers)
                              InputChip(
                                label: Text(helper.name),
                                labelStyle: _textStyle.copyWith(
                                  color: const Color(0xFF008638),
                                  fontSize: 12,
                                ),
                                backgroundColor: const Color(0xFFF0FDF4),
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                deleteIcon: const Icon(Icons.close, size: 16),
                                deleteButtonTooltipMessage:
                                    'Hapus ${helper.name}',
                                onDeleted: () => setState(() {
                                  _helpers.remove(helper);
                                  _helpersError = null;
                                  _formError = null;
                                }),
                              ),
                          ],
                        ),
                      ],
                      if (_helpersError != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(_helpersError!, style: _errorStyle),
                      ],
                    ],
                  ),
                ),
                _field(
                  'Catatan',
                  InputMultilineWithBorder(
                    controller: _note,
                    hintText: 'Type your message here.',
                    errorText: _noteError,
                    onChanged: (_) => _clearError(_ManpowerField.note),
                    height: 96,
                    borderColor: AppColors.line,
                    textStyle: _textStyle,
                    hintStyle: _textStyle.copyWith(
                      color: const Color(0xFF67787C),
                    ),
                  ),
                ),
                if (_formError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(_formError!, style: _errorStyle),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Batal',
                          variant: AppButtonVariant.outlined,
                          borderColor: AppColors.dashboardTeal,
                          textStyle: _textStyle.copyWith(
                            color: AppColors.dashboardTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: 'Simpan',
                          backgroundColor: AppColors.dashboardTeal,
                          textStyle: _textStyle.copyWith(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          isLoading: _isSubmitting,
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _textStyle.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );

  TextStyle get _errorStyle =>
      _textStyle.copyWith(color: AppColors.error, fontSize: 12);

  void _applySubmitError(Object error) {
    String? assigneeError;
    String? targetError;
    String? helpersError;
    String? noteError;
    final unmatchedMessages = <String>[];

    if (error case AppException(:final details)) {
      for (final detail in details) {
        final parsed = Validators.validationDetail(detail);
        if (parsed == null) {
          unmatchedMessages.add(detail);
          continue;
        }
        switch (parsed.field) {
          case 'employeeId':
          case 'employee_id':
            assigneeError = _joinError(assigneeError, parsed.message);
          case 'target':
          case 'targetVolume':
          case 'target_volume':
            targetError = _joinError(targetError, parsed.message);
          case 'helperEmployeeIds':
          case 'helper_employee_ids':
          case 'helpers':
            helpersError = _joinError(helpersError, parsed.message);
          case 'note':
            noteError = _joinError(noteError, parsed.message);
          default:
            unmatchedMessages.add(parsed.message);
        }
      }
      if (details.isEmpty) unmatchedMessages.add(error.message);
    } else {
      final message = error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Bad state: ', '')
          .trim();
      unmatchedMessages.add(
        message.isEmpty ? 'Manpower gagal ditambahkan.' : message,
      );
    }

    setState(() {
      _assigneeError = assigneeError;
      _targetError = targetError;
      _helpersError = helpersError;
      _noteError = noteError;
      _formError = unmatchedMessages.isEmpty
          ? null
          : unmatchedMessages.join('\n');
    });
  }

  void _clearError(_ManpowerField field) {
    if (!mounted) return;
    setState(() {
      switch (field) {
        case _ManpowerField.target:
          _targetError = null;
        case _ManpowerField.note:
          _noteError = null;
      }
      _formError = null;
    });
  }

  String _joinError(String? current, String next) =>
      current == null || current.isEmpty ? next : '$current\n$next';
}

enum _ManpowerField { target, note }

String _formatTarget(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString().replaceFirst(RegExp(r'0+$'), '');
}
