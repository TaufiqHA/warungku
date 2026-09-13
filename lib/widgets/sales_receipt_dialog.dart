import 'package:flutter/material.dart';
import '../data/models/transaction_model.dart';
import '../services/thermal_printer_service.dart';
import 'orderan_aktif_card.dart';

class SalesReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  const SalesReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });
}

class SalesReceiptDialog extends StatefulWidget {
  final String transactionId;
  final String storeName;
  final String dateTimeStr;
  final String customerName;
  final String cashierName;
  final List<SalesReceiptItem> items;
  final double subtotal;
  final double discountAmount;
  final String paymentMethod;
  final String confirmButtonText;
  final bool autoPrint;
  final VoidCallback? onPrint;

  const SalesReceiptDialog({
    super.key,
    required this.transactionId,
    this.storeName = 'WARUNGKU',
    required this.dateTimeStr,
    required this.customerName,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.paymentMethod,
    this.confirmButtonText = 'Cetak',
    this.autoPrint = false,
    this.onPrint,
  });

  double get grandTotal => (subtotal - discountAmount).clamp(0.0, double.infinity);

  factory SalesReceiptDialog.fromTransaction({
    Key? key,
    required TransactionModel trx,
    String confirmButtonText = 'Cetak',
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    return SalesReceiptDialog(
      key: key,
      transactionId: trx.idTransaksi,
      dateTimeStr: _formatDate(trx.waktu),
      customerName: trx.customerName.isNotEmpty && trx.customerName != '-'
          ? trx.customerName
          : 'Pelanggan',
      cashierName: trx.dicatatOleh.isNotEmpty ? trx.dicatatOleh : 'Kasir',
      items: [
        SalesReceiptItem(
          name: trx.namaItem,
          quantity: trx.jumlah,
          price: trx.harga,
          subtotal: trx.totalHarga,
        ),
      ],
      subtotal: trx.totalHarga,
      discountAmount: 0.0,
      paymentMethod: trx.paymentMethod.isNotEmpty ? trx.paymentMethod : 'Cash',
      confirmButtonText: confirmButtonText,
      autoPrint: autoPrint,
      onPrint: onPrint,
    );
  }

  factory SalesReceiptDialog.fromTransactionList({
    Key? key,
    required List<TransactionModel> items,
    String? paymentMethod,
    double discountAmount = 0.0,
    String confirmButtonText = 'Cetak',
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('Transaction items cannot be empty');
    }
    final first = items.first;
    final receiptItems = items
        .map(
          (t) => SalesReceiptItem(
            name: t.namaItem,
            quantity: t.jumlah,
            price: t.harga,
            subtotal: t.totalHarga,
          ),
        )
        .toList();
    final subtotal = items.fold<double>(0.0, (sum, t) => sum + t.totalHarga);
    final method = paymentMethod ?? (first.paymentMethod.isNotEmpty ? first.paymentMethod : 'Cash');
    final customer =
        first.customerName.isNotEmpty && first.customerName != '-' ? first.customerName : 'Pelanggan';
    final cashier = first.dicatatOleh.isNotEmpty ? first.dicatatOleh : 'Kasir';

    return SalesReceiptDialog(
      key: key,
      transactionId: first.idTransaksi,
      dateTimeStr: _formatDate(first.waktu),
      customerName: customer,
      cashierName: cashier,
      items: receiptItems,
      subtotal: subtotal,
      discountAmount: discountAmount,
      paymentMethod: method,
      confirmButtonText: confirmButtonText,
      autoPrint: autoPrint,
      onPrint: onPrint,
    );
  }

  factory SalesReceiptDialog.fromOrderGroup({
    Key? key,
    required OrderanAktifGroup group,
    required String paymentMethod,
    double discountAmount = 0.0,
    String confirmButtonText = 'Cetak',
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    final items = group.items
        .map(
          (t) => SalesReceiptItem(
            name: t.namaItem,
            quantity: t.jumlah,
            price: t.harga,
            subtotal: t.totalHarga,
          ),
        )
        .toList();

    final cashier = group.items.isNotEmpty && group.items.first.dicatatOleh.isNotEmpty
        ? group.items.first.dicatatOleh
        : 'Kasir';

    return SalesReceiptDialog(
      key: key,
      transactionId: group.transactionId,
      dateTimeStr: _formatDate(group.waktu),
      customerName: group.customerName.isNotEmpty && group.customerName != '-'
          ? group.customerName
          : 'Pelanggan',
      cashierName: cashier,
      items: items,
      subtotal: group.totalHarga,
      discountAmount: discountAmount,
      paymentMethod: paymentMethod.isNotEmpty ? paymentMethod : 'Cash',
      confirmButtonText: confirmButtonText,
      autoPrint: autoPrint,
      onPrint: onPrint,
    );
  }

  static Future<void> showFromTransaction({
    required BuildContext context,
    required TransactionModel trx,
    String confirmButtonText = 'Cetak',
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SalesReceiptDialog.fromTransaction(
        trx: trx,
        confirmButtonText: confirmButtonText,
        autoPrint: autoPrint,
        onPrint: onPrint,
      ),
    );
  }

  static Future<void> showFromTransactionList({
    required BuildContext context,
    required List<TransactionModel> items,
    String? paymentMethod,
    double discountAmount = 0.0,
    String confirmButtonText = 'Cetak',
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SalesReceiptDialog.fromTransactionList(
        items: items,
        paymentMethod: paymentMethod,
        discountAmount: discountAmount,
        confirmButtonText: confirmButtonText,
        autoPrint: autoPrint,
        onPrint: onPrint,
      ),
    );
  }

  static Future<void> showFromOrderGroup({
    required BuildContext context,
    required OrderanAktifGroup group,
    required String paymentMethod,
    double discountAmount = 0.0,
    String confirmButtonText = 'Cetak',
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SalesReceiptDialog.fromOrderGroup(
        group: group,
        paymentMethod: paymentMethod,
        discountAmount: discountAmount,
        confirmButtonText: confirmButtonText,
        autoPrint: autoPrint,
        onPrint: onPrint,
      ),
    );
  }

  static String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateStr = '${now.day}/${now.month}/${now.year}';
      return '$dateStr $timeStr';
    }
  }

  @override
  State<SalesReceiptDialog> createState() => _SalesReceiptDialogState();
}

class _SalesReceiptDialogState extends State<SalesReceiptDialog> {
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerPrint(isAuto: true);
      });
    }
  }

  Future<void> _triggerPrint({bool isAuto = false}) async {
    if (_isPrinting) return;
    widget.onPrint?.call();

    if (mounted) {
      setState(() => _isPrinting = true);
    }

    final result = await ThermalPrinterService.instance.printSalesReceipt(
      storeName: widget.storeName,
      transactionId: widget.transactionId,
      dateTimeStr: widget.dateTimeStr,
      customerName: widget.customerName,
      cashierName: widget.cashierName,
      items: widget.items,
      subtotal: widget.subtotal,
      discountAmount: widget.discountAmount,
      paymentMethod: widget.paymentMethod,
    );

    if (mounted) {
      setState(() => _isPrinting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAuto
                ? (result.success ? 'Struk pembayaran otomatis dicetak' : result.message)
                : result.message,
          ),
          backgroundColor: result.success
              ? const Color(0xFF2E7D32)
              : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentGreen = Color(0xFF7CB342);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: accentGreen, size: 24),
              SizedBox(width: 10),
              Text(
                'Pratinjau Struk',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Tutup',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          minWidth: 320,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kertas Struk
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toko Header
                    Center(
                      child: Text(
                        widget.storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        'STRUK PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Divider(height: 24, thickness: 1),

                    // Info Transaksi
                    _buildMetaRow('No. Transaksi', widget.transactionId, theme),
                    const SizedBox(height: 6),
                    _buildMetaRow('Waktu', widget.dateTimeStr, theme),
                    const SizedBox(height: 6),
                    _buildMetaRow('Kasir', widget.cashierName, theme),
                    if (widget.customerName.isNotEmpty && widget.customerName != '-') ...[
                      const SizedBox(height: 6),
                      _buildMetaRow('Pelanggan', widget.customerName, theme),
                    ],

                    const Divider(height: 24, thickness: 1),

                    // Daftar Item
                    ...widget.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.quantity} x ${_formatRupiah(item.price)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(item.subtotal),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 24, thickness: 1),

                    // Subtotal
                    _buildSummaryRow(
                      'Subtotal',
                      _formatRupiah(widget.subtotal),
                      theme,
                      isBold: false,
                    ),

                    // Diskon jika ada
                    if (widget.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        'Diskon',
                        '- ${_formatRupiah(widget.discountAmount)}',
                        theme,
                        isBold: false,
                        textColor: theme.colorScheme.error,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Total Akhir
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatRupiah(widget.grandTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentGreen,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24, thickness: 1),

                    // Metode Bayar
                    _buildSummaryRow(
                      'Metode Bayar',
                      widget.paymentMethod,
                      theme,
                      isBold: true,
                    ),

                    const SizedBox(height: 16),

                    // Pesan Penutup
                    Center(
                      child: Text(
                        'Terima kasih atas kunjungan Anda',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: _isPrinting ? null : () => _triggerPrint(isAuto: false),
          icon: _isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.print_rounded, size: 18),
          label: Text(_isPrinting ? 'Mencetak...' : widget.confirmButtonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, ThemeData theme) {
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
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? textColor,
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
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
