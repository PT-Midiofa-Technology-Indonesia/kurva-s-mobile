import '../../../../core/sync/sync_models.dart';
import 'attendance_operation_payload.dart';

class LocalAttendanceRecord {
  const LocalAttendanceRecord({
    required this.clientSessionId,
    required this.type,
    required this.occurredAt,
    required this.checkInAt,
    required this.checkOutAt,
    required this.state,
  });

  final String clientSessionId;
  final AttendanceType type;
  final DateTime occurredAt;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final OutboxState state;

  String get typeLabel => type == AttendanceType.regular ? 'Regular' : 'Lembur';

  String get statusLabel => switch (state) {
    OutboxState.pending => 'Menunggu dikirim',
    OutboxState.processing => 'Sedang dikirim',
    OutboxState.retry => 'Menunggu dikirim ulang',
    OutboxState.failed => 'Gagal disinkronkan',
    OutboxState.conflict => 'Ditolak server',
    OutboxState.rejected => 'Tidak dapat disinkronkan',
    OutboxState.done => 'Tersinkron',
  };
}
