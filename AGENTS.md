# Workspace Instructions: Plan First, Auto Accept Edits, & UI Styling Consistency

Setiap kali menerima tugas/prompt dari user:
1. **Riset & Perencanaan**: Selalu buat rencana implementasi (`implementation_plan.md`) terlebih dahulu sebelum melakukan perubahan kode atau eksekusi perintah yang memodifikasi project.
2. **Approval**: Minta persetujuan user atas plan yang telah dibuat.
3. **Eksekusi Otonom (Auto Accept Edits)**: Begitu plan disetujui, terapkan semua perubahan file/kode secara langsung dan otonom tanpa meminta konfirmasi per file.
4. **Verifikasi**: Jalankan pengujian/verifikasi hasil kerja dan perbarui `walkthrough.md`.

---

## Aturan Konsistensi UI & Styling:
- **Pencatatan & Reusabilitas Elemen UI**: Setiap kali menambahkan elemen UI baru (seperti button, card, input field, dialog, badge, typography, spacing, atau color token), pastikan styling dan strukturnya dicatat atau dibuatkan komponen/style reusable (misal di tema, shared widgets, atau style constants).
- **Konsistensi Antar Halaman**: Gunakan styling / reusable widget yang sama ketika elemen UI tersebut digunakan di halaman lain agar seluruh tampilan antarmuka aplikasi selalu konsisten dan selaras.
