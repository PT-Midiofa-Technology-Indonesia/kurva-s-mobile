import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'Curva-S';
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static void validate() {
    final value = baseUrl;
    final uri = Uri.tryParse(value);
    if (value.trim() != value ||
        uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        RegExp(r'\s').hasMatch(value)) {
      throw StateError('BASE_URL wajib berupa URL HTTP(S) dengan host valid.');
    }
  }
}
