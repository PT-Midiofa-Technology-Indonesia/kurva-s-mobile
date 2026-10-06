import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/media/offline_image_providers.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/shared/widgets/offline_image.dart';

void main() {
  const url = 'https://storage.example/photo.png';
  Widget app({File? file}) => ProviderScope(
    overrides: [
      offlineImagesEnabledProvider.overrideWithValue(true),
      connectivityStateProvider.overrideWith(
        (_) => Stream.value(const ConnectivityState.offline()),
      ),
      offlineImageFileProvider(url).overrideWith((_) async => file),
    ],
    child: const MaterialApp(
      home: Scaffold(body: OfflineImage(url, width: 40, height: 40)),
    ),
  );

  testWidgets('offline missing image explains availability in preview', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(
      find.byTooltip(
        'Gambar belum tersedia offline. Hubungkan internet untuk mengunduh.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(OfflineImage));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Gambar belum tersedia offline. Hubungkan internet untuk mengunduh.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.byType(OfflineImage), findsOneWidget);
  });

  testWidgets('thumbnail and full preview both render the downloaded file', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('image_widget_test_'),
    ))!;
    final file = File('${root.path}/pixel.png');
    await tester.runAsync(
      () => file.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4AWP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
        ),
      ),
    );
    await tester.pumpWidget(app(file: file));
    await tester.pumpAndSettle();
    final thumbnail = tester.widget<Image>(find.byType(Image));
    expect(thumbnail.image, isA<FileImage>());
    await tester.tap(find.byType(OfflineImage));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Image>(find.byType(Image).last).image,
      isA<FileImage>(),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => root.delete(recursive: true));
  });
}
