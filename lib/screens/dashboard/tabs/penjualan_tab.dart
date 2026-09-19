import 'package:flutter/material.dart';
import '../../../data/models/transaction_group_model.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/detail_transaksi_dialog.dart';
import '../../../widgets/riwayat_transaksi_card.dart';
import '../../../widgets/sales_receipt_dialog.dart';
import '../../transaksi/transaksi_penjualan_screen.dart';

class PenjualanTab extends StatefulWidget {
  final bool canAddTransaction;

  const PenjualanTab({
    super.key,
    this.canAddTransaction = true,
  });

  @override
  State<PenjualanTab> createState() => _PenjualanTabState();
}

class _PenjualanTabState extends State<PenjualanTab> {
  final _transactionService = TransactionService();

  final _searchController = TextEditingController();
  String _selectedFilter = 'Hari Ini';
  final List<String> _filterOptions = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];

  List<TransactionGroup> _transactionGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Hanya menampilkan transaksi yang sudah selesai atau dibatalkan (bukan transaksi berjalan / PENDING)
          final nonPending = list.where((t) => t.orderStatus.toUpperCase() != 'PENDING').toList();
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

  double get _totalFilteredOmzet {
    return _filteredTransactions
        .where((g) => g.orderStatus.toUpperCase() != 'CANCELLED')
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
            // Filter Periode
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((opt) {
                  final isSelected = _selectedFilter == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected && _selectedFilter != opt) {
                          setState(() => _selectedFilter = opt);
                          _loadData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, size: 20),
                  hintText: 'Cari transaksi / pemesan...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ringkasan Omzet Periode
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Penjualan ($_selectedFilter)',
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
                  Text(
                    '${transactions.length} Transaksi',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daftar Transaksi
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
            else
              ...transactions.map((group) {
                return RiwayatTransaksiCard(
                  group: group,
                  onTap: () => _showDetailTransaction(group),
                  onDelete: () => _handleDeleteTransaction(group),
                );
              }),
          ],
        ),
      ),
    );
  }
}
