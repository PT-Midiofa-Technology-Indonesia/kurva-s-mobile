# Aturan untuk AI Coding Agent

Panduan ini berlaku untuk seluruh repository `curva-mobile`. Ikuti instruksi pengguna untuk tugas yang sedang dikerjakan dan baca `AGENTS.md` yang lebih spesifik jika tersedia di direktori tujuan.

## Konteks proyek

- Aplikasi **Curva-S Mobile**, menggunakan Flutter dan Dart.
- Versi Flutter mengikuti `.fvmrc` (saat ini `3.47.2`); batas SDK mengikuti `pubspec.yaml`. Build Android memerlukan JDK 17.
- State management dan dependency injection: **flutter_riverpod**. Navigasi: **go_router**.
- HTTP: **Dio**, dengan autentikasi melalui `DioClient` dan penyimpanan sesi melalui `SecureStorageService`.
- Model JSON: **json_serializable**. Database lokal: **Drift**. Keduanya menggunakan `build_runner`.
- Dukungan offline tersedia untuk operasi tertentu dan dikendalikan oleh `SyncPolicy` serta flag konfigurasi; jangan menganggap semua fitur mendukung offline.

## Peta direktori

| Lokasi | Tanggung jawab |
| --- | --- |
| `lib/main.dart` | Inisialisasi Flutter, konfigurasi, database, dan `ProviderScope` |
| `lib/app/` | Konfigurasi aplikasi, tema, router, dan lifecycle aplikasi |
| `lib/core/` | Network, autentikasi transport, error, storage, database, konektivitas, sinkronisasi, dan konstanta |
| `lib/modules/<fitur>/data/` | Repository, model API, dan sumber data lokal jika tersedia |
| `lib/modules/<fitur>/presentation/` | Halaman, widget khusus fitur, dan controller |
| `lib/modules/<fitur>/*_providers.dart` | Provider dan wiring dependensi fitur |
| `lib/shared/` | Widget, utilitas, extension, dan hasil submit yang digunakan lintas fitur |
| `test/` | Unit test, widget test, dan pengujian database/sinkronisasi |
| `drift_schemas/` | Snapshot skema database untuk migrasi |
| `third_party/file_picker/` | Dependency lokal dengan patch Android; baca `PATCHES.md` sebelum mengubahnya |

Modul yang ada: `auth`, `dashboard`, `expense`, `inventory`, `logistic`, `meeting`, `profile`, `project`, `prospect`, `splash`, dan `workforce`. Ikuti struktur modul yang sedang disentuh; tidak semua modul mempunyai subdirektori yang sama.

## Cara bekerja

1. Periksa `git status --short`, implementasi terkait, dan test terdekat sebelum mengedit.
2. Pertahankan perubahan pengguna yang sudah ada. Jangan melakukan reset, checkout, atau pembersihan file yang menghilangkan pekerjaan di luar tugas.
3. Buat perubahan terarah sesuai permintaan. Hindari refactor massal, pemformatan seluruh repository, atau penambahan dependency tanpa kebutuhan konkret.
4. Gunakan pola kode yang sudah ada. Jangan memperkenalkan framework state management, lapisan arsitektur, atau generator baru untuk menyelesaikan perubahan lokal.
5. Lanjutkan pekerjaan yang sudah jelas cakupannya; tanyakan hanya informasi yang benar-benar diperlukan untuk menentukan perilaku atau kontrak yang belum diketahui.
6. Sampaikan hasil dalam bahasa Indonesia kecuali pengguna meminta bahasa lain. Jelaskan perubahan, verifikasi yang dilakukan, dan kendala yang masih tersisa secara singkat.

## Arsitektur dan gaya kode

- Tempatkan akses API dan database di repository/sumber data. Widget menggunakan provider/controller; jangan membuat klien HTTP atau database baru di halaman.
- Pertahankan pola Riverpod pada fitur terkait, termasuk `autoDispose`, `family`, invalidasi provider, dan lifecycle controller. Jangan memigrasikan pola controller sebagai efek samping tugas lain.
- Gunakan `ref.watch` untuk dependensi reaktif dan `ref.read` untuk aksi sesuai pola yang ada. Hindari efek samping berulang dari `build`.
- Kelola `dispose`, subscription, serta controller input dengan benar. Periksa `mounted` sebelum memakai context setelah operasi async; jaga controller tetap hidup bila operasi yang berjalan memerlukannya.
- Gunakan nama file `snake_case`, tipe `PascalCase`, serta variabel/fungsi `camelCase`. Ikuti format Dart dan lint di `analysis_options.yaml`; jangan menonaktifkan lint secara luas untuk menutupi masalah.
- Ikuti gaya import file sekitar. Gunakan model bertipe dan null safety; jangan menambah `dynamic` atau assertion `!` tanpa kebutuhan dan jaminan yang jelas.
- Daftarkan perubahan navigasi di `lib/app/app_router.dart` dan gunakan konstanta `lib/core/constants/route_names.dart`. Pertahankan mekanisme refresh halaman yang terkait.

## UI dan form

- Gunakan kembali komponen di `lib/shared/widgets/` serta tema dan konstanta `AppColors`, `AppSpacing`, `AppRadius`, dan `AppFonts` sebelum membuat variasi baru.
- Pertahankan bahasa dan istilah UI pada fitur terkait. Manfaatkan validator, formatter tanggal, dan utilitas upload yang sudah tersedia.
- Tangani state loading, kosong, gagal, berhasil, dan offline sesuai kemampuan fitur. Hindari mengosongkan data yang masih valid hanya karena refresh gagal.
- Cegah submit ganda, tampilkan error validasi pada field yang sesuai, dan ikuti pola `FormSubmitResult` pada controller form yang menggunakannya.
- Jaga layout pada layar kecil, keyboard terbuka, safe area, dan mode edge-to-edge. Perubahan status koneksi tidak boleh mereset halaman atau membuang input pengguna.

## API, konfigurasi, dan data pengguna

- Gunakan `DioClient`, `ErrorMapper`, dan `AppException` sesuai pola repository. Pertahankan alur refresh token dan penanganan sesi kedaluwarsa.
- Jangan menebak endpoint, field payload, status bisnis, atau bentuk response. Cari bukti di repository/test atau minta kontrak yang belum tersedia.
- Pertahankan scope akun/perusahaan pada request dan data lokal. Jangan menggunakan ID akun/perusahaan hardcoded dalam kode aplikasi.
- `.env` dimuat saat startup dan `BASE_URL` dibaca melalui `AppConfig`. Flag offline didefinisikan di `lib/core/offline_first_providers.dart`.
- Jangan memasukkan isi `.env`, token, password, signing key, atau data pribadi ke kode, log, dokumentasi, maupun commit. `.env` dibundel sebagai asset aplikasi, sehingga bukan tempat menyimpan rahasia server.
- Jangan mengubah konfigurasi lingkungan, signing, versi aplikasi, atau dependency lockfile kecuali memang diperlukan oleh tugas. Pertahankan `pubspec.lock` ketika memperbarui dependency aplikasi.

## Offline, sinkronisasi, dan migrasi

- Ikuti `SyncPolicy`: operasi online-only tidak boleh masuk antrean tanpa dukungan eksplisit. Pertahankan perilaku saat flag offline dinonaktifkan.
- Gunakan `OutboxService` untuk enqueue, `SyncCoordinator` untuk pemicu sinkronisasi, dan `SyncEngine` untuk pemrosesan. Jangan membuat antrean atau retry paralel di widget.
- Pertahankan isolasi `SyncScope` berdasarkan akun dan perusahaan, idempotency key yang stabil pada retry, pencegahan operasi duplikat, serta urutan dependensi operasi.
- Simpan lampiran antrean melalui `DurableFileStore`; jangan mengandalkan path sementara picker/kamera yang dapat hilang setelah aplikasi ditutup.
- Jangan menghapus outbox, lampiran pending, atau sesi hanya karena timeout/offline. Pertahankan perbedaan antara kegagalan sementara, penolakan server, dan sesi yang benar-benar tidak valid.
- Saat mengubah struktur database, perbarui `schemaVersion` dan migrasi di `lib/core/database/app_database.dart`. Jaga data lama, snapshot historis di `drift_schemas/`, dan kompatibilitas payload antrean yang sudah tersimpan.
- File `*.g.dart` dan `test/generated_migrations/` merupakan hasil generator. Ubah sumbernya lalu regenerasi; jangan mengedit hasil generator secara manual. Untuk migrasi, perbarui snapshot/helper yang relevan dan jalankan test migrasi.

## Perintah dan verifikasi

Jalankan perintah dari root repository. Gunakan FVM agar sesuai `.fvmrc`; bila FVM tidak tersedia, gunakan instalasi Flutter dengan versi yang cocok dan laporkan jika toolchain menghalangi verifikasi.

```sh
# Saat setup atau dependency berubah
fvm flutter pub get

# Menjalankan aplikasi pada device yang tersedia
fvm flutter run

# Setelah mengubah model JSON atau definisi database
fvm dart run build_runner build --delete-conflicting-outputs

# Format hanya file Dart yang disentuh; ganti path contoh berikut
fvm dart format lib/path/file.dart test/path_test.dart

# Analisis setelah perubahan kode
fvm flutter analyze

# Jalankan test terkait; contoh untuk perubahan database
fvm flutter test test/database_migration_test.dart test/offline_first_database_test.dart

# Jalankan seluruh suite bila perubahan berdampak lintas fitur
fvm flutter test
```

- Pilih test berdasarkan perilaku yang berubah. Tambahkan regression test untuk bug logika atau alur penting; perubahan dokumentasi saja tidak memerlukan Flutter test.
- Untuk API/controller, gunakan fake dan override provider seperti test yang ada; hindari ketergantungan pada API produksi. Gunakan `dotenv.testLoad` dengan konfigurasi dummy bila diperlukan.
- `test/offline_queue_config_test.dart` membaca `.env` lokal. Jika konfigurasi itu tidak tersedia, laporkan keterbatasannya; jangan mengarang konfigurasi produksi agar test lolos.
- Untuk perubahan offline, verifikasi retry, restart/persistensi, isolasi scope, dan status pending yang relevan. Untuk UI, verifikasi validasi, loading, serta navigasi yang terdampak.
- Patch `file_picker` lokal membatasi penggunaan memori saat kompresi gambar Android. Jangan menggantinya dengan package upstream tanpa menangani patch tersebut. Jika patch diubah, ikuti validasi `cd android && ./gradlew :file_picker:testDebugUnitTest` dalam `third_party/file_picker/PATCHES.md`.
- Build platform hanya jika relevan dengan tugas. Jangan menganggap `flutter analyze` memeriksa kode native atau `third_party/`, karena direktori tersebut dikecualikan oleh konfigurasi analyzer.
- Sebelum selesai, tinjau diff dan jalankan `git diff --check`. Laporkan perintah yang benar-benar dijalankan beserta hasilnya; jangan mengklaim test/build lulus jika belum dijalankan.
