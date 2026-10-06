// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'period': instance.period.toJson(),
      'attendance': instance.attendance.toJson(),
      'overtime': instance.overtime.toJson(),
      'leave': instance.leave.toJson(),
    };

Map<String, dynamic> _$DashboardPeriodToJson(DashboardPeriod instance) =>
    <String, dynamic>{
      'year': instance.year,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

Map<String, dynamic> _$DashboardAttendanceToJson(
  DashboardAttendance instance,
) => <String, dynamic>{
  'present': instance.present,
  'absent': instance.absent,
  'late': instance.late,
  'leave': instance.leave,
};

Map<String, dynamic> _$DashboardOvertimeToJson(DashboardOvertime instance) =>
    <String, dynamic>{
      'total': instance.total,
      'accepted': instance.accepted,
      'rejected': instance.rejected,
      'requested': instance.requested,
    };

Map<String, dynamic> _$DashboardLeaveToJson(DashboardLeave instance) =>
    <String, dynamic>{
      'approvedDays': instance.approvedDays,
      'rejectedDays': instance.rejectedDays,
    };
