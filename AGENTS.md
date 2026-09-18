# AGENTS.md — Warungku

Aplikasi Flutter manajemen warung / POS, **Android-only**. UI dan komentar berbahasa Indonesia.

## Prinsip kerja (wajib)
1. **Planning first** — sebelum mengedit kode, tampilkan rencana singkat: Tujuan, Analisis, Langkah, Verifikasi. Klarifikasi dulu jika ambigu/berisiko.
2. **Reusable UI** — periksa `plan/ui_components.md` sebelum membuat elemen UI baru; taruh komponen bersama di `lib/widgets/`; catat komponen baru/perubahan ke registry tersebut.
3. **UI minimalis** — label singkat, tanpa teks filler/tagline dekoratif.
4. **Referensi spec** — rujuk `plan/screen.md` (alur/UX & role) dan `plan/api.md` (kontrak endpoint) saat membuat atau mengubah layar dan integrasi API.

## Verifikasi
- `flutter analyze` — harus bebas error.
- `flutter test` — semua test harus lulus. Satu file: `flutter test test/widget_test.dart`. Satu test: `flutter test --plain-name "nama test"`.
- Tidak ada CI; verifikasi dijalankan lokal.

## Arsitektur
- Entry `lib/main.dart`. Rute bernama: `/login`, `/dashboard` (→ `DashboardDispatcher` memilih dashboard sesuai role), `/dashboard/{admin-toko|owner|admin-kantor}`, `/report/monthly`.
- Role: `OWNER`, `ADMIN_TOKO`, `ADMIN_KANTOR` (`lib/core/auth/app_roles.dart`). Halaman dilindungi `RoleGuard`; `DashboardDispatcher`/`RoleGuard`/screen dashboard menerima `testUser` untuk inject user di test.
- Struktur: `lib/screens/` (layar + `tabs/`), `lib/services/` (panggilan HTTP pakai `package:http` langsung), `lib/data/models/`, `lib/core/`, `lib/widgets/`.
- State: murni `StatefulWidget`/`setState` — **tidak ada** BLoC/Provider/Dio/go_router.
- Auth: token & user disimpan di SharedPreferences via `TokenManager`; header `Authorization: Bearer <token>`.
- `ProductService`, `TransactionService`, `ExpenseService`, `UserService` memakai cache in-memory TTL 60 detik (`lib/services/cache_entry.dart`). Setelah mutasi data panggil `forceRefresh: true` / `clearCache()`.
- Base URL: `lib/core/constants/api_constants.dart` (`http://192.168.1.199:8001`). Jangan pakai base URL di `plan/api.md`.

## Gotcha
- `plan/screen.md` & `plan/api.md` mendokumentasikan aplikasi Android/Kotlin (Retrofit/Compose, file `.kt`) yang jadi acuan desain & kontrak API — **bukan** path file repo ini. Path Flutter yang benar ada di `lib/`. `plan/ui_components.md` sudah khusus Flutter.
- Hanya `android/` yang di-track. `ios/`, `linux/`, `macos/`, `windows/`, `web/` bukan bagian repo (bisa tertinggal sebagai untracked di mesin lama) — jangan `git add` folder itu.
- `android/app/src/main/AndroidManifest.xml` tidak punya permission `INTERNET` (hanya manifest debug/profile). Tambahkan sebelum build release yang butuh jaringan.
- Base URL masih HTTP (cleartext) dan tidak ada `usesCleartextTraffic`/network security config — cek ini dulu bila koneksi gagal di Android 9+.
- `flutter analyze` saat ini menyisakan 2 isu minor: import `printing` tidak terpakai di `lib/screens/dashboard/admin_toko_dashboard_screen.dart`, dan import `dart:typed_data` berlebih di `lib/services/excel_export_service.dart`.
- PDF memakai font Helvetica tanpa dukungan Unicode (memunculkan peringatan saat test) — teks non-ASCII perlu font khusus.
- `GEMINI.md` dan `.agents/rules/rules.md` menduplikasi prinsip kerja di file ini.
