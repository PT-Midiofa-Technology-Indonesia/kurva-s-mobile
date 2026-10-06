import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/constants/route_names.dart';
import '../auth/auth_providers.dart';
import '../auth/data/models/auth_user.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minimumSplashDuration = Duration(seconds: 2);
  static const _sessionCheckTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _openNextPage();
  }

  Future<void> _openNextPage() async {
    AuthState authState;
    try {
      final results = await Future.wait([
        Future<void>.delayed(_minimumSplashDuration),
        ref.read(authControllerProvider.future).timeout(_sessionCheckTimeout),
      ]);
      authState = results.last as AuthState;
    } catch (_) {
      // A slow/offline session check must not turn into an implicit logout.
      final settledState = ref.read(authControllerProvider).valueOrNull;
      if (settledState != null) {
        authState = settledState;
      } else {
        final storage = ref.read(secureStorageServiceProvider);
        final storedTokens = await Future.wait([
          _safeRead(storage.readAccessToken),
          _safeRead(storage.readRefreshToken),
        ]);
        final hasSession =
            storedTokens[0]?.isNotEmpty == true ||
            storedTokens[1]?.isNotEmpty == true;
        final cachedUser = hasSession
            ? _decodeCachedUser(await _safeRead(storage.readAuthUser))
            : null;
        authState = hasSession && cachedUser != null
            ? AuthState.authenticated(cachedUser)
            : const AuthState.unauthenticated();
      }
    }

    if (!mounted) {
      return;
    }

    final nextRoute = authState.isAuthenticated
        ? RouteNames.dashboard
        : RouteNames.login;
    context.go(nextRoute);
  }

  AuthUser? _decodeCachedUser(String? rawUser) {
    if (rawUser == null || rawUser.isEmpty) return null;
    try {
      final json = jsonDecode(rawUser);
      return json is Map<String, dynamic> ? AuthUser.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }

  Future<String?> _safeRead(Future<String?> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage(AssetPaths.splashScreen),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
