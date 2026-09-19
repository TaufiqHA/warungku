import 'package:flutter/material.dart';
import '../data/models/transaction_group_model.dart';
import '../data/models/transaction_model.dart';

class DetailTransaksiDialog extends StatelessWidget {
  final TransactionGroup? group;
  final TransactionModel? trx;
  final VoidCallback? onPrintAgain;
  final VoidCallback? onCancel;
  final String? cancelText;

  const DetailTransaksiDialog({
    super.key,
    this.group,
    this.trx,
    this.onPrintAgain,
    this.onCancel,
    this.cancelText,
  }) : assert(group != null || trx != null, 'Either group or trx must be provided');

  TransactionGroup get _effectiveGroup => group ?? TransactionGroup.fromSingleTransaction(trx!);

  static Future<void> show({
    required BuildContext context,
    TransactionGroup? group,
    TransactionModel? trx,
    VoidCallback? onPrintAgain,
    VoidCallback? onCancel,
    String? cancelText,
  }) {
    assert(group != null || trx != null, 'Either group or trx must be provided');
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DetailTransaksiDialog(
        group: group,
        trx: trx,
        onPrintAgain: onPrintAgain,
        onCancel: onCancel,
        cancelText: cancelText,
      ),
    );
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

  String _formatWaktu(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentGreen = Color(0xFF7CB342);
    final effectiveGroup = _effectiveGroup;
    final isCancelled = effectiveGroup.orderStatus.toUpperCase() == 'CANCELLED';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    effectiveGroup.idTransaksi,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (!effectiveGroup.isMultiItem) ...[
                // Single Item Layout (Backward compatible)
                Builder(
                  builder: (context) {
                    final singleItem = effectiveGroup.items.first;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🍜',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                singleItem.namaItem,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  color: isCancelled ? theme.colorScheme.error : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          label: 'Jumlah',
                          value: '${singleItem.jumlah} porsi',
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          label: 'Harga Satuan',
                          value: _formatRupiah(singleItem.harga),
                          theme: theme,
                          valueBold: true,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          label: 'Total',
                          value: _formatRupiah(effectiveGroup.totalHarga),
                          theme: theme,
                          valueBold: true,
                          valueColor: accentGreen,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          label: 'Waktu',
                          value: _formatWaktu(effectiveGroup.waktu),
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          label: 'Dicatat oleh',
                          value: effectiveGroup.dicatatOleh,
                          theme: theme,
                        ),
                        if (effectiveGroup.customerName.isNotEmpty && effectiveGroup.customerName != '-') ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            label: 'Pelanggan',
                            value: effectiveGroup.customerName,
                            theme: theme,
                          ),
                        ],
                        if (effectiveGroup.paymentMethod.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            label: 'Metode Bayar',
                            value: effectiveGroup.paymentMethod,
                            theme: theme,
                          ),
                        ],
                        if (singleItem.catatan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            label: 'Catatan',
                            value: singleItem.catatan,
                            theme: theme,
                            valueItalic: true,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ] else ...[
                // Multi-Item Layout
                _buildDetailRow(
                  label: 'Waktu',
                  value: _formatWaktu(effectiveGroup.waktu),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  label: 'Dicatat oleh',
                  value: effectiveGroup.dicatatOleh,
                  theme: theme,
                ),
                if (effectiveGroup.customerName.isNotEmpty && effectiveGroup.customerName != '-') ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    label: 'Pelanggan',
                    value: effectiveGroup.customerName,
                    theme: theme,
                  ),
                ],
                if (effectiveGroup.paymentMethod.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    label: 'Metode Bayar',
                    value: effectiveGroup.paymentMethod,
                    theme: theme,
                  ),
                ],
                if (effectiveGroup.catatan.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    label: 'Catatan',
                    value: effectiveGroup.catatan,
                    theme: theme,
                    valueItalic: true,
                  ),
                ],
                const Divider(height: 20),
                Text(
                  'Daftar Menu (${effectiveGroup.items.length} item)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ...effectiveGroup.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('🍜', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaItem,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.jumlah} x ${_formatRupiah(item.harga)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (item.catatan.isNotEmpty)
                                Text(
                                  'Catatan: ${item.catatan}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRupiah(item.totalHarga),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
                _buildDetailRow(
                  label: 'Total Belanja (${effectiveGroup.totalQuantity} porsi)',
                  value: _formatRupiah(effectiveGroup.totalHarga),
                  theme: theme,
                  valueBold: true,
                  valueColor: accentGreen,
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons Row: Cetak Ulang & Tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onPrintAgain != null) onPrintAgain!();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: accentGreen,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Cetak Ulang'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: accentGreen,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),

              // Destructive Action: Batalkan (jika transaksi belum batal)
              if (!isCancelled && onCancel != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel!();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    child: Text(cancelText ?? 'Batalkan'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required ThemeData theme,
    bool valueBold = false,
    bool valueItalic = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: valueItalic ? FontStyle.italic : normalStyle,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  static const FontStyle normalStyle = FontStyle.normal;
}
