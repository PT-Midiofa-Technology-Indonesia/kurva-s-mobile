import 'package:flutter/material.dart';

class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Semantics(
      label: '$count perubahan menunggu sinkronisasi',
      child: Chip(
        avatar: const Icon(Icons.schedule_send_outlined, size: 16),
        label: Text('$count menunggu sinkronisasi'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
