import 'package:flutter/material.dart';
import '../../data/models/auth_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/token_manager.dart';
import '../../services/transaction_service.dart';
import '../../widgets/app_autocomplete_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/kitchen_receipt_dialog.dart';

class TransaksiPenjualanScreen extends StatefulWidget {
  final UserModel? testUser;

  const TransaksiPenjualanScreen({
    super.key,
    this.testUser,
  });

  @override
  State<TransaksiPenjualanScreen> createState() => _TransaksiPenjualanScreenState();
}

class _TransaksiPenjualanScreenState extends State<TransaksiPenjualanScreen> {
  final _productService = ProductService();
  final _transactionService = TransactionService();

  final _customerController = TextEditingController();
  final _productController = TextEditingController();
  final _productFocusNode = FocusNode();
  final _qtyController = TextEditingController(text: '1');
  final _hargaController = TextEditingController();

  UserModel? _currentUser;
  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  final List<CartItemModel> _cartItems = [];

  bool _isLoadingProducts = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _productController.dispose();
    _productFocusNode.dispose();
    _qtyController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final user = widget.testUser ?? await TokenManager.getUser();
    try {
      final list = await _productService.getProducts();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _products = list;
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingProducts = false;
        });
      }
    }
  }

  double get _totalHarga {
    return _cartItems.fold<double>(0.0, (sum, item) => sum + item.subtotal);
  }

  String _formatRupiah(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  void _onProductSelected(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _productController.text = product.name;
        _hargaController.text = _formatRupiah(product.price);
      } else {
        _hargaController.clear();
      }
    });
  }

  void _addToCart() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih barang terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuantitas (Qty) minimal 1'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == _selectedProduct!.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += qty;
      } else {
        _cartItems.add(
          CartItemModel(
            product: _selectedProduct!,
            quantity: qty,
            unitPrice: _selectedProduct!.price,
          ),
        );
      }

      // Reset product & form
      _selectedProduct = null;
      _productController.clear();
      _qtyController.text = '1';
      _hargaController.clear();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateCartQty(int index, int delta) {
    setState(() {
      final newQty = _cartItems[index].quantity + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQty;
      }
    });
  }

  Future<void> _submitOrder() async {
    final customerName = _customerController.text.trim();
    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Nama Pelanggan / No. Meja'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja masih kosong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final trxId = await _transactionService.createOrder(
        customerName: customerName,
        items: _cartItems,
        orderStatus: 'PENDING',
        paymentMethod: 'CASH',
      );

      if (!mounted) return;

      // Show receipt preview dialog for kitchen order
      await KitchenReceiptDialog.showFromCart(
        context: context,
        transactionId: trxId,
        customerName: customerName,
        cartItems: _cartItems,
        autoPrint: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser?.role.toUpperCase() == 'OWNER') {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Transaksi Penjualan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body: Center(
          child: AppCard(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.block_rounded, size: 32, color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
                Text(
                  'Akses Ditolak',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Owner tidak dapat menambahkan transaksi. Pembuatan transaksi hanya dapat dilakukan oleh kasir (Admin Toko).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Kembali',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasItems = _cartItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transaksi Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Card Buat Pesanan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buat Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Input Nama Pelanggan / No. Meja
                        AppTextField(
                          label: 'Nama Pelanggan / No. Meja',
                          showLabelAbove: false,
                          hintText: 'Nama Pelanggan / No. Meja',
                          controller: _customerController,
                        ),
                        const SizedBox(height: 12),

                        // Input Nama Barang (Pencarian Autocomplete)
                        AppAutocompleteField<ProductModel>(
                          controller: _productController,
                          focusNode: _productFocusNode,
                          hintText: _isLoadingProducts ? 'Memuat barang...' : 'Nama Barang',
                          enabled: !_isLoadingProducts,
                          minChars: 2,
                          displayStringForOption: (p) => p.name,
                          optionsFilter: (query) {
                            final lowerQuery = query.toLowerCase();
                            return _products.where((p) => p.name.toLowerCase().contains(lowerQuery));
                          },
                          onSelected: (product) {
                            _onProductSelected(product);
                          },
                          onClear: () {
                            _onProductSelected(null);
                          },
                          optionItemBuilder: (context, product) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatRupiah(product.price),
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Row: Qty & Harga
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Qty',
                                showLabelAbove: false,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Harga',
                                showLabelAbove: false,
                                hintText: 'Harga',
                                controller: _hargaController,
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Tombol + Tambah ke Keranjang
                        AppButton(
                          text: '+ Tambah ke Keranjang',
                          height: 44,
                          backgroundColor: const Color(0xFF7CB342),
                          foregroundColor: Colors.white,
                          onPressed: _addToCart,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Keranjang Belanja
                  const Text(
                    'Keranjang Belanja',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!hasItems)
                    const SizedBox(height: 30)
                  else
                    ..._cartItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatRupiah(item.unitPrice)} x ${item.quantity} = ${_formatRupiah(item.subtotal)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _updateCartQty(index, -1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _updateCartQty(index, 1),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 22, color: theme.colorScheme.error),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            // Sticky Bottom Footer
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatRupiah(_totalHarga),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Buat Pesanan & Cetak Dapur',
                    icon: const Icon(Icons.print_outlined, size: 20),
                    height: 48,
                    isLoading: _isSubmitting,
                    backgroundColor: hasItems ? theme.colorScheme.primary : const Color(0xFFE0E0E0),
                    foregroundColor: hasItems ? theme.colorScheme.onPrimary : const Color(0xFF9E9E9E),
                    onPressed: hasItems ? _submitOrder : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
