import 'package:flutter/material.dart';
import '../../../core/utils/tanggal_formatter.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/transaction_group_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../services/expense_service.dart';
import '../../../services/laba_rugi_pdf_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_sliver_card.dart';
import '../../../widgets/detail_transaksi_dialog.dart';
import '../../../widgets/filter_custom_tanggal_dialog.dart';
import '../../report/monthly_report_screen.dart';

class LabaRugiTab extends StatefulWidget {
  final VoidCallback? onOpenMonthlyReport;

  /// Service opsional agar test bisa menyuntikkan http client palsu.
  final TransactionService? transactionService;
  final ExpenseService? expenseService;

  const LabaRugiTab({
    super.key,
    this.onOpenMonthlyReport,
    this.transactionService,
    this.expenseService,
  });

  /// Mengubah string tanggal server menjadi tanggal kalender lokal (tanpa jam).
  ///
  /// Mendukung format ISO (`2026-09-11T10:15:30Z`) maupun format teks API
  /// pengeluaran (`11 Sep 2026`). Mengembalikan null bila format tak dikenali.
  static DateTime? localDate(String? raw) {
    final dt = TanggalFormatter.parse(raw);
    if (dt == null) return null;
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateTime(local.year, local.month, local.day);
  }

  /// Mengecek apakah [raw] berada dalam rentang [start]-[end] secara inklusif.
  static bool isDateInRange(String? raw, DateTime start, DateTime end) {
    final date = localDate(raw);
    if (date == null) return false;
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  /// Menghitung rentang tanggal inklusif untuk setiap opsi filter berdasarkan kalender lokal.
  static DateTimeRange? dateRangeForFilter(
    String filter, {
    DateTimeRange? customRange,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    switch (filter) {
      case 'Hari Ini':
        return DateTimeRange(start: today, end: today);
      case 'Kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case 'Minggu Ini':
        // Senin adalah awal minggu (weekday 1)
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return DateTimeRange(start: monday, end: sunday);
      case 'Bulan Ini':
        final firstDay = DateTime(today.year, today.month, 1);
        final lastDay = DateTime(today.year, today.month + 1, 0);
        return DateTimeRange(start: firstDay, end: lastDay);
      case 'Bulan Lalu':
        final firstDayLastMonth = DateTime(today.year, today.month - 1, 1);
        final lastDayLastMonth = DateTime(today.year, today.month, 0);
        return DateTimeRange(start: firstDayLastMonth, end: lastDayLastMonth);
      case 'Pilih Tanggal':
        return customRange;
      case 'Semua':
      default:
        return null;
    }
  }

  /// Nama filter server yang gabungan jendelanya menutupi seluruh [localRange].
  ///
  /// API hanya mendukung jendela `Hari Ini`/`Minggu Ini`/`Bulan Ini`/
  /// `Bulan Lalu` dan menghitung batasnya di zona `UTC`
  /// (`api/config/app.php`), sedangkan kalender yang dilihat pengguna memakai
  /// zona perangkat. [tzOffset] karena itu dipakai untuk menggeser rentang
  /// lokal ke jendela UTC sebelum dicocokkan.
  ///
  /// Kombinasi dengan total durasi terkecil yang dipilih supaya muatan yang
  /// diunduh sekecil mungkin (mis. `Hari Ini` cukup lewat `Minggu Ini`). Bila
  /// tidak ada kombinasi yang menutupi (mis. rentang dua bulan ke belakang),
  /// `['Semua']` dikembalikan sebagai jalan terakhir.
  static List<String> serverFiltersForRange({
    required DateTimeRange? localRange,
    Duration tzOffset = Duration.zero,
    DateTime? now,
  }) {
    if (localRange == null) return const ['Semua'];

    final utc = (now ?? DateTime.now()).toUtc();
    final utcMidnight = DateTime.utc(utc.year, utc.month, utc.day);
    final weekStart =
        utcMidnight.subtract(Duration(days: utcMidnight.weekday - 1));
    final monthStart = DateTime.utc(utc.year, utc.month, 1);
    final nextMonthStart = DateTime.utc(utc.year, utc.month + 1, 1);
    final lastMonthStart = DateTime.utc(utc.year, utc.month - 1, 1);

    final windows = <_FilterWindow>[
      _FilterWindow(
        'Hari Ini',
        utcMidnight,
        utcMidnight.add(const Duration(days: 1)),
      ),
      _FilterWindow(
        'Minggu Ini',
        weekStart,
        weekStart.add(const Duration(days: 7)),
      ),
      _FilterWindow('Bulan Ini', monthStart, nextMonthStart),
      _FilterWindow('Bulan Lalu', lastMonthStart, monthStart),
    ];

    // Jendela target dibangun sebagai instant UTC: pergantian hari lokal 00:00
    // sama dengan 00:00 UTC dikurangi offset perangkat.
    final start = DateTime.utc(
      localRange.start.year,
      localRange.start.month,
      localRange.start.day,
    ).subtract(tzOffset);
    final end = DateTime.utc(
      localRange.end.year,
      localRange.end.month,
      localRange.end.day,
    ).add(const Duration(days: 1)).subtract(tzOffset);

    List<_FilterWindow> bestCombo = const [];
    Duration? bestSpan;

    for (int mask = 1; mask < (1 << windows.length); mask++) {
      final combo = <_FilterWindow>[];
      var span = Duration.zero;
      for (int i = 0; i < windows.length; i++) {
        if (mask & (1 << i) != 0) {
          combo.add(windows[i]);
          span += windows[i].span;
        }
      }
      if (!_windowCombinationCovers(combo, start, end)) continue;
      if (bestSpan == null ||
          span < bestSpan ||
          (span == bestSpan && combo.length < bestCombo.length)) {
        bestSpan = span;
        bestCombo = combo;
      }
    }

    if (bestCombo.isEmpty) return const ['Semua'];
    final ordered = [...bestCombo]..sort((a, b) => a.start.compareTo(b.start));
    return ordered.map((w) => w.filter).toList();
  }

  static bool _windowCombinationCovers(
    List<_FilterWindow> windows,
    DateTime start,
    DateTime end,
  ) {
    if (windows.isEmpty) return false;
    final sorted = [...windows]..sort((a, b) => a.start.compareTo(b.start));
    var cursor = start;
    for (final w in sorted) {
      if (!w.end.isAfter(cursor)) continue;
      if (w.start.isAfter(cursor)) return false;
      cursor = w.end;
      if (!cursor.isBefore(end)) return true;
    }
    return !cursor.isBefore(end);
  }

  @override
  State<LabaRugiTab> createState() => _LabaRugiTabState();
}

/// Jendela filter yang didukung API, dihitung pada zona `UTC`.
class _FilterWindow {
  final String filter;
  final DateTime start;
  final DateTime end;

  const _FilterWindow(this.filter, this.start, this.end);

  Duration get span => end.difference(start);
}

class _LabaRugiTabState extends State<LabaRugiTab> {
  late final TransactionService _transactionService =
      widget.transactionService ?? TransactionService();
  late final ExpenseService _expenseService =
      widget.expenseService ?? ExpenseService();

  /// Filter `Semua` menarik seluruh riwayat sehingga cache-nya dibuat lebih
  /// panjang agar tidak diunduh ulang saat pengguna berpindah filter.
  static const Duration _heavyFilterCacheTtl = Duration(minutes: 5);

  String _selectedFilter = 'Bulan Ini';
  final List<String> _filters = [
    'Hari Ini',
    'Kemarin',
    'Minggu Ini',
    'Bulan Ini',
    'Bulan Lalu',
    'Semua',
    'Pilih Tanggal',
  ];

  DateTimeRange? _customDateRange;
  String _selectedDataType = 'Tampilkan Semua';

  double _totalRevenue = 0;
  double _totalExpense = 0;
  List<TransactionGroup> _groups = [];
  List<ExpenseModel> _rawExpenses = [];
  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _expensesByDate = [];
  List<Map<String, dynamic>> _topSelling = [];

  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  /// Penanda urutan permintaan agar respons lama tidak menimpa hasil terbaru.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Nama filter server untuk transaksi: `waktu` berupa stempel waktu, jadi
  /// rentang lokal digeser offset zona perangkat.
  List<String> _transactionServerFilters() {
    return LabaRugiTab.serverFiltersForRange(
      localRange: LabaRugiTab.dateRangeForFilter(
        _selectedFilter,
        customRange: _customDateRange,
      ),
      tzOffset: DateTime.now().timeZoneOffset,
    );
  }

  /// Nama filter server untuk pengeluaran: kolom `date` sudah berupa tanggal
  /// kalender lokal pengguna, jadi tidak perlu pergeseran zona.
  List<String> _expenseServerFilters() {
    return LabaRugiTab.serverFiltersForRange(
      localRange: LabaRugiTab.dateRangeForFilter(
        _selectedFilter,
        customRange: _customDateRange,
      ),
    );
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final requestId = ++_requestId;
    setState(() => _isLoading = true);

    try {
      // Hanya periode terpilih yang diunduh; penyaringan kalender lokal tetap
      // diterapkan agar batas tanggal presisi di zona perangkat.
      final results = await Future.wait([
        _fetchTransactions(_transactionServerFilters(), forceRefresh),
        _fetchExpenses(_expenseServerFilters(), forceRefresh),
      ]);

      var trxList = results[0] as List<TransactionModel>;
      var expList = results[1] as List<ExpenseModel>;

      // Terapkan penyaringan tanggal aktif secara inklusif
      final activeRange = LabaRugiTab.dateRangeForFilter(
        _selectedFilter,
        customRange: _customDateRange,
      );

      if (activeRange != null) {
        final start = activeRange.start;
        final end = activeRange.end;

        trxList = trxList
            .where((t) => LabaRugiTab.isDateInRange(t.waktu, start, end))
            .toList();

        expList = expList
            .where((e) => LabaRugiTab.isDateInRange(e.tanggal, start, end))
            .toList();
      }

      // Hitung total penjualan & pengeluaran sesuai pilihan jenis data
      double rev = 0;
      if (_selectedDataType != 'Pengeluaran Saja') {
        for (final t in trxList) {
          if (t.isCompleted) {
            rev += t.totalHarga;
          }
        }
      }

      double exp = 0;
      if (_selectedDataType != 'Pemasukan Saja' && _selectedDataType != 'Rincian Menu Terlaris') {
        for (final e in expList) {
          exp += e.jumlah;
        }
      }

      // Agregasi dihitung sekali di sini, bukan berulang di setiap build.
      final groups = _buildGroups(trxList);

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _groups = groups;
        _rawExpenses = expList;
        _dailySales = _buildDailySales(groups);
        _expensesByDate = _buildExpensesByDate(expList);
        _topSelling = _buildTopSelling(trxList);
        _totalRevenue = rev;
        _totalExpense = exp;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (_) {
      // Periode gagal dimuat: bersihkan angka periode sebelumnya agar total
      // yang tampil tidak pernah mencampur dua periode berbeda.
      if (mounted && requestId == _requestId) {
        setState(() {
          _groups = [];
          _rawExpenses = [];
          _dailySales = [];
          _expensesByDate = [];
          _topSelling = [];
          _totalRevenue = 0;
          _totalExpense = 0;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  /// Mengunduh setiap [filters] lalu menggabungkannya tanpa duplikat, karena
  /// jendela seperti `Minggu Ini` dan `Bulan Ini` saling tumpang tindih.
  ///
  /// Bila salah satu permintaan gagal, kegagalan diteruskan supaya halaman
  /// tidak menampilkan total yang hanya sebagian (angka laba rugi harus utuh).
  Future<List<TransactionModel>> _fetchTransactions(
    List<String> filters,
    bool forceRefresh,
  ) async {
    final batches = await Future.wait(
      filters.map(
        (f) => _transactionService.getTransactions(
          filter: f,
          forceRefresh: forceRefresh,
          cacheTtl: f == 'Semua' ? _heavyFilterCacheTtl : null,
        ),
      ),
    );

    final seen = <String>{};
    final merged = <TransactionModel>[];
    for (final batch in batches) {
      for (final t in batch) {
        final key =
            '${t.idTransaksi}|${t.id}|${t.waktu}|${t.namaItem}|${t.jumlah}|${t.harga}';
        if (seen.add(key)) merged.add(t);
      }
    }
    return merged;
  }

  Future<List<ExpenseModel>> _fetchExpenses(
    List<String> filters,
    bool forceRefresh,
  ) async {
    final batches = await Future.wait(
      filters.map(
        (f) => _expenseService.getExpenses(
          filter: f,
          forceRefresh: forceRefresh,
          cacheTtl: f == 'Semua' ? _heavyFilterCacheTtl : null,
        ),
      ),
    );

    final seen = <String>{};
    final merged = <ExpenseModel>[];
    for (final batch in batches) {
      for (final e in batch) {
        final key = e.id.isNotEmpty
            ? e.id
            : '${e.tanggal}|${e.kategori}|${e.keterangan}|${e.jumlah}';
        if (seen.add(key)) merged.add(e);
      }
    }
    return merged;
  }

  String get _activeFilterLabel {
    if (_selectedFilter == 'Pilih Tanggal' && _customDateRange != null) {
      final s = _customDateRange!.start;
      final e = _customDateRange!.end;
      final startStr = TanggalFormatter.singkat(s);
      final endStr = TanggalFormatter.singkat(e);
      return (s.year == e.year && s.month == e.month && s.day == e.day)
          ? startStr
          : '$startStr - $endStr';
    }
    return _selectedFilter;
  }

  Future<void> _openCustomFilterDialog() async {
    final now = DateTime.now();
    final res = await FilterCustomTanggalDialog.show(
      context: context,
      initialStartDate: _customDateRange?.start ?? now.subtract(const Duration(days: 7)),
      initialEndDate: _customDateRange?.end ?? now,
      initialDataType: _selectedDataType,
    );

    if (res != null) {
      setState(() {
        _customDateRange = DateTimeRange(start: res.startDate, end: res.endDate);
        _selectedDataType = res.dataType;
        _selectedFilter = 'Pilih Tanggal';
      });
      _loadData(forceRefresh: true);
    }
  }

  String _formatRupiah(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().toInt().toString();
    final buffer = StringBuffer(isNegative ? '-Rp ' : 'Rp ');
    for (int i = 0; i < absAmount.length; i++) {
      if (i > 0 && (absAmount.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(absAmount[i]);
    }
    return buffer.toString();
  }

  static const List<String> _hariList = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static const List<String> _bulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  String _formatTanggalLengkap(DateTime dt) {
    final hari = _hariList[dt.weekday - 1];
    final tgl = dt.day.toString().padLeft(2, '0');
    final bulan = _bulanList[dt.month - 1];
    final tahun = dt.year;
    return '$hari, $tgl $bulan $tahun';
  }

  String _formatJam(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '$jam:$menit';
    } catch (_) {
      return '--:--';
    }
  }

  // Pengelompokan seluruh transaksi berstatus valid ke TransactionGroup (Struk)
  List<TransactionGroup> _buildGroups(List<TransactionModel> transactions) {
    final valid = transactions
        .where((t) => t.isCompleted)
        .toList();
    final groups = TransactionGroup.fromTransactionList(valid);
    groups.sort((a, b) {
      try {
        final dtA = DateTime.parse(a.waktu);
        final dtB = DateTime.parse(b.waktu);
        return dtB.compareTo(dtA);
      } catch (_) {
        return 0;
      }
    });
    return groups;
  }

  // 6. Pengelompokan penjualan per tanggal untuk Rincian Harian (Akordeon)
  List<Map<String, dynamic>> _buildDailySales(List<TransactionGroup> groups) {
    final Map<String, List<TransactionGroup>> map = {};
    final Map<String, DateTime?> dateOf = {};
    for (final g in groups) {
      final date = LabaRugiTab.localDate(g.waktu);
      final dateKey =
          date != null ? TanggalFormatter.keIso(date) : g.waktu.trim();
      dateOf[dateKey] = date;
      map.putIfAbsent(dateKey, () => []).add(g);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((k) {
      final dayGroups = map[k]!;
      double total = 0.0;
      for (final g in dayGroups) {
        total += g.totalHarga;
      }

      final date = dateOf[k];
      final displayDate = date != null ? _formatTanggalLengkap(date) : k;

      return {
        'dateKey': k,
        'displayDate': displayDate,
        'total': total,
        'groups': dayGroups,
      };
    }).toList();
  }

  // 7. Pengelompokan pengeluaran per tanggal
  List<Map<String, dynamic>> _buildExpensesByDate(List<ExpenseModel> expenses) {
    final Map<String, List<ExpenseModel>> map = {};
    final Map<String, DateTime?> dateOf = {};
    for (final e in expenses) {
      final date = LabaRugiTab.localDate(e.tanggal);
      final dateKey =
          date != null ? TanggalFormatter.keIso(date) : e.tanggal.trim();
      dateOf[dateKey] = date;
      map.putIfAbsent(dateKey, () => []).add(e);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((k) {
      final items = map[k]!;
      double total = 0.0;
      for (final it in items) {
        total += it.jumlah;
      }

      final date = dateOf[k];
      final displayDate = date != null ? _formatTanggalLengkap(date) : k;

      return {
        'dateKey': k,
        'displayDate': displayDate,
        'count': items.length,
        'total': total,
        'items': items,
      };
    }).toList();
  }

  // 9. Perhitungan Menu Terlaris pada periode aktif
  List<Map<String, dynamic>> _buildTopSelling(List<TransactionModel> transactions) {
    final Map<String, Map<String, dynamic>> map = {};
    for (final t in transactions) {
      if (!t.isCompleted) continue;
      final name = t.namaItem.trim();
      if (name.isEmpty) continue;

      if (!map.containsKey(name)) {
        map[name] = {
          'name': name,
          'qty': 0,
          'omzet': 0.0,
        };
      }
      map[name]!['qty'] = (map[name]!['qty'] as int) + t.jumlah;
      map[name]!['omzet'] = (map[name]!['omzet'] as double) + t.totalHarga;
    }

    final list = map.values.toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    return list;
  }

  void _navigateToMonthlyReport() {
    if (widget.onOpenMonthlyReport != null) {
      widget.onOpenMonthlyReport!();
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => const MonthlyReportScreen(),
        ),
      );
    }
  }

  Future<void> _handleExportPdf() async {
    try {
      String filterTitle = _selectedFilter;
      if (_selectedFilter == 'Pilih Tanggal' && _customDateRange != null) {
        final start = _customDateRange!.start;
        final end = _customDateRange!.end;
        filterTitle = '${TanggalFormatter.singkat(start)} - ${TanggalFormatter.singkat(end)}';
      }

      await LabaRugiPdfService.printLabaRugiReport(
        filterTitle: filterTitle,
        totalRevenue: _totalRevenue,
        totalExpense: _totalExpense,
        groups: _groups,
        expenses: _rawExpenses,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final text = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: icon == null
              ? text
              : Row(
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: text),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _emptySection(BuildContext context, String message) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && !_hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    final netProfit = _totalRevenue - _totalExpense;
    final isProfit = netProfit >= 0;
    final dailySales = _dailySales;
    final expensesByDate = _expensesByDate;
    final transactionGroups = _groups;
    final topSelling = _topSelling;

    final divider = Divider(
      height: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadData(forceRefresh: true),
            child: CustomScrollView(
              slivers: [
                // 1. Header Halaman, 2. Banner Card, 3. Ringkasan Laba-Rugi,
                // 4. Filter Periode, 5. Card Rekap Performa (jumlah elemen tetap).
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        'Laporan Keuangan',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analisis Performa Warung',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Banner Card: Laporan Bulanan per Item
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan Bulanan per Item',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lihat rincian penjualan harian untuk setiap barang.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _navigateToMonthlyReport,
                                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                                label: const Text(
                                  'Buka Laporan Item',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Section Header: Ringkasan Laba-Rugi + Tombol PDF
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ringkasan Laba-Rugi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Export PDF',
                            onPressed: _handleExportPdf,
                            icon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PDF',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4. Filter Periode (Choice Chips)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((f) {
                            final isSelected = _selectedFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: isSelected,
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (f == 'Pilih Tanggal') {
                                    _openCustomFilterDialog();
                                  } else if (selected && _selectedFilter != f) {
                                    setState(() {
                                      _selectedFilter = f;
                                      _customDateRange = null;
                                      _selectedDataType = 'Tampilkan Semua';
                                    });
                                    // Cache per rentang dipakai ulang; unduhan
                                    // ulang hanya lewat pull-to-refresh.
                                    _loadData();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Card Rekap Performa
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekap Performa ($_activeFilterLabel)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Builder(
                              builder: (context) {
                                String subtitle = '(Penjualan - Pengeluaran)';
                                if (_selectedDataType == 'Pengeluaran Saja') {
                                  subtitle = '(Pengeluaran Operasional)';
                                } else if (_selectedDataType == 'Pemasukan Saja') {
                                  subtitle = '(Pemasukan Penjualan)';
                                } else if (_selectedDataType == 'Rincian Menu Terlaris') {
                                  subtitle = '(Omzet Penjualan Menu)';
                                }
                                return Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Penjualan',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(_totalRevenue),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pengeluaran',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '- ${_formatRupiah(_totalExpense)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Laba Bersih:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(netProfit),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isProfit
                                        ? Colors.green.shade700
                                        : theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. Section Rincian Harian (Akordeon Transaksi Harian)
                if (_selectedDataType == 'Tampilkan Semua' ||
                    _selectedDataType == 'Pemasukan Saja' ||
                    _selectedDataType == 'Laba Rugi Saja') ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _sectionHeader(context, title: 'Rincian Harian'),
                  if (dailySales.isEmpty)
                    _emptySection(context, 'Tidak ada transaksi pada periode ini')
                  else
                    AppSliverCard(
                      sliver: SliverList.separated(
                        itemCount: dailySales.length,
                        separatorBuilder: (_, _) => divider,
                        itemBuilder: (context, index) {
                          final day = dailySales[index];
                          final displayDate = day['displayDate'] as String;
                          final total = day['total'] as double;
                          final groups = day['groups'] as List<TransactionGroup>;

                          return Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              title: Text(
                                displayDate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              trailing: Text(
                                _formatRupiah(total),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              children: groups.map((g) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: InkWell(
                                    onTap: () => DetailTransaksiDialog.show(
                                      context: context,
                                      group: g,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.receipt_outlined,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  g.idTransaksi,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${_formatJam(g.waktu)} • ${g.totalQuantity} item',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatRupiah(g.totalHarga),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                ],

                // 7. Section Rincian Pengeluaran
                if (_selectedDataType == 'Tampilkan Semua' ||
                    _selectedDataType == 'Pengeluaran Saja') ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _sectionHeader(context, title: 'Rincian Pengeluaran'),
                  if (expensesByDate.isEmpty)
                    _emptySection(context, 'Tidak ada pengeluaran pada periode ini')
                  else
                    AppSliverCard(
                      innerPadding: const EdgeInsets.symmetric(vertical: 4),
                      sliver: SliverList.separated(
                        itemCount: expensesByDate.length,
                        separatorBuilder: (_, _) => divider,
                        itemBuilder: (context, index) {
                          final group = expensesByDate[index];
                          final displayDate = group['displayDate'] as String;
                          final count = group['count'] as int;
                          final total = group['total'] as double;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayDate,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count pengeluaran • - ${_formatRupiah(total)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],

                // 8. Section Daftar Transaksi Per Struk
                if (_selectedDataType == 'Tampilkan Semua' ||
                    _selectedDataType == 'Pemasukan Saja') ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _sectionHeader(
                    context,
                    title: 'Daftar Transaksi Per Struk ($_activeFilterLabel)',
                    icon: Icons.receipt_long_rounded,
                  ),
                  if (transactionGroups.isEmpty)
                    _emptySection(context, 'Tidak ada transaksi pada periode ini')
                  else
                    AppSliverCard(
                      innerPadding: const EdgeInsets.symmetric(vertical: 4),
                      sliver: SliverList.separated(
                        itemCount: transactionGroups.length,
                        separatorBuilder: (_, _) => divider,
                        itemBuilder: (context, index) {
                          final g = transactionGroups[index];
                          final paymentText = g.paymentMethod.isNotEmpty
                              ? g.paymentMethod.toUpperCase()
                              : 'CASH';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.idTransaksi,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Berhasil • $paymentText',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatRupiah(g.totalHarga),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],

                // 9. Section Menu Terlaris
                if (_selectedDataType == 'Tampilkan Semua' ||
                    _selectedDataType == 'Rincian Menu Terlaris') ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _sectionHeader(
                    context,
                    title: 'Menu Terlaris ($_activeFilterLabel)',
                    icon: Icons.emoji_events_outlined,
                  ),
                  if (topSelling.isEmpty)
                    _emptySection(context, 'Tidak ada data penjualan menu')
                  else
                    AppSliverCard(
                      innerPadding: const EdgeInsets.symmetric(vertical: 4),
                      sliver: SliverList.separated(
                        itemCount: topSelling.length,
                        separatorBuilder: (_, _) => divider,
                        itemBuilder: (context, index) {
                          final item = topSelling[index];
                          final name = item['name'] as String;
                          final qty = item['qty'] as int;
                          final omzet = item['omzet'] as double;

                          Color rankColor;
                          if (index == 0) {
                            rankColor = const Color(0xFFD97706); // Emas hangat
                          } else if (index == 1) {
                            rankColor = const Color(0xFF64748B); // Perak
                          } else if (index == 2) {
                            rankColor = const Color(0xFFB45309); // Perunggu
                          } else {
                            rankColor = theme.colorScheme.onSurfaceVariant;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '#${index + 1} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: rankColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$qty porsi terjual • ${_formatRupiah(omzet)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          if (_isLoading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
