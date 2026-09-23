import 'package:flutter/material.dart';
import '../core/utils/tanggal_formatter.dart';
import '../data/models/transaction_group_model.dart';
import '../data/models/transaction_model.dart';
import 'app_badge.dart';
import 'app_card.dart';

class RiwayatTransaksiCard extends StatefulWidget {
  final TransactionGroup? group;
  final TransactionModel? trx;
  final VoidCallback? onTap;
  final Future<bool?> Function()? onDelete;
  final bool isCompact;
  final bool isExpandable;
  final bool initiallyExpanded;
  final VoidCallback? onPrintAgain;
  final VoidCallback? onDetail;

  const RiwayatTransaksiCard({
    super.key,
    this.group,
    this.trx,
    this.onTap,
    this.onDelete,
    this.isCompact = false,
    this.isExpandable = true,
    this.initiallyExpanded = false,
    this.onPrintAgain,
    this.onDetail,
  }) : assert(group != null || trx != null, 'Either group or trx must be provided');

  @override
  State<RiwayatTransaksiCard> createState() => _RiwayatTransaksiCardState();
}

class _RiwayatTransaksiCardState extends State<RiwayatTransaksiCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant RiwayatTransaksiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  TransactionGroup get _effectiveGroup =>
      widget.group ?? TransactionGroup.fromSingleTransaction(widget.trx!);

  /// Waktu transaksi dalam zona waktu perangkat (`21 Sep 2026, 12:16`).
  /// Nilai mentah dipakai kembali bila format waktu tidak dikenali.
  String _formatWaktuSingkat(String raw, [String? idTransaksi]) {
    final lokal = TanggalFormatter.tanggalJam(raw, idTransaksi: idTransaksi);
    return lokal.isNotEmpty ? lokal : raw;
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

  Widget _buildPaymentBadge(BuildContext context, String method) {
    final m = method.trim().toUpperCase();
    Color bg;
    Color border;
    Color text;

    if (m == 'CASH' || m == 'TUNAI') {
      bg = Colors.green.shade50;
      border = Colors.green.shade200;
      text = Colors.green.shade700;
    } else if (m == 'QRIS') {
      bg = Colors.purple.shade50;
      border = Colors.purple.shade200;
      text = Colors.purple.shade700;
    } else if (m == 'TRANSFER' || m == 'BANK') {
      bg = Colors.blue.shade50;
      border = Colors.blue.shade200;
      text = Colors.blue.shade700;
    } else {
      bg = Colors.grey.shade100;
      border = Colors.grey.shade300;
      text = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        m.isNotEmpty ? m : 'CASH',
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(
    BuildContext context,
    ThemeData theme,
    TransactionGroup effectiveGroup,
  ) {
    final isCancelled = effectiveGroup.orderStatus.toUpperCase() == 'CANCELLED';
    final hasCashier = effectiveGroup.dicatatOleh.isNotEmpty &&
        effectiveGroup.dicatatOleh != '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Divider(
          height: 1,
          thickness: 0.8,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 10),

        // Daftar Item Transaksi
        ...effectiveGroup.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.jumlah}x ${item.namaItem}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.catatan.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            'Catatan: ${item.catatan}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatRupiah(item.totalHarga),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),

        // Info Kasir jika ada
        if (hasCashier) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Kasir: ${effectiveGroup.dicatatOleh}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 10),
        Divider(
          height: 1,
          thickness: 0.6,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 8),

        // Baris Tombol Aksi: Cetak Ulang, Detail Lengkap, Hapus (khusus Owner)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onDelete != null) ...[
              TextButton.icon(
                onPressed: () async {
                  await widget.onDelete!();
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  'Hapus',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (widget.onDetail != null || (widget.isExpandable && widget.onTap != null)) ...[
              OutlinedButton.icon(
                onPressed: widget.onDetail ?? widget.onTap,
                icon: const Icon(Icons.receipt_outlined, size: 15),
                label: const Text('Detail', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (widget.onPrintAgain != null) ...[
              FilledButton.icon(
                onPressed: widget.onPrintAgain,
                icon: const Icon(Icons.print_rounded, size: 15),
                label: const Text('Cetak Ulang', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCompactCard(BuildContext context, TransactionGroup effectiveGroup) {
    final theme = Theme.of(context);
    final isCancelled = effectiveGroup.orderStatus.toUpperCase() == 'CANCELLED';
    final hasCustomerName = effectiveGroup.customerName.isNotEmpty &&
        effectiveGroup.customerName != '-' &&
        effectiveGroup.customerName.toLowerCase() != 'pelanggan';

    final totalItem = effectiveGroup.totalQuantity;
    final itemSummary = effectiveGroup.items.map((i) => i.namaItem).join(', ');
    final subtitleText = '${_formatWaktuSingkat(effectiveGroup.waktu, effectiveGroup.idTransaksi)} · $totalItem item · $itemSummary';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Avatar Receipt Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // 2. Info Detail Tengah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasCustomerName) ...[
                      Text(
                        effectiveGroup.customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        effectiveGroup.idTransaksi,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Text(
                        effectiveGroup.idTransaksi,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    _buildPaymentBadge(context, effectiveGroup.paymentMethod),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Nominal Total & Dropdown Arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatRupiah(effectiveGroup.totalHarga),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _buildExpandedDetails(context, theme, effectiveGroup)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard(BuildContext context, TransactionGroup effectiveGroup) {
    final theme = Theme.of(context);
    final isCancelled = effectiveGroup.orderStatus.toUpperCase() == 'CANCELLED';
    final customerDisplayName = effectiveGroup.customerName.isNotEmpty && effectiveGroup.customerName != '-'
        ? effectiveGroup.customerName
        : 'Pelanggan';

    return AppCard(
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
                      effectiveGroup.idTransaksi,
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
              AppBadge.status(effectiveGroup.orderStatus),
            ],
          ),
          const Divider(height: 14),

          // Body: Jika multi-item tampilkan daftar item & total, jika single-item format ringkas
          if (effectiveGroup.isMultiItem) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...effectiveGroup.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.jumlah}x ${item.namaItem}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (item.catatan.isNotEmpty)
                                Text(
                                  'Catatan: ${item.catatan}',
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${effectiveGroup.totalQuantity} item • ${effectiveGroup.paymentMethod}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _formatRupiah(effectiveGroup.totalHarga),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Builder(
              builder: (context) {
                final singleItem = effectiveGroup.items.first;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            singleItem.namaItem,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${singleItem.jumlah} x ${_formatRupiah(singleItem.harga)} • ${effectiveGroup.paymentMethod}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (singleItem.catatan.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Catatan: ${singleItem.catatan}',
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
                      _formatRupiah(effectiveGroup.totalHarga),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveGroup = _effectiveGroup;

    final cardContent = widget.isCompact
        ? _buildCompactCard(context, effectiveGroup)
        : _buildStandardCard(context, effectiveGroup);

    final cardWidget = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (widget.isCompact && widget.isExpandable) {
            setState(() => _expanded = !_expanded);
          } else if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      ),
    );

    if (widget.onDelete == null) {
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
      key: ValueKey('dismiss_trx_${effectiveGroup.idTransaksi}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await widget.onDelete!();
      },
      background: dismissBackground,
      secondaryBackground: dismissBackground,
      child: cardWidget,
    );
  }
}
