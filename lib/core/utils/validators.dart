class Validators {
  const Validators._();

  static bool isRequired(String value) {
    return value.trim().isNotEmpty;
  }

  static String? requiredText(String value, String message) {
    return isRequired(value) ? null : message;
  }

  static String? digitsOnly(
    String value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return requiredMessage;
    return RegExp(r'^\d+$').hasMatch(trimmed) ? null : invalidMessage;
  }

  static ({String field, String message})? validationDetail(String detail) {
    final separator = detail.indexOf(':');
    if (separator <= 0 || separator == detail.length - 1) return null;

    return (
      field: detail.substring(0, separator).trim(),
      message: detail.substring(separator + 1).trim(),
    );
  }
}
