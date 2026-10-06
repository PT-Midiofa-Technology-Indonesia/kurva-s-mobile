import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/widgets/meeting_participants_bottom_sheet.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';

class MeetingDetailPage extends ConsumerWidget {
  const MeetingDetailPage({required this.detail, super.key});

  final MeetingDetailData detail;

  static const _orange = AppColors.pendingApproval;
  static const _tableBorderColor = AppColors.tabBorder;
  static const _tableHeaderBackground = AppColors.cardBackground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = detail.meetingId.isEmpty
        ? null
        : ref.watch(meetingDetailProvider(detail.meetingId));
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Detail Meeting',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: detailState == null
                  ? _MeetingDetailContent(detail: detail)
                  : detailState.when(
                      loading: () => const AppSkeletonDetailView(),
                      error: (error, _) => NetworkAwareErrorView(
                        error: error,
                        message: error.toString(),
                        onRetry: () => ref.invalidate(
                          meetingDetailProvider(detail.meetingId),
                        ),
                      ),
                      data: (value) => RefreshIndicator(
                        onRefresh: () => ref.refresh(
                          meetingDetailProvider(detail.meetingId).future,
                        ),
                        child: _MeetingDetailContent(
                          detail: MeetingDetailData.fromModel(value),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingDetailContent extends StatelessWidget {
  const _MeetingDetailContent({required this.detail});

  final MeetingDetailData detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _MeetingInformation(detail: detail),
        _ToDoSection(items: detail.toDos),
      ],
    );
  }
}

class _MeetingInformation extends StatelessWidget {
  const _MeetingInformation({required this.detail});

  final MeetingDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'Perusahaan', value: detail.company),
          const SizedBox(height: 20),
          _DetailField(label: 'Judul', value: detail.title),
          const SizedBox(height: 20),
          _DetailField(
            label: 'Status',
            value: detail.status,
            valueColor: MeetingDetailPage._orange,
            valueFontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 20),
          _DetailField(label: 'Project', value: detail.project),
          const SizedBox(height: 20),
          _DetailField(label: 'Tanggal', value: detail.date),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Waktu mulai',
                  value: detail.startTime,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Waktu Selesai',
                  value: detail.endTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Participants(participants: detail.participants),
          const SizedBox(height: 20),
          _DetailField(label: 'Topik', value: detail.topic),
          const SizedBox(height: 20),
          _DetailField(label: 'Keputusan', value: detail.decision),
          const SizedBox(height: 20),
          _DetailField(label: 'Lokasi', value: detail.location),
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
    this.valueFontWeight = FontWeight.w400,
  });

  final String label;
  final String value;
  final Color valueColor;
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
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 1.43,
            fontWeight: valueFontWeight,
          ),
        ),
      ],
    );
  }
}

class _Participants extends StatelessWidget {
  const _Participants({required this.participants});

  final List<MeetingParticipantData> participants;

  void _showParticipants(BuildContext context) {
    if (participants.isEmpty) return;
    MeetingParticipantsBottomSheet.show(context, participants: participants);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peserta',
          style: TextStyle(
            color: AppColors.ink,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: participants.isEmpty
                ? null
                : () => _showParticipants(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: participants.isEmpty
                        ? 0
                        : 40 + (participants.length - 1) * 30,
                    height: 40,
                    child: Stack(
                      children: [
                        for (
                          var index = 0;
                          index < participants.length;
                          index++
                        )
                          Positioned(
                            left: index * 30,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.white,
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: participants[index].color,
                                child: Text(
                                  participants[index].initials,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (participants.isNotEmpty)
                    const SizedBox(width: AppSpacing.sm),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Text(
                      '${participants.length} Personil',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToDoSection extends StatelessWidget {
  const _ToDoSection({required this.items});

  final List<MeetingToDoData> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To Do',
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.inter,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: MeetingDetailPage._tableBorderColor),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    children: [
                      const _ToDoRow(
                        backgroundColor:
                            MeetingDetailPage._tableHeaderBackground,
                        cells: [
                          _ToDoCell(width: 80, child: _HeaderText('Kode')),
                          _ToDoCell(width: 220, child: _HeaderText('Tugas')),
                          _ToDoCell(
                            width: 120,
                            showRightBorder: false,
                            child: _HeaderText('Status'),
                          ),
                        ],
                      ),
                      for (var index = 0; index < items.length; index++)
                        _ToDoDataRow(
                          item: items[index],
                          showBottomBorder: index < items.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToDoDataRow extends StatelessWidget {
  const _ToDoDataRow({required this.item, required this.showBottomBorder});

  final MeetingToDoData item;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return _ToDoRow(
      minHeight: 64,
      showBottomBorder: showBottomBorder,
      cells: [
        _ToDoCell(
          width: 80,
          alignment: Alignment.center,
          showRightBorder: false,
          child: Text(
            item.code,
            style: const TextStyle(
              color: AppColors.infoBlue,
              fontFamily: AppFonts.geist,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _ToDoCell(
          width: 220,
          showRightBorder: false,
          child: Text(
            item.task,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.geist,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _ToDoCell(
          width: 120,
          alignment: Alignment.centerLeft,
          showRightBorder: false,
          child: _StatusPill(label: item.status),
        ),
      ],
    );
  }
}

class _ToDoRow extends StatelessWidget {
  const _ToDoRow({
    required this.cells,
    this.backgroundColor = AppColors.white,
    this.minHeight = 44,
    this.showBottomBorder = true,
  });

  final List<Widget> cells;
  final Color backgroundColor;
  final double minHeight;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: showBottomBorder
                ? MeetingDetailPage._tableBorderColor
                : AppColors.transparent,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Row(children: cells),
        ),
      ),
    );
  }
}

class _ToDoCell extends StatelessWidget {
  const _ToDoCell({
    required this.width,
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.showRightBorder = true,
  });

  final double width;
  final Widget child;
  final AlignmentGeometry alignment;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: showRightBorder
                ? MeetingDetailPage._tableBorderColor
                : AppColors.transparent,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: AppFonts.geist,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: MeetingDetailPage._orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_calendar_outlined,
            size: 14,
            color: MeetingDetailPage._orange,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.geist,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingDetailData {
  const MeetingDetailData({
    this.meetingId = '',
    this.company = '-',
    this.title = '-',
    this.status = '-',
    this.project = '-',
    this.date = '-',
    this.startTime = '-',
    this.endTime = '-',
    this.participants = const [],
    this.topic = '-',
    this.decision = '-',
    this.location = '-',
    this.toDos = const [],
  });

  final String meetingId;
  final String company;
  final String title;
  final String status;
  final String project;
  final String date;
  final String startTime;
  final String endTime;
  final List<MeetingParticipantData> participants;
  final String topic;
  final String decision;
  final String location;
  final List<MeetingToDoData> toDos;

  factory MeetingDetailData.fromModel(MeetingDetail detail) {
    return MeetingDetailData(
      meetingId: detail.id,
      company: _display(detail.companyName),
      title: _display(detail.title),
      status: _display(detail.status),
      project: _display(detail.projectName),
      date: formatIndonesianDate(detail.date, shortMonth: true),
      startTime: formatApiTime(date: detail.date, time: detail.startTime),
      endTime: formatApiTime(date: detail.date, time: detail.endTime),
      participants: detail.participants
          .map(
            (participant) => MeetingParticipantData(
              name: _display(participant.name),
              initials: participant.initials,
              color:
                  _colorFromHex(participant.colorHex) ??
                  _participantColor(participant.id + participant.name),
            ),
          )
          .toList(growable: false),
      topic: _display(detail.topic),
      decision: _display(detail.decision),
      location: _display(detail.location),
      toDos: detail.toDos
          .map(
            (task) => MeetingToDoData(
              code: _display(task.code),
              task: _display(task.title),
              status: _display(task.status),
            ),
          )
          .toList(growable: false),
    );
  }

  factory MeetingDetailData.fallback() {
    return const MeetingDetailData();
  }
}

class MeetingToDoData {
  const MeetingToDoData({
    required this.code,
    required this.task,
    this.status = 'Proses',
  });

  final String code;
  final String task;
  final String status;
}

String _display(String value) => value.trim().isEmpty ? '-' : value;

Color _participantColor(String value) {
  const colors = [
    AppColors.participantPurple,
    AppColors.participantGreen,
    AppColors.participantMagenta,
  ];
  if (value.isEmpty) return colors.first;
  final index =
      value.codeUnits.fold<int>(0, (sum, code) => sum + code) % colors.length;
  return colors[index];
}

Color? _colorFromHex(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  if (normalized.length != 6 && normalized.length != 8) return null;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) return null;
  return AppColors.fromHex(value);
}
