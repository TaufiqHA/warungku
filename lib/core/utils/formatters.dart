import 'package:intl/intl.dart';

/// Helper pemformatan mata uang, tanggal, dan jam sesuai standar Indonesia
class Formatters {
  Formatters._();

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka menjadi format mata uang Rupiah (contoh: Rp 25.000)
  static String formatRupiah(num amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format tanggal lengkap bahasa Indonesia (contoh: Senin, 05 September 2026)
  static String formatTanggalIndo(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
  }

  /// Format tanggal singkat (contoh: 05 Sep 2026)
  static String formatTanggalSingkat(DateTime dateTime) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
  }

  /// Format jam (contoh: 14:30)
  static String formatJam(DateTime dateTime) {
    return DateFormat('HH:mm', 'id_ID').format(dateTime);
  }

  /// Format tanggal dan jam lengkap (contoh: 05 Sep 2026, 14:30)
  static String formatTanggalJam(DateTime dateTime) {
    return '${formatTanggalSingkat(dateTime)}, ${formatJam(dateTime)}';
  }
}
