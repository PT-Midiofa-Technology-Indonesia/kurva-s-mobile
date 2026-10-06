import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_environment.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/debug/network_inspector_toggle.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../auth_providers.dart';
import 'login_controller.dart';
import 'widgets/login_input.dart';
import 'widgets/login_phone_input.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final controller = ref.watch(loginControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 68,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 56),
                          child: _LoginContent(
                            mode: controller.mode,
                            showDebugActions:
                                isNetworkInspectorEnabledAtStartup,
                            emailController: controller.emailController,
                            phoneController: controller.phoneController,
                            passwordController: controller.passwordController,
                            rememberMe: controller.rememberMe,
                            obscurePassword: controller.obscurePassword,
                            identityErrorText: controller.identityErrorText,
                            passwordErrorText: controller.passwordErrorText,
                            isLoading: isLoading,
                            onModeChanged: controller.setMode,
                            onRememberChanged: controller.setRememberMe,
                            onTogglePassword:
                                controller.togglePasswordVisibility,
                            onUseDummyLogin: controller.useDummyLogin,
                            onLogin: isLoading
                                ? null
                                : () async {
                                    final result = await ref
                                        .read(loginControllerProvider)
                                        .login();
                                    if (!context.mounted) {
                                      return;
                                    }

                                    if (result.status ==
                                        LoginSubmitStatus.failure) {
                                      AppToast.error(
                                        context,
                                        result.message ?? 'Login gagal.',
                                      );
                                      return;
                                    }

                                    if (result.status ==
                                        LoginSubmitStatus.validationFailed) {
                                      return;
                                    }

                                    if (result.status ==
                                        LoginSubmitStatus.success) {
                                      AppToast.success(
                                        context,
                                        'Login berhasil.',
                                      );
                                      context.go(RouteNames.dashboard);
                                    }
                                  },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 68, child: _PoweredByFooter()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent({
    required this.mode,
    required this.showDebugActions,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.identityErrorText,
    required this.passwordErrorText,
    required this.isLoading,
    required this.onModeChanged,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onUseDummyLogin,
    required this.onLogin,
  });

  final LoginMode mode;
  final bool showDebugActions;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final String? identityErrorText;
  final String? passwordErrorText;
  final bool isLoading;
  final ValueChanged<LoginMode> onModeChanged;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onUseDummyLogin;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 548,
      child: Column(
        children: [
          SizedBox(height: 108, child: _LoginHeader(mode: mode)),
          SizedBox(
            height: 76,
            child: _LoginMethodTabs(mode: mode, onChanged: onModeChanged),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                if (mode == LoginMode.email)
                  LoginInput(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    errorText: identityErrorText,
                  )
                else
                  LoginPhoneInput(
                    controller: phoneController,
                    errorText: identityErrorText,
                  ),
                const SizedBox(height: 10),
                LoginInput(
                  controller: passwordController,
                  hintText: 'Kata Sandi',
                  obscureText: obscurePassword,
                  errorText: passwordErrorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.ink,
                      size: 24,
                    ),
                    tooltip: obscurePassword
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    onPressed: onTogglePassword,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: _RememberMeRow(
                    value: rememberMe,
                    onChanged: onRememberChanged,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              children: [
                AppButton(
                  label: isLoading ? 'Memproses...' : 'Masuk',
                  isLoading: isLoading,
                  onPressed: onLogin,
                ),
                if (showDebugActions) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : onUseDummyLogin,
                    child: Text(
                      mode == LoginMode.email
                          ? 'Gunakan dummy login email'
                          : 'Gunakan dummy login telepon',
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.mode});

  final LoginMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Masuk',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.geist,
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            mode == LoginMode.email
                ? 'Masukkan email dan kata sandimu'
                : 'Masukkan nomor telepon dan kata sandimu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.geist,
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginMethodTabs extends StatelessWidget {
  const _LoginMethodTabs({required this.mode, required this.onChanged});

  final LoginMode mode;
  final ValueChanged<LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isEmail = mode == LoginMode.email;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Container(
          width: 272,
          height: 44,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.tabBackground,
            border: Border.all(color: AppColors.tabBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _LoginTab(
                  label: 'Email',
                  selected: isEmail,
                  onTap: () => onChanged(LoginMode.email),
                ),
              ),
              Expanded(
                child: _LoginTab(
                  label: 'Nomor Telepon',
                  selected: !isEmail,
                  onTap: () => onChanged(LoginMode.phone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.white : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.softShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.geist,
              color: selected ? AppColors.loginTeal : AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.loginTeal,
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Ingat Saya',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoweredByFooter extends StatelessWidget {
  const _PoweredByFooter();

  @override
  Widget build(BuildContext context) {
    final isProductionRelease =
        kReleaseMode && appFlavor == AppEnvironment.production.name;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: isProductionRelease
          ? null
          : () async {
              final nextValue = !await readNetworkInspectorPreference();
              await setNetworkInspectorPreference(nextValue);
              if (!context.mounted) {
                return;
              }

              AppToast.info(
                context,
                nextValue
                    ? 'Debug tools akan aktif setelah restart app.'
                    : 'Debug tools akan nonaktif setelah restart app.',
              );
            },
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Powered by',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'CURVA-S',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
