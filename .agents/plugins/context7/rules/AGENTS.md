# Context7 Guidelines

Gunakan Context7 MCP Server (`resolve-library-id` dan `get-library-docs`) saat:
- Memerlukan dokumentasi terkini, API reference, atau panduan implementasi paket pihak ketiga (misalnya paket Flutter/Dart seperti `intl`, `http`, `pdf`, `shared_preferences`, dll.).
- Terjadi keraguan terhadap API signature versi tertentu untuk mencegah halusinasi kode atau penggunaan metode yang deprecated.

## Alur Penggunaan
1. **Resolve Library ID**: Panggil tool `resolve-library-id` dengan parameter `libraryName` (contoh: "intl", "pdf", "http").
2. **Fetch Documentation**: Gunakan `context7CompatibleLibraryID` yang diperoleh untuk memanggil `get-library-docs` dengan topik spesifik (opsional) guna mendapatkan dokumentasi resmi dan contoh kode yang relevan.
