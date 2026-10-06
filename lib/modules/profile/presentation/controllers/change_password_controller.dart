import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/forms/form_submit_result.dart';
import '../../../auth/auth_providers.dart';

final changePasswordControllerProvider =
    ChangeNotifierProvider.autoDispose<ChangePasswordController>((ref) {
      return ChangePasswordController(ref);
    });

class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController(this._ref) {
    currentPasswordController.addListener(_clearCurrentPasswordError);
    newPasswordController.addListener(_clearNewPasswordError);
    confirmPasswordController.addListener(_clearConfirmPasswordError);
  }

  final Ref _ref;
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool hasServerErrors = false;
  String? currentPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

  Future<FormSubmitResult> submit() async {
    if (isSubmitting) return const FormSubmitIgnored();
    hasSubmitted = true;
    hasServerErrors = false;
    if (!_validate()) return const FormSubmitInvalid();
    isSubmitting = true;
    notifyListeners();

    try {
      await _ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPasswordController.text,
            newPassword: newPasswordController.text,
            newPasswordConfirmation: confirmPasswordController.text,
          );
      hasSubmitted = false;
      currentPasswordError = null;
      newPasswordError = null;
      confirmPasswordError = null;
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      return const FormSubmitSuccess('Kata sandi berhasil diperbarui.');
    } on AppException catch (error) {
      if (!_applyServerErrors(error.details)) rethrow;
      return const FormSubmitInvalid();
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  bool _validate() {
    currentPasswordError = _validateCurrentPassword();
    newPasswordError = _validateNewPassword();
    confirmPasswordError = _validateConfirmation();
    notifyListeners();
    return currentPasswordError == null &&
        newPasswordError == null &&
        confirmPasswordError == null;
  }

  bool _applyServerErrors(List<String> details) {
    var applied = false;
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;
      switch (parsed.field) {
        case 'currentPassword':
        case 'current_password':
          currentPasswordError = _joinError(
            currentPasswordError,
            parsed.message,
          );
        case 'newPassword':
        case 'new_password':
          newPasswordError = _joinError(newPasswordError, parsed.message);
        case 'newPasswordConfirmation':
        case 'new_password_confirmation':
          confirmPasswordError = _joinError(
            confirmPasswordError,
            parsed.message,
          );
        default:
          continue;
      }
      applied = true;
    }
    if (applied) {
      hasServerErrors = true;
      notifyListeners();
    }
    return applied;
  }

  String _joinError(String? current, String next) =>
      current == null || current.isEmpty ? next : '$current\n$next';

  void _clearCurrentPasswordError() {
    if (!hasSubmitted) return;
    currentPasswordError = _validateCurrentPassword();
    notifyListeners();
  }

  void _clearNewPasswordError() {
    if (!hasSubmitted) return;
    newPasswordError = _validateNewPassword();
    confirmPasswordError = _validateConfirmation();
    notifyListeners();
  }

  void _clearConfirmPasswordError() {
    if (!hasSubmitted) return;
    confirmPasswordError = _validateConfirmation();
    notifyListeners();
  }

  String? _validateCurrentPassword() => currentPasswordController.text.isEmpty
      ? 'Kata sandi saat ini wajib diisi.'
      : null;
  String? _validateNewPassword() {
    final value = newPasswordController.text;
    if (value.isEmpty) return 'Kata sandi baru wajib diisi.';
    return value.length < 8 ? 'Kata sandi baru minimal 8 karakter.' : null;
  }

  String? _validateConfirmation() {
    final value = confirmPasswordController.text;
    if (value.isEmpty) return 'Konfirmasi kata sandi baru wajib diisi.';
    return value != newPasswordController.text
        ? 'Konfirmasi kata sandi baru tidak sesuai.'
        : null;
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
