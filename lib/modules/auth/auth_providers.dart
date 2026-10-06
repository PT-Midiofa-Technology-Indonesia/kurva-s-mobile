import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/auth_repository.dart';
import 'data/models/auth_user.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    secureStorage: ref.watch(secureStorageServiceProvider),
    onSessionExpired: () {
      ref.read(authControllerProvider.notifier).expireSession();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dioClient: ref.watch(dioClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    if (!await repository.hasSession()) {
      return const AuthState.unauthenticated();
    }

    try {
      final user = await repository.me();
      return AuthState.authenticated(user);
    } catch (_) {
      try {
        await repository.refreshToken();
        final user = await repository.me();
        return AuthState.authenticated(user);
      } catch (_) {
        // Network and server failures do not prove that the durable session is
        // invalid. DioClient clears it only for a definitive auth rejection.
        if (await repository.hasSession()) {
          final cachedUser = await repository.cachedUser();
          if (cachedUser != null) {
            return AuthState.authenticated(cachedUser);
          }
        }
        return const AuthState.unauthenticated();
      }
    }
  }

  Future<void> login({
    required String identity,
    required String password,
    required bool rememberMe,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.login(
        identity: identity,
        password: password,
        rememberMe: rememberMe,
      );
      final user = await repository.me();
      return AuthState.authenticated(user);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return const AuthState.unauthenticated();
    });
  }

  Future<void> refreshSession() async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.refreshToken();
      final user = await repository.me();
      return AuthState.authenticated(user);
    });
  }

  void expireSession() {
    state = const AsyncData(AuthState.unauthenticated());
  }
}

class AuthState {
  const AuthState._({required this.status, this.user});

  const AuthState.authenticated(AuthUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final AuthUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

enum AuthStatus { authenticated, unauthenticated }
