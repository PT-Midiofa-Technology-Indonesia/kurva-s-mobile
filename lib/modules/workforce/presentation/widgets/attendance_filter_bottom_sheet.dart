import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/selection_bottom_sheet.dart';
import '../../data/models/attendance_list.dart';
import '../../data/models/leave.dart';
import '../../data/models/overtime.dart';

class AttendanceFilterBottomSheet extends StatefulWidget {
  const AttendanceFilterBottomSheet({required this.initialFilter, super.key});

  final AttendanceListFilter initialFilter;

  static Future<AttendanceListFilter?> show(
    BuildContext context, {
    required AttendanceListFilter initialFilter,
  }) {
    return showModalBottomSheet<AttendanceListFilter>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) =>
          AttendanceFilterBottomSheet(initialFilter: initialFilter),
    );
  }

  @override
  State<AttendanceFilterBottomSheet> createState() =>
      _AttendanceFilterBottomSheetState();
}

class _AttendanceFilterBottomSheetState
    extends State<AttendanceFilterBottomSheet> {
  static const _statuses = [
    _FilterOption(label: 'Hadir', value: 'present'),
    _FilterOption(label: 'Terlambat', value: 'late'),
    _FilterOption(label: 'Cuti', value: 'leave'),
  ];
  static const _locations = [
    _FilterOption(label: 'Office', value: 'Office'),
    _FilterOption(label: 'Warehouse', value: 'Warehouse'),
  ];

  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedYear;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter.status;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedYear = widget.initialFilter.year;
    _selectedLocation = widget.initialFilter.locationType;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Gunakan Filter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontFamily: AppFonts.inter,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: 'Tutup',
                      padding: EdgeInsets.zero,
                      color: AppColors.dashboardTeal,
                      icon: const Icon(Icons.close, size: 36),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      title: 'Status',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final status in _statuses)
                            _FilterChip(
                              label: status.label,
                              selected: _selectedStatus == status.value,
                              onPressed: () {
                                setState(() {
                                  _selectedStatus =
                                      _selectedStatus == status.value
                                      ? null
                                      : status.value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      title: 'Periode',
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterField(
                              label:
                                  formatFilterDate(_startDate) ??
                                  'Dari tanggal',
                              selected: _startDate != null,
                              onPressed: _pickStartDate,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                            child: Divider(
                              color: AppColors.inputBorder,
                              thickness: 1,
                            ),
                          ),
                          Expanded(
                            child: _FilterField(
                              label:
                                  formatFilterDate(_endDate) ??
                                  'Sampai tanggal',
                              selected: _endDate != null,
                              onPressed: _pickEndDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      title: 'Tahun',
                      child: _FilterField(
                        label: _selectedYear?.toString() ?? 'Pilih tahun',
                        selected: _selectedYear != null,
                        borderColor: AppColors.inputBorder,
                        onPressed: () async {
                          final selectedYear = await _showYearSelection(
                            context,
                            selectedYear: _selectedYear,
                          );

                          if (!mounted || selectedYear == null) return;

                          setState(() {
                            _selectedYear = _selectedYear == selectedYear
                                ? null
                                : selectedYear;
                          });
                        },
                      ),
                    ),
                    _FilterSection(
                      title: 'Tipe lokasi',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final location in _locations)
                            _FilterChip(
                              label: location.label,
                              selected: _selectedLocation == location.value,
                              onPressed: () {
                                setState(() {
                                  _selectedLocation =
                                      _selectedLocation == location.value
                                      ? null
                                      : location.value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + bottomPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dashboardTeal,
                          side: const BorderSide(
                            color: AppColors.dashboardTeal,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedStatus = null;
                            _startDate = null;
                            _endDate = null;
                            _selectedLocation = null;
                            _selectedYear = null;
                          });
                        },
                        child: const Text('Atur ulang'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Terapkan',
                      backgroundColor: AppColors.dashboardTeal,
                      textStyle: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        AttendanceListFilter(
                          status: _selectedStatus,
                          startDate: _startDate,
                          endDate: _endDate,
                          year: _selectedYear,
                          locationType: _selectedLocation,
                          perPage: widget.initialFilter.perPage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _startDate = pickedDate;
      if (_endDate != null && _endDate!.isBefore(pickedDate)) {
        _endDate = pickedDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() => _endDate = pickedDate);
  }
}

class OvertimeFilterBottomSheet extends StatefulWidget {
  const OvertimeFilterBottomSheet({required this.initialFilter, super.key});

  final OvertimeListFilter initialFilter;

  static Future<OvertimeListFilter?> show(
    BuildContext context, {
    required OvertimeListFilter initialFilter,
  }) {
    return showModalBottomSheet<OvertimeListFilter>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) =>
          OvertimeFilterBottomSheet(initialFilter: initialFilter),
    );
  }

  @override
  State<OvertimeFilterBottomSheet> createState() =>
      _OvertimeFilterBottomSheetState();
}

class _OvertimeFilterBottomSheetState extends State<OvertimeFilterBottomSheet> {
  static const _statuses = [
    _FilterOption(label: 'Menunggu persetujuan', value: 'pending'),
    _FilterOption(label: 'Disetujui', value: 'approved'),
    _FilterOption(label: 'Ditolak', value: 'rejected'),
    _FilterOption(label: 'Dibatalkan', value: 'cancelled'),
  ];

  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter.status;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedYear = widget.initialFilter.year;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Gunakan Filter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontFamily: AppFonts.inter,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: 'Tutup',
                      padding: EdgeInsets.zero,
                      color: AppColors.dashboardTeal,
                      icon: const Icon(Icons.close, size: 36),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      title: 'Status',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final status in _statuses)
                            _FilterChip(
                              label: status.label,
                              selected: _selectedStatus == status.value,
                              onPressed: () {
                                setState(() {
                                  _selectedStatus =
                                      _selectedStatus == status.value
                                      ? null
                                      : status.value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      title: 'Periode',
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterField(
                              label:
                                  formatFilterDate(_startDate) ??
                                  'Dari tanggal',
                              selected: _startDate != null,
                              onPressed: _pickStartDate,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                            child: Divider(
                              color: AppColors.inputBorder,
                              thickness: 1,
                            ),
                          ),
                          Expanded(
                            child: _FilterField(
                              label:
                                  formatFilterDate(_endDate) ??
                                  'Sampai tanggal',
                              selected: _endDate != null,
                              onPressed: _pickEndDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      title: 'Tahun',
                      child: _FilterField(
                        label: _selectedYear?.toString() ?? 'Pilih tahun',
                        selected: _selectedYear != null,
                        borderColor: AppColors.inputBorder,
                        onPressed: () async {
                          final selectedYear = await _showYearSelection(
                            context,
                            selectedYear: _selectedYear,
                          );

                          if (!mounted || selectedYear == null) return;

                          setState(() {
                            _selectedYear = _selectedYear == selectedYear
                                ? null
                                : selectedYear;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + bottomPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dashboardTeal,
                        side: const BorderSide(
                          color: AppColors.dashboardTeal,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _startDate = null;
                          _endDate = null;
                          _selectedYear = null;
                        });
                      },
                      child: const Text('Atur ulang'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Terapkan',
                      backgroundColor: AppColors.dashboardTeal,
                      textStyle: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        OvertimeListFilter(
                          status: _selectedStatus,
                          startDate: _startDate,
                          endDate: _endDate,
                          year: _selectedYear,
                          perPage: widget.initialFilter.perPage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _startDate = pickedDate;
      if (_endDate != null && _endDate!.isBefore(pickedDate)) {
        _endDate = pickedDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() => _endDate = pickedDate);
  }
}

class LeaveFilterBottomSheet extends StatefulWidget {
  const LeaveFilterBottomSheet({required this.initialFilter, super.key});

  final LeaveListFilter initialFilter;

  static Future<LeaveListFilter?> show(
    BuildContext context, {
    required LeaveListFilter initialFilter,
  }) {
    return showModalBottomSheet<LeaveListFilter>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) =>
          LeaveFilterBottomSheet(initialFilter: initialFilter),
    );
  }

  @override
  State<LeaveFilterBottomSheet> createState() => _LeaveFilterBottomSheetState();
}

class _LeaveFilterBottomSheetState extends State<LeaveFilterBottomSheet> {
  static const _statuses = [
    _FilterOption(label: 'Menunggu persetujuan', value: 'pending'),
    _FilterOption(label: 'Disetujui', value: 'approved'),
    _FilterOption(label: 'Ditolak', value: 'rejected'),
    _FilterOption(label: 'Dibatalkan', value: 'cancelled'),
    _FilterOption(label: 'Selesai', value: 'done'),
  ];

  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter.status;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedYear = widget.initialFilter.year;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Gunakan Filter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontFamily: AppFonts.inter,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: 'Tutup',
                      padding: EdgeInsets.zero,
                      color: AppColors.dashboardTeal,
                      icon: const Icon(Icons.close, size: 36),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      title: 'Status',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final status in _statuses)
                            _FilterChip(
                              label: status.label,
                              selected: _selectedStatus == status.value,
                              onPressed: () {
                                setState(() {
                                  _selectedStatus =
                                      _selectedStatus == status.value
                                      ? null
                                      : status.value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      title: 'Periode',
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterField(
                              label:
                                  formatFilterDate(_startDate) ??
                                  'Dari tanggal',
                              selected: _startDate != null,
                              onPressed: _pickStartDate,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                            child: Divider(
                              color: AppColors.inputBorder,
                              thickness: 1,
                            ),
                          ),
                          Expanded(
                            child: _FilterField(
                              label:
                                  formatFilterDate(_endDate) ??
                                  'Sampai tanggal',
                              selected: _endDate != null,
                              onPressed: _pickEndDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _FilterSection(
                      title: 'Tahun',
                      child: _FilterField(
                        label: _selectedYear?.toString() ?? 'Pilih tahun',
                        selected: _selectedYear != null,
                        borderColor: AppColors.inputBorder,
                        onPressed: () async {
                          final selectedYear = await _showYearSelection(
                            context,
                            selectedYear: _selectedYear,
                          );

                          if (!mounted || selectedYear == null) return;

                          setState(() {
                            _selectedYear = _selectedYear == selectedYear
                                ? null
                                : selectedYear;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + bottomPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dashboardTeal,
                        side: const BorderSide(
                          color: AppColors.dashboardTeal,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _startDate = null;
                          _endDate = null;
                          _selectedYear = null;
                        });
                      },
                      child: const Text('Atur ulang'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Terapkan',
                      backgroundColor: AppColors.dashboardTeal,
                      textStyle: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        LeaveListFilter(
                          status: _selectedStatus,
                          startDate: _startDate,
                          endDate: _endDate,
                          year: _selectedYear,
                          perPage: widget.initialFilter.perPage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _startDate = pickedDate;
      if (_endDate != null && _endDate!.isBefore(pickedDate)) {
        _endDate = pickedDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() => _endDate = pickedDate);
  }
}

class _FilterOption {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final String value;
}

Future<int?> _showYearSelection(
  BuildContext context, {
  required int? selectedYear,
}) {
  return SelectionBottomSheet.show<int>(
    context,
    title: 'Pilih tahun',
    options: _yearOptions(),
    selectedOption: selectedYear,
    labelBuilder: (year) => year.toString(),
  );
}

List<int> _yearOptions() {
  final currentYear = DateTime.now().year;
  return [for (var year = currentYear; year >= currentYear - 4; year--) year];
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.inter,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    if (!selected) {
      return Material(
        color: AppColors.cardBackground,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: _FilterLabel(label: label),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.white,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dashboardTeal),
            borderRadius: borderRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.dashboardTeal,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _FilterLabel(label: label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: AppFonts.inter,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    this.selected = false,
    this.borderColor,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  borderColor ??
                  (selected ? AppColors.dashboardTeal : AppColors.inputBorder),
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.ink : AppColors.inputBorder,
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.ink,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
