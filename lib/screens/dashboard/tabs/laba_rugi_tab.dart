import 'package:flutter/material.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../services/expense_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_card.dart';
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

  // Pengelompokan pengeluaran per tanggal (diurutkan tanggal terbaru)
  List<Map<String, dynamic>> get _expensesGroupedByDate {
    final Map<String, List<ExpenseModel>> map = {};
    for (final e in _expenses) {
      String dateKey = e.tanggal.trim();
      if (dateKey.length >= 10) {
        dateKey = dateKey.substring(0, 10);
      }
      map.putIfAbsent(dateKey, () => []).add(e);
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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

  // Breakdown transaksi per tanggal
  Map<String, List<TransactionModel>> get _groupedTransactionsByDate {
    final Map<String, List<TransactionModel>> map = {};
    for (final t in _transactions) {
      if (t.orderStatus.toUpperCase() == 'CANCELLED') continue;
      String dateKey = t.waktu;
      try {
        final dt = DateTime.parse(t.waktu).toLocal();
        dateKey = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        if (dateKey.length >= 10) {
          dateKey = dateKey.substring(0, 10);
        }
      }
      map.putIfAbsent(dateKey, () => []).add(t);
    }
    return map;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final netProfit = _totalRevenue - _totalExpense;
    final isProfit = netProfit >= 0;
    final expensesByDate = _expensesGroupedByDate;
    final groupedTrx = _groupedTransactionsByDate;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Filter Periode
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

            // 2. Kartu Ringkasan Neraca Keuangan
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris 1: Total Pendapatan & Total Pengeluaran
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pendapatan',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRupiah(_totalRevenue),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Pengeluaran',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRupiah(_totalExpense),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _totalExpense > 0 ? theme.colorScheme.error : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Baris 2: Laba Bersih & Badge Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Laba Bersih ($_selectedFilter)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppBadge(
                        text: isProfit ? 'Untung' : 'Defisit',
                        backgroundColor: isProfit
                            ? Colors.green.shade50
                            : theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                        textColor: isProfit ? Colors.green.shade700 : theme.colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(netProfit),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isProfit ? Colors.green.shade700 : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Tombol Akses Laporan Bulanan
            AppCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: _navigateToMonthlyReport,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan Bulanan',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Performa penjualan & rekap kalender',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Buka',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Rincian Pengeluaran per Tanggal
            Text(
              'Rincian Pengeluaran',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (expensesByDate.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          Row(
                            children: [
                              Text(
                                '$count pengeluaran',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '  •  ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              Text(
                                '- ${_formatRupiah(total)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // 5. Breakdown Riwayat Penjualan per Tanggal (Akordeon)
            Text(
              'Riwayat Penjualan per Tanggal',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (groupedTrx.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada data penjualan pada periode ini',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...groupedTrx.entries.map((group) {
                final dateStr = group.key;
                final items = group.value;
                final dateTotal = items.fold<double>(0.0, (sum, t) => sum + t.totalHarga);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.event_note_rounded, size: 18, color: theme.colorScheme.primary),
                        ),
                        title: Text(
                          dateStr,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${items.length} Transaksi',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        trailing: Text(
                          _formatRupiah(dateTotal),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        children: [
                          const Divider(height: 1),
                          ...items.map((t) {
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                t.namaItem,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${t.customerName} • ${t.jumlah} x ${_formatRupiah(t.harga)}',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                              trailing: Text(
                                _formatRupiah(t.totalHarga),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
