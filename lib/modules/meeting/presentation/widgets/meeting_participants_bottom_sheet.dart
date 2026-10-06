import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';

class MeetingParticipantsBottomSheet extends StatelessWidget {
  const MeetingParticipantsBottomSheet({required this.participants, super.key});

  final List<MeetingParticipantData> participants;

  static Future<void> show(
    BuildContext context, {
    required List<MeetingParticipantData> participants,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) =>
          MeetingParticipantsBottomSheet(participants: participants),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ParticipantsHeader(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  return _ParticipantItem(participant: participants[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsHeader extends StatelessWidget {
  const _ParticipantsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          const Expanded(
            child: Text(
              'Peserta',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            width: 56,
            height: 56,
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
    );
  }
}

class _ParticipantItem extends StatelessWidget {
  const _ParticipantItem({required this.participant});

  final MeetingParticipantData participant;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: participant.color,
            child: Text(
              participant.initials,
              style: const TextStyle(
                color: AppColors.white,
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              participant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.inter,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingParticipantData {
  const MeetingParticipantData({
    required this.name,
    required this.initials,
    required this.color,
  });

  final String name;
  final String initials;
  final Color color;
}
