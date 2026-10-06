import 'package:json_annotation/json_annotation.dart';

part 'auth_user.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.userType,
    required this.registeredSince,
    this.phoneNumber,
    this.workplace,
    this.roles = const [],
    this.permissions = const [],
    this.companies = const [],
    this.assignments = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool isActive;
  final String userType;
  final String registeredSince;
  final AuthWorkplace? workplace;
  final List<String> roles;
  final List<String> permissions;
  final List<AuthCompany> companies;
  final List<AuthAssignment> assignments;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      userType: json['userType'] as String? ?? '',
      registeredSince: json['registeredSince'] as String? ?? '',
      workplace: json['workplace'] is Map<String, dynamic>
          ? AuthWorkplace.fromJson(json['workplace'] as Map<String, dynamic>)
          : null,
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
      companies: _objectList(json['companies'], AuthCompany.fromJson),
      assignments: _objectList(json['assignments'], AuthAssignment.fromJson),
    );
  }
  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AuthWorkplace {
  const AuthWorkplace({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final String type;

  factory AuthWorkplace.fromJson(Map<String, dynamic> json) {
    return AuthWorkplace(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => _$AuthWorkplaceToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AuthCompany {
  const AuthCompany({required this.id, required this.name});

  final String id;
  final String name;

  factory AuthCompany.fromJson(Map<String, dynamic> json) {
    return AuthCompany(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => _$AuthCompanyToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AuthAssignment {
  const AuthAssignment({this.company, this.department});

  final AuthCompany? company;
  final AuthDepartment? department;

  factory AuthAssignment.fromJson(Map<String, dynamic> json) {
    return AuthAssignment(
      company: json['company'] is Map<String, dynamic>
          ? AuthCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? AuthDepartment.fromJson(json['department'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$AuthAssignmentToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AuthDepartment {
  const AuthDepartment({required this.id, required this.name});

  final String id;
  final String name;

  factory AuthDepartment.fromJson(Map<String, dynamic> json) {
    return AuthDepartment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => _$AuthDepartmentToJson(this);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<String>().toList(growable: false);
}

List<T> _objectList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(mapper)
      .toList(growable: false);
}
