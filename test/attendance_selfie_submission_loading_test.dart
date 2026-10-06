import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:curva_mobile/modules/workforce/data/models/attendance_operation_payload.dart';
import 'package:curva_mobile/modules/workforce/data/models/today_attendance.dart';
import 'package:curva_mobile/modules/workforce/presentation/attendance_selfie_session_controller.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_attendance_selfie_page.dart';

void main() {
  testWidgets(
    'selfie submission uses inline loading and keeps errors in page',
    (tester) async {
      final submission = Completer<AttendanceStored>();
      final session = AttendanceSelfieSessionController()
        ..selfie = XFile('/tmp/test-selfie.jpg')
        ..position = Position(
          longitude: 106.8,
          latitude: -6.2,
          timestamp: DateTime(2026, 8, 31),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceSelfieSessionControllerProvider.overrideWith(
              (ref) => session,
            ),
            attendanceSelfieSubmissionServiceProvider.overrideWithValue(
              _FakeSubmissionService(submission.future),
            ),
          ],
          child: const MaterialApp(
            home: WorkforceAttendanceSelfiePage(
              request: AttendanceSelfieRequest(
                presenceType: AttendancePresenceType.regular,
                action: AttendanceSelfieAction.checkIn,
                workplace: AttendanceWorkplace(
                  type: 'Office',
                  id: 'office-1',
                  name: 'Kantor',
                  latitude: '-6.2',
                  longitude: '106.8',
                  radiusMeters: 100,
                  workStartTime: '08:00',
                  workEndTime: '17:00',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final modalBarriersBefore = find.byType(ModalBarrier).evaluate().length;

      await tester.tap(find.text('Gunakan Foto'));
      await tester.pump();

      expect(find.text('Menyimpan presensi...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Foto dan lokasi sedang disimpan dengan aman di perangkat.'),
        findsOneWidget,
      );
      expect(find.byType(ModalBarrier).evaluate().length, modalBarriersBefore);

      submission.completeError(StateError('Penyimpanan foto gagal.'));
      await tester.pump();

      expect(find.text('Penyimpanan foto gagal.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Gunakan Foto'), findsOneWidget);
    },
  );
}

class _FakeSubmissionService extends AttendanceSelfieSubmissionService {
  _FakeSubmissionService(this.result) : super(repository: _noRepository);

  final Future<AttendanceStored> result;

  @override
  Future<AttendanceStored> submit({
    required AttendanceSelfieRequest request,
    required AttendanceCapture capture,
  }) => result;

  static Never _noRepository() => throw UnimplementedError();
}
