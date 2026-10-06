import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/page_open_refresh_scope.dart';
import '../auth_providers.dart';

final loginControllerProvider =
    ChangeNotifierProvider.autoDispose<LoginController>((ref) {
      return LoginController(ref);
    });

enum LoginMode { email, phone }

enum LoginSubmitStatus { success, validationFailed, failure }

class LoginSubmitResult {
  const LoginSubmitResult._(this.status, [this.message]);

  const LoginSubmitResult.success() : this._(LoginSubmitStatus.success);

  const LoginSubmitResult.validationFailed()
    : this._(LoginSubmitStatus.validationFailed);

  const LoginSubmitResult.failure(String message)
    : this._(LoginSubmitStatus.failure, message);

  final LoginSubmitStatus status;
  final String? message;
}

class LoginController extends ChangeNotifier
    implements PageOpenRefreshController {
  LoginController(this._ref) {
    emailController.addListener(_handleIdentityChanged);
    phoneController.addListener(_handleIdentityChanged);
    passwordController.addListener(_handlePasswordChanged);
  }

  final Ref _ref;

  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  LoginMode mode = LoginMode.email;
  bool rememberMe = false;
  bool obscurePassword = true;
  bool showValidationErrors = false;
  String? identityError;
  String? passwordError;

  String? get identityErrorText {
    if (identityError case final error?) return error;
    if (!showValidationErrors) return null;

    final value = mode == LoginMode.email
        ? emailController.text
        : phoneController.text;
    if (value.trim().isNotEmpty) return null;
    return mode == LoginMode.email
        ? 'Email wajib diisi'
        : 'Nomor telepon wajib diisi';
  }

  String? get passwordErrorText {
    if (passwordError case final error?) return error;
    if (!showValidationErrors || passwordController.text.isNotEmpty) {
      return null;
    }
    return 'Kata sandi wajib diisi';
  }

  void setMode(LoginMode value) {
    if (mode == value) {
      return;
    }

    mode = value;
    showValidationErrors = false;
    identityError = null;
    passwordError = null;
    notifyListeners();
  }

  void setRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void useDummyLogin() {
    if (mode == LoginMode.email) {
      emailController.text = 'mobile.admin@mail.com';
    } else {
      phoneController.text = '85743065515';
    }
    passwordController.text = 'password';
    showValidationErrors = false;
    identityError = null;
    passwordError = null;
    notifyListeners();
  }

  @override
  void refresh() {
    showValidationErrors = false;
    identityError = null;
    passwordError = null;
    notifyListeners();
  }

  Future<LoginSubmitResult> login() async {
    identityError = null;
    passwordError = null;

    final accountController = mode == LoginMode.email
        ? emailController
        : phoneController;
    final hasEmptyField =
        accountController.text.trim().isEmpty ||
        passwordController.text.isEmpty;

    if (hasEmptyField) {
      showValidationErrors = true;
      notifyListeners();
      return const LoginSubmitResult.validationFailed();
    }

    final identity = mode == LoginMode.phone
        ? '62${accountController.text.trim()}'
        : accountController.text.trim();

    await _ref
        .read(authControllerProvider.notifier)
        .login(
          identity: identity,
          password: passwordController.text,
          rememberMe: rememberMe,
        );

    final nextState = _ref.read(authControllerProvider);
    if (nextState.hasError) {
      final error = nextState.error;
      if (error case AppException(hasErrors: true)) {
        _applyServerErrors(error.details);
        return const LoginSubmitResult.validationFailed();
      }
      final message = error is AppException
          ? error.message
          : 'Login gagal. Silakan coba lagi.';
      return LoginSubmitResult.failure(message);
    }

    if (nextState.valueOrNull?.isAuthenticated ?? false) {
      return const LoginSubmitResult.success();
    }

    return const LoginSubmitResult.failure('Login gagal. Silakan coba lagi.');
  }

  void _applyServerErrors(List<String> details) {
    for (final detail in details) {
      final parsed = Validators.validationDetail(detail);
      if (parsed == null) continue;

      switch (parsed.field) {
        case 'identity':
          identityError = _joinError(identityError, parsed.message);
        case 'password':
          passwordError = _joinError(passwordError, parsed.message);
      }
    }
    notifyListeners();
  }

  String _joinError(String? current, String next) {
    return current == null || current.isEmpty ? next : '$current\n$next';
  }

  void _handleIdentityChanged() {
    final hadServerError = identityError != null;
    identityError = null;
    if (hadServerError || showValidationErrors) notifyListeners();
  }

  void _handlePasswordChanged() {
    final hadServerError = passwordError != null;
    passwordError = null;
    if (hadServerError || showValidationErrors) notifyListeners();
  }

  @override
  void dispose() {
    emailController.removeListener(_handleIdentityChanged);
    phoneController.removeListener(_handleIdentityChanged);
    passwordController.removeListener(_handlePasswordChanged);
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
