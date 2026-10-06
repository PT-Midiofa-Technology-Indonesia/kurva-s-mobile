import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/upload_source_bottom_sheet.dart';

abstract final class UploadFilePicker {
  static Future<List<PlatformFile>> pick(
    BuildContext context, {
    String sourceTitle = 'Pilih sumber bukti',
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
    bool withData = false,
  }) async {
    final source = await UploadSourceBottomSheet.show(
      context,
      title: sourceTitle,
    );
    if (source == null || !context.mounted) return const [];

    if (source == UploadSource.camera) {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image == null) return const [];

      return [
        PlatformFile(
          name: _fileName(image),
          path: image.path,
          size: await image.length(),
          bytes: withData ? await image.readAsBytes() : null,
        ),
      ];
    }

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
      withData: withData,
    );
    return result?.files ?? const [];
  }

  static String _fileName(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) return name;

    final segments = file.path.split('/');
    return segments.isEmpty ? 'bukti.jpg' : segments.last;
  }
}
