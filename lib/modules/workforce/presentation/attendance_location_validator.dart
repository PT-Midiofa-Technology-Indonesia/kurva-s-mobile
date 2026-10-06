import 'dart:math' as math;

import '../data/models/today_attendance.dart';

const _earthRadiusMeters = 6371000.0;

String? validateAttendanceLocation({
  required double latitude,
  required double longitude,
  required AttendanceWorkplace? workplace,
  required bool debugToolsEnabled,
}) {
  if (debugToolsEnabled) return null;
  if (workplace == null) {
    return 'Data lokasi presensi belum tersedia. '
        'Hubungkan perangkat ke internet untuk memperbarui data.';
  }

  final workplaceLatitude = double.tryParse(workplace.latitude.trim());
  final workplaceLongitude = double.tryParse(workplace.longitude.trim());
  if (!_isValidCoordinate(workplaceLatitude, workplaceLongitude) ||
      workplace.radiusMeters <= 0) {
    return 'Data koordinat atau radius lokasi presensi tidak valid. '
        'Hubungi admin.';
  }

  if (!_isValidCoordinate(latitude, longitude)) {
    return 'Koordinat perangkat tidak valid. Aktifkan lokasi lalu coba lagi.';
  }

  final distance = _distanceInMeters(
    latitude,
    longitude,
    workplaceLatitude!,
    workplaceLongitude!,
  );
  if (distance <= workplace.radiusMeters) return null;

  final locationName = workplace.name.trim().isEmpty
      ? 'lokasi presensi'
      : workplace.name.trim();
  return 'Anda berada di luar radius $locationName. '
      'Jarak ${distance.round()} m, radius ${workplace.radiusMeters} m.';
}

bool _isValidCoordinate(double? latitude, double? longitude) {
  return latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

double _distanceInMeters(
  double fromLatitude,
  double fromLongitude,
  double toLatitude,
  double toLongitude,
) {
  final latitudeDelta = _toRadians(toLatitude - fromLatitude);
  final longitudeDelta = _toRadians(toLongitude - fromLongitude);
  final fromLatitudeRadians = _toRadians(fromLatitude);
  final toLatitudeRadians = _toRadians(toLatitude);
  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(fromLatitudeRadians) *
          math.cos(toLatitudeRadians) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final normalizedHaversine = haversine.clamp(0.0, 1.0).toDouble();
  final centralAngle =
      2 *
      math.atan2(
        math.sqrt(normalizedHaversine),
        math.sqrt(1 - normalizedHaversine),
      );
  return _earthRadiusMeters * centralAngle;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
