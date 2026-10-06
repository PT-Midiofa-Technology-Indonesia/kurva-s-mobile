import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_state.dart';
import '../../core/offline_first_providers.dart';
import '../../core/sync/sync_models.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStateProvider).valueOrNull;
    final offline = connectivity?.isOffline ?? false;
    if (!offline && !ref.watch(syncPolicyProvider).showGlobalStatusUi) {
      return const SizedBox.shrink();
    }

    final sync = ref.watch(syncStatusProvider).valueOrNull;
    final pending = ref.watch(pendingOperationCountProvider).valueOrNull ?? 0;

    final message = _message(connectivity, sync, pending);
    if (message == null) return const SizedBox.shrink();

    return Material(
      color: offline
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          label: message,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  offline ? Icons.cloud_off_outlined : Icons.sync,
                  size: 18,
                  semanticLabel: offline ? 'Offline' : 'Sinkronisasi',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _message(
    ConnectivityState? connectivity,
    SyncStatus? sync,
    int pending,
  ) {
    if (connectivity?.status == ConnectionStatus.offline) {
      if (pending > 0) {
        return '$pending perubahan menunggu sinkronisasi. Data tersimpan aman di perangkat.';
      }
      return 'Mode offline. Data yang tersimpan tetap tersedia.';
    }
    if (sync?.state == SyncRunState.syncing && pending > 0) {
      return 'Koneksi tersedia. Menyinkronkan $pending perubahan…';
    }
    if (sync?.state == SyncRunState.paused ||
        sync?.state == SyncRunState.failed) {
      return sync?.message ?? 'Sinkronisasi tertunda dan akan dicoba lagi.';
    }
    if (pending > 0) {
      return '$pending perubahan project menunggu sinkronisasi.';
    }
    return null;
  }
}
