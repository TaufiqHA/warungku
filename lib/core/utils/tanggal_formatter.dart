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

  /// Mengecek apakah tanggal dari server sama dengan tanggal hari ini pada zona waktu lokal.
  static bool isToday(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final dt = parse(value);
    if (dt == null) return false;
    final localDt = dt.isUtc ? dt.toLocal() : dt;
    final now = DateTime.now();
    return localDt.year == now.year && localDt.month == now.month && localDt.day == now.day;
  }
}
