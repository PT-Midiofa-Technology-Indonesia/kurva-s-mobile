import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/app_exception.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/modules/prospect/data/models/prospect_models.dart';
import 'package:curva_mobile/modules/prospect/data/prospect_repository.dart';
import 'package:curva_mobile/modules/prospect/presentation/prospect_create_controller.dart';
import 'package:curva_mobile/modules/prospect/presentation/prospect_create_page.dart';
import 'package:curva_mobile/modules/prospect/prospect_providers.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  testWidgets('maps API prospect errors to title and client fields', (
    tester,
  ) async {
    final storage = _FakeSecureStorage();
    final repository = _ValidationErrorProspectRepository(
      dioClient: DioClient(secureStorage: storage),
    );
    late ProspectCreateController form;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prospectRepositoryProvider.overrideWithValue(repository),
          prospectCompanyIdProvider.overrideWithValue(null),
          prospectCreateControllerProvider.overrideWith((ref) {
            form = ProspectCreateController(ref)
              ..titleController.text = 'Prospek pengujian'
              ..clientController.text = 'Klien pengujian'
              ..estimatedValueController.text = '1000000'
              ..setProjectType(_projectType)
              ..setStartPeriod(DateTime(2026, 8, 21))
              ..setEndPeriod(DateTime(2026, 9, 21))
              ..setTenderDeadline(DateTime(2026, 8, 30));
            return form;
          }),
        ],
        child: const MaterialApp(home: ProspectCreatePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(form.clientError, 'Nama klien wajib diisi.');
    expect(form.titleError, 'Judul prospek wajib diisi.');
    expect(find.text('Nama klien wajib diisi.'), findsOneWidget);
    expect(find.text('Judul prospek wajib diisi.'), findsOneWidget);
    expect(find.text('Periksa kembali data yang ditandai.'), findsNothing);
    expect(find.text('Data yang diberikan tidak valid.'), findsNothing);
  });
}

const _projectType = ProspectProjectType(
  id: 'project-type-1',
  code: 'BUILD',
  name: 'Building',
  description: null,
  isActive: true,
);

class _ValidationErrorProspectRepository extends ProspectRepository {
  const _ValidationErrorProspectRepository({required super.dioClient});

  @override
  Future<List<ProspectProjectType>> fetchProjectTypes() async => const [
    _projectType,
  ];

  @override
  Future<String?> createProspect({
    required ProspectCreateRequest request,
    String? companyId,
  }) async {
    throw const AppException(
      'Data yang diberikan tidak valid.',
      code: 'VALIDATION_ERROR',
      details: [
        'clientName: Nama klien wajib diisi.',
        'title: Judul prospek wajib diisi.',
      ],
      hasErrors: true,
    );
  }
}

class _FakeSecureStorage extends SecureStorageService {}
