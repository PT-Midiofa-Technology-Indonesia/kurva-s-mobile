import 'package:curva_mobile/app/app_config.dart';
import 'package:curva_mobile/app/app_environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android loads only the file selected by the build flavor', () {
    for (final name in ['staging', 'demo', 'production']) {
      expect(
        AppEnvironment.envFileFor(
          platform: TargetPlatform.android,
          isWeb: false,
          flavor: name,
        ),
        'config/$name/.env',
      );
    }
  });

  test('Android never silently falls back to production', () {
    for (final flavor in [null, '', 'prod', 'stag', 'unknown']) {
      expect(
        () => AppEnvironment.envFileFor(
          platform: TargetPlatform.android,
          isWeb: false,
          flavor: flavor,
        ),
        throwsStateError,
      );
    }
  });

  test('non-Android platforms retain their existing environment file', () {
    for (final platform in TargetPlatform.values) {
      if (platform == TargetPlatform.android) continue;
      expect(
        AppEnvironment.envFileFor(
          platform: platform,
          isWeb: false,
          flavor: null,
        ),
        '.env',
      );
    }
    expect(
      AppEnvironment.envFileFor(
        platform: TargetPlatform.android,
        isWeb: true,
        flavor: null,
      ),
      '.env',
    );
  });

  group('startup URL validation', () {
    tearDown(dotenv.clean);

    test('accepts HTTP(S) URLs including API paths and local ports', () {
      for (final url in [
        'https://api.example.test/api/v1/',
        'http://localhost:8080/api',
      ]) {
        dotenv.testLoad(fileInput: 'BASE_URL=$url');
        expect(AppConfig.validate, returnsNormally);
      }
    });

    test(
      'rejects missing, malformed, relative and credential-bearing URLs',
      () {
        for (final value in [
          '',
          '/api',
          'api.example.test',
          'https://',
          'https://bad host.test',
          'ftp://example.test',
          'https://user:password@example.test',
        ]) {
          dotenv.testLoad(fileInput: 'BASE_URL=$value');
          expect(AppConfig.validate, throwsStateError);
        }
        dotenv.testLoad(fileInput: 'UNRELATED=true');
        expect(AppConfig.validate, throwsStateError);
      },
    );
  });
}
