import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/models/attendance_list.dart';
import '../workforce_providers.dart';
import 'package:curva_mobile/shared/widgets/offline_image.dart';

class WorkforceAttendanceDetailPage extends ConsumerWidget {
  const WorkforceAttendanceDetailPage({required this.attendanceId, super.key});

  final String attendanceId;

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = attendanceId.isEmpty
        ? null
        : ref.watch(attendanceDetailProvider(attendanceId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Presensi', onBackPressed: () => context.pop()),
            Expanded(
              child:
                  detailState?.when(
                    loading: () => const AppSkeletonDetailView(),
                    error: (error, _) => NetworkAwareErrorView(
                      error: error,
                      cacheFeatureKey: 'attendanceCacheRead',
                      message: _errorMessage(error),
                      onRetry: () => ref.invalidate(
                        attendanceDetailProvider(attendanceId),
                      ),
                    ),
                    data: (record) => _DetailContent(
                      detail: record.toDetailData(),
                      onRefresh: () => ref
                          .refresh(
                            attendanceDetailProvider(attendanceId).future,
                          )
                          .then<void>((_) {}),
                    ),
                  ) ??
                  const ErrorView(message: 'Data presensi tidak valid.'),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message.isEmpty ? 'Gagal memuat detail presensi.' : message;
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail, required this.onRefresh});

  final AttendanceDetailData detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _DetailTimeHero(detail: detail),
          _DetailInfoSection(detail: detail),
          _AdminNoteSection(note: detail.adminNote),
          _SelfieSection(detail: detail),
        ],
      ),
    );
  }
}

class _DetailTimeHero extends StatelessWidget {
  const _DetailTimeHero({required this.detail});

  final AttendanceDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 166,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.workforceHeroStart, AppColors.workforceHeroEnd],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimeSummary(label: 'Check in', value: detail.inTime),
          ),
          Expanded(
            child: _TimeSummary(label: 'Check out', value: detail.outTime),
          ),
        ],
      ),
    );
  }
}

class _TimeSummary extends StatelessWidget {
  const _TimeSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: WorkforceAttendanceDetailPage._fontFamily,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: WorkforceAttendanceDetailPage._accentFontFamily,
            fontSize: 36,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DetailInfoSection extends StatelessWidget {
  const _DetailInfoSection({required this.detail});

  final AttendanceDetailData detail;

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
              Expanded(
                child: _DetailField(
                  label: 'Status',
                  value: detail.status,
                  valueColor: detail.statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailField(label: 'Tipe Lokasi', value: detail.locationType),
          const SizedBox(height: 24),
          _DetailField(label: 'Lokasi', value: detail.locationName),
          const SizedBox(height: 24),
          _DetailField(label: 'Project', value: detail.project),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Terlambat', value: detail.late),
              ),
              Expanded(
                child: _DetailField(
                  label: 'Pulang awal',
                  value: detail.earlyLeave,
                ),
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
                    fontFamily: WorkforceAttendanceDetailPage._fontFamily,
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
                fontFamily: WorkforceAttendanceDetailPage._fontFamily,
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

class _SelfieSection extends StatelessWidget {
  const _SelfieSection({required this.detail});

  final AttendanceDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Selfie'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SelfieItem(
                  label: 'Check in',
                  value: detail.inTime,
                  imageUrl: detail.checkInSelfieUrl,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SelfieItem(
                  label: 'Check out',
                  value: detail.outTime,
                  imageUrl: detail.checkOutSelfieUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelfieItem extends StatelessWidget {
  const _SelfieItem({
    required this.label,
    required this.value,
    required this.imageUrl,
  });

  final String label;
  final String value;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _SelfieImage(imageUrl: imageUrl),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: WorkforceAttendanceDetailPage._fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontFamily: WorkforceAttendanceDetailPage._fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelfieImage extends StatelessWidget {
  const _SelfieImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const _SelfiePlaceholder();
    }

    return OfflineImage(
      url,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _SelfiePlaceholder(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const _SelfiePlaceholder(),
    );
  }
}

class _SelfiePlaceholder extends StatelessWidget {
  const _SelfiePlaceholder({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.cardBackground,
      alignment: Alignment.center,
      child:
          child ??
          Image.asset(
            AssetPaths.noImage,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
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
        fontFamily: WorkforceAttendanceDetailPage._fontFamily,
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
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: WorkforceAttendanceDetailPage._fontFamily,
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
            fontFamily: WorkforceAttendanceDetailPage._fontFamily,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
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

class AttendanceDetailData {
  const AttendanceDetailData({
    required this.date,
    required this.locationType,
    required this.locationName,
    required this.project,
    required this.inTime,
    required this.outTime,
    required this.status,
    required this.statusColor,
    required this.late,
    required this.earlyLeave,
    required this.adminNote,
    required this.checkInSelfieUrl,
    required this.checkOutSelfieUrl,
  });

  factory AttendanceDetailData.fallback() {
    return const AttendanceDetailData(
      date: '5 Jun 2026',
      locationType: 'Warehouse',
      locationName: 'Warehouse A',
      project: 'Project A',
      inTime: '8:05',
      outTime: '17:35',
      status: 'Hadir',
      statusColor: AppColors.workforceStatusInfo,
      late: '5 Menit',
      earlyLeave: '0 Menit',
      adminNote:
          'In a laoreet purus. Integer turpis quam, laoreet id orci nec, ultrices lacinia nunc. Aliquam erat vo',
      checkInSelfieUrl: null,
      checkOutSelfieUrl: null,
    );
  }

  final String date;
  final String locationType;
  final String locationName;
  final String project;
  final String inTime;
  final String outTime;
  final String status;
  final Color statusColor;
  final String late;
  final String earlyLeave;
  final String adminNote;
  final String? checkInSelfieUrl;
  final String? checkOutSelfieUrl;
}

extension _AttendanceRecordDetail on AttendanceRecord {
  AttendanceDetailData toDetailData() {
    return AttendanceDetailData(
      date: formatIndonesianDate(attendanceDate),
      locationType: locationType.isEmpty ? '-' : locationType,
      locationName: location?.name.isNotEmpty == true ? location!.name : '-',
      project: project?.name.isNotEmpty == true ? project!.name : '-',
      inTime: _trimLeadingZero(checkIn ?? '-'),
      outTime: _trimLeadingZero(checkOut ?? '-'),
      status: statusLabel,
      statusColor: _statusColor,
      late: '$lateMinutes Menit',
      earlyLeave: '$earlyLeaveMinutes Menit',
      adminNote: adminNote ?? '',
      checkInSelfieUrl: selfies?.checkIn,
      checkOutSelfieUrl: selfies?.checkOut,
    );
  }

  Color get _statusColor {
    return switch (status) {
      'present' => AppColors.green,
      'late' => AppColors.rose,
      'absent' => AppColors.rose,
      'leave' => AppColors.green,
      'day_off' => AppColors.workforceStatusInfo,
      'half_day' => AppColors.workforceStatusWarning,
      _ => AppColors.workforceStatusInfo,
    };
  }

  String _trimLeadingZero(String value) {
    if (value.length >= 2 && value.startsWith('0')) {
      return value.substring(1);
    }

    return value;
  }
}
