import 'package:curva_mobile/modules/workforce/data/models/overtime.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API date/time conversion', () {
    test(
      'interprets a timestamp without offset as UTC and returns local time',
      () {
        final result = parseApiDateTime('2026-07-20T12:30:45');

        expect(result, DateTime.utc(2026, 7, 20, 12, 30, 45).toLocal());
      },
    );

    test('does not shift a calendar-only date', () {
      final result = parseApiDateTime('2026-07-20');

      expect(result, DateTime(2026, 7, 20));
    });

    test('combines separate UTC date and time before converting to local', () {
      final result = parseApiUtcDateAndTime('2026-07-20', '23:15');

      expect(result, DateTime.utc(2026, 7, 20, 23, 15).toLocal());
    });

    test('combines local calendar date and time without shifting the day', () {
      final result = parseLocalDateAndTime('2026-07-20', '23:15:30');

      expect(result, DateTime(2026, 7, 20, 23, 15, 30));
    });

    test('formats a full API timestamp in local device time', () {
      final local = DateTime.utc(2026, 7, 20, 23, 15).toLocal();

      expect(
        formatApiTime(date: null, time: '2026-07-20T23:15:00Z'),
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}',
      );
    });

    test('formats separate UTC date and time in local device time', () {
      final local = DateTime.utc(2026, 7, 20, 23, 15).toLocal();

      expect(
        formatApiTime(date: '2026-07-20', time: '23:15'),
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}',
      );
    });

    test('serializes overtime date and clock fields in local time', () {
      final localDate = DateTime(2026, 7, 20);
      final input = OvertimeRequestInput(
        overtimeDate: localDate,
        startTime: '08:30',
        endTime: '10:15',
        locationType: 'office',
        locationId: 'location-id',
        reason: 'Testing',
      );

      final json = input.toJson();

      expect(json['overtimeDate'], formatDateParam(localDate));
      expect(json['startTime'], '08:30');
      expect(json['endTime'], '10:15');
    });
  });
}
