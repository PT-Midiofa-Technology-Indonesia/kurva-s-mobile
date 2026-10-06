import 'package:json_annotation/json_annotation.dart';

part 'dashboard_summary.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class DashboardSummary {
  const DashboardSummary({
    required this.period,
    required this.attendance,
    required this.overtime,
    required this.leave,
  });

  final DashboardPeriod period;
  final DashboardAttendance attendance;
  final DashboardOvertime overtime;
  final DashboardLeave leave;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      period: json['period'] is Map<String, dynamic>
          ? DashboardPeriod.fromJson(json['period'] as Map<String, dynamic>)
          : const DashboardPeriod(year: 0, startDate: '', endDate: ''),
      attendance: json['attendance'] is Map<String, dynamic>
          ? DashboardAttendance.fromJson(
              json['attendance'] as Map<String, dynamic>,
            )
          : const DashboardAttendance(present: 0, absent: 0, late: 0, leave: 0),
      overtime: json['overtime'] is Map<String, dynamic>
          ? DashboardOvertime.fromJson(json['overtime'] as Map<String, dynamic>)
          : const DashboardOvertime(
              total: 0,
              accepted: 0,
              rejected: 0,
              requested: 0,
            ),
      leave: json['leave'] is Map<String, dynamic>
          ? DashboardLeave.fromJson(json['leave'] as Map<String, dynamic>)
          : const DashboardLeave(approvedDays: 0, rejectedDays: 0),
    );
  }

  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class DashboardPeriod {
  const DashboardPeriod({
    required this.year,
    required this.startDate,
    required this.endDate,
  });

  final int year;
  final String startDate;
  final String endDate;

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      year: _intValue(json['year']),
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$DashboardPeriodToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class DashboardAttendance {
  const DashboardAttendance({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
  });

  final int present;
  final int absent;
  final int late;
  final int leave;

  factory DashboardAttendance.fromJson(Map<String, dynamic> json) {
    return DashboardAttendance(
      present: _intValue(json['present']),
      absent: _intValue(json['absent']),
      late: _intValue(json['late']),
      leave: _intValue(json['leave']),
    );
  }

  Map<String, dynamic> toJson() => _$DashboardAttendanceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class DashboardOvertime {
  const DashboardOvertime({
    required this.total,
    required this.accepted,
    required this.rejected,
    required this.requested,
  });

  final int total;
  final int accepted;
  final int rejected;
  final int requested;

  factory DashboardOvertime.fromJson(Map<String, dynamic> json) {
    return DashboardOvertime(
      total: _intValue(json['total'] ?? json['totalOvertime']),
      accepted: _intValue(
        json['accepted'] ?? json['approved'] ?? json['received'],
      ),
      rejected: _intValue(json['rejected']),
      requested: _intValue(
        json['requested'] ?? json['request'] ?? json['pending'],
      ),
    );
  }

  Map<String, dynamic> toJson() => _$DashboardOvertimeToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class DashboardLeave {
  const DashboardLeave({
    required this.approvedDays,
    required this.rejectedDays,
  });

  final int approvedDays;
  final int rejectedDays;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get totalSubmission => approvedDays + rejectedDays;

  factory DashboardLeave.fromJson(Map<String, dynamic> json) {
    return DashboardLeave(
      approvedDays: _intValue(json['approvedDays'] ?? json['approved']),
      rejectedDays: _intValue(json['rejectedDays'] ?? json['rejected']),
    );
  }

  Map<String, dynamic> toJson() => _$DashboardLeaveToJson(this);
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
