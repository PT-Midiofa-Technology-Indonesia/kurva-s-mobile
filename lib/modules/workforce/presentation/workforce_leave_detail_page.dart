import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/server_refresh_delay.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/leave.dart';
import '../workforce_providers.dart';

class WorkforceLeaveDetailPage extends ConsumerStatefulWidget {
  const WorkforceLeaveDetailPage({required this.leaveId, super.key});

  final String leaveId;

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;

  @override
  ConsumerState<WorkforceLeaveDetailPage> createState() =>
      _WorkforceLeaveDetailPageState();
}

class _WorkforceLeaveDetailPageState
    extends ConsumerState<WorkforceLeaveDetailPage> {
  var _isCancelling = false;

  Future<void> _cancelLeave() async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'Apakah Anda yakin?',
      cancelLabel: 'Tidak',
      confirmLabel: 'Ya, batalkan',
    );

    if (confirm != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final message = await ref
          .read(workforceRepositoryProvider)
          .cancelLeave(widget.leaveId);
      await waitForServerRefresh();
      if (!mounted) return;
      ref.invalidate(leaveListControllerProvider);
      ref.invalidate(leaveDetailProvider(widget.leaveId));

      AppToast.success(context, message ?? 'Pengajuan cuti dibatalkan.');
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(leaveDetailProvider(widget.leaveId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Detail Cuti', onBackPressed: () => context.pop()),
            Expanded(
              child: detailAsync.when(
                data: (record) {
                  final detail = LeaveDetailData.fromRecord(record);
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(leaveDetailProvider(widget.leaveId).future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _LeaveInfoSection(detail: detail),
                        _AdminNoteSection(note: detail.adminNote),
                      ],
                    ),
                  );
                },
                loading: () => const AppSkeletonDetailView(showHero: false),
                error: (error, _) => NetworkAwareErrorView(
                  error: error,
                  message: _errorMessage(error),
                  onRetry: () =>
                      ref.invalidate(leaveDetailProvider(widget.leaveId)),
                ),
              ),
            ),
            detailAsync.maybeWhen(
              data: (record) {
                if (!record.canCancel) return const SizedBox.shrink();
                return SafeArea(
                  top: false,
                  child: _CancelActionBar(
                    isLoading: _isCancelling,
                    onCancel: _isCancelling ? null : _cancelLeave,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message.isEmpty ? 'Gagal memuat detail cuti.' : message;
  }
}

class _LeaveInfoSection extends StatelessWidget {
  const _LeaveInfoSection({required this.detail});

  final LeaveDetailData detail;

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
          _DetailField(
            label: 'Status',
            value: detail.status,
            valueColor: detail.statusColor,
            valueFontFamily: WorkforceLeaveDetailPage._accentFontFamily,
            valueFontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 20),
          _DetailField(label: 'Keperluan cuti', value: detail.purpose),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Tanggal mulai',
                  value: detail.startDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailField(
                  label: 'Tanggal berakhir',
                  value: detail.endDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Durasi', value: detail.duration),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(label: 'Kuota', value: detail.quota),
              ),
            ],
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
                    fontFamily: WorkforceLeaveDetailPage._fontFamily,
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
                fontFamily: WorkforceLeaveDetailPage._fontFamily,
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
  const _CancelActionBar({required this.onCancel, required this.isLoading});

  final VoidCallback? onCancel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: AppButton(
        label: isLoading ? 'Membatalkan...' : 'Batalkan',
        isLoading: isLoading,
        variant: AppButtonVariant.danger,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.1),
        textStyle: const TextStyle(
          fontFamily: WorkforceLeaveDetailPage._fontFamily,
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
        fontFamily: WorkforceLeaveDetailPage._fontFamily,
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
    this.valueFontFamily = WorkforceLeaveDetailPage._fontFamily,
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
            fontFamily: WorkforceLeaveDetailPage._fontFamily,
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

class LeaveDetailData {
  const LeaveDetailData({
    required this.status,
    required this.statusColor,
    required this.purpose,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.quota,
    required this.adminNote,
    required this.canCancel,
  });

  factory LeaveDetailData.fallback() {
    return const LeaveDetailData(
      status: 'Menunggu persetujuan',
      statusColor: AppColors.pendingApproval,
      purpose: 'Pulang kampung',
      startDate: '20 Jun 2026',
      endDate: '23 Jun 2026',
      duration: '3 hari',
      quota: '8 hari',
      adminNote: '',
      canCancel: true,
    );
  }

  factory LeaveDetailData.fromRecord(LeaveRecord record) {
    return LeaveDetailData(
      status: record.statusLabel,
      statusColor: _leaveStatusColor(record.normalizedStatus),
      purpose: record.title.isEmpty ? '-' : record.title,
      startDate: _formatDisplayDate(record.startDate),
      endDate: _formatDisplayDate(record.endDate),
      duration: record.totalDays > 0 ? '${record.totalDays} hari' : '-',
      quota: record.balance == null ? '-' : '${record.balance!.remaining} hari',
      adminNote: record.adminNote ?? '',
      canCancel: record.canCancel,
    );
  }

  final String status;
  final Color statusColor;
  final String purpose;
  final String startDate;
  final String endDate;
  final String duration;
  final String quota;
  final String adminNote;
  final bool canCancel;
}

Color _leaveStatusColor(String status) {
  return switch (status) {
    'pending' => AppColors.pendingApproval,
    'approved' => AppColors.workforceStatusInfo,
    'done' => AppColors.green,
    'rejected' => AppColors.rose,
    'cancelled' => AppColors.rose,
    _ => AppColors.workforceStatusInfo,
  };
}

String _formatDisplayDate(String value) {
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
