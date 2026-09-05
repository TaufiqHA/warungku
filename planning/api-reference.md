# API Reference - Aplikasi Manajemen Warung

Dokumen ini merinci seluruh spesifikasi *endpoint* API (Application Programming Interface) yang dibutuhkan oleh *frontend* Android aplikasi Manajemen Warung untuk dapat beroperasi secara penuh menggunakan server backend.

## Informasi Umum

- **Base URL**: `https://api.warung.com/v1`
- **Format Data**: JSON (`application/json`)
- **Autentikasi**: Menggunakan Bearer Token pada Header `Authorization` untuk seluruh *endpoint* yang dilindungi (kecuali `/auth/login`).
  ```text
  Authorization: Bearer <your_jwt_token_here>
  ```

---

## 1. Modul Autentikasi & User (Auth)

### POST `/auth/login`
Digunakan untuk melakukan autentikasi pengguna masuk ke sistem.

- **Autentikasi**: Tidak Butuh
- **Request Body**:
  ```json
  {
    "username": "toko_owner",
    "password": "securepassword123"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Login berhasil",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "user": {
        "id": "USR-001",
        "name": "Taufiq",
        "username": "toko_owner",
        "role": "Owner"
      }
    }
  }
  ```
- **Response (401 Unauthorized)**:
  ```json
  {
    "success": false,
    "message": "Username atau password salah"
  }
  ```

---

### GET `/users/me`
Mengambil informasi detail mengenai pengguna yang sedang aktif/login saat ini berdasarkan token JWT.

- **Autentikasi**: Bearer Token
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "id": "USR-001",
      "name": "Taufiq",
      "username": "toko_owner",
      "role": "Owner"
    }
  }
  ```

---

### POST `/auth/logout`
Melakukan proses keluar aplikasi dan menonaktifkan token pengguna di sisi server.

- **Autentikasi**: Bearer Token
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Logout berhasil"
  }
  ```

---

## 2. Modul Manajemen Barang (Products)

### GET `/products`
Mengambil semua daftar barang jualan/menu aktif.

- **Autentikasi**: Bearer Token
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "PRD-001",
        "name": "Es Teh Manis",
        "category": "Minuman",
        "price": 5000.0,
        "imageUrl": "https://api.warung.com/images/esteh.png"
      },
      {
        "id": "PRD-002",
        "name": "Nasi Goreng Spesial",
        "category": "Makanan",
        "price": 15000.0,
        "imageUrl": "https://api.warung.com/images/nasgor.png"
      }
    ]
  }
  ```

---

### POST `/products`
Menambahkan barang jualan baru ke sistem.

- **Autentikasi**: Bearer Token
- **Request Body**:
  ```json
  {
    "name": "Ayam Geprek",
    "category": "Makanan",
    "price": 13000.0,
    "imageUrl": "https://api.warung.com/images/ayamgeprek.png"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "message": "Barang berhasil ditambahkan",
    "data": {
      "id": "PRD-003",
      "name": "Ayam Geprek",
      "category": "Makanan",
      "price": 13000.0,
      "imageUrl": "https://api.warung.com/images/ayamgeprek.png"
    }
  }
  ```

---

### PUT `/products/{id}`
Memperbarui informasi barang jualan yang sudah ada berdasarkan `id`.

- **Autentikasi**: Bearer Token
- **Request Body**:
  ```json
  {
    "name": "Ayam Geprek Sambal Ijo",
    "category": "Makanan",
    "price": 14000.0,
    "imageUrl": "https://api.warung.com/images/ayamgeprek_ijo.png"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Barang berhasil diperbarui",
    "data": {
      "id": "PRD-003",
      "name": "Ayam Geprek Sambal Ijo",
      "category": "Makanan",
      "price": 14000.0,
      "imageUrl": "https://api.warung.com/images/ayamgeprek_ijo.png"
    }
  }
  ```

---

### DELETE `/products/{id}`
Menghapus barang jualan dari sistem (soft delete/hard delete tergantung sistem backend).

- **Autentikasi**: Bearer Token
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Barang berhasil dihapus"
  }
  ```

---

## 3. Modul Transaksi Penjualan (Transactions)

### GET `/transactions`
Mengambil semua riwayat transaksi penjualan kasir (Mendukung filter tanggal).

- **Autentikasi**: Bearer Token
- **Query Parameters**:
  - `filter` *(opsional)*: `Hari Ini` | `Minggu Ini` | `Bulan Ini` | `Bulan Lalu` | `Semua`
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "idTransaksi": "TRX-20260530001",
        "id": "1",
        "namaItem": "Es Teh Manis",
        "jumlah": 2,
        "harga": 5000.0,
        "waktu": "2026-05-30T10:15:30Z",
        "dicatatOleh": "Taufiq",
        "catatan": ""
      },
      {
        "idTransaksi": "TRX-20260530001",
        "id": "2",
        "namaItem": "Nasi Goreng Spesial",
        "jumlah": 1,
        "harga": 15000.0,
        "waktu": "2026-05-30T10:15:30Z",
        "dicatatOleh": "Taufiq",
        "catatan": "Tidak pedas"
      }
    ]
  }
  ```

---

### POST `/transactions`
Menyimpan transaksi order penjualan baru yang diinput oleh Kasir.

- **Autentikasi**: Bearer Token
- **Request Body**:
  ```json
  {
    "idTransaksi": "TRX-20260530001",
    "waktu": "2026-05-30T10:15:30Z",
    "dicatatOleh": "Taufiq",
    "items": [
      {
        "namaItem": "Es Teh Manis",
        "jumlah": 2,
        "harga": 5000.0,
        "catatan": ""
      },
      {
        "namaItem": "Nasi Goreng Spesial",
        "jumlah": 1,
        "harga": 15000.0,
        "catatan": "Tidak pedas"
      }
    ]
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "message": "Transaksi berhasil disimpan",
    "data": {
      "idTransaksi": "TRX-20260530001",
      "waktu": "2026-05-30T10:15:30Z",
      "totalHarga": 25000.0
    }
  }
  ```

---

## 4. Modul Biaya Operasional (Expenses)

### GET `/expenses`
Mengambil seluruh daftar pengeluaran operasional (Mendukung filter tanggal).

- **Autentikasi**: Bearer Token
- **Query Parameters**:
  - `filter` *(opsional)*: `Hari Ini` | `Minggu Ini` | `Bulan Ini` | `Bulan Lalu` | `Semua`
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "EXP-001",
        "kategori": "Bahan Baku",
        "keterangan": "Belanja sembako",
        "jumlah": 450000.0,
        "tanggal": "30 Mei 2026",
        "pembuat": "Admin Kantor"
      },
      {
        "id": "EXP-002",
        "kategori": "Biaya Operasional",
        "keterangan": "Gaji bu warung",
        "jumlah": 1500000.0,
        "tanggal": "30 Mei 2026",
        "pembuat": "Owner"
      }
    ]
  }
  ```

---

### POST `/expenses`
Mencatat entri pengeluaran biaya operasional baru.

- **Autentikasi**: Bearer Token
- **Request Body**:
  ```json
  {
    "kategori": "Bahan Baku",
    "keterangan": "Belanja telur ayam",
    "jumlah": 280000.0,
    "tanggal": "30 Mei 2026",
    "pembuat": "Admin Kantor"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "message": "Catatan biaya berhasil disimpan",
    "data": {
      "id": "EXP-003",
      "kategori": "Bahan Baku",
      "keterangan": "Belanja telur ayam",
      "jumlah": 280000.0,
      "tanggal": "30 Mei 2026",
      "pembuat": "Admin Kantor"
    }
  }
  ```

---

### PUT `/expenses/{id}`
Mengedit/memperbarui data pengeluaran operasional yang salah diinput.

- **Autentikasi**: Bearer Token
- **Request Body**:
  ```json
  {
    "kategori": "Bahan Baku",
    "keterangan": "Belanja telur ayam (10kg)",
    "jumlah": 290000.0,
    "tanggal": "30 Mei 2026"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Catatan biaya berhasil diperbarui",
    "data": {
      "id": "EXP-003",
      "kategori": "Bahan Baku",
      "keterangan": "Belanja telur ayam (10kg)",
      "jumlah": 290000.0,
      "tanggal": "30 Mei 2026",
      "pembuat": "Admin Kantor"
    }
  }
  ```

---

### DELETE `/expenses/{id}`
Menghapus pengeluaran biaya operasional yang salah diinput.

- **Autentikasi**: Bearer Token
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Catatan biaya berhasil dihapus"
  }
  ```
