import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_header.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  static const _items = [
    _FaqItem(
      question: 'Apa itu CURVA-S Mobile?',
      answer:
          'CURVA-S Mobile adalah aplikasi operasional perusahaan untuk membantu karyawan mengakses kebutuhan kerja secara mobile.',
    ),
    _FaqItem(
      question: 'Siapa pengguna aplikasi ini?',
      answer:
          'Aplikasi ini digunakan oleh karyawan yang telah memiliki akun dan hak akses dari perusahaan.',
    ),
    _FaqItem(
      question: 'Bagaimana cara masuk ke aplikasi?',
      answer:
          'Masuk menggunakan akun yang telah didaftarkan oleh perusahaan. Jika tidak dapat masuk, hubungi HR atau administrator.',
    ),
  ];

  int? _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'FAQ',
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _items.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.line,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _FaqTile(
                    item: item,
                    isExpanded: _expandedIndex == index,
                    onTap: () {
                      setState(() {
                        _expandedIndex = _expandedIndex == index ? null : index;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  final _FaqItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.ink,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Text(
                  item.answer,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
