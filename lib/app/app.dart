import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_inspector/network_inspector.dart';

import 'app_config.dart';
import '../modules/project/project_providers.dart';
import 'app_router.dart';
import 'app_theme.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/route_names.dart';
import '../core/debug/network_inspector_toggle.dart';
import '../core/connectivity/connectivity_state.dart';
import '../core/offline_first_providers.dart';
import '../core/media/offline_image_providers.dart';
import '../core/sync/sync_models.dart';
import '../modules/auth/auth_providers.dart';
import '../modules/workforce/workforce_providers.dart';
import '../shared/widgets/connectivity_banner.dart';
import '../shared/widgets/environment_badge.dart';

class CurvaApp extends ConsumerStatefulWidget {
  const CurvaApp({super.key});

  @override
  ConsumerState<CurvaApp> createState() => _CurvaAppState();
}

class _CurvaAppState extends ConsumerState<CurvaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncCoordinatorProvider).requestSync(SyncTrigger.foreground);
      ref.invalidate(offlineImagePrefetchProvider);
      unawaited(_refreshAttendanceReferences());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    ref.listen(authControllerProvider, (previous, next) {
      final authState = next.valueOrNull;
      if (authState == null || authState.isAuthenticated) {
        return;
      }

      final currentLocation = AppRouter.router.state.matchedLocation;
      if (currentLocation != RouteNames.splash &&
          currentLocation != RouteNames.login) {
        AppRouter.router.go(RouteNames.login);
      }
    });
    ref.listen(authControllerProvider, (previous, next) {
      if (next.valueOrNull?.isAuthenticated ?? false) {
        ref.read(syncCoordinatorProvider).requestSync(SyncTrigger.bootstrap);
        unawaited(_refreshAttendanceReferences());
      }
    });
    ref.listen(connectivityStateProvider, (previous, next) {
      final previousStatus = previous?.valueOrNull?.status;
      final nextStatus = next.valueOrNull?.status;
      if (nextStatus == ConnectionStatus.online &&
          previousStatus != ConnectionStatus.online) {
        ref
            .read(syncCoordinatorProvider)
            .requestSync(SyncTrigger.connectivityRestored);
        unawaited(_refreshAttendanceReferences());
      }
    });
    ref.watch(projectSyncRefreshProvider);
    ref.watch(offlineImagePrefetchProvider);
    ref.listen(pendingOperationCountProvider, (previous, next) {
      final count = next.valueOrNull;
      if (count != null && ref.read(currentAccountIdProvider) != null) {
        ref.read(syncCoordinatorProvider).updatePendingCount(count);
      }
    });

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUiOverlayStyle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (child != null)
                Column(
                  children: [
                    const ConnectivityBanner(),
                    Expanded(
                      // Keep the router under the same widget type when the
                      // connectivity status changes. Conditionally inserting
                      // this MediaQuery used to unmount the whole routed page,
                      // disposing auto-dispose providers (including the project
                      // task list) exactly when the device went offline.
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: isOffline,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ValueListenableBuilder<bool>(
                valueListenable: networkInspectorEnabled,
                builder: (context, isEnabled, _) {
                  if (!isEnabled) {
                    return const SizedBox.shrink();
                  }

                  return const _NetworkInspectorButton();
                },
              ),
              const EnvironmentBadge(flavor: appFlavor),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshAttendanceReferences() async {
    try {
      await ref.read(attendanceRepositoryProvider)?.refreshReferences();
    } catch (_) {
      // Cache lama tetap digunakan. Foreground refresh berikutnya akan mencoba
      // kembali tanpa mengosongkan state offline.
    }
  }
}

class _NetworkInspectorButton extends StatefulWidget {
  const _NetworkInspectorButton();

  @override
  State<_NetworkInspectorButton> createState() =>
      _NetworkInspectorButtonState();
}

class _NetworkInspectorButtonState extends State<_NetworkInspectorButton> {
  static const double _buttonSize = 44;
  static const double _screenMargin = 16;

  bool _isInspectorOpen = false;
  Offset? _position;

  Future<void> _openInspector() async {
    if (_isInspectorOpen) {
      return;
    }

    setState(() => _isInspectorOpen = true);
    await AppRouter.rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => ActivityPage()),
    );
    if (mounted) {
      setState(() => _isInspectorOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInspectorOpen) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final position = _constrainPosition(
      _position ??
          Offset(
            mediaQuery.size.width -
                mediaQuery.padding.right -
                _screenMargin -
                _buttonSize,
            mediaQuery.size.height -
                mediaQuery.padding.bottom -
                _screenMargin -
                _buttonSize,
          ),
      mediaQuery,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: SizedBox.square(
        dimension: _buttonSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openInspector,
          onPanUpdate: (details) {
            setState(() {
              _position = _constrainPosition(
                (_position ?? position) + details.delta,
                mediaQuery,
              );
            });
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.overlayShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.network_check,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Offset _constrainPosition(Offset position, MediaQueryData mediaQuery) {
    final minX = mediaQuery.padding.left + _screenMargin;
    final minY = mediaQuery.padding.top + _screenMargin;
    final maxX =
        mediaQuery.size.width -
        mediaQuery.padding.right -
        _screenMargin -
        _buttonSize;
    final maxY =
        mediaQuery.size.height -
        mediaQuery.padding.bottom -
        _screenMargin -
        _buttonSize;

    return Offset(
      position.dx.clamp(minX, maxX < minX ? minX : maxX),
      position.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }
}
