import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/workforce/data/models/location.dart';
import 'package:curva_mobile/modules/workforce/data/models/overtime.dart';
import 'package:curva_mobile/modules/workforce/data/workforce_repository.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_overtime_request_page.dart';
import 'package:curva_mobile/modules/workforce/presentation/workforce_request_form_controllers.dart';
import 'package:curva_mobile/modules/workforce/workforce_providers.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('maps API overtime errors to their respective fields', (
    tester,
  ) async {
    final storage = _FakeSecureStorage();
    final repository = _ValidationErrorWorkforceRepository(
      dioClient: DioClient(secureStorage: storage),
    );
    late OvertimeRequestFormController form;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workforceRepositoryProvider.overrideWithValue(repository),
          overtimeRequestFormControllerProvider.overrideWith((ref) {
            form = OvertimeRequestFormController(ref)
              ..setDate(DateTime(2026, 8, 21))
              ..setStartTime(const TimeOfDay(hour: 9, minute: 0))
              ..setEndTime(const TimeOfDay(hour: 10, minute: 0))
              ..setLocationType('Office')
              ..setLocation(_location)
              ..reasonController.text = 'Alasan pengujian';
            return form;
          }),
        ],
        child: const MaterialApp(home: WorkforceOvertimeRequestPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajukan lembur'));
    await tester.pumpAndSettle();

    expect(form.dateError, 'Tanggal wajib diisi.');
    expect(form.startTimeError, 'Waktu mulai wajib diisi.');
    expect(form.endTimeError, 'Waktu berakhir wajib diisi.');
    expect(form.locationTypeError, 'Tipe lokasi wajib dipilih.');
    expect(form.locationError, 'Lokasi wajib dipilih.');
    expect(form.reasonError, 'Alasan lembur wajib diisi.');
    expect(find.text('Tanggal wajib diisi.'), findsOneWidget);
    expect(find.text('Periksa kembali data yang ditandai.'), findsNothing);
    expect(find.text('Data yang diberikan tidak valid.'), findsNothing);
  });
}

const _location = WorkforceLocation(
  id: 'location-1',
  type: 'Office',
  code: 'OFFICE-1',
  name: 'Kantor Pusat',
  latitude: '-6.2',
  longitude: '106.8',
);

class _ValidationErrorWorkforceRepository extends WorkforceRepository {
  const _ValidationErrorWorkforceRepository({required super.dioClient});

  @override
  Future<String?> submitOvertime(OvertimeRequestInput input) async {
    throw const AppException(
      'Data yang diberikan tidak valid.',
      code: 'VALIDATION_ERROR',
      details: [
        'overtimeDate: Tanggal wajib diisi.',
        'startTime: Waktu mulai wajib diisi.',
        'endTime: Waktu berakhir wajib diisi.',
        'locationType: Tipe lokasi wajib dipilih.',
        'locationId: Lokasi wajib dipilih.',
        'reason: Alasan lembur wajib diisi.',
      ],
      hasErrors: true,
    );
  }
}

class _FakeSecureStorage extends SecureStorageService {}
