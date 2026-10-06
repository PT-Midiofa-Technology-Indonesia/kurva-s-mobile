# curva_mobile

A new Flutter project.

Android builds require Flutter **3.47.2** (see `.fvmrc`) and JDK 17.
See [Android build and Play Console maintenance](docs/android-play-console.md)
for the toolchain, local file-picker patch, and validation steps.

## Android environments

Android mendukung flavor `staging`, `demo`, dan `production`, semuanya bernama
**Curva-S**. Jalankan dengan `fvm flutter run --flavor staging` atau build dengan
`fvm flutter build apk --flavor production --release`.

Lihat [panduan environment Android](docs/android-environments.md) untuk file `.env`,
Firebase, keystore, ikon, serta setup lokal/CI. Konfigurasi lokal staging/demo
sementara menyalin production; JSON Firebase perlu client resmi untuk package
staging/demo sebelum kedua flavor tersebut dapat dibuild.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
