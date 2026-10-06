import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_header.dart';

class TermConditionPage extends StatelessWidget {
  const TermConditionPage({super.key});

  static const _sections = [
    _TermSection(
      title: 'Syarat & Ketentuan platform',
      updatedAt: 'Terakhir diperbarui: 21 Juli 2026',
      paragraphs: [
        'CURVA-S Mobile adalah aplikasi yang digunakan untuk mendukung aktivitas kerja, termasuk presensi, pengajuan lembur, pencatatan lokasi kerja, dan pengelolaan informasi pengguna.',
        'Pengguna adalah karyawan atau pihak lain yang telah memperoleh akses resmi dari perusahaan.',
      ],
    ),
    _TermSection(
      title: '1. Akun dan akses pengguna',
      paragraphs: [
        'Setiap pengguna bertanggung jawab menjaga kerahasiaan informasi akun dan kata sandinya.',
        'Pengguna tidak diperkenankan memberikan akses akun kepada pihak lain. Seluruh aktivitas yang dilakukan melalui akun menjadi tanggung jawab pemilik akun.',
      ],
    ),
    _TermSection(
      title: '2. Penggunaan aplikasi',
      paragraphs: [
        'Pengguna wajib memberikan informasi yang benar, akurat, dan dapat dipertanggungjawabkan.',
        'Aplikasi hanya boleh digunakan untuk keperluan pekerjaan sesuai dengan kebijakan perusahaan. Penyalahgunaan aplikasi dapat mengakibatkan pembatasan atau penonaktifan akun.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Term & Conditions',
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _sections.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.line,
                ),
                itemBuilder: (context, index) {
                  return _TermSectionView(section: _sections[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermSectionView extends StatelessWidget {
  const _TermSectionView({required this.section});

  final _TermSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.inter,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          if (section.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TermBodyText(section.updatedAt!),
          ],
          for (final paragraph in section.paragraphs) ...[
            const SizedBox(height: AppSpacing.lg),
            _TermBodyText(paragraph),
          ],
        ],
      ),
    );
  }
}

class _TermBodyText extends StatelessWidget {
  const _TermBodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontFamily: AppFonts.inter,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _TermSection {
  const _TermSection({
    required this.title,
    required this.paragraphs,
    this.updatedAt,
  });

  final String title;
  final String? updatedAt;
  final List<String> paragraphs;
}
