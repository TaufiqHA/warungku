import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku/app/config/app_colors.dart';
import 'package:warungku/app/config/app_theme.dart';
import 'package:warungku/app/config/app_typography.dart';
import 'package:warungku/core/utils/formatters.dart';
import 'package:warungku/core/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });

  group('Formatters Unit Tests', () {
    test('formatRupiah formats currency correctly', () {
      expect(Formatters.formatRupiah(15000), 'Rp 15.000');
      expect(Formatters.formatRupiah(0), 'Rp 0');
      expect(Formatters.formatRupiah(1250000), 'Rp 1.250.000');
      expect(Formatters.formatRupiah(999999999), 'Rp 999.999.999');
    });

    test('formatTanggalIndo formats date in Indonesian format', () {
      // 2026-09-05 is Saturday (Sabtu)
      final date = DateTime(2026, 9, 5);
      final formatted = Formatters.formatTanggalIndo(date);
      expect(formatted, 'Sabtu, 05 September 2026');
    });

    test('formatTanggalSingkat formats date in short format', () {
      final date = DateTime(2026, 9, 5);
      final formatted = Formatters.formatTanggalSingkat(date);
      expect(formatted, '05 Sep 2026');
    });

    test('formatJam formats time in HH:mm format', () {
      final date = DateTime(2026, 9, 5, 14, 30);
      final formatted = Formatters.formatJam(date);
      expect(formatted, '14:30');
    });

    test('formatTanggalJam formats combined date and time', () {
      final date = DateTime(2026, 9, 5, 8, 15);
      final formatted = Formatters.formatTanggalJam(date);
      expect(formatted, '05 Sep 2026, 08:15');
    });
  });

  group('AppColors Tests', () {
    test('Primary and Semantic colors are defined according to specification', () {
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.secondary, const Color(0xFF0D9488));
      expect(AppColors.success, const Color(0xFF16A34A));
      expect(AppColors.danger, const Color(0xFFDC2626));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.info, const Color(0xFF0284C7));
      expect(AppColors.background, const Color(0xFFF8FAFC));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
    });
  });

  group('AppTheme Material 3 Tests', () {
    testWidgets('AppTheme.lightTheme builds correctly within widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Click'),
              ),
            ),
          ),
        ),
      );

      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.colorScheme.error, AppColors.danger);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.elevatedButtonTheme.style, isNotNull);
      expect(theme.outlinedButtonTheme.style, isNotNull);
      expect(theme.textButtonTheme.style, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
    });
  });

  group('AppTypography Tests', () {
    testWidgets('Typography styles render text without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Display', style: AppTypography.displayLarge),
                Text('Title', style: AppTypography.titleLarge),
                Text('Body', style: AppTypography.bodyMedium),
                Text('Currency', style: AppTypography.currencyLarge),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(AppTypography.currencyLarge.color, AppColors.primary);
      expect(AppTypography.titleLarge.fontSize, 20);
    });
  });

  group('AppDialog Widget Tests', () {
    testWidgets('showConfirmDialog renders side-by-side cancel and confirm buttons', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await AppDialog.showConfirmDialog(
                      context: context,
                      title: 'Konfirmasi Keluar',
                      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
                      confirmText: 'Keluar',
                      cancelText: 'Batal',
                      isDanger: true,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Keluar'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin keluar dari aplikasi?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Konfirmasi Keluar'), findsNothing);
    });
  });
}
