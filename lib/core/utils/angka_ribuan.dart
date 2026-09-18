import 'package:flutter/services.dart';

/// Utilitas angka bergaya Indonesia (pemisah ribuan titik).
///
/// Dipakai pada input nominal rupiah agar user melihat `15.000` saat mengetik
/// `15000`, tanpa mengubah nilai yang dikirim ke API.
class AngkaRibuan {
  AngkaRibuan._();

  /// `15000` → `15.000` (tanda minus dipertahankan bila negatif).
  static String format(num value) =>
      formatDigits(value.abs().toInt().toString(), isNegative: value < 0);

  /// Menyisipkan titik pemisah pada deretan digit apa pun (tanpa konversi int,
  /// sehingga aman untuk input panjang).
  static String formatDigits(String digits, {bool isNegative = false}) {
    final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return '';

    final buffer = StringBuffer(isNegative ? '-' : '');
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  /// `15.000` → `15000.0`; mengembalikan null bila tidak ada angka sama sekali.
  static double? parse(String? text) {
    if (text == null) return null;
    final isNegative = text.trim().startsWith('-');
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final value = double.tryParse(digits);
    if (value == null) return null;
    return isNegative ? -value : value;
  }

  /// `15000` → `15000` (hanya digit, tanpa pemisah) untuk payload API.
  static String toDigits(String? text) {
    if (text == null) return '';
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

/// [TextInputFormatter] yang menyisipkan titik pemisah ribuan secara otomatis.
///
/// Hanya menerima angka; karakter lain (huruf, spasi, simbol) langsung dibuang
/// dan kursor diletakkan di akhir teks.
class RibuanInputFormatter extends TextInputFormatter {
  const RibuanInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = AngkaRibuan.toDigits(newValue.text);

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Buang nol di depan agar tidak menjadi "015.000".
    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = AngkaRibuan.formatDigits(normalized);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
