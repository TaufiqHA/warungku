import 'package:flutter/material.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/role_guard.dart';
import '../../data/models/transaction_model.dart';
import '../../services/monthly_report_pdf_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/app_card.dart';

class MonthlyReportScreen extends StatefulWidget {
  final int? initialMonth;
  final int? initialYear;

  const MonthlyReportScreen({
    super.key,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _transactionService = TransactionService();

  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _months = const [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<int> _years = [2024, 2025, 2026, 2027];

  List<TransactionModel> _monthTransactions = [];
  bool _isLoading = true;
  String _selectedItem = 'Semua Menu';
  final Set<int> _expandedDays = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = widget.initialMonth ?? now.month;
    _selectedYear = widget.initialYear ?? now.year;
    _loadReportData();
  }

  Future<void> _loadReportData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final all = await _transactionService.getTransactions(
        filter: 'Semua',
        forceRefresh: forceRefresh,
      ).catchError((_) => <TransactionModel>[]);
      
      final filtered = all.where((t) {
        if (!t.isCompleted) return false;
        try {
          final dt = DateTime.parse(t.waktu);
          return dt.month == _selectedMonth && dt.year == _selectedYear;
        } catch (_) {
          return true; // Fallback jika format waktu kustom
        }
      }).toList();

      if (mounted) {
        setState(() {
          _monthTransactions = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _availableItems {
    final set = <String>{};
    for (final t in _monthTransactions) {
      final name = t.namaItem.trim();
      if (name.isNotEmpty) set.add(name);
    }
    final list = set.toList()..sort();
    return ['Semua Menu', ...list];
  }

  List<TransactionModel> get _effectiveTransactions {
    if (_selectedItem == 'Semua Menu') {
      return _monthTransactions;
    }
    return _monthTransactions.where((t) => t.namaItem == _selectedItem).toList();
  }

  int get _totalOrder {
    // Hitung ID transaksi unik yang selesai
    final set = <String>{};
    for (final t in _effectiveTransactions) {
      set.add(t.idTransaksi);
    }
    return set.length;
  }

  double get _totalOmzet {
    return _effectiveTransactions.fold<double>(0.0, (sum, t) => sum + t.totalHarga);
  }

  double get _averageOrderValue {
    final count = _totalOrder;
    if (count == 0) return 0.0;
    return _totalOmzet / count;
  }

  List<Map<String, dynamic>> get _topSellingMenu {
    final Map<String, Map<String, dynamic>> map = {};
    for (final t in _effectiveTransactions) {
      if (!map.containsKey(t.namaItem)) {
        map[t.namaItem] = {
          'name': t.namaItem,
          'qty': 0,
          'omzet': 0.0,
        };
      }
      map[t.namaItem]!['qty'] = (map[t.namaItem]!['qty'] as int) + t.jumlah;
      map[t.namaItem]!['omzet'] = (map[t.namaItem]!['omzet'] as double) + t.totalHarga;
    }

    final list = map.values.toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    return list;
  }

  Map<int, Map<String, dynamic>> get _dailyBreakdown {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final Map<int, Map<String, dynamic>> map = {};

    for (int day = 1; day <= daysInMonth; day++) {
      map[day] = {
        'day': day,
        'orderCount': 0,
        'omzet': 0.0,
      };
    }

    final Map<int, Set<String>> dayTrxIds = {};
    for (final t in _effectiveTransactions) {
      int day = 1;
      try {
        final dt = DateTime.parse(t.waktu);
        day = dt.day;
      } catch (_) {}

      if (day >= 1 && day <= daysInMonth) {
        dayTrxIds.putIfAbsent(day, () => <String>{}).add(t.idTransaksi);
        map[day]!['omzet'] = (map[day]!['omzet'] as double) + t.totalHarga;
      }
    }

    dayTrxIds.forEach((day, trxSet) {
      if (map.containsKey(day)) {
        map[day]!['orderCount'] = trxSet.length;
      }
    });

    return map;
  }

  Map<int, List<TransactionModel>> get _dailyTransactions {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final Map<int, List<TransactionModel>> map = {};
    for (int day = 1; day <= daysInMonth; day++) {
      map[day] = [];
    }

    for (final t in _effectiveTransactions) {
      int day = 1;
      try {
        final dt = DateTime.parse(t.waktu);
        day = dt.day;
      } catch (_) {}

      if (day >= 1 && day <= daysInMonth) {
        map[day]!.add(t);
      }
    }
    return map;
  }

  List<Map<String, dynamic>> _getDayItems(List<TransactionModel> txs) {
    final Map<String, Map<String, dynamic>> itemMap = {};
    for (final t in txs) {
      if (!itemMap.containsKey(t.namaItem)) {
        itemMap[t.namaItem] = {
          'name': t.namaItem,
          'qty': 0,
          'omzet': 0.0,
        };
      }
      itemMap[t.namaItem]!['qty'] = (itemMap[t.namaItem]!['qty'] as int) + t.jumlah;
      itemMap[t.namaItem]!['omzet'] = (itemMap[t.namaItem]!['omzet'] as double) + t.totalHarga;
    }
    final list = itemMap.values.toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    return list;
  }

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Future<void> _handlePrintReport() async {
    try {
      await MonthlyReportPdfService.printMonthlyReport(
        month: _selectedMonth,
        year: _selectedYear,
        monthName: _months[_selectedMonth - 1],
        totalOrder: _totalOrder,
        totalOmzet: _totalOmzet,
        averageOrderValue: _averageOrderValue,
        topSellingMenu: _topSellingMenu,
        dailyBreakdown: _dailyBreakdown,
        storeName: 'Warungku',
        filteredItem: _selectedItem,
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
    return RoleGuard(
      allowedRole: AppRoles.owner,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final topSelling = _topSellingMenu;
    final daily = _dailyBreakdown;
    final dailyTxs = _dailyTransactions;
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Laporan Bulanan',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Cetak Laporan',
            onPressed: _handlePrintReport,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadReportData(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            // 1. Bar Pemilih Bulan & Tahun
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(
                              _months[index],
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null && val != _selectedMonth) {
                            setState(() => _selectedMonth = val);
                            _loadReportData();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items: _years.map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text(
                            '$y',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedYear) {
                          setState(() => _selectedYear = val);
                          _loadReportData();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 1b. Bar Pemilih Item Menu (Di Bawah Tanggal)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _availableItems.contains(_selectedItem) ? _selectedItem : 'Semua Menu',
                        isExpanded: true,
                        items: _availableItems.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: item == _selectedItem ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedItem) {
                            setState(() => _selectedItem = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Tiga Kartu Ringkasan Kinerja Bulanan
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Order',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalOrder Pesanan',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Omzet',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_totalOmzet),
                            style: theme.textTheme.titleSmall?.copyWith(
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
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rata-rata Penjualan per Order (AOV)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatRupiah(_averageOrderValue),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Menu Terlaris (Top Selling Menu)
            Text(
              'Menu Terlaris (Top Selling)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (topSelling.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Belum ada data penjualan pada periode ini',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topSelling.length > 5 ? 5 : topSelling.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final item = topSelling[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber.shade100
                                  : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: index == 0 ? Colors.amber.shade900 : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['qty']} porsi terjual',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRupiah(item['omzet'] as double),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // 4. Rincian Penjualan Harian
            Text(
              'Rincian Penjualan Harian',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daysInMonth,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final data = daily[day] ?? {'orderCount': 0, 'omzet': 0.0};
                  final count = data['orderCount'] as int;
                  final omzet = data['omzet'] as double;
                  final isExpanded = _expandedDays.contains(day);
                  final dayTxs = dailyTxs[day] ?? [];
                  final dayItems = isExpanded ? _getDayItems(dayTxs) : <Map<String, dynamic>>[];

                  return InkWell(
                    onTap: count > 0
                        ? () {
                            setState(() {
                              if (_expandedDays.contains(day)) {
                                _expandedDays.remove(day);
                              } else {
                                _expandedDays.add(day);
                              }
                            });
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '$day ${_months[_selectedMonth - 1].substring(0, 3)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  count > 0 ? '$count Transaksi' : '-',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                omzet > 0 ? _formatRupiah(omzet) : '-',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: omzet > 0 ? FontWeight.bold : FontWeight.normal,
                                  color: omzet > 0 ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                          if (isExpanded && dayItems.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: dayItems.map((it) {
                                  final name = it['name'] as String;
                                  final qty = it['qty'] as int;
                                  final itemOmzet = it['omzet'] as double;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 5,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$qty porsi',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _formatRupiah(itemOmzet),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
