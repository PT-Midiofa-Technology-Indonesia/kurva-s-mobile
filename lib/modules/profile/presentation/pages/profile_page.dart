import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/debug/network_inspector_toggle.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline_first_providers.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/name_acronym.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/network_aware_error_view.dart';
import '../../../auth/auth_providers.dart';
import '../../../auth/data/models/auth_user.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const _fontFamily = AppFonts.inter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Profil Pengguna',
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go(RouteNames.dashboard);
              },
            ),
            Expanded(
              child: authState.when(
                data: (state) {
                  final user = state.user;
                  if (user == null) {
                    return ErrorView(
                      message: 'Data profil tidak tersedia.',
                      onRetry: () => ref.invalidate(authControllerProvider),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(authControllerProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        _ProfileHero(name: user.name),
                        _InfoSection(
                          title: 'Informasi umum',
                          items: _profileItems(user),
                        ),
                        _EmployeeInfoSection(
                          assignments: _employeeAssignments(user),
                        ),
                        const _HelpSection(),
                        const _AppVersionInfo(),
                        if (isNetworkInspectorEnabledAtStartup)
                          const _ClearDatabaseLink(),
                      ],
                    ),
                  );
                },
                error: (error, _) {
                  final message = error is AppException
                      ? error.message
                      : 'Gagal memuat profil.';
                  return NetworkAwareErrorView(
                    error: error,
                    message: message,
                    onRetry: () => ref.invalidate(authControllerProvider),
                  );
                },
                loading: () => const AppSkeletonDetailView(sectionCount: 4),
              ),
            ),
            const SafeArea(top: false, child: _LogoutFooter()),
          ],
        ),
      ),
    );
  }

  static List<_ProfileInfoItem> _profileItems(AuthUser user) {
    return [
      _ProfileInfoItem(
        label: 'Terdaftar sejak',
        value: user.registeredSince.isEmpty
            ? '-'
            : 'Akun ini terdaftar pada '
                  '${formatIndonesianDate(user.registeredSince)}',
      ),
      _ProfileInfoItem(label: 'Alamat email', value: _dash(user.email)),
      _ProfileInfoItem(label: 'Nomor telepon', value: _dash(user.phoneNumber)),
      _ProfileInfoItem(
        label: 'Status',
        value: user.isActive ? 'Aktif' : 'Nonaktif',
      ),
      _ProfileInfoItem(
        label: 'Role',
        value: user.roles.isEmpty ? '-' : user.roles.join(', '),
      ),
    ];
  }

  static List<_EmployeeAssignmentInfo> _employeeAssignments(AuthUser user) {
    final assignments = [
      for (final assignment in user.assignments)
        _EmployeeAssignmentInfo(
          company: _dash(assignment.company?.name),
          department: _dash(assignment.department?.name),
        ),
    ];
    final assignedCompanyIds = {
      for (final assignment in user.assignments)
        if (assignment.company?.id case final id? when id.isNotEmpty) id,
    };

    for (final company in user.companies) {
      if (!assignedCompanyIds.contains(company.id)) {
        assignments.add(
          _EmployeeAssignmentInfo(
            company: _dash(company.name),
            department: '-',
          ),
        );
      }
    }

    return assignments.isEmpty
        ? const [_EmployeeAssignmentInfo(company: '-', department: '-')]
        : assignments;
  }

  static String _dash(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value;
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.avatarGradientStart,
                  AppColors.avatarGradientEnd,
                ],
              ),
            ),
            child: Text(
              nameAcronym(name),
              style: const TextStyle(
                color: AppColors.white,
                fontFamily: ProfilePage._fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: ProfilePage._fontFamily,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});

  final String title;
  final List<_ProfileInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: ProfilePage._fontFamily,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in items) ...[
            _InfoItem(item: item),
            if (item != items.last) const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _EmployeeInfoSection extends StatelessWidget {
  const _EmployeeInfoSection({required this.assignments});

  final List<_EmployeeAssignmentInfo> assignments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            child: Text(
              'Informasi karyawan',
              style: TextStyle(
                color: AppColors.ink,
                fontFamily: ProfilePage._fontFamily,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < assignments.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(
                    item: _ProfileInfoItem(
                      label: 'Perusahaan',
                      value: assignments[index].company,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoItem(
                    item: _ProfileInfoItem(
                      label: 'Departemen',
                      value: assignments[index].department,
                    ),
                  ),
                ],
              ),
            ),
            if (index < assignments.length - 1) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, thickness: 1, color: AppColors.line),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.item});

  final _ProfileInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: ProfilePage._fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.value,
          style: const TextStyle(
            color: AppColors.muted,
            fontFamily: ProfilePage._fontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  static const _items = [
    _HelpItem(label: 'FAQ', icon: Icons.chat_bubble_outline),
    _HelpItem(label: 'Hubungi admin', icon: Icons.headset_mic_outlined),
    _HelpItem(label: 'Term & Condition', icon: Icons.article_outlined),
    _HelpItem(label: 'Ubah kata sandi', icon: Icons.article_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bantuan',
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: ProfilePage._fontFamily,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in _items) ...[
            _HelpRow(item: item),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.item});

  static const _adminWhatsappPhone = '62895391051818';

  final _HelpItem item;

  @override
  Widget build(BuildContext context) {
    final routeName = switch (item.label) {
      'FAQ' => RouteNames.profileFaq,
      'Term & Condition' => RouteNames.profileTermCondition,
      'Ubah kata sandi' => RouteNames.profileChangePassword,
      _ => null,
    };
    final onTap = item.label == 'Hubungi admin'
        ? () => _openAdminWhatsapp(context)
        : routeName == null
        ? null
        : () {
            context.push(routeName);
          };

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Icon(item.icon, color: AppColors.ink, size: 28),
              ),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: ProfilePage._fontFamily,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right, color: AppColors.ink, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAdminWhatsapp(BuildContext context) async {
    final uri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': _adminWhatsappPhone},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    AppToast.error(context, 'WhatsApp tidak tersedia.');
  }
}

class _AppVersionInfo extends StatelessWidget {
  const _AppVersionInfo();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;
        final appVersion = packageInfo == null
            ? null
            : '${packageInfo.version} (Build ${packageInfo.buildNumber})';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Center(
            child: Text(
              appVersion == null ? 'App Version' : 'App Version $appVersion',
              style: const TextStyle(
                color: AppColors.muted,
                fontFamily: ProfilePage._fontFamily,
                fontSize: 14,
                height: 1.33,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClearDatabaseLink extends ConsumerStatefulWidget {
  const _ClearDatabaseLink();

  @override
  ConsumerState<_ClearDatabaseLink> createState() => _ClearDatabaseLinkState();
}

class _ClearDatabaseLinkState extends ConsumerState<_ClearDatabaseLink> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Center(
        child: TextButton(
          onPressed: _isClearing ? null : _clearDatabase,
          child: Text(
            _isClearing ? 'Clearing database...' : 'Clear local database',
          ),
        ),
      ),
    );
  }

  Future<void> _clearDatabase() async {
    final shouldClear = await showAppConfirmationDialog(
      context: context,
      title: 'Clear all database data?',
      confirmLabel: 'Yes, clear',
    );
    if (shouldClear != true || !mounted) {
      return;
    }

    setState(() => _isClearing = true);
    try {
      await ref.read(appDatabaseProvider).clearAllData();
      if (mounted) {
        AppToast.success(context, 'Database cleared.');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Failed to clear database.');
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}

class _LogoutFooter extends ConsumerStatefulWidget {
  const _LogoutFooter();

  @override
  ConsumerState<_LogoutFooter> createState() => _LogoutFooterState();
}

class _LogoutFooterState extends ConsumerState<_LogoutFooter> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(color: AppColors.white),
      child: AppButton(
        label: _isLoggingOut ? 'Keluar...' : 'Keluar dari aplikasi',
        isLoading: _isLoggingOut,
        variant: AppButtonVariant.danger,
        onPressed: _isLoggingOut
            ? null
            : () async {
                final shouldLogout = await _showLogoutConfirmation(context);
                if (shouldLogout != true || !context.mounted) {
                  return;
                }

                setState(() => _isLoggingOut = true);
                await ref.read(authControllerProvider.notifier).logout();

                if (!context.mounted) {
                  return;
                }

                final authState = ref.read(authControllerProvider);
                final state = authState.valueOrNull;
                if (state != null && !state.isAuthenticated) {
                  context.go(RouteNames.login);
                  return;
                }

                final error = authState.error;
                AppToast.error(
                  context,
                  error is AppException ? error : 'Gagal keluar dari aplikasi.',
                );
                setState(() => _isLoggingOut = false);
              },
      ),
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showAppConfirmationDialog(
      context: context,
      title: 'Keluar dari aplikasi?',
      cancelLabel: 'Tidak',
      confirmLabel: 'Ya, keluar',
    );
  }
}

class _ProfileInfoItem {
  const _ProfileInfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _EmployeeAssignmentInfo {
  const _EmployeeAssignmentInfo({
    required this.company,
    required this.department,
  });

  final String company;
  final String department;
}

class _HelpItem {
  const _HelpItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
