import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({required this.detail, super.key});

  final ProjectDetailData detail;

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;
  static const _orange = AppColors.pendingApproval;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: detail.title, onBackPressed: () => context.pop()),
            Expanded(
              child: detail.projectId.isEmpty
                  ? _ProjectDetailContent(detail: detail)
                  : _ProjectDetailLoader(initialDetail: detail),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetailLoader extends ConsumerWidget {
  const _ProjectDetailLoader({required this.initialDetail});

  final ProjectDetailData initialDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(
      projectDetailProvider(initialDetail.projectId),
    );

    return detailState.when(
      loading: () => const AppSkeletonDetailView(),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'projectCacheRead',
        message: error.toString(),
        onRetry: () =>
            ref.invalidate(projectDetailProvider(initialDetail.projectId)),
      ),
      data: (project) => RefreshIndicator(
        onRefresh: () async {
          final _ = await ref.refresh(
            projectDetailProvider(initialDetail.projectId).future,
          );
        },
        child: _ProjectDetailContent(
          detail: ProjectDetailData.fromProject(
            project,
            title: initialDetail.title,
          ),
        ),
      ),
    );
  }
}

class _ProjectDetailContent extends StatelessWidget {
  const _ProjectDetailContent({required this.detail});

  final ProjectDetailData detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [_ProjectDetailSection(detail: detail)],
    );
  }
}

class _ProjectDetailSection extends StatelessWidget {
  const _ProjectDetailSection({required this.detail});

  final ProjectDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'Proyek', value: detail.projectName),
          const SizedBox(height: 20),
          _DetailField(
            label: 'Status',
            value: detail.status,
            valueColor: ProjectDetailPage._orange,
            valueFontFamily: ProjectDetailPage._accentFontFamily,
            valueFontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 20),
          _DetailField(label: 'Klien', value: detail.client),
          const SizedBox(height: 20),
          _DetailField(label: 'Periode', value: detail.period),
          const SizedBox(height: 20),
          _DetailField(label: 'Deskripsi', value: detail.description),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Hari kerja',
                  value: detail.workingDays,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Jumlah tugas',
                  value: detail.taskCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.muted,
    this.valueFontFamily = ProjectDetailPage._fontFamily,
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
            fontFamily: ProjectDetailPage._fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
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

class ProjectDetailData {
  const ProjectDetailData({
    this.projectId = '',
    this.title = 'Task Project',
    required this.projectName,
    required this.status,
    required this.client,
    required this.period,
    required this.description,
    required this.workingDays,
    required this.taskCount,
  });

  final String projectId;
  final String title;
  final String projectName;
  final String status;
  final String client;
  final String period;
  final String description;
  final String workingDays;
  final String taskCount;

  factory ProjectDetailData.fromProject(
    Project project, {
    String title = 'Task Project',
  }) {
    final taskCount = project.summary?.taskProject ?? project.nodesCount;

    return ProjectDetailData(
      projectId: project.id,
      title: title,
      projectName: project.name,
      status: _statusLabel(project.status),
      client: project.client?.name ?? '-',
      period: _formatDateRange(project.startDate, project.endDate),
      description: project.description ?? '-',
      workingDays: project.durationDays > 0 ? '${project.durationDays} d' : '-',
      taskCount: taskCount.toString(),
    );
  }

  factory ProjectDetailData.fallback() {
    return const ProjectDetailData(
      projectName: 'Pembangunan Jembatan Sungai Cempaka',
      status: 'Proses',
      client: 'CV Pembangunan Indonesia',
      period: 'Jun 20 - Des 20, 2026',
      description:
          'Proyek pembangunan jembatan penghubung antar kecamatan dengan estimasi pekerjaan struktur utama dan akses jalan.',
      workingDays: '128 d',
      taskCount: '203',
    );
  }
}

String _formatDateRange(String? startDate, String? endDate) {
  final start = parseApiDateTime(startDate);
  final end = parseApiDateTime(endDate);
  if (start == null && end == null) {
    return '-';
  }
  if (start == null) {
    return _formatDate(end!);
  }
  if (end == null) {
    return _formatDate(start);
  }

  return '${_formatDate(start)} - ${_formatDate(end)}';
}

String _formatDate(DateTime date) {
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

  return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
}

String _statusLabel(String status) {
  return status;
}
