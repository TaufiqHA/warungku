import 'package:flutter/material.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_card.dart';

class BiayaTab extends StatefulWidget {
  const BiayaTab({super.key});

  @override
  State<BiayaTab> createState() => _BiayaTabState();
}

class _BiayaTabState extends State<BiayaTab> {
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Bahan Baku', 'Operasional', 'Lainnya'];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data pengeluaran operasional warung
    final expenses = [
      {
        'keterangan': 'Belanja Bahan Baku Beras & Minyak',
        'kategori': 'Bahan Baku',
        'nominal': 450000.0,
        'tanggal': '11 Sep 2026',
      },
      {
        'keterangan': 'Tagihan Listrik & Air Warung',
        'kategori': 'Operasional',
        'nominal': 280000.0,
        'tanggal': '10 Sep 2026',
      },
    ];

    final filteredExpenses = expenses.where((e) {
      if (_selectedCategory == 'Semua') return true;
      return e['kategori'] == _selectedCategory;
    }).toList();

    final totalExpense = filteredExpenses.fold<double>(
      0.0,
      (sum, e) => sum + (e['nominal'] as double),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter Kategori
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = c);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Kartu Total Biaya
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pengeluaran ($_selectedCategory)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRupiah(totalExpense),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daftar Riwayat Biaya
          ...filteredExpenses.map((exp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp['keterangan'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              AppBadge(
                                text: exp['kategori'] as String,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                textColor: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                exp['tanggal'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRupiah(exp['nominal'] as double),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
