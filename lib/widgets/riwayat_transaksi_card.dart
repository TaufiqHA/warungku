import 'package:flutter/material.dart';
import '../data/models/transaction_model.dart';
import 'app_badge.dart';
import 'app_card.dart';

class RiwayatTransaksiCard extends StatelessWidget {
  final TransactionModel trx;
  final VoidCallback? onTap;
  final Future<bool?> Function()? onDelete;

  const RiwayatTransaksiCard({
    super.key,
    required this.trx,
    this.onTap,
    this.onDelete,
  });

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
    final isCancelled = trx.orderStatus.toUpperCase() == 'CANCELLED';
    final customerDisplayName = trx.customerName.isNotEmpty && trx.customerName != '-'
        ? trx.customerName
        : 'Pelanggan';

    final cardWidget = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nama Pelanggan & Nomor Transaksi + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerDisplayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trx.idTransaksi,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppBadge.status(trx.orderStatus),
                ],
              ),
              const Divider(height: 14),

              // Body: Nama Item & Rincian (Tanpa tombol Batal fisik)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trx.namaItem,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${trx.jumlah} x ${_formatRupiah(trx.harga)} • ${trx.paymentMethod}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (trx.catatan.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Catatan: ${trx.catatan}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    _formatRupiah(trx.totalHarga),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) {
      return cardWidget;
    }

    final dismissBackground = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          SizedBox(width: 6),
          Text(
            'Hapus',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('dismiss_trx_${trx.idTransaksi}_${trx.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await onDelete!();
      },
      background: dismissBackground,
      secondaryBackground: dismissBackground,
      child: cardWidget,
    );
  }
}
