import 'package:flutter/material.dart';
import '../../../core/utils/tanggal_formatter.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../services/expense_service.dart';
import '../../../services/token_manager.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/biaya_card.dart';

/// Beranda khusus role Admin Kantor.
///
/// Fokus pada beban operasional: ringkasan pengeluaran hari ini / minggu ini /
/// bulan ini, rincian per pos biaya bulan berjalan, jalan pintas ke tab
/// Biaya Operasional & Profil, serta daftar pengeluaran terakhir.
class BerandaKantorTab extends StatefulWidget {
  final VoidCallback? onGoToBiaya;
  final VoidCallback? onGoToProfil;

  const BerandaKantorTab({
    super.key,
    this.onGoToBiaya,
    this.onGoToProfil,
  });

  @override
  State<BerandaKantorTab> createState() => _BerandaKantorTabState();
}

class _BerandaKantorTabState extends State<BerandaKantorTab> {
  final _expenseService = ExpenseService();

  UserModel? _currentUser;
  List<ExpenseModel> _bulanIni = [];
  double _totalHariIni = 0;
  double _totalMingguIni = 0;
  double _totalBulanIni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _expenseService
            .getExpenses(filter: 'Hari Ini', forceRefresh: forceRefresh)
            .catchError((_) => <ExpenseModel>[]),
        _expenseService
            .getExpenses(filter: 'Minggu Ini', forceRefresh: forceRefresh)
            .catchError((_) => <ExpenseModel>[]),
        _expenseService
            .getExpenses(filter: 'Bulan Ini', forceRefresh: forceRefresh)
            .catchError((_) => <ExpenseModel>[]),
      ]);

      final user = await TokenManager.getUser();

      double sumOf(List<ExpenseModel> list) =>
          list.fold<double>(0.0, (sum, e) => sum + e.jumlah);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _totalHariIni = sumOf(results[0]);
          _totalMingguIni = sumOf(results[1]);
          _totalBulanIni = sumOf(results[2]);
          _bulanIni = results[2];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

  /// Total pengeluaran bulan berjalan per pos kategori (nominal terbesar dulu).
  List<MapEntry<String, double>> get _rincianPosBulanIni {
    final map = <String, double>{};
    for (final e in _bulanIni) {
      final key = e.kategori.trim().isEmpty ? 'Biaya dll' : e.kategori.trim();
      map[key] = (map[key] ?? 0) + e.jumlah;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Pengeluaran terbaru (maksimal 5) dari bulan berjalan.
  List<ExpenseModel> get _pengeluaranTerakhir {
    final list = [..._bulanIni];
    list.sort((a, b) {
      final da = TanggalFormatter.parse(a.tanggal);
      final db = TanggalFormatter.parse(b.tanggal);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rincianPos = _rincianPosBulanIni;
    final terakhir = _pengeluaranTerakhir;

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Kartu Sambutan Pengguna
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.business_center_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.name.isNotEmpty == true
                            ? _currentUser!.name
                            : 'Admin Kantor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppBadge.role(_currentUser?.role.isNotEmpty == true
                              ? _currentUser!.role
                              : 'ADMIN_KANTOR'),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              TanggalFormatter.lengkap(DateTime.now()),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 16),

          // 2. Metrik Beban Pengeluaran
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetric(
                    label: 'Biaya Hari Ini',
                    value: _totalHariIni,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetric(
                    label: 'Minggu Ini',
                    value: _totalMingguIni,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetric(
                    label: 'Bulan Ini',
                    value: _totalBulanIni,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Jalan Pintas Menu
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.payments_outlined,
                    label: 'Biaya',
                    onTap: widget.onGoToBiaya,
                  ),
                ),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.account_circle_outlined,
                    label: 'Profil',
                    onTap: widget.onGoToProfil,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Rincian Pos Biaya Bulan Ini
          Text(
            'Rincian Pos Biaya',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: rincianPos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Belum ada pengeluaran bulan ini',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rincianPos.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final pos = rincianPos[index];
                      final persen = _totalBulanIni > 0
                          ? (pos.value / _totalBulanIni) * 100
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pos.key,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${persen.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatRupiah(pos.value),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),

          // 5. Pengeluaran Terakhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran Terakhir',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                tooltip: 'Muat Ulang',
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (terakhir.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada catatan pengeluaran',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...terakhir.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BiayaCard(
                  expense: e,
                  onTap: widget.onGoToBiaya,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetric({required String label, required double value}) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
