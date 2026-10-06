// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LeaveListResultToJson(LeaveListResult instance) =>
    <String, dynamic>{
      'records': instance.records.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
      'links': instance.links.toJson(),
    };

Map<String, dynamic> _$LeaveRecordToJson(LeaveRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'reason': instance.reason,
      'leaveType': instance.leaveType?.toJson(),
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'totalDays': instance.totalDays,
      'status': instance.status,
      'adminNote': instance.adminNote,
      'balance': instance.balance?.toJson(),
      'submittedAt': instance.submittedAt,
      'apiStatusLabel': instance.apiStatusLabel,
      'canSubmit': instance.canSubmit,
    };

Map<String, dynamic> _$LeaveTypeToJson(LeaveType instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'isPaid': instance.isPaid,
  'requiresDocument': instance.requiresDocument,
  'quota': instance.quota,
  'balance': instance.balance?.toJson(),
};

Map<String, dynamic> _$LeaveReferenceToJson(LeaveReference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

Map<String, dynamic> _$LeaveBalanceToJson(LeaveBalance instance) =>
    <String, dynamic>{
      'quota': instance.quota,
      'used': instance.used,
      'remaining': instance.remaining,
    };

Map<String, dynamic> _$LeaveRequestInputToJson(LeaveRequestInput instance) =>
    <String, dynamic>{
      'leaveTypeId': instance.leaveTypeId,
      'reason': instance.reason,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
    };
