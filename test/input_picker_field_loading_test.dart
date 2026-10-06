import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/shared/widgets/input_picker_field.dart';

void main() {
  testWidgets('loading picker disables only itself', (tester) async {
    var pickerPresses = 0;
    var otherPresses = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              InputPickerField(
                label: 'Pilih lokasi',
                value: '',
                isLoading: true,
                loadingText: 'Memuat lokasi...',
                onTap: () => pickerPresses += 1,
              ),
              TextButton(
                onPressed: () => otherPresses += 1,
                child: const Text('Aksi lain'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Memuat lokasi...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Memuat lokasi...'));
    await tester.tap(find.text('Aksi lain'));

    expect(pickerPresses, 0);
    expect(otherPresses, 1);
  });

  testWidgets('loading does not change picker field height', (tester) async {
    Future<double> pumpPicker({
      required bool isLoading,
      String value = '',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputPickerField(
              label: 'Pilih lokasi',
              value: value,
              isLoading: isLoading,
              loadingText: 'Memuat lokasi...',
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getSize(find.byType(InputPickerField)).height;
    }

    final idleHeight = await pumpPicker(isLoading: false);
    final loadingHeight = await pumpPicker(isLoading: true);
    final valuedIdleHeight = await pumpPicker(
      isLoading: false,
      value: 'Kantor pusat',
    );
    final valuedLoadingHeight = await pumpPicker(
      isLoading: true,
      value: 'Kantor pusat',
    );

    expect(loadingHeight, idleHeight);
    expect(valuedLoadingHeight, valuedIdleHeight);
    expect(find.text('Memuat lokasi...'), findsOneWidget);
  });
}
