import 'package:flutter/material.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/transaction_group_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../services/expense_service.dart';
import '../../../services/monthly_report_pdf_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/detail_transaksi_dialog.dart';
import '../../report/monthly_report_screen.dart';

class LabaRugiTab extends StatefulWidget {
  final VoidCallback? onOpenMonthlyReport;

  const LabaRugiTab({
    super.key,
    this.onOpenMonthlyReport,
  });

  @override
  State<LabaRugiTab> createState() => _LabaRugiTabState();
}

class _LabaRugiTabState extends State<LabaRugiTab> {
  final _transactionService = TransactionService();
  final _expenseService = ExpenseService();

  String _selectedFilter = 'Bulan Ini';
  final List<String> _filters = [
    'Hari Ini',
    'Kemarin',
    'Minggu Ini',
    'Bulan Ini',
    'Bulan Lalu',
    'Semua',
    'Pilih Rentang',
  ];

  DateTimeRange? _customDateRange;

  double _totalRevenue = 0;
  double _totalExpense = 0;
  List<TransactionModel> _transactions = [];
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      String filterArg = _selectedFilter;
      if (filterArg == 'Pilih Rentang') {
        filterArg = 'Semua';
      }

      final trxFut = _transactionService.getTransactions(
        filter: filterArg,
        forceRefresh: forceRefresh,
      ).catchError((_) => <TransactionModel>[]);

      final expFut = _expenseService.getExpenses(
        filter: filterArg,
        forceRefresh: forceRefresh,
      ).catchError((_) => <ExpenseModel>[]);

      final results = await Future.wait([trxFut, expFut]);
      var trxList = results[0] as List<TransactionModel>;
      var expList = results[1] as List<ExpenseModel>;

      if (_selectedFilter == 'Pilih Rentang' && _customDateRange != null) {
        final start = _customDateRange!.start;
        final end = _customDateRange!.end.add(const Duration(days: 1));

        trxList = trxList.where((t) {
          try {
            final dt = DateTime.parse(t.waktu);
            return dt.isAfter(start) && dt.isBefore(end);
          } catch (_) {
            return true;
          }
        }).toList();

        expList = expList.where((e) {
          try {
            final dt = DateTime.parse(e.tanggal);
            return dt.isAfter(start) && dt.isBefore(end);
          } catch (_) {
            return true;
          }
        }).toList();
      }

      double rev = 0;
      for (final t in trxList) {
        if (t.orderStatus.toUpperCase() != 'CANCELLED') {
          rev += t.totalHarga;
        }
      }

      double exp = 0;
      for (final e in expList) {
        exp += e.jumlah;
      }

      if (mounted) {
        setState(() {
          _transactions = trxList;
          _expenses = expList;
          _totalRevenue = rev;
          _totalExpense = exp;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Pilih Rentang';
      });
      _loadData();
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
  List<TransactionGroup> get _transactionGroups {
    final valid = _transactions
        .where((t) => t.orderStatus.toUpperCase() != 'CANCELLED')
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
  List<Map<String, dynamic>> get _dailySalesBreakdown {
    final Map<String, List<TransactionGroup>> map = {};
    for (final g in _transactionGroups) {
      String dateKey = g.waktu.trim();
      if (dateKey.length >= 10) {
        dateKey = dateKey.substring(0, 10);
      }
      map.putIfAbsent(dateKey, () => []).add(g);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((k) {
      final groups = map[k]!;
      double total = 0.0;
      for (final g in groups) {
        total += g.totalHarga;
      }

      String displayDate = k;
      try {
        final dt = DateTime.parse(k);
        displayDate = _formatTanggalLengkap(dt);
      } catch (_) {
        displayDate = k;
      }

      return {
        'dateKey': k,
        'displayDate': displayDate,
        'total': total,
        'groups': groups,
      };
    }).toList();
  }

  // 7. Pengelompokan pengeluaran per tanggal
  List<Map<String, dynamic>> get _expensesGroupedByDate {
    final Map<String, List<ExpenseModel>> map = {};
    for (final e in _expenses) {
      String dateKey = e.tanggal.trim();
      if (dateKey.length >= 10) {
        dateKey = dateKey.substring(0, 10);
      }
      map.putIfAbsent(dateKey, () => []).add(e);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((k) {
      final items = map[k]!;
      double total = 0.0;
      for (final it in items) {
        total += it.jumlah;
      }

      String displayDate = k;
      try {
        final dt = DateTime.parse(k);
        displayDate = _formatTanggalLengkap(dt);
      } catch (_) {
        displayDate = k;
      }

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
  List<Map<String, dynamic>> get _topSellingMenu {
    final Map<String, Map<String, dynamic>> map = {};
    for (final t in _transactions) {
      if (t.orderStatus.toUpperCase() == 'CANCELLED') continue;
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
      final now = DateTime.now();
      await MonthlyReportPdfService.printMonthlyReport(
        month: now.month,
        year: now.year,
        monthName: _bulanList[now.month - 1],
        totalOrder: _transactionGroups.length,
        totalOmzet: _totalRevenue,
        averageOrderValue: _transactionGroups.isEmpty
            ? 0.0
            : _totalRevenue / _transactionGroups.length,
        topSellingMenu: _topSellingMenu,
        dailyBreakdown: const {},
        storeName: 'Warungku',
        filteredItem: 'Semua Menu',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final netProfit = _totalRevenue - _totalExpense;
    final isProfit = netProfit >= 0;
    final dailySales = _dailySalesBreakdown;
    final expensesByDate = _expensesGroupedByDate;
    final transactionGroups = _transactionGroups;
    final topSelling = _topSellingMenu;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Header Halaman
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
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                        if (f == 'Pilih Rentang') {
                          _pickCustomDateRange();
                        } else if (selected && _selectedFilter != f) {
                          setState(() {
                            _selectedFilter = f;
                            _customDateRange = null;
                          });
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
                    'Rekap Performa ($_selectedFilter)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(Penjualan - Pengeluaran)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
            const SizedBox(height: 20),

            // 6. Section Rincian Harian (Akordeon Transaksi Harian)
            Text(
              'Rincian Harian',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (dailySales.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada transaksi pada periode ini',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dailySales.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
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
            const SizedBox(height: 20),

            // 7. Section Rincian Pengeluaran
            Text(
              'Rincian Pengeluaran',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (expensesByDate.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada pengeluaran pada periode ini',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expensesByDate.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
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
            const SizedBox(height: 20),

            // 8. Section Daftar Transaksi Per Struk
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Daftar Transaksi Per Struk ($_selectedFilter)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (transactionGroups.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada transaksi pada periode ini',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactionGroups.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final g = transactionGroups[index];
                    final paymentText = g.paymentMethod.isNotEmpty
                        ? g.paymentMethod.toUpperCase()
                        : 'CASH';

                    return InkWell(
                      onTap: () => DetailTransaksiDialog.show(
                        context: context,
                        group: g,
                      ),
                      child: Padding(
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
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // 9. Section Menu Terlaris
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Menu Terlaris ($_selectedFilter)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (topSelling.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada data penjualan menu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topSelling.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

