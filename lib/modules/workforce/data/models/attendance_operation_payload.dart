import 'package:json_annotation/json_annotation.dart';

part 'attendance_operation_payload.g.dart';

enum AttendanceAction { checkIn, checkOut }

enum AttendanceType { regular, overtime }

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendanceOperationPayload {
  const AttendanceOperationPayload({
    required this.clientSessionId,
    required this.action,
    required this.type,
    required this.occurredAt,
    required this.timezoneOffsetMinutes,
    required this.latitude,
    required this.longitude,
    this.overtimeId,
    this.overtimeLabel,
    this.accuracyMeters,
    this.isMocked = false,
  });

  static const payloadVersion = 1;

  final String clientSessionId;
  final AttendanceAction action;
  final AttendanceType type;
  final String? overtimeId;
  final String? overtimeLabel;
  final DateTime occurredAt;
  final int timezoneOffsetMinutes;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final bool isMocked;

  Map<String, Object?> toJson() {
    final json = _$AttendanceOperationPayloadToJson(this);
    json['payloadVersion'] = payloadVersion;
    json['action'] = action == AttendanceAction.checkIn
        ? 'check_in'
        : 'check_out';
    json['occurredAt'] = occurredAt.toUtc().toIso8601String();
    return json;
  }

  factory AttendanceOperationPayload.fromJson(Map<String, dynamic> json) {
    if (json['payloadVersion'] != payloadVersion) {
      throw const FormatException('Versi payload presensi tidak didukung.');
    }
    final sessionId = json['clientSessionId'] as String? ?? '';
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    if (sessionId.isEmpty || occurredAt == null) {
      throw const FormatException('Payload presensi tidak lengkap.');
    }
    return AttendanceOperationPayload(
      clientSessionId: sessionId,
      action: switch (json['action']) {
        'check_in' => AttendanceAction.checkIn,
        'check_out' => AttendanceAction.checkOut,
        _ => throw const FormatException('Aksi presensi tidak valid.'),
      },
      type: switch (json['type']) {
        'regular' => AttendanceType.regular,
        'overtime' => AttendanceType.overtime,
        _ => throw const FormatException('Jenis presensi tidak valid.'),
      },
      overtimeId: json['overtimeId'] as String?,
      overtimeLabel: json['overtimeLabel'] as String?,
      occurredAt: occurredAt.toUtc(),
      timezoneOffsetMinutes:
          (json['timezoneOffsetMinutes'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      isMocked: json['isMocked'] == true,
    );
  }
}

class AttendanceCapture {
  const AttendanceCapture({
    required this.selfiePath,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.isMocked = false,
    this.occurredAt,
  });

  final String selfiePath;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final bool isMocked;
  final DateTime? occurredAt;
}

sealed class AttendanceEnqueueResult {
  const AttendanceEnqueueResult();
}

class AttendanceStored extends AttendanceEnqueueResult {
  const AttendanceStored({
    required this.operationId,
    required this.clientSessionId,
  });

  final String operationId;
  final String clientSessionId;
}

class AttendanceStoreFailed extends AttendanceEnqueueResult {
  const AttendanceStoreFailed(this.message);
  final String message;
}
