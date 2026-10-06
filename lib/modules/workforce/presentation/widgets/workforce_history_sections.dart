import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../data/models/attendance_list.dart';
import '../../data/models/leave.dart';
import '../../data/models/local_attendance_record.dart';
import '../../data/models/overtime.dart';

class AttendanceHistory extends StatelessWidget {
  const AttendanceHistory({
    super.key,
    required this.records,
    this.showEmptyState = true,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onLoadMore,
  });
  final List<AttendanceRecord> records;
  final bool showEmptyState;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final VoidCallback onLoadMore;
  @override
  Widget build(BuildContext context) {
    final sections = _byMonth(records, (item) => item.attendanceDate);
    return Column(
      children: [
        if (sections.isEmpty && showEmptyState)
          const SizedBox(
            height: 360,
            child: WorkforceHistoryEmptyState(
              title: 'Belum ada data presensi',
              message:
                  'Riwayat presensi belum tersedia.\nSilakan lakukan presensi terlebih dahulu.',
            ),
          ),
        for (final section in sections)
          _HistorySection(
            title: section.$1,
            children: [
              for (final item in section.$2)
                AttendanceHistoryTile(record: item),
            ],
          ),
        _LoadState(
          isLoading: isLoadingMore,
          error: loadMoreError,
          onRetry: onLoadMore,
        ),
      ],
    );
  }
}

class LocalAttendanceHistory extends StatelessWidget {
  const LocalAttendanceHistory({
    super.key,
    required this.records,
    required this.isOffline,
  });
  final List<LocalAttendanceRecord> records;
  final bool isOffline;
  @override
  Widget build(BuildContext context) => _HistorySection(
    title: 'Presensi lokal',
    children: [
      for (final item in records)
        _LocalAttendanceTile(record: item, isOffline: isOffline),
    ],
  );
}

class OvertimeHistory extends StatelessWidget {
  const OvertimeHistory({
    super.key,
    required this.records,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onLoadMore,
  });
  final List<OvertimeRecord> records;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final VoidCallback onLoadMore;
  @override
  Widget build(BuildContext context) {
    final sections = _byMonth(records, (item) => item.overtimeDate);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 104),
      children: [
        if (sections.isEmpty)
          const SizedBox(
            height: 360,
            child: WorkforceHistoryEmptyState(
              title: 'Belum ada data lembur',
              message:
                  'Riwayat lembur belum tersedia.\nSilakan ajukan lembur terlebih dahulu.',
            ),
          ),
        for (final section in sections)
          _HistorySection(
            title: section.$1,
            children: [
              for (final item in section.$2) OvertimeHistoryTile(record: item),
            ],
          ),
        _LoadState(
          isLoading: isLoadingMore,
          error: loadMoreError,
          onRetry: onLoadMore,
        ),
      ],
    );
  }
}

class LeaveHistory extends StatelessWidget {
  const LeaveHistory({
    super.key,
    required this.records,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onLoadMore,
  });
  final List<LeaveRecord> records;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final VoidCallback onLoadMore;
  @override
  Widget build(BuildContext context) {
    final sections = _byMonth(records, (item) => item.startDate);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 104),
      children: [
        if (sections.isEmpty)
          const SizedBox(
            height: 360,
            child: WorkforceHistoryEmptyState(
              title: 'Belum ada data cuti',
              message:
                  'Riwayat cuti belum tersedia.\nSilakan ajukan cuti terlebih dahulu.',
            ),
          ),
        for (final section in sections)
          _HistorySection(
            title: section.$1,
            children: [
              for (final item in section.$2) LeaveHistoryTile(record: item),
            ],
          ),
        _LoadState(
          isLoading: isLoadingMore,
          error: loadMoreError,
          onRetry: onLoadMore,
        ),
      ],
    );
  }
}

class WorkforceHistoryEmptyState extends StatelessWidget {
  const WorkforceHistoryEmptyState({
    super.key,
    required this.title,
    required this.message,
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AssetPaths.projectTaskEmpty, width: 128, height: 128),
        const SizedBox(height: 40),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.dashboardTeal,
            fontFamily: AppFonts.inter,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      ...children,
    ],
  );
}

class AttendanceHistoryTile extends StatelessWidget {
  const AttendanceHistoryTile({super.key, required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) => _HistoryTile(
    onTap: () =>
        context.push(RouteNames.workforceAttendanceDetail, extra: record.id),
    highlighted: record.adminNote?.trim().isNotEmpty ?? false,
    title: record.listDate,
    titleColor: record.checkIn != null && record.checkOut == null
        ? AppColors.workforceStatusInfo
        : AppColors.ink,
    details: _TimeRange(
      start: record.checkIn ?? '-',
      end: record.checkOut ?? '-',
    ),
    trailingTitle: record.locationType.isEmpty ? '-' : record.locationType,
    status: record.statusLabel,
    statusColor: _attendanceColor(record.status),
  );
}

class OvertimeHistoryTile extends StatelessWidget {
  const OvertimeHistoryTile({super.key, required this.record});
  final OvertimeRecord record;
  @override
  Widget build(BuildContext context) {
    final title = record.title?.trim().isNotEmpty == true
        ? record.title!
        : (record.reason?.trim().isNotEmpty == true ? record.reason! : '-');
    return _HistoryTile(
      minHeight: 100,
      onTap: () =>
          context.push(RouteNames.workforceOvertimeDetail, extra: record.id),
      highlighted: record.adminNote?.trim().isNotEmpty ?? false,
      title: title,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeRange(
            start: _clock(record.startTime),
            end: _clock(record.endTime),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(_shortDate(record.overtimeDate), style: _detailStyle),
        ],
      ),
      status: record.displayStatusLabel,
      statusColor: _requestColor(record.status),
    );
  }
}

class LeaveHistoryTile extends StatelessWidget {
  const LeaveHistoryTile({super.key, required this.record});
  final LeaveRecord record;
  @override
  Widget build(BuildContext context) => _HistoryTile(
    minHeight: 100,
    onTap: () =>
        context.push(RouteNames.workforceLeaveDetail, extra: record.id),
    highlighted: record.adminNote?.trim().isNotEmpty ?? false,
    title: record.title,
    details: _DateRange(
      start: _shortDate(record.startDate),
      end: _shortDate(record.endDate),
    ),
    status: record.statusLabel,
    statusColor: _requestColor(record.normalizedStatus),
  );
}

class _LocalAttendanceTile extends StatelessWidget {
  const _LocalAttendanceTile({required this.record, required this.isOffline});
  final LocalAttendanceRecord record;
  final bool isOffline;
  @override
  Widget build(BuildContext context) => _HistoryTile(
    highlighted: false,
    title: '${_shortDate(_dateParam(record.occurredAt))} - ${record.typeLabel}',
    titleColor: AppColors.workforceStatusInfo,
    details: _TimeRange(
      start: _localTime(record.checkInAt),
      end: _localTime(record.checkOutAt),
    ),
    trailingTitle: 'Lokal',
    trailingWidth: 104,
    status: isOffline ? 'Menunggu koneksi internet' : record.statusLabel,
    statusColor: _localColor(record.state, isOffline),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.highlighted,
    required this.title,
    required this.details,
    required this.status,
    required this.statusColor,
    this.onTap,
    this.trailingTitle,
    this.trailingWidth = 76,
    this.titleColor = AppColors.ink,
    this.minHeight = 76,
  });
  final bool highlighted;
  final String title, status;
  final Widget details;
  final Color statusColor, titleColor;
  final VoidCallback? onTap;
  final String? trailingTitle;
  final double trailingWidth;
  final double minHeight;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          crossAxisAlignment: minHeight > 76
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            _CalendarBadge(highlighted: highlighted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontFamily: AppFonts.geist,
                      fontSize: 14,
                      height: 1.43,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  details,
                  if (trailingTitle == null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontFamily: AppFonts.geist,
                        fontSize: 14,
                        height: 1.43,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingTitle != null) ...[
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: trailingWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trailingTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _detailStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: statusColor,
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TimeRange extends StatelessWidget {
  const _TimeRange({required this.start, required this.end});
  final String start, end;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Label('In', start),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Icon(
          Icons.arrow_forward,
          color: AppColors.workforceStatusInfo,
          size: 20,
        ),
      ),
      _Label('Out', end),
    ],
  );
}

class _DateRange extends StatelessWidget {
  const _DateRange({required this.start, required this.end});
  final String start, end;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(
          start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _detailStyle,
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Icon(
          Icons.arrow_forward,
          color: AppColors.workforceStatusInfo,
          size: 20,
        ),
      ),
      Flexible(
        child: Text(
          end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _detailStyle,
        ),
      ),
    ],
  );
}

class _Label extends StatelessWidget {
  const _Label(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) =>
      Text('$label  $value', style: _detailStyle);
}

const _detailStyle = TextStyle(
  color: AppColors.ink,
  fontFamily: AppFonts.inter,
  fontSize: 14,
  height: 1.43,
  fontWeight: FontWeight.w500,
);

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge({required this.highlighted});
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.workforceIconBackground,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.calendar_month_outlined,
          color: AppColors.workforceStatusInfo,
        ),
      ),
      if (highlighted)
        const Positioned(
          right: 0,
          top: -2,
          child: CircleAvatar(radius: 5, backgroundColor: AppColors.rose),
        ),
    ],
  );
}

class _LoadState extends StatelessWidget {
  const _LoadState({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => isLoading
      ? const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        )
      : error != null
      ? Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Gagal memuat data. Coba lagi'),
            ),
          ),
        )
      : const SizedBox.shrink();
}

List<(String, List<T>)> _byMonth<T>(List<T> records, String Function(T) date) {
  final output = <String, List<T>>{};
  for (final item in records) {
    output.putIfAbsent(_month(date(item)), () => []).add(item);
  }
  return output.entries.map((item) => (item.key, item.value)).toList();
}

String _month(String value) {
  final date = parseApiDateTime(value);
  if (date == null) return 'Tanggal tidak diketahui';
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _shortDate(String value) {
  final date = parseApiDateTime(value);
  if (date == null) return value.isEmpty ? '-' : value;
  const months = [
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _clock(String value) =>
    value.length >= 5 ? value.substring(0, 5) : (value.isEmpty ? '-' : value);
String _dateParam(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _localTime(DateTime? value) => value == null
    ? '-'
    : '${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
Color _attendanceColor(String value) => switch (value) {
  'present' || 'leave' => AppColors.green,
  'late' || 'absent' => AppColors.rose,
  'half_day' => AppColors.workforceStatusWarning,
  _ => AppColors.workforceStatusInfo,
};
Color _requestColor(String value) => switch (value) {
  'pending' => AppColors.pendingApproval,
  'approved' => AppColors.workforceStatusInfo,
  'done' => AppColors.green,
  'rejected' || 'cancelled' => AppColors.rose,
  _ => AppColors.workforceStatusInfo,
};
Color _localColor(OutboxState state, bool offline) => offline
    ? AppColors.workforceStatusWarning
    : switch (state) {
        OutboxState.pending ||
        OutboxState.processing ||
        OutboxState.retry => AppColors.workforceStatusWarning,
        OutboxState.failed ||
        OutboxState.conflict ||
        OutboxState.rejected => AppColors.rose,
        OutboxState.done => AppColors.green,
      };
