import 'package:flutter/material.dart';
import '../../../core/utils/tanggal_formatter.dart';
import '../../../data/models/transaction_group_model.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_filter_pill.dart';
import '../../../widgets/detail_transaksi_dialog.dart';
import '../../../widgets/riwayat_transaksi_card.dart';
import '../../../widgets/sales_receipt_dialog.dart';
import '../../transaksi/transaksi_penjualan_screen.dart';

class PenjualanTab extends StatefulWidget {
  final bool canAddTransaction;
  final String? initialFilter;
  final bool isActive;
  final TransactionService? transactionService;

  const PenjualanTab({
    super.key,
    this.canAddTransaction = true,
    this.initialFilter,
    this.isActive = true,
    this.transactionService,
  });

  @override
  State<PenjualanTab> createState() => _PenjualanTabState();
}

class _PenjualanTabState extends State<PenjualanTab> with WidgetsBindingObserver {
  late final TransactionService _transactionService;

  final _searchController = TextEditingController();
  late String _selectedFilter;
  late final String _defaultFilter;
  final List<String> _filterOptions = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];

  List<TransactionGroup> _transactionGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transactionService = widget.transactionService ?? TransactionService();
    _defaultFilter = widget.initialFilter ?? (widget.canAddTransaction ? 'Hari Ini' : 'Minggu Ini');
    _selectedFilter = _defaultFilter;
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PenjualanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadData(forceRefresh: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _loadData(forceRefresh: true);
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _transactionService.getTransactions(
        filter: _selectedFilter,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          var filteredList = list;
          if (_selectedFilter == 'Hari Ini') {
            filteredList = list.where((t) => TanggalFormatter.isToday(t.waktu)).toList();
          }
          // Hanya menampilkan transaksi yang sudah selesai atau dibatalkan (bukan transaksi berjalan / PENDING)
          final nonPending = filteredList.where((t) => !t.isPending).toList();
          _transactionGroups = TransactionGroup.fromTransactionList(nonPending);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<TransactionGroup> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _transactionGroups;
    return _transactionGroups.where((g) {
      final matchCust = g.customerName.toLowerCase().contains(query);
      final matchId = g.idTransaksi.toLowerCase().contains(query);
      final matchItems = g.items.any((i) => i.namaItem.toLowerCase().contains(query));
      return matchCust || matchId || matchItems;
    }).toList();
  }

  /// Kunci tanggal lokal (`2026-09-21`) dari waktu ISO server, supaya
  /// pengelompokan bill sejalan dengan jam yang ditampilkan ke pengguna.
  String _dateKeyLokal(String waktu) {
    final dt = TanggalFormatter.parse(waktu);
    if (dt == null) {
      final raw = waktu.trim();
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
    return TanggalFormatter.keIso(dt.isUtc ? dt.toLocal() : dt);
  }

  Map<String, List<TransactionGroup>> get _groupedTransactions {
    final Map<String, List<TransactionGroup>> map = {};
    for (final g in _filteredTransactions) {
      final dateKey = _dateKeyLokal(g.waktu);
      map.putIfAbsent(dateKey, () => []).add(g);
    }
    for (final key in map.keys) {
      map[key]!.sort((a, b) {
        try {
          final dtA = DateTime.parse(a.waktu);
          final dtB = DateTime.parse(b.waktu);
          return dtB.compareTo(dtA);
        } catch (_) {
          return 0;
        }
      });
    }
    return map;
  }

  double get _totalFilteredOmzet {
    return _filteredTransactions
        .where((g) => g.isCompleted)
        .fold(0.0, (sum, g) => sum + g.totalHarga);
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

  Future<bool> _handleDeleteTransaction(TransactionGroup group) async {
    final displayName = group.customerName.isNotEmpty && group.customerName != '-'
        ? group.customerName
        : group.idTransaksi;
    final confirm = await AppDialog.showConfirmation(
      context: context,
      title: 'Hapus Transaksi',
      message: 'Hapus transaksi "$displayName"?',
      confirmText: 'Hapus',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _transactionService.deleteTransaction(group.idTransaksi);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      } catch (e) {
        try {
          await _transactionService.cancelTransaction(group.idTransaksi);
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi dibatalkan'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return true;
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return false;
        }
      }
    }
    return false;
  }

  void _handlePrintAgain(TransactionGroup group) {
    SalesReceiptDialog.showFromTransactionList(
      context: context,
      items: group.items,
      confirmButtonText: 'Cetak Ulang',
      autoPrint: false,
      onPrint: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mencetak ulang struk ${group.idTransaksi}...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showDetailTransaction(TransactionGroup group) {
    DetailTransaksiDialog.show(
      context: context,
      group: group,
      cancelText: widget.canAddTransaction ? 'Batalkan' : 'Hapus Transaksi',
      onPrintAgain: () => _handlePrintAgain(group),
      onCancel: () => _handleDeleteTransaction(group),
    );
  }

  Future<void> _showFilterSheet() async {
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Periode Penjualan',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              ..._filterOptions.map((opt) {
                final isSelected = _selectedFilter == opt;
                return ListTile(
                  dense: true,
                  title: Text(
                    opt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 20)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(opt),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != _selectedFilter && mounted) {
      setState(() => _selectedFilter = selected);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.canAddTransaction
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const TransaksiPenjualanScreen(),
                  ),
                );
                if (result == true && mounted) {
                  _loadData(forceRefresh: true);
                }
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Input Transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // 1. Header Layar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penjualan Harian',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TanggalFormatter.lengkap(DateTime.now()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _loadData(forceRefresh: true),
                  icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Baris Filter Ringkas & Kolom Pencarian
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, size: 20),
                        hintText: 'Cari transaksi...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 145),
                  child: AppFilterPill(
                    icon: Icons.calendar_month_outlined,
                    label: _selectedFilter,
                    isActive: _selectedFilter != _defaultFilter,
                    onTap: _showFilterSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Ringkasan Omzet Periode
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFilter == 'Hari Ini'
                            ? 'Total Hari Ini'
                            : 'Total Penjualan ($_selectedFilter)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(_totalFilteredOmzet),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${transactions.length} Transaksi',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Daftar Transaksi per Tanggal
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (transactions.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Tidak ada riwayat transaksi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final grouped = _groupedTransactions;
                  final sortedDateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                  final todayIso = TanggalFormatter.keIso(DateTime.now());

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedDateKeys.map((dateKey) {
                      final groupsOnDate = grouped[dateKey]!;
                      final isSameAsToday = dateKey == todayIso;
                      final isFirstGroup = dateKey == sortedDateKeys.first;

                      String dateLabel;
                      try {
                        final dt = DateTime.parse(dateKey);
                        dateLabel = TanggalFormatter.bulanPenuh(dt);
                      } catch (_) {
                        dateLabel = dateKey;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 10),
                            child: isSameAsToday || isFirstGroup
                                ? Text(
                                    'DAFTAR TRANSAKSI',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  )
                                : Text(
                                    dateLabel,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                          ...groupsOnDate.map((group) {
                            return RiwayatTransaksiCard(
                              group: group,
                              isCompact: true,
                              onTap: () => _showDetailTransaction(group),
                              onDelete: () => _handleDeleteTransaction(group),
                            );
                          }),
                          const SizedBox(height: 6),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
