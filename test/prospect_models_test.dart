import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/modules/prospect/data/models/prospect_models.dart';

void main() {
  test('prospect document requirement parses multiple uploaded documents', () {
    final requirement = ProspectDocumentRequirement.fromJson({
      'id': 'requirement-1',
      'isMandatory': true,
      'isActive': true,
      'documentType': {
        'id': 'type-1',
        'code': 'PHOTO',
        'name': 'Foto',
        'allowedFileTypes': 'jpg,png',
        'allowedFileSize': 2048,
      },
      'uploadedDocuments': [
        {
          'id': 'document-1',
          'fileName': 'photo-1.jpg',
          'fileSize': 1024,
          'fileUrl': 'https://example.test/photo-1.jpg',
        },
        {
          'id': 'document-2',
          'fileName': 'photo-2.jpg',
          'fileSize': 2048,
          'fileUrl': 'https://example.test/photo-2.jpg',
        },
      ],
    });

    expect(requirement.uploadedDocuments, hasLength(2));
    expect(requirement.uploadedDocuments.first.id, 'document-1');
    expect(requirement.uploadedDocuments.last.fileName, 'photo-2.jpg');
    expect(requirement.uploadedDocument?.id, 'document-1');
  });

  test(
    'prospect document requirement keeps singular response compatibility',
    () {
      final requirement = ProspectDocumentRequirement.fromJson({
        'id': 'requirement-1',
        'uploadedDocument': {
          'id': 'document-1',
          'name': 'document.pdf',
          'size': 512,
          'url': 'https://example.test/document.pdf',
        },
      });

      expect(requirement.uploadedDocuments, hasLength(1));
      expect(requirement.uploadedDocuments.single.fileName, 'document.pdf');
    },
  );
}
