/// Utilitas format tanggal berbahasa Indonesia.
///
/// Dipakai oleh tab Biaya Operasional, Beranda Admin Kantor, dan formulir biaya
/// agar format tampilan tanggal konsisten dengan kontrak API
/// (`11 Sep 2026`).
class TanggalFormatter {
  TanggalFormatter._();

  static const List<String> _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _bulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// `18 September 2026` (tanpa nama hari).
  static String bulanPenuh(DateTime dt) =>
      '${dt.day} ${_bulan[dt.month - 1]} ${dt.year}';

  /// `Jumat, 18 September 2026` — format kartu sambutan dashboard.
  static String lengkap(DateTime dt) =>
      '${_hari[dt.weekday - 1]}, ${bulanPenuh(dt)}';

  /// `18 Sep 2026` — format tanggal yang dikirim ke API pengeluaran.
  static String singkat(DateTime dt) =>
      '${dt.day} ${_bulanSingkat[dt.month - 1]} ${dt.year}';

  /// `2026-09-18` — format query parameter `start_date` / `end_date`.
  static String keIso(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// Membaca tanggal dari server (ISO `2026-09-18T...` atau `18 Sep 2026`).
  /// Mengembalikan null bila format tidak dikenali.
  static DateTime? parse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // Bersihkan nama hari jika ada (misal: "Minggu, 20 September 2026")
    final withoutDayName = raw.contains(',') ? raw.split(',').last.trim() : raw;
    final isoFromClean = DateTime.tryParse(withoutDayName);
    if (isoFromClean != null) return isoFromClean;

    // Format angka: DD-MM-YYYY atau DD/MM/YYYY
    final dmyRegex = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
    final dmyMatch = dmyRegex.firstMatch(withoutDayName);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      final y = int.tryParse(dmyMatch.group(3)!);
      if (d != null && m != null && y != null && m >= 1 && m <= 12) {
        return DateTime(y, m, d);
      }
    }

    // Format tampilan teks: "18 Sep 2026" / "18 September 2026"
    final parts = withoutDayName.split(RegExp(r'\s+'));
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
    final year = int.tryParse(parts[2]);
    if (day == null || year == null) return null;

    final monthToken = parts[1].toLowerCase();
    int? month;
    for (var i = 0; i < _bulan.length; i++) {
      final penuh = _bulan[i].toLowerCase();
      final singkat = _bulanSingkat[i].toLowerCase();
      if (monthToken == penuh || monthToken == singkat || monthToken.startsWith(singkat)) {
        month = i + 1;
        break;
      }
    }
    if (month == null) return null;

    return DateTime(year, month, day);
  }

  /// Membaca string waktu server atau kode transaksi menjadi `DateTime` lokal.
  ///
  /// Bila [idTransaksi] memuat pola 14-digit tanggal-jam POS (`TRX-20260922184736`),
  /// waktu lokal tersebut diprioritaskan agar presisi dengan jam kasir.
  /// Bila [value] berupa ISO UTC (`Z`) dan zona sistem dilaporkan UTC 0
  /// (isu deteksi libc Android), otomatis diterapkan fallback zona WIB (+7)
  /// agar jam tidak tertinggal 7 jam dari stempel transaksi.
  static DateTime? parseLokal(String? value, {String? idTransaksi}) {
    if (idTransaksi != null && idTransaksi.trim().isNotEmpty) {
      final match = RegExp(r'TRX-(\d{4})(\d{2})(\d{2})[-_]?(\d{2})(\d{2})(\d{2})')
          .firstMatch(idTransaksi.trim());
      if (match != null) {
        final y = int.tryParse(match.group(1)!);
        final m = int.tryParse(match.group(2)!);
        final d = int.tryParse(match.group(3)!);
        final h = int.tryParse(match.group(4)!);
        final min = int.tryParse(match.group(5)!);
        final s = int.tryParse(match.group(6)!);
        if (y != null && m != null && d != null && h != null && min != null && s != null) {
          return DateTime(y, m, d, h, min, s);
        }
      }
    }

    if (value == null || value.trim().isEmpty) return null;
    final dt = DateTime.tryParse(value.trim());
    if (dt == null) return null;
    if (dt.isUtc) {
      if (DateTime.now().timeZoneOffset != Duration.zero) {
        return dt.toLocal();
      }
      return dt.add(const Duration(hours: 7));
    }
    return dt;
  }

  /// `14:08` — jam lokal (HH:mm) dari string waktu ISO server atau kode transaksi.
  ///
  /// Mengembalikan string kosong bila nilai tidak memuat komponen jam
  /// (misalnya tanggal tampilan `18 Sep 2026`) sehingga pemanggil dapat
  /// menyembunyikan barisnya.
  static String jamMenit(String? value, {String? idTransaksi}) {
    final local = parseLokal(value, idTransaksi: idTransaksi);
    if (local == null) return '';
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// `20 Sep 2026, 09:00` — tanggal dan jam lokal dari string waktu ISO server atau kode transaksi.
  ///
  /// Kosong bila nilai tidak dapat dibaca sebagai waktu.
  static String tanggalJam(String? value, {String? idTransaksi}) {
    final local = parseLokal(value, idTransaksi: idTransaksi);
    if (local == null) return '';
    return '${singkat(local)}, ${jamMenit(value, idTransaksi: idTransaksi)}';
  }

  /// Mengecek apakah tanggal dari server sama dengan tanggal hari ini pada zona waktu lokal.
  static bool isToday(String? value, {String? idTransaksi}) {
    if ((value == null || value.trim().isEmpty) && idTransaksi == null) return false;
    final local = parseLokal(value, idTransaksi: idTransaksi) ?? parse(value);
    if (local == null) return false;
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }
}
