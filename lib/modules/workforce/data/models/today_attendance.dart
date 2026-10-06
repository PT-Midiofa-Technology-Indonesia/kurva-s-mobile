import 'package:json_annotation/json_annotation.dart';

part 'today_attendance.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class TodayAttendance {
  const TodayAttendance({
    required this.date,
    required this.serverTime,
    required this.regular,
    required this.overtime,
  });

  final String date;
  final String serverTime;
  final RegularAttendance regular;
  final OvertimeAttendance overtime;

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      date: json['date'] as String? ?? '',
      serverTime: json['serverTime'] as String? ?? '',
      regular: json['regular'] is Map<String, dynamic>
          ? RegularAttendance.fromJson(json['regular'] as Map<String, dynamic>)
          : const RegularAttendance(
              checkedIn: false,
              checkedOut: false,
              workplace: null,
            ),
      overtime: json['overtime'] is Map<String, dynamic>
          ? OvertimeAttendance.fromJson(
              json['overtime'] as Map<String, dynamic>,
            )
          : const OvertimeAttendance(available: false),
    );
  }
  Map<String, dynamic> toJson() => _$TodayAttendanceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class RegularAttendance {
  const RegularAttendance({
    required this.checkedIn,
    required this.checkedOut,
    required this.workplace,
    this.attendanceId,
    this.clientSessionId,
    this.checkInOccurredAt,
    this.checkInSyncedAt,
    this.checkOutOccurredAt,
    this.checkOutSyncedAt,
  });

  final bool checkedIn;
  final bool checkedOut;
  final String? attendanceId;
  final AttendanceWorkplace? workplace;
  final String? clientSessionId;
  final String? checkInOccurredAt;
  final String? checkInSyncedAt;
  final String? checkOutOccurredAt;
  final String? checkOutSyncedAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasOpenAttendance => checkedIn && !checkedOut;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get canCheckIn => !checkedIn;

  factory RegularAttendance.fromJson(Map<String, dynamic> json) {
    return RegularAttendance(
      checkedIn: json['checkedIn'] == true,
      checkedOut: json['checkedOut'] == true,
      attendanceId: json['attendanceId'] as String?,
      clientSessionId: json['clientSessionId'] as String?,
      checkInOccurredAt: json['checkInOccurredAt'] as String?,
      checkInSyncedAt: json['checkInSyncedAt'] as String?,
      checkOutOccurredAt: json['checkOutOccurredAt'] as String?,
      checkOutSyncedAt: json['checkOutSyncedAt'] as String?,
      workplace: json['workplace'] is Map<String, dynamic>
          ? AttendanceWorkplace.fromJson(
              json['workplace'] as Map<String, dynamic>,
            )
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$RegularAttendanceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AttendanceWorkplace {
  const AttendanceWorkplace({
    required this.type,
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.workStartTime,
    required this.workEndTime,
  });

  final String type;
  final String id;
  final String name;
  final String latitude;
  final String longitude;
  final int radiusMeters;
  final String workStartTime;
  final String workEndTime;

  factory AttendanceWorkplace.fromJson(Map<String, dynamic> json) {
    return AttendanceWorkplace(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
      radiusMeters: _intValue(json['radiusMeters']),
      workStartTime: json['workStartTime'] as String? ?? '',
      workEndTime: json['workEndTime'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => _$AttendanceWorkplaceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class OvertimeAttendance {
  const OvertimeAttendance({
    required this.available,
    this.overtimeId,
    this.reason,
    this.startTime,
    this.endTime,
    this.window,
    this.checkedIn = false,
    this.checkedOut = false,
    this.attendanceId,
    this.workplace,
    this.clientSessionId,
    this.checkInOccurredAt,
    this.checkInSyncedAt,
    this.checkOutOccurredAt,
    this.checkOutSyncedAt,
  });

  final bool available;
  final String? overtimeId;
  final String? reason;
  final String? startTime;
  final String? endTime;
  final OvertimeAttendanceWindow? window;
  final bool checkedIn;
  final bool checkedOut;
  final String? attendanceId;
  final AttendanceWorkplace? workplace;
  final String? clientSessionId;
  final String? checkInOccurredAt;
  final String? checkInSyncedAt;
  final String? checkOutOccurredAt;
  final String? checkOutSyncedAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasOpenAttendance => available && checkedIn && !checkedOut;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get canCheckIn =>
      available &&
      !checkedIn &&
      !checkedOut &&
      overtimeId != null &&
      overtimeId!.isNotEmpty;

  factory OvertimeAttendance.fromJson(Map<String, dynamic> json) {
    return OvertimeAttendance(
      available: json['available'] == true,
      overtimeId: json['overtimeId'] as String?,
      reason: json['reason'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      window: json['window'] is Map<String, dynamic>
          ? OvertimeAttendanceWindow.fromJson(
              json['window'] as Map<String, dynamic>,
            )
          : null,
      checkedIn: json['checkedIn'] == true,
      checkedOut: json['checkedOut'] == true,
      attendanceId: json['attendanceId'] as String?,
      clientSessionId: json['clientSessionId'] as String?,
      checkInOccurredAt: json['checkInOccurredAt'] as String?,
      checkInSyncedAt: json['checkInSyncedAt'] as String?,
      checkOutOccurredAt: json['checkOutOccurredAt'] as String?,
      checkOutSyncedAt: json['checkOutSyncedAt'] as String?,
      workplace: json['workplace'] is Map<String, dynamic>
          ? AttendanceWorkplace.fromJson(
              json['workplace'] as Map<String, dynamic>,
            )
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$OvertimeAttendanceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class OvertimeAttendanceWindow {
  const OvertimeAttendanceWindow({required this.from, required this.to});

  final String from;
  final String to;

  factory OvertimeAttendanceWindow.fromJson(Map<String, dynamic> json) {
    return OvertimeAttendanceWindow(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => _$OvertimeAttendanceWindowToJson(this);
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
