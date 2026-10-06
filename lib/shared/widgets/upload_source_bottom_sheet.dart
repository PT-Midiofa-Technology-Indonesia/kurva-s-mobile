import 'package:flutter/material.dart';

import 'selection_bottom_sheet.dart';

enum UploadSource {
  camera('Camera'),
  file('Ambil dari file');

  const UploadSource(this.label);

  final String label;
}

abstract final class UploadSourceBottomSheet {
  static Future<UploadSource?> show(
    BuildContext context, {
    String title = 'Pilih sumber bukti',
  }) {
    return SelectionBottomSheet.show<UploadSource>(
      context,
      title: title,
      options: UploadSource.values,
      selectedOption: null,
      labelBuilder: (source) => source.label,
    );
  }
}
