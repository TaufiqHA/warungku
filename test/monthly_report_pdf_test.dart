import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/services/monthly_report_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonthlyReportPdfService Tests', () {
    test('generateMonthlyReportBytes returns valid PDF document bytes', () async {
      final bytes = await MonthlyReportPdfService.generateMonthlyReportBytes(
        month: 5,
        year: 2025,
        monthName: 'Mei',
        totalOrder: 15,
        totalOmzet: 450000.0,
        averageOrderValue: 30000.0,
        topSellingMenu: [
          {'name': 'Nasi Goreng Spesial', 'qty': 20, 'omzet': 300000.0},
          {'name': 'Es Teh Manis', 'qty': 30, 'omzet': 150000.0},
        ],
        dailyBreakdown: {
          1: {'orderCount': 5, 'omzet': 150000.0},
          2: {'orderCount': 10, 'omzet': 300000.0},
        },
        storeName: 'Warungku Test',
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      // Pastikan byte diawali dengan '%PDF-'
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateMonthlyReportBytes handles empty data gracefully', () async {
      final bytes = await MonthlyReportPdfService.generateMonthlyReportBytes(
        month: 1,
        year: 2026,
        monthName: 'Januari',
        totalOrder: 0,
        totalOmzet: 0.0,
        averageOrderValue: 0.0,
        topSellingMenu: [],
        dailyBreakdown: {},
        storeName: 'Warungku',
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateMonthlyReportBytes supports filteredItem parameter', () async {
      final bytes = await MonthlyReportPdfService.generateMonthlyReportBytes(
        month: 5,
        year: 2025,
        monthName: 'Mei',
        totalOrder: 5,
        totalOmzet: 150000.0,
        averageOrderValue: 30000.0,
        topSellingMenu: [
          {'name': 'Nasi Goreng Spesial', 'qty': 10, 'omzet': 150000.0},
        ],
        dailyBreakdown: {
          1: {'orderCount': 5, 'omzet': 150000.0},
        },
        storeName: 'Warungku Test',
        filteredItem: 'Nasi Goreng Spesial',
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
