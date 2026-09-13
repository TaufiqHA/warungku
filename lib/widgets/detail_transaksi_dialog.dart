import 'package:flutter/material.dart';
import '../data/models/transaction_model.dart';

class DetailTransaksiDialog extends StatelessWidget {
  final TransactionModel trx;
  final VoidCallback? onPrintAgain;
  final VoidCallback? onCancel;
  final String? cancelText;

  const DetailTransaksiDialog({
    super.key,
    required this.trx,
    this.onPrintAgain,
    this.onCancel,
    this.cancelText,
  });

  static Future<void> show({
    required BuildContext context,
    required TransactionModel trx,
    VoidCallback? onPrintAgain,
    VoidCallback? onCancel,
    String? cancelText,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DetailTransaksiDialog(
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
    final isCancelled = trx.orderStatus.toUpperCase() == 'CANCELLED';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            Text(
              'Detail Transaksi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),

            // Item Name with Icon
            Row(
              children: [
                const Text(
                  '🍜',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trx.namaItem,
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

            // Property Rows
            _buildDetailRow(
              label: 'Jumlah',
              value: '${trx.jumlah} porsi',
              theme: theme,
            ),
            const SizedBox(height: 8),

            _buildDetailRow(
              label: 'Harga Satuan',
              value: _formatRupiah(trx.harga),
              theme: theme,
              valueBold: true,
            ),
            const SizedBox(height: 8),

            _buildDetailRow(
              label: 'Total',
              value: _formatRupiah(trx.totalHarga),
              theme: theme,
              valueBold: true,
              valueColor: accentGreen,
            ),
            const SizedBox(height: 8),

            _buildDetailRow(
              label: 'Waktu',
              value: _formatWaktu(trx.waktu),
              theme: theme,
            ),
            const SizedBox(height: 8),

            _buildDetailRow(
              label: 'Dicatat oleh',
              value: trx.dicatatOleh,
              theme: theme,
            ),

            if (trx.customerName.isNotEmpty && trx.customerName != '-') ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                label: 'Pelanggan',
                value: trx.customerName,
                theme: theme,
              ),
            ],

            if (trx.paymentMethod.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                label: 'Metode Bayar',
                value: trx.paymentMethod,
                theme: theme,
              ),
            ],

            if (trx.catatan.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                label: 'Catatan',
                value: trx.catatan,
                theme: theme,
                valueItalic: true,
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
            fontStyle: valueItalic ? FontStyle.italic : FontStyle.normal,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
