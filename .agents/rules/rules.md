# Aturan & Instruksi Agen (Agent Rules)

Semua agen kecerdasan buatan (AI Agents / Antigravity / Gemini) yang bekerja di proyek ini WAJIB mematuhi 4 prinsip utama berikut pada setiap tugas:

---

## 1. Planning First (Perencanaan Sebelum Eksekusi)
- **Wajib Planning di Setiap Prompt**: Setiap kali menerima instruksi, prompt, atau tugas baru dari pengguna, agen **TIDAK BOLEH** langsung mengedit kode secara tiba-tiba tanpa pemikiran terstruktur. Agen harus terlebih dahulu menyusun dan menampilkan rencana (planning) yang jelas.
- **Format Rencana**:
  1. **Tujuan**: Apa yang ingin dicapai pada tugas saat ini.
  2. **Analisis**: File yang terpengaruh, dependensi, dan arsitektur yang relevan.
  3. **Langkah Kerja (Step-by-Step)**: Urutan aksi yang akan dilakukan secara spesifik.
  4. **Verifikasi**: Cara memastikan hasil kerja berjalan baik dan bebas error.
- Jika ada hal yang kurang jelas atau rancu, tanyakan/klarifikasi kepada pengguna sebelum mengeksekusi langkah berisiko tinggi.

---

## 2. Reusable UI Components & UI Registry (Konsistensi Style Seluruh Halaman)
- **Modular & Reusable**: Jangan membuat elemen UI yang redundan di dalam file halaman (screen) secara hardcoded jika elemen tersebut berpotensi digunakan di halaman lain (misal: Button, Card, TextField, Status Badge, App Header, Dialog, BottomSheet, Loading State).
- **Lokasi Komponen**: Simpan widget yang dapat digunakan ulang di direktori `lib/widgets/` (atau `lib/shared/components/`).
- **Wajib Catat ke Registry**: Setiap kali membuat atau memperbarui komponen UI baru, **WAJIB mencatatnya di `plan/ui_components.md`**.
  - Catat: Nama komponen, file path, tujuan penggunaan, properti/parameter utama, dan panduan styling.
- **Reusability Check Sebelum Buat Baru**: Sebelum membuat elemen UI di layar/halaman baru, agen **WAJIB memeriksa katalog di `plan/ui_components.md`** terlebih dahulu. Gunakan komponen yang sudah ada agar semua halaman memiliki gaya visual, padding, radius sudut (border radius), bayangan (elevation), dan tema warna yang seragam.

---

## 3. Desain UI Minimalis & Tanpa Teks Tambahan Berlebih
- **Filosofi Minimalis**: Antarmuka pengguna harus bersih (clean), modern, rapi, dan hanya memuat informasi yang esensial.
- **Bebas Teks Berlebih (No Text Clutter)**:
  - Jangan menambahkan kalimat deskriptif panjang, instruksi filler, atau tagline dekoratif yang tidak perlu pada card, header, maupun form.
  - Gunakan label yang singkat, padat, dan to-the-point.
    - *Contoh baik*: Label "Email", "Kata Sandi", "Simpan", "Hapus".
    - *Contoh buruk*: "Silakan masukkan alamat email akun Anda di sini", "Klik tombol di bawah ini untuk menyimpan perubahan".
- **Visual Hierarchy & Whitespace**: Gunakan whitespace yang proporsional, grid yang konsisten, dan ikon yang intuitif untuk memandu navigasi pengguna tanpa memerlukan teks bantuan yang panjang.
- **Kontras & Elegan**: Gunakan palet warna yang sederhana, terfokus, tidak berlebihan, dan sesuai dengan tema aplikasi.

---

## 4. Referensi Layar & Integrasi API (Screen Reference & API Integration)
- **Wajib Mereferensi `plan/screen.md`**: Setiap pembuatan atau modifikasi layar (screen), widget halaman, formulir input, modal/dialog, atau alur navigasi baru WAJIB mereferensikan spesifikasi yang telah ditetapkan pada `plan/screen.md`.
- **Wajib Terhubung ke API di `plan/api.md`**: Setiap halaman atau fitur UI yang mengelola, menampilkan, atau mengirim data WAJIB diintegrasikan dengan endpoint API yang terdokumentasi pada `plan/api.md` (sesuai kontrak request payload, query params, response body, HTTP method, status kode, dan header autentikasi token).
- **Konsistensi Alur Data**: Pastikan kesesuaian antara input form UI dan payload API, serta mengimplementasikan penanganan state loading, error handling/snackbar responsif, dan mekanisme offline/sinkronisasi jika disyaratkan.
