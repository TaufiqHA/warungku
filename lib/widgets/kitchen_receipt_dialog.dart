import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/transaction_model.dart';
import '../services/thermal_printer_service.dart';
import 'orderan_aktif_card.dart';

class KitchenReceiptDialog extends StatefulWidget {
  final OrderanAktifGroup group;
  final bool autoPrint;
  final VoidCallback? onPrint;

  const KitchenReceiptDialog({
    super.key,
    required this.group,
    this.autoPrint = false,
    this.onPrint,
  });

  static Future<void> show({
    required BuildContext context,
    required OrderanAktifGroup group,
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => KitchenReceiptDialog(
        group: group,
        autoPrint: autoPrint,
        onPrint: onPrint,
      ),
    );
  }

  static Future<void> showFromCart({
    required BuildContext context,
    required String transactionId,
    required String customerName,
    required List<CartItemModel> cartItems,
    bool autoPrint = false,
    VoidCallback? onPrint,
  }) {
    final now = DateTime.now().toIso8601String();
    final group = OrderanAktifGroup(
      transactionId: transactionId,
      customerName: customerName,
      waktu: now,
      items: cartItems
          .map(
            (c) => TransactionModel(
              idTransaksi: transactionId,
              id: c.product.id,
              namaItem: c.product.name,
              jumlah: c.quantity,
              harga: c.product.price,
              waktu: now,
              dicatatOleh: 'Kasir',
              catatan: c.notes,
              paymentMethod: 'CASH',
              orderStatus: 'PENDING',
              customerName: customerName,
            ),
          )
          .toList(),
    );

    return show(
      context: context,
      group: group,
      autoPrint: autoPrint,
      onPrint: onPrint,
    );
  }

  @override
  State<KitchenReceiptDialog> createState() => _KitchenReceiptDialogState();
}

class _KitchenReceiptDialogState extends State<KitchenReceiptDialog> {
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
    widget.onPrint?.call();

    if (mounted) {
      setState(() => _isPrinting = true);
    }

    final result = await ThermalPrinterService.instance.printKitchenReceipt(widget.group);

    if (mounted) {
      setState(() => _isPrinting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAuto
                ? (result.success ? 'Struk dapur otomatis dicetak' : result.message)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Color(0xFF7CB342), size: 24),
              SizedBox(width: 10),
              Text('Struk Dapur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'PESANAN DAPUR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Text(
                      'Meja / Pelanggan: ${widget.group.customerName.isNotEmpty && widget.group.customerName != '-' ? widget.group.customerName : 'Pelanggan'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No. Pesanan: ${widget.group.transactionId}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Waktu: $dateStr $timeStr',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                    const Divider(height: 20),
                    ...widget.group.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.namaItem,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '${item.jumlah}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.catatan.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    ' * ${item.catatan}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),
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
          label: Text(_isPrinting ? 'Mencetak...' : 'Cetak'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7CB342),
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
}
