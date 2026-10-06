import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/offline_first_providers.dart';
import '../../core/sync/sync_policy.dart';
import 'error_view.dart';

class NetworkAwareErrorView extends ConsumerWidget {
  const NetworkAwareErrorView({
    this.onRetry,
    this.error,
    this.message,
    this.cacheFeatureKey,
    super.key,
  });

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;
  final String? cacheFeatureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = error is DioException
        ? ErrorMapper.fromDio(error as DioException)
        : error;
    final appError = failure is AppException ? failure : null;
    if (appError?.kind == AppExceptionKind.forbidden) {
      return const ErrorView(
        title: 'Akses ditolak',
        message: 'Anda tidak mempunyai hak akses untuk fitur ini.',
      );
    }

    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    final description = message ?? appError?.message ?? failure?.toString();
    final isConnectionFailure =
        appError?.kind == AppExceptionKind.connection ||
        (error == null && _isConnectionFailure(message));
    final cacheMiss = appError?.kind == AppExceptionKind.offlineCacheMiss;
    // An HTTP response or a known application error must not be overwritten
    // just because connectivity changed after the request completed.
    final unknownOffline = isOffline && error == null;
    if (cacheMiss || isConnectionFailure || unknownOffline) {
      final featureKey = cacheFeatureKey;
      final supportsCache =
          cacheMiss ||
          (featureKey != null &&
              ref.watch(syncPolicyProvider).readMode(featureKey) ==
                  ReadCapability.cacheRead);
      return ErrorView(
        title: supportsCache
            ? 'Tidak ada koneksi internet'
            : 'Fitur hanya tersedia online',
        message: supportsCache
            ? 'Data belum tersimpan di perangkat. Sambungkan perangkat ke internet dan buka halaman ini untuk menyiapkan akses offline.'
            : 'Fitur ini hanya tersedia dalam mode online. Sambungkan perangkat ke internet untuk menggunakan fitur ini.',
        retryLabel: 'Coba lagi',
        onRetry: onRetry,
      );
    }

    return ErrorView(message: description, onRetry: onRetry);
  }

  bool _isConnectionFailure(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return normalized.contains('tidak dapat terhubung ke server') ||
        normalized.contains('terjadi kesalahan jaringan');
  }
}
