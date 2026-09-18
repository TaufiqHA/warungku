import 'package:flutter/material.dart';
import '../../../core/utils/tanggal_formatter.dart';
import '../../../data/models/expense_model.dart';
import '../../../services/expense_service.dart';
import '../../../services/token_manager.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_filter_pill.dart';
import '../../../widgets/biaya_card.dart';
import '../../../widgets/form_biaya_dialog.dart';

/// Tab Biaya Operasional (role Admin Kantor & Owner).
///
/// Filter kategori + periode (termasuk rentang tanggal), kartu total
/// pengeluaran terfilter, dan daftar riwayat pengeluaran dengan aksi
/// tambah / ubah / hapus via endpoint `/api/v1/expenses`.
class BiayaTab extends StatefulWidget {
  const BiayaTab({super.key});

  @override
  State<BiayaTab> createState() => _BiayaTabState();
}

class _BiayaTabState extends State<BiayaTab> {
  final _expenseService = ExpenseService();

  static const List<String> _periodeOptions = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Bulan Lalu',
    'Semua',
    'Pilih Rentang',
  ];

  final Set<String> _knownCategories = {...FormBiayaDialog.kategoriOptions};

  static const String _defaultPeriode = 'Bulan Ini';

  String _selectedPeriode = _defaultPeriode;
  String _selectedKategori = 'Semua';
  DateTimeRange? _customRange;

  List<ExpenseModel> _expenses = [];
  String _pembuatName = 'Admin Kantor';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      var filterArg = _selectedPeriode;
      String? startDate;
      String? endDate;

      if (filterArg == 'Pilih Rentang') {
        filterArg = 'Semua';
        if (_customRange != null) {
          startDate = TanggalFormatter.keIso(_customRange!.start);
          endDate = TanggalFormatter.keIso(_customRange!.end);
        }
      }

      final list = await _expenseService
          .getExpenses(
            filter: filterArg,
            startDate: startDate,
            endDate: endDate,
            forceRefresh: forceRefresh,
          )
          .catchError((_) => <ExpenseModel>[]);

      final user = await TokenManager.getUser();

      if (mounted) {
        setState(() {
          _expenses = list;
          _knownCategories.addAll(
            list.map((e) => e.kategori).where((k) => k.trim().isNotEmpty),
          );
          _pembuatName = (user?.name.isNotEmpty == true) ? user!.name : 'Admin Kantor';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriode = 'Pilih Rentang';
      });
      _loadData();
    }
  }

  /// Bottom sheet pemilih opsi filter (dipakai periode & kategori).
  Future<String?> _showOptionSheet({
    required String title,
    required List<String> options,
    required String selected,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<String>(
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
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((option) {
                      final isSelected = option == selected;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 20,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => Navigator.of(ctx).pop(option),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPeriodeSheet() async {
    final selected = await _showOptionSheet(
      title: 'Periode',
      options: _periodeOptions,
      selected: _selectedPeriode,
    );
    if (!mounted || selected == null) return;

    if (selected == 'Pilih Rentang') {
      await _pickCustomRange();
      return;
    }
    if (selected == _selectedPeriode) return;

    setState(() {
      _selectedPeriode = selected;
      _customRange = null;
    });
    _loadData();
  }

  Future<void> _showKategoriSheet() async {
    final selected = await _showOptionSheet(
      title: 'Kategori',
      options: _kategoriOptions,
      selected: _selectedKategori,
    );
    if (!mounted || selected == null || selected == _selectedKategori) return;

    setState(() => _selectedKategori = selected);
  }

  Future<void> _handleTambah() async {
    final result = await FormBiayaDialog.show(
      context: context,
      pembuat: _pembuatName,
    );
    if (result == null || !mounted) return;

    try {
      await _expenseService.addExpense(
        kategori: result.kategori,
        keterangan: result.keterangan,
        jumlah: result.jumlah,
        tanggal: result.tanggal,
        pembuat: _pembuatName,
      );
      await _loadData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil dicatat'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(ExpenseModel expense) async {
    final result = await FormBiayaDialog.show(
      context: context,
      initial: expense,
      pembuat: expense.pembuat.isNotEmpty ? expense.pembuat : _pembuatName,
    );
    if (result == null || !mounted) return;

    try {
      await _expenseService.updateExpense(
        id: expense.id,
        kategori: result.kategori,
        keterangan: result.keterangan,
        jumlah: result.jumlah,
        tanggal: result.tanggal,
        pembuat: expense.pembuat.isNotEmpty ? expense.pembuat : _pembuatName,
      );
      await _loadData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil diperbarui'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(ExpenseModel expense) async {
    final confirm = await AppDialog.showConfirmation(
      context: context,
      title: 'Hapus Biaya',
      message: 'Hapus catatan "${expense.keterangan}"?',
      confirmText: 'Hapus',
      isDestructive: true,
    );
    if (confirm != true || !mounted) return;

    try {
      await _expenseService.deleteExpense(expense.id);
      await _loadData(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan pengeluaran berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  String get _periodeLabel {
    if (_selectedPeriode == 'Pilih Rentang' && _customRange != null) {
      return '${TanggalFormatter.singkat(_customRange!.start)} - '
          '${TanggalFormatter.singkat(_customRange!.end)}';
    }
    return _selectedPeriode;
  }

  List<String> get _kategoriOptions => ['Semua', ..._knownCategories];

  /// Pengeluaran terfilter kategori, diurutkan tanggal terbaru lebih dulu.
  List<ExpenseModel> get _filteredExpenses {
    final list = _expenses.where((e) {
      if (_selectedKategori == 'Semua') return true;
      return e.kategori.toLowerCase() == _selectedKategori.toLowerCase();
    }).toList();

    list.sort((a, b) {
      final da = TanggalFormatter.parse(a.tanggal);
      final db = TanggalFormatter.parse(b.tanggal);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = _filteredExpenses;
    final total = expenses.fold<double>(0.0, (sum, e) => sum + e.jumlah);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleTambah,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            // 1. Baris Filter Ringkas (Periode & Kategori)
            Row(
              children: [
                Expanded(
                  child: AppFilterPill(
                    icon: Icons.calendar_month_outlined,
                    label: _periodeLabel,
                    isActive: _selectedPeriode != _defaultPeriode,
                    onTap: _showPeriodeSheet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppFilterPill(
                    icon: Icons.category_outlined,
                    label: _selectedKategori,
                    isActive: _selectedKategori != 'Semua',
                    onTap: _showKategoriSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Kartu Total Pengeluaran Terfilter
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pengeluaran',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${expenses.length} entri',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_selectedKategori • $_periodeLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Daftar Riwayat Pengeluaran
            Text(
              'Riwayat Pengeluaran',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (expenses.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Tidak ada pengeluaran pada periode ini',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...expenses.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BiayaCard(
                    expense: e,
                    onEdit: () => _handleEdit(e),
                    onDelete: () => _handleDelete(e),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
