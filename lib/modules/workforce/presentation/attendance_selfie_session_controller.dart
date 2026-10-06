import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

final attendanceSelfieSessionControllerProvider =
    ChangeNotifierProvider.autoDispose<AttendanceSelfieSessionController>((
      ref,
    ) {
      return AttendanceSelfieSessionController();
    });

class AttendanceSelfieSessionController extends ChangeNotifier {
  static const _locationTimeout = Duration(seconds: 15);
  XFile? selfie;
  Position? position;
  bool openingCamera = false;
  bool loadingLocation = false;
  bool preparingSession = false;
  bool locationServiceDisabled = false;
  bool openedLocationSettings = false;
  String? errorMessage;
  String? locationErrorMessage;

  void setPreparing(bool value) {
    preparingSession = value;
    notifyListeners();
  }

  Future<Position?> loadLocation() async {
    loadingLocation = true;
    locationServiceDisabled = false;
    locationErrorMessage = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationServiceDisabled = true;
        locationErrorMessage = 'Layanan lokasi belum aktif.';
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationErrorMessage = 'Izin lokasi diperlukan untuk presensi.';
        return null;
      }
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      );
      return position;
    } on TimeoutException {
      locationErrorMessage =
          'Lokasi belum terbaca. Pastikan GPS aktif lalu coba lagi.';
      return null;
    } catch (_) {
      locationErrorMessage = 'Lokasi tidak dapat dibaca. Coba lagi.';
      return null;
    } finally {
      loadingLocation = false;
      notifyListeners();
    }
  }

  void beginCamera() {
    openingCamera = true;
    errorMessage = null;
    notifyListeners();
  }

  void setCameraResult(XFile? value) {
    selfie = value;
    openingCamera = false;
    errorMessage = value == null ? 'Pengambilan foto dibatalkan.' : null;
    notifyListeners();
  }

  void setCameraError([String? message]) {
    openingCamera = false;
    errorMessage = message ?? 'Kamera tidak dapat dibuka. Periksa izin kamera.';
    notifyListeners();
  }

  Future<bool> ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isDenied) status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return true;
    errorMessage = status.isPermanentlyDenied
        ? 'Izin kamera ditolak permanen. Aktifkan izin kamera dari pengaturan aplikasi.'
        : 'Izin kamera diperlukan untuk presensi.';
    notifyListeners();
    if (status.isPermanentlyDenied) await openAppSettings();
    return false;
  }

  Future<void> openLocationSettings() async {
    openedLocationSettings = true;
    await Geolocator.openLocationSettings();
  }

  void resumedFromLocationSettings() {
    openedLocationSettings = false;
    loadLocation();
  }
}
