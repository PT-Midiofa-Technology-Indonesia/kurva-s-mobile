import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/workforce/data/models/today_attendance.dart';
import 'package:curva_mobile/modules/workforce/presentation/attendance_location_validator.dart';

void main() {
  const workplace = AttendanceWorkplace(
    type: 'office',
    id: 'office-1',
    name: 'Kantor Pusat',
    latitude: '-6.200000',
    longitude: '106.800000',
    radiusMeters: 100,
    workStartTime: '08:00',
    workEndTime: '17:00',
  );

  test('accepts a coordinate inside the workplace radius', () {
    final error = validateAttendanceLocation(
      latitude: -6.2005,
      longitude: 106.8,
      workplace: workplace,
      debugToolsEnabled: false,
    );

    expect(error, isNull);
  });

  test('rejects a coordinate outside the workplace radius', () {
    final error = validateAttendanceLocation(
      latitude: -6.21,
      longitude: 106.8,
      workplace: workplace,
      debugToolsEnabled: false,
    );

    expect(error, contains('di luar radius Kantor Pusat'));
  });

  test('bypasses radius validation when debug tools are enabled', () {
    final error = validateAttendanceLocation(
      latitude: -7,
      longitude: 107,
      workplace: workplace,
      debugToolsEnabled: true,
    );

    expect(error, isNull);
  });

  test('rejects attendance when workplace data is unavailable', () {
    final error = validateAttendanceLocation(
      latitude: -6.2,
      longitude: 106.8,
      workplace: null,
      debugToolsEnabled: false,
    );

    expect(error, contains('belum tersedia'));
  });

  test('allows missing workplace data only when debug tools are enabled', () {
    final error = validateAttendanceLocation(
      latitude: -6.2,
      longitude: 106.8,
      workplace: null,
      debugToolsEnabled: true,
    );

    expect(error, isNull);
  });

  test('rejects an invalid configured workplace', () {
    const invalidWorkplace = AttendanceWorkplace(
      type: 'office',
      id: 'office-1',
      name: 'Kantor Pusat',
      latitude: '',
      longitude: '106.800000',
      radiusMeters: 0,
      workStartTime: '08:00',
      workEndTime: '17:00',
    );

    final error = validateAttendanceLocation(
      latitude: -6.2,
      longitude: 106.8,
      workplace: invalidWorkplace,
      debugToolsEnabled: false,
    );

    expect(error, contains('tidak valid'));
  });
}
