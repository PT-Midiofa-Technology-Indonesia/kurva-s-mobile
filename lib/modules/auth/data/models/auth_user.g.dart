// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'isActive': instance.isActive,
  'userType': instance.userType,
  'registeredSince': instance.registeredSince,
  'workplace': instance.workplace?.toJson(),
  'roles': instance.roles,
  'permissions': instance.permissions,
  'companies': instance.companies.map((e) => e.toJson()).toList(),
  'assignments': instance.assignments.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$AuthWorkplaceToJson(AuthWorkplace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
    };

Map<String, dynamic> _$AuthCompanyToJson(AuthCompany instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

Map<String, dynamic> _$AuthAssignmentToJson(AuthAssignment instance) =>
    <String, dynamic>{
      'company': instance.company?.toJson(),
      'department': instance.department?.toJson(),
    };

Map<String, dynamic> _$AuthDepartmentToJson(AuthDepartment instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
