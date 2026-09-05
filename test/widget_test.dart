import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Formatters Unit Tests', () {
    test('formatRupiah formats currency correctly', () {
      expect(Formatters.formatRupiah(15000), 'Rp 15.000');
      expect(Formatters.formatRupiah(0), 'Rp 0');
      expect(Formatters.formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('formatTanggalIndo formats date in Indonesian format', () {
      final date = DateTime(2026, 9, 5);
      final formatted = Formatters.formatTanggalIndo(date);
      expect(formatted, contains('September 2026'));
    });

    test('formatJam formats time in HH:mm format', () {
      final date = DateTime(2026, 9, 5, 14, 30);
      final formatted = Formatters.formatJam(date);
      expect(formatted, '14:30');
    });
  });
}
