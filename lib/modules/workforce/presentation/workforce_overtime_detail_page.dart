import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/server_refresh_delay.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/overtime.dart';
import '../workforce_providers.dart';

class WorkforceOvertimeDetailPage extends ConsumerStatefulWidget {
  const WorkforceOvertimeDetailPage({required this.overtimeId, super.key});

  final String overtimeId;

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;

  @override
  ConsumerState<WorkforceOvertimeDetailPage> createState() =>
      _WorkforceOvertimeDetailPageState();
}

class _WorkforceOvertimeDetailPageState
    extends ConsumerState<WorkforceOvertimeDetailPage> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(overtimeDetailProvider(widget.overtimeId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Detail Lembur',
              onBackPressed: () => context.pop(),
            ),
            Expanded(child: _buildBody(detailState)),
            if (detailState.valueOrNull?.canCancel ?? false)
              SafeArea(
                top: false,
                child: _CancelActionBar(
                  isCancelling: _isCancelling,
                  onCancel: _isCancelling ? null : _cancelOvertime,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<OvertimeRecord> detailState) {
    return detailState.when(
      loading: () => const AppSkeletonDetailView(showHero: false),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'attendanceCacheRead',
        message: _errorMessage(error),
        onRetry: () =>
            ref.invalidate(overtimeDetailProvider(widget.overtimeId)),
      ),
      data: (record) {
        final detail = OvertimeDetailData.fromRecord(record);

        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(overtimeDetailProvider(widget.overtimeId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _OvertimeInfoSection(detail: detail),
              _ReasonSection(reason: detail.reason),
              _AdminNoteSection(note: detail.adminNote),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelOvertime() async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Apakah Anda yakin?',
      cancelLabel: 'Tidak',
      confirmLabel: 'Ya, batalkan',
    );

    if (!mounted || confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final message = await ref
          .read(workforceRepositoryProvider)
          .cancelOvertime(widget.overtimeId);
      await waitForServerRefresh();
      if (!mounted) return;

      ref.invalidate(overtimeListControllerProvider);
      ref.invalidate(overtimeDetailProvider(widget.overtimeId));
      AppToast.success(context, message ?? 'Pengajuan lembur dibatalkan.');
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is AppException) return error.message;
    final message = error.toString();
    return message.isEmpty ? 'Gagal memuat detail lembur.' : message;
  }
}

class _OvertimeInfoSection extends StatelessWidget {
  const _OvertimeInfoSection({required this.detail});

  final OvertimeDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Keterangan'),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Tanggal', value: detail.date),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailField(
                  label: 'Status',
                  value: detail.status,
                  valueColor: detail.statusColor,
                  valueFontFamily:
                      WorkforceOvertimeDetailPage._accentFontFamily,
                  valueFontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailField(label: 'Tipe lokasi', value: detail.locationType),
          const SizedBox(height: 20),
          _DetailField(label: 'Lokasi', value: detail.locationName),
          const SizedBox(height: 20),
          _DetailField(label: 'Project', value: detail.project),
          const SizedBox(height: 20),
          _DetailField(label: 'Total', value: detail.total),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Mulai', value: detail.startTime),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailField(label: 'Berakhir', value: detail.endTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Alasan'),
          const SizedBox(height: 20),
          Text(
            reason,
            style: const TextStyle(
              color: AppColors.muted,
              fontFamily: WorkforceOvertimeDetailPage._fontFamily,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNoteSection extends StatelessWidget {
  const _AdminNoteSection({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final noteText = note.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Catatan admin'),
          if (noteText.isEmpty) ...[
            const SizedBox(height: 16),
            CustomPaint(
              painter: const _DashedBorderPainter(),
              child: Container(
                height: 76,
                alignment: Alignment.center,
                child: const Text(
                  'Tidak ada catatan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontFamily: WorkforceOvertimeDetailPage._fontFamily,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              noteText,
              style: const TextStyle(
                color: AppColors.muted,
                fontFamily: WorkforceOvertimeDetailPage._fontFamily,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CancelActionBar extends StatelessWidget {
  const _CancelActionBar({required this.onCancel, required this.isCancelling});

  final VoidCallback? onCancel;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: AppButton(
        label: isCancelling ? 'Membatalkan...' : 'Batalkan',
        isLoading: isCancelling,
        variant: AppButtonVariant.danger,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.1),
        textStyle: const TextStyle(
          fontFamily: WorkforceOvertimeDetailPage._fontFamily,
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        onPressed: onCancel,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: WorkforceOvertimeDetailPage._fontFamily,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.muted,
    this.valueFontFamily = WorkforceOvertimeDetailPage._fontFamily,
    this.valueFontWeight = FontWeight.w400,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String valueFontFamily;
  final FontWeight valueFontWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: WorkforceOvertimeDetailPage._fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: valueFontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: valueFontWeight,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(8);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, radius));
    final paint = Paint()
      ..color = AppColors.inputBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 8).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OvertimeDetailData {
  const OvertimeDetailData({
    required this.date,
    required this.status,
    required this.statusColor,
    required this.locationType,
    required this.locationName,
    required this.project,
    required this.total,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.adminNote,
    required this.canCancel,
  });

  factory OvertimeDetailData.fallback() {
    return const OvertimeDetailData(
      date: '5 Juni 2026',
      status: 'Menunggu persetujuan',
      statusColor: AppColors.workforceStatusWarning,
      locationType: 'Warehouse',
      locationName: 'Warehouse A',
      project: 'Project A',
      total: '60 menit',
      startTime: '19:00',
      endTime: '20:00',
      reason:
          'In a laoreet purus. Integer turpis quam, laoreet id orci nec, ultrices lacinia nunc. Aliquam erat vo',
      adminNote: '',
      canCancel: true,
    );
  }

  factory OvertimeDetailData.fromRecord(OvertimeRecord record) {
    return OvertimeDetailData(
      date: formatIndonesianDate(record.overtimeDate),
      status: record.displayStatusLabel,
      statusColor: _statusColor(record.status),
      locationType: record.locationType.isEmpty ? '-' : record.locationType,
      locationName: record.location?.name ?? '-',
      project: record.project?.name ?? '-',
      total: _durationLabel(record.totalMinutes),
      startTime: _formatTime(record.startTime),
      endTime: _formatTime(record.endTime),
      reason: record.reason?.isNotEmpty == true ? record.reason! : '-',
      adminNote: record.adminNote ?? '',
      canCancel: record.canCancel,
    );
  }

  final String date;
  final String status;
  final Color statusColor;
  final String locationType;
  final String locationName;
  final String project;
  final String total;
  final String startTime;
  final String endTime;
  final String reason;
  final String adminNote;
  final bool canCancel;
}

Color _statusColor(String status) {
  return switch (status) {
    'pending' => AppColors.workforceStatusWarning,
    'approved' => AppColors.workforceStatusInfo,
    'done' => AppColors.green,
    'rejected' => AppColors.rose,
    'cancelled' => AppColors.rose,
    _ => AppColors.workforceStatusInfo,
  };
}

String _durationLabel(int totalMinutes) {
  if (totalMinutes <= 0) return '-';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes menit';
  if (minutes == 0) return '$hours jam';
  return '$hours jam $minutes menit';
}

String _formatTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value.isEmpty ? '-' : value;
}
