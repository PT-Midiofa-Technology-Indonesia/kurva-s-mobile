import 'package:curva_mobile/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.digitsOnly', () {
    test('requires a value', () {
      expect(
        Validators.digitsOnly(
          '  ',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        'required',
      );
    });

    test('accepts only an integer made entirely of digits', () {
      expect(
        Validators.digitsOnly(
          '100',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
      expect(
        Validators.digitsOnly(
          'abc100',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        'invalid',
      );
    });
  });

  group('Validators.validationDetail', () {
    test('separates a structured field key from its message', () {
      expect(
        Validators.validationDetail('items.1.amount: Nominal tidak valid'),
        (field: 'items.1.amount', message: 'Nominal tidak valid'),
      );
    });

    test('rejects an unstructured detail', () {
      expect(Validators.validationDetail('Nominal tidak valid'), isNull);
    });
  });
}
