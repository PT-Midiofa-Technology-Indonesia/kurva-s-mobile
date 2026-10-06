import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppEnvironment {
  staging,
  demo,
  production;

  String get envFile => 'config/$name/.env';

  static AppEnvironment fromFlavor(String? flavor) {
    return switch (flavor) {
      'staging' => staging,
      'demo' => demo,
      'production' => production,
      _ => throw StateError(
        'Pilih environment Android dengan --flavor staging, demo, atau production.',
      ),
    };
  }

  static String envFileFor({
    required TargetPlatform platform,
    required bool isWeb,
    required String? flavor,
  }) {
    // Platform lain masih memakai konfigurasi root sebelum migrasi flavor.
    if (isWeb || platform != TargetPlatform.android) return '.env';
    return fromFlavor(flavor).envFile;
  }

  static String get currentEnvFile => envFileFor(
    platform: defaultTargetPlatform,
    isWeb: kIsWeb,
    flavor: appFlavor,
  );
}
