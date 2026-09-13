import 'package:flutter/material.dart';

class PilihMetodePembayaranDialog extends StatefulWidget {
  final double totalPesanan;

  const PilihMetodePembayaranDialog({
    super.key,
    required this.totalPesanan,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required double totalPesanan,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PilihMetodePembayaranDialog(totalPesanan: totalPesanan),
    );
  }

  @override
  State<PilihMetodePembayaranDialog> createState() => _PilihMetodePembayaranDialogState();
}

class _PilihMetodePembayaranDialogState extends State<PilihMetodePembayaranDialog> {
  final _discountController = TextEditingController();
  bool _isPercentDiscount = false;
  String _selectedPaymentMethod = 'Cash';

  final List<String> _paymentMethods = ['Cash', 'QRIS', 'Transfer'];

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  double get _discountValue {
    final text = _discountController.text.trim();
    if (text.isEmpty) return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  double get _calculatedDiscountAmount {
    if (_isPercentDiscount) {
      final percent = _discountValue.clamp(0.0, 100.0);
      return (widget.totalPesanan * percent) / 100.0;
    } else {
      return _discountValue.clamp(0.0, widget.totalPesanan);
    }
  }

  double get _totalTagihan {
    final finalAmount = widget.totalPesanan - _calculatedDiscountAmount;
    return finalAmount < 0 ? 0.0 : finalAmount;
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
    const selectedPurple = Color(0xFFEDEBF7);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Pilih Metode Pembayaran',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 14),

            // Total Pesanan
            Text(
              'Total Pesanan: ${_formatRupiah(widget.totalPesanan)}',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            // Discount Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _isPercentDiscount ? 'Diskon (%)' : 'Diskon (Rp)',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Toggle %
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPercentDiscount = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isPercentDiscount ? selectedPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isPercentDiscount
                            ? selectedPurple
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isPercentDiscount
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Toggle Rp
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPercentDiscount = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: !_isPercentDiscount ? selectedPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isPercentDiscount
                            ? selectedPurple
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: !_isPercentDiscount
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Total Tagihan
            Text(
              'Total Tagihan: ${_formatRupiah(_totalTagihan)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            // Label Metode Pembayaran
            Text(
              'Metode Pembayaran:',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),

            // Payment Methods Chips
            Row(
              children: _paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPaymentMethod = method),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? selectedPurple
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Text(
                        method,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Footer Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: accentGreen,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'paymentMethod': _selectedPaymentMethod,
                          'discountAmount': _calculatedDiscountAmount,
                          'finalTotal': _totalTagihan,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Konfirmasi Bayar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
