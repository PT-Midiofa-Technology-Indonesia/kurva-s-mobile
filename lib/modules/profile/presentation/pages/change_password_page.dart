import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/input_password_text_field.dart';
import '../../../../shared/forms/form_submit_result.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentPasswordKey = GlobalKey();
  final _newPasswordKey = GlobalKey();
  final _confirmPasswordKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(changePasswordControllerProvider);

    Future<void> handleSave() async {
      FocusScope.of(context).unfocus();
      try {
        final result = await controller.submit();
        if (!context.mounted) return;
        if (result case FormSubmitInvalid(:final message)) {
          if (message != null) AppToast.warning(context, message);
          _scrollToFirstInvalid(controller);
        } else if (result case FormSubmitSuccess(:final message)) {
          AppToast.success(context, message);
        }
      } catch (error) {
        if (context.mounted) {
          AppToast.error(context, error);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Ubah Kata Sandi',
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  KeyedSubtree(
                    key: _currentPasswordKey,
                    child: InputPasswordTextField(
                      label: 'Kata sandi saat ini',
                      controller: controller.currentPasswordController,
                      isRequired: true,
                      errorText: controller.currentPasswordError,
                    ),
                  ),
                  KeyedSubtree(
                    key: _newPasswordKey,
                    child: InputPasswordTextField(
                      label: 'Kata sandi baru',
                      controller: controller.newPasswordController,
                      isRequired: true,
                      errorText: controller.newPasswordError,
                    ),
                  ),
                  KeyedSubtree(
                    key: _confirmPasswordKey,
                    child: InputPasswordTextField(
                      label: 'Ulangi kata sandi baru',
                      controller: controller.confirmPasswordController,
                      isRequired: true,
                      textInputAction: TextInputAction.done,
                      errorText: controller.confirmPasswordError,
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.white,
                child: AppButton(
                  label: controller.isSubmitting ? 'Menyimpan...' : 'Simpan',
                  isLoading: controller.isSubmitting,
                  backgroundColor: AppColors.dashboardTeal,
                  elevation: 4,
                  shadowColor: AppColors.softShadow,
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                  onPressed: controller.isSubmitting ? null : handleSave,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToFirstInvalid(ChangePasswordController controller) {
    final key = controller.currentPasswordError != null
        ? _currentPasswordKey
        : controller.newPasswordError != null
        ? _newPasswordKey
        : controller.confirmPasswordError != null
        ? _confirmPasswordKey
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fieldContext = key?.currentContext;
      if (fieldContext == null) return;
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }
}
