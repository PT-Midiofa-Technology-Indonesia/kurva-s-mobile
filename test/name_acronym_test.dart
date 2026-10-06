import 'package:curva_mobile/shared/utils/name_acronym.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nameAcronym', () {
    test('uses the first and last words for a full name', () {
      expect(nameAcronym('Budi Setiawan Putra'), 'BP');
    });

    test('uses one letter for a single-word name', () {
      expect(nameAcronym('Wahyu'), 'W');
    });

    test('normalizes whitespace and casing', () {
      expect(nameAcronym('  dewi   lestari  '), 'DL');
    });

    test('uses a fallback for an empty name', () {
      expect(nameAcronym('   '), '?');
    });
  });
}
