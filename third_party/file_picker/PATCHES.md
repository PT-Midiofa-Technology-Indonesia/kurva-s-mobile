# Local Android bitmap fix

Based on the unmodified runtime sources of `file_picker` 10.3.10 from pub.dev,
under the included MIT LICENSE. The root pubspec uses this directory directly,
so the fix survives clean builds and does not depend on a modified pub cache.

Play Console's release mapping identifies `R1.i.b` as `FileUtils.compressImage`.
That method previously decoded full-resolution images without BitmapFactory.Options.
The patch reads bounds, reopens the content URI, and decodes using a power-of-two
inSampleSize that limits the longest edge to 2048 pixels. Small images retain
their dimensions. Streams are closed and decoded pixels are recycled even when
compression fails. This affects image compression only; original documents and
images selected without compression are not resized.

The Android compression implementation and its tests are patched. Version 12
has an upstream compression rewrite, but also changes file selection APIs and the
iOS deployment minimum. This local patch preserves the existing cross-platform API.
Remove the local dependency when deliberately migrating to that upstream API.

Validation: `cd android && ./gradlew :file_picker:testDebugUnitTest`.

## Built-in Kotlin migration

The Android Gradle configuration also uses AGP 9 built-in Kotlin: the standalone
Kotlin plugin/classpath are removed, and `kotlin.compilerOptions` keeps the JVM 11
target aligned with Java. The plugin requires Flutter >=3.44 / Dart >=3.12 for
this DSL; the host enables built-in Kotlin with Flutter >=3.47.
The bitmap patch and all runtime APIs remain unchanged.

Validate both `fvm flutter build apk --debug --flavor staging` from the repository
root and `cd android && ./gradlew :file_picker:testDebugUnitTest` with JDK 17.
