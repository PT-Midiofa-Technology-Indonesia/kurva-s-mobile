String formatDate(String? value) {
  final date = parseApiDateTime(value);
  if (date == null) return value == null || value.isEmpty ? '-' : value;

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatIndonesianDate(String? value, {bool shortMonth = false}) {
  final date = parseApiDateTime(value);
  if (date == null) return value == null || value.isEmpty ? '-' : value;

  const shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  const longMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  final months = shortMonth ? shortMonths : longMonths;
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Parses a date/time returned by the API for display in the device timezone.
///
/// Backend timestamps are UTC. Some responses omit the trailing `Z`, so a
/// date-time without an explicit offset is interpreted as UTC as well. A
/// date-only value is a calendar date (not an instant) and is intentionally
/// left unchanged to prevent it moving to another day in negative timezones.
DateTime? parseApiDateTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = value.trim();
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return null;

  final hasTime = normalized.contains('T') || normalized.contains(' ');
  if (!hasTime) return parsed;

  final utc = parsed.isUtc
      ? parsed
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.toLocal();
}

/// Serializes an instant sent to the API as an ISO-8601 UTC timestamp.
String? formatUtcDateTimeParam(DateTime? value) =>
    value?.toUtc().toIso8601String();

/// Combines separate UTC date and time fields from the API into local time.
DateTime? parseApiUtcDateAndTime(String? date, String? time) {
  if (date == null || time == null) return null;
  final dateParts = date.split('-');
  final timeParts = time.split(':');
  if (dateParts.length < 3 || timeParts.length < 2) return null;

  final year = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final day = int.tryParse(dateParts[2].substring(0, 2));
  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  if ([year, month, day, hour, minute].contains(null)) return null;

  return DateTime.utc(year!, month!, day!, hour!, minute!).toLocal();
}

/// Combines separate calendar date and wall-clock fields without applying a
/// timezone conversion.
///
/// This is intended for API fields such as workforce overtime dates/times,
/// whose values describe the user's local calendar rather than a UTC instant.
DateTime? parseLocalDateAndTime(String? date, String? time) {
  if (date == null || time == null) return null;
  final dateParts = date.trim().split('-');
  final timeParts = time.trim().split(':');
  if (dateParts.length < 3 || timeParts.length < 2) return null;

  final year = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final day = int.tryParse(dateParts[2].substring(0, 2));
  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  final second = timeParts.length >= 3
      ? int.tryParse(timeParts[2].split('.').first)
      : 0;
  if ([year, month, day, hour, minute, second].contains(null)) return null;

  final value = DateTime(year!, month!, day!, hour!, minute!, second!);
  if (value.year != year ||
      value.month != month ||
      value.day != day ||
      value.hour != hour ||
      value.minute != minute ||
      value.second != second) {
    return null;
  }
  return value;
}

String? formatDateParam(DateTime? value) {
  if (value == null) return null;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String? formatFilterDate(DateTime? value) {
  if (value == null) return null;
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year.toString().padLeft(4, '0')}';
}

String formatApiTime({required String? date, required String? time}) {
  if (time == null || time.trim().isEmpty) return '-';
  final normalized = time.trim();
  final hasDateTime = normalized.contains('T') || normalized.contains(' ');
  final parsed = hasDateTime
      ? parseApiDateTime(normalized)
      : parseApiUtcDateAndTime(date, normalized);
  if (parsed == null) return normalized;
  return '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}
