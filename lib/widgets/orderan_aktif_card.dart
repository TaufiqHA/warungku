import 'package:flutter/material.dart';
import '../core/utils/tanggal_formatter.dart';
import '../data/models/transaction_model.dart';

class OrderanAktifGroup {
  final String transactionId;
  final String customerName;
  final String waktu;
  final String orderStatus;
  final List<TransactionModel> items;

  OrderanAktifGroup({
    required this.transactionId,
    required this.customerName,
    required this.waktu,
    this.orderStatus = 'PENDING',
    required this.items,
  });

  double get totalHarga => items.fold(0, (sum, item) => sum + item.totalHarga);

  /// Waktu transaksi lengkap dengan tanggal (`20 Sep 2026, 09:00`).
  /// Kosong bila waktu tidak dapat dibaca dari server.
  String get waktuLengkap => TanggalFormatter.tanggalJam(waktu);

  /// Nomor transaksi siap tampil (`#TRX-20260920-01`).
  String get nomorTransaksi =>
      transactionId.trim().isEmpty ? '' : '#${transactionId.trim()}';

  /// Nama pelanggan yang layak tampil, atau `Pesanan` bila tidak diisi.
  String get namaTampil {
    final nama = customerName.trim();
    return nama.isEmpty || nama == '-' ? 'Pesanan' : nama;
  }

  /// Jumlah seluruh porsi pada bill ini.
  int get totalPorsi => items.fold(0, (sum, item) => sum + item.jumlah);

  /// Jumlah porsi yang sudah disajikan (tidak melebihi jumlah pesanan).
  int get totalServed => items.fold(
        0,
        (sum, item) =>
            sum + (item.servedQty > item.jumlah ? item.jumlah : item.servedQty),
      );

  bool get isAllServed =>
      items.isNotEmpty && items.every((item) => item.servedQty >= item.jumlah);
  bool get isReady =>
      orderStatus.trim().toUpperCase() == 'READY' ||
      orderStatus.trim().toUpperCase() == 'SIAP' ||
      isAllServed;
}

/// Kartu orderan aktif di Beranda Admin Toko.
///
/// Bentuk ringkas (default) hanya menampilkan nama pelanggan, jam & nomor
/// transaksi, badge status, serta ringkasan bill. Rincian item beserta aksi
/// (Print Dapur, + Item, Bayar & Cetak) muncul saat kartu diperluas.
class OrderanAktifCard extends StatefulWidget {
  final OrderanAktifGroup group;
  final bool initiallyExpanded;
  final ValueChanged<TransactionModel>? onIncrementServed;
  final ValueChanged<TransactionModel>? onDecrementServed;
  final ValueChanged<TransactionModel>? onEditItem;
  final VoidCallback? onPrintDapur;
  final VoidCallback? onAddItem;
  final VoidCallback? onPayAndPrint;

  const OrderanAktifCard({
    super.key,
    required this.group,
    this.initiallyExpanded = false,
    this.onIncrementServed,
    this.onDecrementServed,
    this.onEditItem,
    this.onPrintDapur,
    this.onAddItem,
    this.onPayAndPrint,
  });

  @override
  State<OrderanAktifCard> createState() => _OrderanAktifCardState();
}

class _OrderanAktifCardState extends State<OrderanAktifCard> {
  static const _accentGreen = Color(0xFF7CB342);

  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant OrderanAktifCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bila slot yang sama kini menampilkan transaksi berbeda, pakai preferensi
    // awal kartu baru alih-alih mewarisi status buka/tutup transaksi lama.
    if (oldWidget.group.transactionId != widget.group.transactionId ||
        oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

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
    final group = widget.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tap untuk buka/tutup): nama pelanggan, nomor transaksi,
          // waktu transaksi, status badge, dan indikator expand.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          group.namaTampil,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(theme, group),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (group.nomorTransaksi.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _buildInfoRow(theme, Icons.tag, group.nomorTransaksi),
                  ],
                  if (group.waktuLengkap.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _buildInfoRow(theme, Icons.access_time, group.waktuLengkap),
                  ],
                ],
              ),
            ),
          ),

          // Ringkasan bill saat kartu tertutup; rincian item saat diperluas.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _buildExpandedContent(theme, group)
                : _buildCollapsedSummary(theme, group),
          ),
        ],
      ),
    );
  }

  /// Satu baris info di header: ikon kecil + teks, dipotong ellipsis bila panjang.
  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme, OrderanAktifGroup group) {
    final ready = group.isReady;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ready ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
          width: 0.8,
        ),
      ),
      child: Text(
        ready
            ? (group.isAllServed ? 'Siap Bayar' : 'Siap Saji')
            : 'Disiapkan',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ready ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }

  Widget _buildCollapsedSummary(ThemeData theme, OrderanAktifGroup group) {
    final ringkasan = group.totalPorsi > 0
        ? '${group.items.length} menu • ${group.totalServed}/${group.totalPorsi} disajikan'
        : '${group.items.length} menu';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              ringkasan,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRupiah(group.totalHarga),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, OrderanAktifGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // List Items
        ...group.items.map((item) {
          final isItemComplete = item.servedQty >= item.jumlah;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Text: Qty x Nama Item
                Expanded(
                  child: Text(
                    '${item.jumlah}x ${item.namaItem}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                // Edit Icon
                if (widget.onEditItem != null)
                  InkWell(
                    onTap: () => widget.onEditItem!(item),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),

                // Minimalist Stepper Pill (- served / total +)
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus Button
                      InkWell(
                        onTap: item.servedQty > 0 &&
                                widget.onDecrementServed != null
                            ? () => widget.onDecrementServed!(item)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: item.servedQty > 0
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Ratio text: served / total
                      Text(
                        '${item.servedQty} / ${item.jumlah}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isItemComplete
                              ? const Color(0xFF2E7D32)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Plus Button
                      InkWell(
                        onTap: item.servedQty < item.jumlah &&
                                widget.onIncrementServed != null
                            ? () => widget.onIncrementServed!(item)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: item.servedQty < item.jumlah
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const Divider(height: 18),

        // Row 1: Total Price & Secondary Actions (Print Dapur & + Item).
        // Wrap dipakai agar tombol turun ke baris berikutnya pada layar sempit
        // atau saat ukuran font sistem diperbesar, bukan terpotong overflow.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Total: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: _formatRupiah(group.totalHarga),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _accentGreen,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Print Dapur
                InkWell(
                  onTap: widget.onPrintDapur,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Print Dapur',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _accentGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // + Item
                InkWell(
                  onTap: widget.onAddItem,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      '+ Item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.onAddItem != null
                            ? _accentGreen
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Main Action Button (Bayar & Cetak)
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: group.isReady ? widget.onPayAndPrint : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.38),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Bayar & Cetak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
