import 'package:curva_mobile/modules/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth user can be restored from its cached JSON', () {
    const user = AuthUser(
      id: 'user-1',
      name: 'Offline User',
      email: 'offline@example.com',
      phoneNumber: '08123456789',
      isActive: true,
      userType: 'employee',
      registeredSince: '2025-01-01',
      workplace: AuthWorkplace(id: 'site-1', name: 'Site A', type: 'site'),
      roles: ['supervisor'],
      permissions: ['project.read'],
      companies: [AuthCompany(id: 'company-1', name: 'Company A')],
      assignments: [
        AuthAssignment(
          company: AuthCompany(id: 'company-1', name: 'Company A'),
          department: AuthDepartment(id: 'department-1', name: 'Operations'),
        ),
      ],
    );

    final restored = AuthUser.fromJson(user.toJson());

    expect(restored.id, user.id);
    expect(restored.name, user.name);
    expect(restored.phoneNumber, user.phoneNumber);
    expect(restored.workplace?.id, 'site-1');
    expect(restored.roles, ['supervisor']);
    expect(restored.permissions, ['project.read']);
    expect(restored.companies.single.id, 'company-1');
    expect(restored.assignments.single.department?.id, 'department-1');
  });
}
