# Dokumentasi API - Manajemen Warung FE

Dokumen ini merinci seluruh spesifikasi *endpoint* API (Application Programming Interface) yang digunakan oleh aplikasi **Manajemen Warung (Frontend Android)**, arsitektur integrasi, data model request/response, serta pemetaan lengkap ke setiap **halaman / layar (screen & tab UI)** yang menggunakannya.

---

## 1. Arsitektur & Informasi Umum

- **Base URL Server**: `http://103.30.146.68` *(dikonfigurasi pada `RetrofitClient.kt`)*
- **Format Pertukaran Data**: JSON (`application/json`)
- **HTTP Client**: Retrofit 2 + OkHttp 3 Logging Interceptor + Moshi Converter (`KotlinJsonAdapterFactory`)
- **Autentikasi**: Menggunakan Bearer Token pada Header `Authorization` untuk seluruh endpoint privat.
  ```http
  Authorization: Bearer <jwt_token_aplikasi>
  Accept: application/json
  Content-Type: application/json
  ```
- **Mekanisme Token**: Disimpan secara lokal di `EncryptedSharedPreferences` via `TokenManager.kt` dan di-inject otomatis oleh OkHttp Interceptor.
- **Dukungan Offline-First**: Pada modul penjualan/kasir, request yang gagal karena keterbatasan konektivitas disimpan di antrean lokal (`LocalStorageHelper.kt`) dan disinkronisasi ulang otomatis saat koneksi pulih (`syncUnsyncedData`).

---

## 2. Matriks Pemetaan Halaman UI & Endpoint API

Tabel berikut memberikan gambaran menyeluruh keterkaitan antara layar/halaman dalam aplikasi Android dan endpoint API yang dipanggil:

| Layar / Halaman / Tab UI | File Sumber | Endpoint API yang Dipanggil | ViewModel / Repository | Pemicu / Aksi Pengguna |
| :--- | :--- | :--- | :--- | :--- |
| **Login Screen** | `LoginScreen.kt` | `POST /api/v1/auth/login` | `AuthViewModel` & `AuthRepository` | Pengguna memasukkan email/password dan menekan tombol *Masuk* |
| **Dashboard - Beranda** | `DashboardScreen.kt`<br>*(BerandaTabContent)* | `GET /api/v1/users/me`<br>`GET /api/v1/products`<br>`GET /api/v1/transactions`<br>`GET /api/v1/expenses` | Direct via `RetrofitClient` | Memuat ringkasan omzet, laba kotor/bersih, stok menipis, dan transaksi terbaru saat dashboard dibuka |
| **Dashboard - Penjualan** | `DashboardScreen.kt`<br>*(PenjualanTabContent)* | `GET /api/v1/transactions`<br>`POST /api/v1/transactions`<br>`PATCH /api/v1/transactions/{id}/cancel`<br>`DELETE /api/v1/transactions/{id}` | Direct via `RetrofitClient` | Memfilter transaksi (Hari Ini/Bulan Ini), input transaksi cepat, membatalkan transaksi kasir, dan menghapus permanen (khusus Owner) |
| **Dashboard - Manajemen Barang** | `DashboardScreen.kt`<br>*(BarangTabContent)* | `GET /api/v1/products`<br>`POST /api/v1/products`<br>`PUT /api/v1/products/{id}`<br>`DELETE /api/v1/products/{id}`<br>`POST /api/v1/categories`<br>`GET /api/v1/products/export`<br>`POST /api/v1/categories/layout`<br>`POST /api/v1/products/layout` | Direct via `RetrofitClient` | Melihat katalog, menambah menu/kategori, mengubah info harga & stok, menghapus menu, ekspor Excel, dan mengurutkan tata letak tampilan produk/kategori |
| **Dashboard - Laba Rugi** | `DashboardScreen.kt`<br>*(LabaRugiTabContent)* | `GET /api/v1/transactions`<br>`GET /api/v1/expenses` | Direct via `RetrofitClient` | Menghitung akumulasi pendapatan penjualan dikurangi beban operasional berdasarkan rentang tanggal/filter |
| **Dashboard - Biaya Operasional** | `DashboardScreen.kt`<br>*(BiayaTabContent)* | `GET /api/v1/expenses`<br>`POST /api/v1/expenses`<br>`PUT /api/v1/expenses/{id}`<br>`DELETE /api/v1/expenses/{id}` | `BiayaViewModel` & Direct via `RetrofitClient` | Melihat riwayat pengeluaran, menambah beban baru, mengedit catatan pengeluaran, serta menghapus data biaya |
| **Dashboard - Antrean Pesanan Aktif** | `ActiveOrdersScreen.kt`<br>*(ActiveOrdersTabContent)* | `GET /api/v1/transactions`<br>`PATCH /api/v1/transactions/{id}/status`<br>`POST /api/v1/transactions/{id}/items`<br>`DELETE /api/v1/transactions/{id}/items/{itemId}`<br>`PATCH /api/v1/transactions/{id}/items/{itemId}`<br>`PATCH /api/v1/transactions/{id}/items/{itemId}/served`<br>`PATCH /api/v1/transactions/{id}/cancel` | `SalesViewModel` & `LocalStorageHelper` | Polling realtime daftar pesanan (Pending/Ready), mengubah status pesanan, tambah/hapus item pesanan berjalan, dan update jumlah porsi tersaji di dapur |
| **Dashboard - Manajemen User** | `UserManagementScreen.kt`<br>*(UserManagementTabContent)* | `GET /api/v1/users`<br>`PUT /api/v1/users/{id}` | `UserRepository` | Khusus role Owner: melihat daftar pengguna sistem dan mengedit nama, email, serta password staf/kasir |
| **Dashboard / Layar Profil** | `ProfileScreen.kt`<br>*(ProfilTabContent)* | `GET /api/v1/users/me`<br>`PUT /api/v1/users/me`<br>`PUT /api/v1/settings/warung`<br>`POST /api/v1/auth/logout` | `AuthViewModel`, `ProfilViewModel`, `UserRepository` | Mengambil info profil aktif, mengubah nama user, mengubah info identitas warung (nama/alamat/email toko), dan tombol logout |
| **Layar Kasir (POS)** | `SalesScreen.kt` | `GET /api/v1/products`<br>`POST /api/v1/transactions` | `SalesViewModel` & `LocalStorageHelper` | Mengambil data menu jualan untuk autocomplete/pencarian kasir, dan menyimpan order baru saat checkout/cetak pesanan dapur |
| **Laporan Bulanan** | `MonthlyReportScreen.kt` | `GET /api/v1/products`<br>`GET /api/v1/transactions` | `ReportViewModel` & `LocalStorageHelper` | Menganalisis tren penjualan bulanan, menu terlaris, rekap pendapatan per tanggal, dan grafik performa |

---

## 3. Dokumentasi Detail Endpoint per Modul

### 3.1. Modul Autentikasi (`AuthApiService`)

#### 1. POST `/api/v1/auth/login`
- **Fungsi**: Memverifikasi kredensial pengguna dan mengembalikan token otentikasi JWT.
- **Autentikasi**: Publik (Tanpa Token).
- **Digunakan di Halaman**: `LoginScreen.kt` via `AuthViewModel.login()`.
- **Request Body**:
  ```json
  {
    "email": "owner@warung.com",
    "password": "password123"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Login berhasil",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "user": {
        "id": "USR-001",
        "name": "Taufiq H",
        "username": "taufiq_owner",
        "email": "owner@warung.com",
        "role": "OWNER"
      }
    }
  }
  ```
- **Response Gagal (401 Unauthorized)**:
  ```json
  {
    "success": false,
    "message": "Email atau kata sandi salah"
  }
  ```

---

#### 2. POST `/api/v1/auth/logout`
- **Fungsi**: Mengakhiri sesi pengguna aktif dan menginvalidasi token di server.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `ProfileScreen.kt` / `ProfilTabContent` via `AuthViewModel.logout()`.
- **Request Body**: Tidak ada.
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Logout berhasil"
  }
  ```

---

### 3.2. Modul Pengguna (`UserApiService`)

#### 1. GET `/api/v1/users/me`
- **Fungsi**: Mengambil informasi detail profil pengguna yang sedang login berdasarkan token JWT.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `DashboardScreen.kt` (inisialisasi hak akses) & `ProfileScreen.kt` via `UserRepository.getCurrentUser()`.
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "id": "USR-001",
      "name": "Taufiq H",
      "username": "taufiq_owner",
      "email": "owner@warung.com",
      "role": "OWNER"
    }
  }
  ```

---

#### 2. PUT `/api/v1/users/me`
- **Fungsi**: Mengubah data profil pengguna yang sedang login (misal update nama tampilan).
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `ProfileScreen.kt` / `ProfilTabContent` via `UserRepository.updateProfile()`.
- **Request Body**:
  ```json
  {
    "name": "Taufiq Hidayat",
    "username": "taufiq_owner"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Profil berhasil diperbarui"
  }
  ```

---

#### 3. GET `/api/v1/users`
- **Fungsi**: Mengambil seluruh daftar pengguna aplikasi (Admin Toko, Admin Kantor, Owner).
- **Autentikasi**: Bearer Token (Khusus Role `OWNER`).
- **Digunakan di Halaman**: `UserManagementScreen.kt` / `UserManagementTabContent` via `UserRepository.getAllUsers()`.
- **Response Berhasil (200 OK)**:
  ```json
  {
    "data": [
      {
        "id": "USR-001",
        "name": "Taufiq H",
        "username": "taufiq_owner",
        "email": "owner@warung.com",
        "role": "OWNER"
      },
      {
        "id": "USR-002",
        "name": "Kasir Toko",
        "username": "kasir_1",
        "email": "kasir1@warung.com",
        "role": "ADMIN_TOKO"
      }
    ]
  }
  ```

---

#### 4. PUT `/api/v1/users/{id}`
- **Fungsi**: Mengubah data pengguna tertentu (nama, email, atau reset password).
- **Autentikasi**: Bearer Token (Khusus Role `OWNER`).
- **Path Parameter**: `id` - ID pengguna yang diedit.
- **Digunakan di Halaman**: `UserManagementScreen.kt` via dialog edit user.
- **Request Body**:
  ```json
  {
    "name": "Kasir Pagi Baru",
    "email": "kasirpagi@warung.com",
    "password": "newpassword123"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Data pengguna berhasil diubah",
    "data": {
      "id": "USR-002",
      "name": "Kasir Pagi Baru",
      "username": "kasir_1",
      "email": "kasirpagi@warung.com",
      "role": "ADMIN_TOKO"
    }
  }
  ```

---

### 3.3. Modul Produk & Kategori (`ProductApiService`)

#### 1. GET `/api/v1/products`
- **Fungsi**: Mengambil seluruh katalog produk/menu jualan warung.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**:
  - `DashboardScreen.kt` (Tab Beranda & Tab Manajemen Barang)
  - `SalesScreen.kt` (Autocomplete & pemilihan menu di kasir via `SalesViewModel.loadItems()`)
  - `MonthlyReportScreen.kt` (Rekap menu via `ReportViewModel.loadData()`)
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "PRD-001",
        "name": "Ayam Geprek Sambal Korek",
        "price": 15000.0,
        "category": "Makanan"
      },
      {
        "id": "PRD-002",
        "name": "Es Teh Manis",
        "price": 4000.0,
        "category": "Minuman"
      }
    ]
  }
  ```

---

#### 2. POST `/api/v1/products`
- **Fungsi**: Menambahkan menu/barang baru ke daftar inventaris.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Dialog Tambah Menu).
- **Request Body**:
  ```json
  {
    "id": "PRD-003",
    "name": "Jus Jeruk Segar",
    "price": 6000.0,
    "category": "Minuman"
  }
  ```
- **Response Berhasil (200 / 201)**:
  ```json
  {
    "success": true,
    "message": "Produk berhasil ditambahkan",
    "data": {
      "id": "PRD-003",
      "name": "Jus Jeruk Segar",
      "price": 6000.0,
      "category": "Minuman"
    }
  }
  ```

---

#### 3. PUT `/api/v1/products/{id}`
- **Fungsi**: Memperbarui informasi produk (nama, harga, kategori).
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - ID produk yang diperbarui.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Dialog Edit Menu).
- **Request Body**:
  ```json
  {
    "id": "PRD-003",
    "name": "Jus Jeruk Murni",
    "price": 7000.0,
    "category": "Minuman"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Produk berhasil diperbarui",
    "data": {
      "id": "PRD-003",
      "name": "Jus Jeruk Murni",
      "price": 7000.0,
      "category": "Minuman"
    }
  }
  ```

---

#### 4. DELETE `/api/v1/products/{id}`
- **Fungsi**: Menghapus produk dari katalog menu.
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - ID produk yang akan dihapus.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Dialog Konfirmasi Hapus).
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Produk berhasil dihapus"
  }
  ```

---

#### 5. POST `/api/v1/categories`
- **Fungsi**: Menambahkan kategori produk baru (misal: "Snack", "Paket Nasi").
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Tambah Kategori).
- **Request Body**:
  ```json
  {
    "name": "Snack"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Kategori berhasil ditambahkan"
  }
  ```

---

#### 6. GET `/api/v1/products/export`
- **Fungsi**: Menghasilkan tautan ekspor file laporan katalog produk/inventaris (Excel/CSV).
- **Autentikasi**: Bearer Token.
- **Query Parameters**:
  - `search` *(opsional)*: Kata kunci filter nama barang
  - `category_id` *(opsional)*: ID kategori
  - `sort_by` *(opsional)*: Kolom sorting (`name`, `price`, dll.)
  - `sort_order` *(opsional)*: `asc` | `desc`
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Tombol Ekspor).
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Export data berhasil disiapkan",
    "download_url": "http://103.30.146.68/exports/products_2026.xlsx"
  }
  ```

---

#### 7. POST `/api/v1/categories/layout`
- **Fungsi**: Menyimpan urutan tata letak tab/kategori produk di layar kasir/menu.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Pengaturan Susunan Kategori).
- **Request Body**:
  ```json
  {
    "categories": [
      { "name": "Makanan", "order": 1 },
      { "name": "Minuman", "order": 2 },
      { "name": "Snack", "order": 3 }
    ]
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Urutan kategori berhasil disimpan"
  }
  ```

---

#### 8. POST `/api/v1/products/layout`
- **Fungsi**: Menyimpan urutan tata letak posisi item produk di dalam katalog.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Manajemen Barang -> Pengaturan Susunan Produk).
- **Request Body**:
  ```json
  {
    "products": [
      { "id": "PRD-001", "order": 1 },
      { "id": "PRD-002", "order": 2 }
    ]
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Urutan produk berhasil disimpan"
  }
  ```

---

### 3.4. Modul Transaksi Penjualan (`TransactionApiService`)

#### 1. GET `/api/v1/transactions`
- **Fungsi**: Mengambil seluruh riwayat atau antrean transaksi penjualan.
- **Autentikasi**: Bearer Token.
- **Query Parameter**:
  - `filter` *(opsional)*: `Hari Ini` | `Minggu Ini` | `Bulan Ini` | `Bulan Lalu` | `Semua`
- **Digunakan di Halaman**:
  - `DashboardScreen.kt` (Tab Beranda, Tab Penjualan, Tab Laba Rugi)
  - `ActiveOrdersScreen.kt` (Monitoring antrean pesanan via `SalesViewModel.fetchActiveOrders()`)
  - `MonthlyReportScreen.kt` (Laporan bulanan via `ReportViewModel.loadData()`)
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "idTransaksi": "TRX-20260911001",
        "id": "1",
        "namaItem": "Ayam Geprek Sambal Korek",
        "jumlah": 2,
        "harga": 15000.0,
        "waktu": "2026-09-11T10:15:30Z",
        "dicatatOleh": "Admin Toko",
        "catatan": "Pedas level 3",
        "payment_method": "Cash",
        "orderStatus": "PENDING",
        "customer_name": "Meja 4",
        "servedQty": 0
      }
    ]
  }
  ```

---

#### 2. POST `/api/v1/transactions`
- **Fungsi**: Mendaftarkan pesanan/transaksi penjualan baru yang dibuat oleh kasir.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**:
  - `SalesScreen.kt` via `SalesViewModel.processTransaction()` -> `LocalStorageHelper.addTransaction()`
  - `DashboardScreen.kt` (Form input transaksi manual)
  - Offline sync worker via `LocalStorageHelper.syncUnsyncedData()`
- **Request Body**:
  ```json
  {
    "idTransaksi": "TRX-20260911102500",
    "waktu": "2026-09-11T10:25:00Z",
    "dicatatOleh": "Admin Toko",
    "payment_method": "CASH",
    "customerName": "Bpk. Rahmat",
    "orderStatus": "PENDING",
    "status": "PENDING",
    "discount_amount": 0,
    "items": [
      {
        "namaItem": "Ayam Geprek Sambal Korek",
        "jumlah": 2,
        "harga": 15000.0,
        "catatan": "Sambal dipisah",
        "servedQty": 0,
        "product_id": "PRD-001",
        "quantity": 2,
        "unit_price": 15000.0,
        "subtotal": 30000.0
      }
    ]
  }
  ```
- **Response Berhasil (201 Created / 200 OK)**:
  ```json
  {
    "success": true,
    "message": "Transaksi berhasil dibuat"
  }
  ```

---

#### 3. PATCH `/api/v1/transactions/{id}/cancel`
- **Fungsi**: Membatalkan pesanan transaksi yang sudah masuk ke sistem.
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - Kode transaksi (misal: `TRX-20260911001`).
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Penjualan) & `ActiveOrdersScreen.kt`.
- **Request Body**:
  ```json
  {
    "reason": "Pembatalan oleh kasir"
  }
  ```
- **Response Berhasil (200 OK)**: Status HTTP 200 OK.

---

#### 4. PATCH `/api/v1/transactions/{id}/status`
- **Fungsi**: Memperbarui alur status pesanan (misal: `PENDING` -> `READY` -> `COMPLETED`) beserta metode pembayaran saat pelunasan kasir.
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - Kode transaksi.
- **Digunakan di Halaman**: `ActiveOrdersScreen.kt` via `SalesViewModel.updateActiveOrderStatus()`.
- **Request Body**:
  ```json
  {
    "status": "COMPLETED",
    "payment_method": "QRIS",
    "discount_amount": 5000
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Status transaksi berhasil diperbarui"
  }
  ```

---

#### 5. POST `/api/v1/transactions/{id}/items`
- **Fungsi**: Menambahkan menu/item tambahan ke pesanan yang masih aktif (`PENDING`).
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - Kode transaksi.
- **Digunakan di Halaman**: `ActiveOrdersScreen.kt` via `SalesViewModel.addItemToActiveOrder()`.
- **Request Body**:
  ```json
  {
    "product_id": "PRD-002",
    "quantity": 1,
    "unit_price": 4000.0,
    "subtotal": 4000.0
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Item pesanan berhasil ditambahkan"
  }
  ```

---

#### 6. DELETE `/api/v1/transactions/{id}/items/{itemId}`
- **Fungsi**: Menghapus salah satu baris item dari pesanan aktif yang belum selesai.
- **Autentikasi**: Bearer Token.
- **Path Parameters**:
  - `id`: Kode transaksi
  - `itemId`: ID item dalam transaksi
- **Digunakan di Halaman**: `ActiveOrdersScreen.kt` via `SalesViewModel.removeItemFromActiveOrder()`.
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Item pesanan berhasil dihapus"
  }
  ```

---

#### 7. PATCH `/api/v1/transactions/{id}/items/{itemId}`
- **Fungsi**: Mengubah kuantitas item pada transaksi yang masih berjalan.
- **Autentikasi**: Bearer Token.
- **Path Parameters**:
  - `id`: Kode transaksi
  - `itemId`: ID item dalam transaksi
- **Digunakan di Halaman**: `ActiveOrdersScreen.kt` via `SalesViewModel.updateItemQuantityInActiveOrder()`.
- **Request Body**:
  ```json
  {
    "quantity": 3,
    "subtotal": 45000.0
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Jumlah item transaksi diperbarui"
  }
  ```

---

#### 8. PATCH `/api/v1/transactions/{id}/items/{itemId}/served`
- **Fungsi**: Menandai jumlah porsi hidangan yang sudah disajikan/selesai dimasak oleh dapur (*Kitchen Display Tracking*).
- **Autentikasi**: Bearer Token.
- **Path Parameters**:
  - `id`: Kode transaksi
  - `itemId`: ID item dalam transaksi
- **Digunakan di Halaman**: `ActiveOrdersScreen.kt` via `SalesViewModel.updateItemServedQty()`.
- **Request Body**:
  ```json
  {
    "served_qty": 2
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Jumlah porsi tersaji berhasil dicatat"
  }
  ```

---

#### 9. DELETE `/api/v1/transactions/{id}`
- **Fungsi**: Menghapus transaksi secara permanen dari basis data.
- **Autentikasi**: Bearer Token (Khusus Role `OWNER`).
- **Path Parameter**: `id` - Kode transaksi.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Penjualan -> Tombol Hapus Transaksi Permanen).
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Transaksi berhasil dihapus secara permanen"
  }
  ```

---

### 3.5. Modul Biaya Operasional (`ExpenseApiService`)

#### 1. GET `/api/v1/expenses`
- **Fungsi**: Mengambil seluruh catatan beban/pengeluaran operasional warung.
- **Autentikasi**: Bearer Token.
- **Query Parameters**:
  - `filter` *(opsional)*: `Hari Ini` | `Minggu Ini` | `Bulan Ini` | `Bulan Lalu` | `Semua`
  - `start_date` *(opsional)*: Format `YYYY-MM-DD`
  - `end_date` *(opsional)*: Format `YYYY-MM-DD`
- **Digunakan di Halaman**:
  - `DashboardScreen.kt` (Tab Beranda, Tab Biaya Operasional, Tab Laba Rugi)
  - `BiayaViewModel.kt`
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "EXP-001",
        "kategori": "Bahan Baku",
        "keterangan": "Belanja Beras 25kg dan Minyak Goreng",
        "jumlah": 350000.0,
        "tanggal": "11 Sep 2026",
        "pembuat": "Admin Kantor"
      },
      {
        "id": "EXP-002",
        "kategori": "Utilitas",
        "keterangan": "Token Listrik Warung",
        "jumlah": 100000.0,
        "tanggal": "10 Sep 2026",
        "pembuat": "Owner"
      }
    ]
  }
  ```

---

#### 2. POST `/api/v1/expenses`
- **Fungsi**: Mencatat pos pengeluaran operasional baru.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Biaya Operasional -> Dialog Tambah Biaya) via `BiayaViewModel.addExpense()`.
- **Request Body**:
  ```json
  {
    "kategori": "Bahan Baku",
    "keterangan": "Beli Gas LPG 3kg (2 tabung)",
    "jumlah": 44000.0,
    "tanggal": "11 Sep 2026",
    "pembuat": "Admin Kantor"
  }
  ```
- **Response Berhasil (200 / 201)**:
  ```json
  {
    "success": true,
    "message": "Pengeluaran berhasil dicatat",
    "data": {
      "id": "EXP-003",
      "kategori": "Bahan Baku",
      "keterangan": "Beli Gas LPG 3kg (2 tabung)",
      "jumlah": 44000.0,
      "tanggal": "11 Sep 2026",
      "pembuat": "Admin Kantor"
    }
  }
  ```

---

#### 3. PUT `/api/v1/expenses/{id}`
- **Fungsi**: Memperbarui entri pengeluaran operasional yang telah dicatat.
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - ID pengeluaran operasional.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Biaya Operasional -> Dialog Edit Biaya) via `BiayaViewModel.updateExpense()`.
- **Request Body**:
  ```json
  {
    "kategori": "Bahan Baku",
    "keterangan": "Beli Gas LPG 3kg (3 tabung)",
    "jumlah": 66000.0,
    "tanggal": "11 Sep 2026",
    "pembuat": "Admin Kantor"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Pengeluaran berhasil diperbarui",
    "data": {
      "id": "EXP-003",
      "kategori": "Bahan Baku",
      "keterangan": "Beli Gas LPG 3kg (3 tabung)",
      "jumlah": 66000.0,
      "tanggal": "11 Sep 2026",
      "pembuat": "Admin Kantor"
    }
  }
  ```

---

#### 4. DELETE `/api/v1/expenses/{id}`
- **Fungsi**: Menghapus catatan biaya operasional.
- **Autentikasi**: Bearer Token.
- **Path Parameter**: `id` - ID pengeluaran operasional.
- **Digunakan di Halaman**: `DashboardScreen.kt` (Tab Biaya Operasional -> Dialog Hapus Biaya) via `BiayaViewModel.deleteExpense()`.
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Catatan pengeluaran berhasil dihapus"
  }
  ```

---

### 3.6. Modul Pengaturan Warung (`WarungSettingApiService`)

#### 1. PUT `/api/v1/settings/warung`
- **Fungsi**: Memperbarui identitas toko/warung (nama warung, alamat, dan email kontak) yang tercetak pada kop struk thermal serta quotation PDF.
- **Autentikasi**: Bearer Token.
- **Digunakan di Halaman**: `ProfileScreen.kt` (Form Pengaturan Profil Warung) via `ProfilViewModel.saveProfile()`.
- **Request Body**:
  ```json
  {
    "name": "Warung Makan Berkah",
    "address": "Jl. Raya Kampus No. 12, Sleman, Yogyakarta",
    "email": "kontak@warungberkah.com"
  }
  ```
- **Response Berhasil (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Pengaturan warung berhasil disimpan"
  }
  ```

---

## 4. Konvensi Status Code HTTP

| Status Code | Arti | Keterangan |
| :--- | :--- | :--- |
| **200 OK** | Sukses | Request berhasil diproses dan data dikembalikan |
| **201 Created** | Dibuat | Resource baru berhasil dibuat (misal: tambah transaksi, menu, biaya) |
| **400 Bad Request** | Request Tidak Valid | Validasi input gagal (format data salah, field wajib kosong) |
| **401 Unauthorized** | Tidak Terautentikasi | Token tidak ditemukan, sudah kadaluarsa, atau kredensial login salah |
| **403 Forbidden** | Akses Ditolak | Pengguna tidak memiliki hak akses (role tidak sesuai, misal non-Owner) |
| **404 Not Found** | Tidak Ditemukan | Resource ID tidak ditemukan di basis data |
| **500 Internal Server Error** | Kesalahan Server | Terjadi error internal di server backend |
