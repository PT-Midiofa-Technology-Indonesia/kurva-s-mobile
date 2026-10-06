import 'package:flutter/material.dart';

import '../../core/sync/sync_models.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({required this.status, super.key});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (status.state) {
      SyncRunState.syncing => (Icons.sync, 'Sedang menyinkronkan'),
      SyncRunState.paused => (
        Icons.pause_circle_outline,
        'Sinkronisasi dijeda',
      ),
      SyncRunState.failed => (Icons.error_outline, 'Sinkronisasi gagal'),
      SyncRunState.completed => (Icons.cloud_done_outlined, 'Tersinkronisasi'),
      SyncRunState.idle => (Icons.cloud_queue_outlined, 'Siap menyinkronkan'),
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}
