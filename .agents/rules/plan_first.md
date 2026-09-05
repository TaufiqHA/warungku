# Planning First, Autonomous Execution, & UI Styling Consistency Rule

Setiap kali menerima tugas/prompt dari user:

1. **Riset & Perencanaan (Plan First)**:
   - Lakukan analisis dan buat `implementation_plan.md` terlebih dahulu sebelum melakukan perubahan kode atau eksekusi perintah yang memodifikasi project.
   - Cantumkan daftar perubahan file dan rencana verifikasi secara jelas.

2. **Persetujuan (Approval)**:
   - Minta persetujuan user atas `implementation_plan.md` sebelum memulai penulisan kode.

3. **Implementasi Otonom (Auto Accept / Apply Edits)**:
   - Setelah user menyetujui plan, langsung eksekusi dan terapkan seluruh perubahan file/edit secara otomatis tanpa meminta konfirmasi ulang per berkas.
   - Jalankan perintah yang diperlukan untuk verifikasi atau eksekusi secara proaktif.

4. **Konsistensi Styling & Elemen UI (UI Consistency)**:
   - **Catat & Standarisasi**: Setiap kali membuat atau menambahkan elemen UI baru (misal: tombol, kartu/card, text field, chip/badge, modal, warna, dsb.), catat styling tersebut atau jadikan reusable widget/theme token.
   - **Gunakan Kembali di Seluruh Halaman**: Selalu gunakan styling/komponen reusable yang sama saat elemen tersebut dipakai di halaman/tampilan lain agar seluruh UI aplikasi konsisten.

5. **Verifikasi & Rangkuman**:
   - Uji hasil implementasi dan perbarui `walkthrough.md` untuk merangkum seluruh perubahan yang telah dilakukan.
