import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/errors/error_mapper.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';

void main() {
  testWidgets('does not show an error toast when API response has errors', (
    tester,
  ) async {
    final exception = ErrorMapper.fromDio(
      _dioError({
        'message': 'Data tidak valid.',
        'errorCode': 'VALIDATION_ERROR',
        'errors': {
          'email': ['Email sudah digunakan.'],
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppToast.error(context, exception),
            child: const Text('Show'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Data tidak valid.'), findsNothing);
  });

  testWidgets('shows only message when API response has no errors', (
    tester,
  ) async {
    final exception = ErrorMapper.fromDio(
      _dioError({'message': 'Akses ditolak.', 'errorCode': 'FORBIDDEN'}),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppToast.error(context, exception),
            child: const Text('Show'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Akses ditolak.'), findsOneWidget);
    expect(find.textContaining('FORBIDDEN'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('replacing a toast removes only the previous overlay entry', (
    tester,
  ) async {
    late BuildContext toastContext;
    var underlyingPresses = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            toastContext = context;
            return Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 72,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 74,
                      child: TextButton(
                        onPressed: () => underlyingPresses += 1,
                        child: const Text('Underlying action'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    AppToast.info(toastContext, 'First toast');
    await tester.pump(const Duration(milliseconds: 300));

    AppToast.warning(toastContext, 'Second toast');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('First toast'), findsNothing);
    expect(find.text('Second toast'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Second toast'), findsNothing);

    await tester.tap(find.text('Underlying action'));
    expect(underlyingPresses, 1);
  });
}

DioException _dioError(Map<String, dynamic> data) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 422,
      data: data,
    ),
  );
}
