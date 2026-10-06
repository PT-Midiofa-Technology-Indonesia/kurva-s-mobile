import 'dart:convert';
import 'dart:io';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/shared/widgets/image_preview.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview supports zoom, reset, close and system back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImagePreview(
            title: 'Foto laporan',
            previewBuilder: (_) => const FlutterLogo(size: 200),
            child: const Icon(Icons.photo),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.photo));
    await tester.pumpAndSettle();
    expect(find.text('Foto laporan'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    final previewBackground = tester.widget<ColoredBox>(
      find.ancestor(
        of: find.byType(InteractiveViewer),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(previewBackground.color, AppColors.black);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final first = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(center - const Offset(60, 0));
    await second.moveTo(center + const Offset(60, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(100, 0));
    await second.moveTo(center + const Offset(100, 0));
    await tester.pump();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reset ukuran'));
    await tester.pump();
    expect(viewer.transformationController!.value, Matrix4.identity());
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(find.byIcon(Icons.photo));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('local upload opens original image without triggering remove', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('preview_test_'),
    ))!;
    final file = File('${root.path}/pixel.png');
    await tester.runAsync(
      () => file.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4AWP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
        ),
      ),
    );
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadImageList(
            items: [
              UploadImageItem(
                name: 'Foto.png',
                path: file.uri.toString(),
                size: 100,
              ),
            ],
            onRemovePressed: (_) => removed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ImagePreview));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<FileImage>());
    expect((image.image as FileImage).file.path, file.path);
    expect(removed, isFalse);
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus bukti'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => root.delete(recursive: true));
  });

  testWidgets('failed remote image remains closable on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImagePreview.network(
            url: 'https://storage.example/missing.jpg',
            title: 'Nama foto yang sangat panjang untuk menguji layar kecil',
            child: const Icon(Icons.photo),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.photo));
    await tester.pumpAndSettle();
    expect(find.text('Gambar tidak dapat ditampilkan.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
