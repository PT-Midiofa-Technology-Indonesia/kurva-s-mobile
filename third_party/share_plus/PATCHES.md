# Android built-in Kotlin backport

Based on `share_plus` 10.1.4 from pub.dev, under the included LICENSE.
Runtime sources and upstream tests are unchanged; the example app is omitted.
The root pubspec overrides this package so transitive users resolve the same copy.

network_inspector 1.1.4 requires share_plus ^10.1.4. The hosted 13.2.0
migration also requires win32 6, which conflicts with the existing
file_picker Windows implementation (win32 5).
This backport preserves the current Dart APIs and platform implementations.

Changes:
- Remove application of the standalone Kotlin Android Gradle plugin and its
  buildscript dependency.
- Replace `android.kotlinOptions` with `kotlin.compilerOptions` (JVM 17).
- Let Kotlin supply its matching standard library instead of pinning an older one.
- Require Flutter >=3.44 / Dart >=3.12, following Flutter's plugin migration guide.

The host app enables built-in Kotlin using AGP 9 and Flutter >=3.47.
Validate from the repository root with:

```sh
fvm flutter pub get
fvm flutter build apk --debug --flavor staging
```

Remove this override and local copy when upgrading the dependent packages together
to compatible hosted versions that support built-in Kotlin. Do not replace this
copy with the same unpatched upstream version.

Reference: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
