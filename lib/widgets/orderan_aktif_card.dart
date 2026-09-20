import 'package:flutter/material.dart';
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
  bool get isAllServed => items.isNotEmpty && items.every((item) => item.servedQty >= item.jumlah);
  bool get isReady =>
      orderStatus.trim().toUpperCase() == 'READY' ||
      orderStatus.trim().toUpperCase() == 'SIAP' ||
      isAllServed;
}

class OrderanAktifCard extends StatelessWidget {
  final OrderanAktifGroup group;
  final ValueChanged<TransactionModel>? onIncrementServed;
  final ValueChanged<TransactionModel>? onDecrementServed;
  final ValueChanged<TransactionModel>? onEditItem;
  final VoidCallback? onPrintDapur;
  final VoidCallback? onAddItem;
  final VoidCallback? onPayAndPrint;

  const OrderanAktifCard({
    super.key,
    required this.group,
    this.onIncrementServed,
    this.onDecrementServed,
    this.onEditItem,
    this.onPrintDapur,
    this.onAddItem,
    this.onPayAndPrint,
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
    const accentGreen = Color(0xFF7CB342);

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
          // Header Customer / Meja & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.customerName.isNotEmpty && group.customerName != '-'
                      ? group.customerName
                      : 'Pesanan #${group.transactionId.length > 8 ? group.transactionId.substring(group.transactionId.length - 8) : group.transactionId}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (group.isReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                  ),
                  child: Text(
                    group.isAllServed ? 'Siap Bayar' : 'Siap Saji',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCC80), width: 0.8),
                  ),
                  child: const Text(
                    'Disiapkan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),
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
                  if (onEditItem != null)
                    InkWell(
                      onTap: () => onEditItem!(item),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),

                  // Minimalist Stepper Pill (- served / total +)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Minus Button
                        InkWell(
                          onTap: item.servedQty > 0 && onDecrementServed != null
                              ? () => onDecrementServed!(item)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.remove,
                              size: 14,
                              color: item.servedQty > 0
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.25),
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
                          onTap: item.servedQty < item.jumlah && onIncrementServed != null
                              ? () => onIncrementServed!(item)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: item.servedQty < item.jumlah
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.25),
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

          // Row 1: Total Price & Secondary Actions (Print Dapur & + Item)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        color: accentGreen,
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
                    onTap: onPrintDapur,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        'Print Dapur',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // + Item
                  InkWell(
                    onTap: onAddItem,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        '+ Item',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: onAddItem != null
                              ? accentGreen
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
              onPressed: group.isReady ? onPayAndPrint : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
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
      ),
    );
  }
}
