import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/tanggal_formatter.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/transaction_group_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../services/product_service.dart';
import '../../../services/token_manager.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/kitchen_receipt_dialog.dart';
import '../../../widgets/orderan_aktif_card.dart';
import '../../../widgets/pilih_metode_pembayaran_dialog.dart';
import '../../../widgets/sales_receipt_dialog.dart';
import '../../../widgets/tambah_item_pesanan_dialog.dart';

class BerandaTab extends StatefulWidget {
  final VoidCallback? onGoToPenjualan;
  final VoidCallback? onGoToBarang;
  final VoidCallback? onGoToProfil;
  final VoidCallback? onGoToLabaRugi;
  final VoidCallback? onGoToUserManagement;
  final VoidCallback? onOpenMonthlyReport;
  final VoidCallback? onQuickLogout;

  /// Menandai tab ini sedang terlihat di dashboard. Saat berubah dari `false`
  /// ke `true`, Orderan Aktif disegarkan ulang agar bill yang sudah dilunasi
  /// di sesi/perangkat lain tidak tertinggal di layar.
  final bool isActive;

  /// Service opsional untuk injeksi pada pengujian.
  final TransactionService? transactionService;
  final ProductService? productService;

  const BerandaTab({
    super.key,
    this.onGoToPenjualan,
    this.onGoToBarang,
    this.onGoToProfil,
    this.onGoToLabaRugi,
    this.onGoToUserManagement,
    this.onOpenMonthlyReport,
    this.onQuickLogout,
    this.isActive = true,
    this.transactionService,
    this.productService,
  });

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> with WidgetsBindingObserver {
  late final TransactionService _transactionService;
  late final ProductService _productService;

  Timer? _pollingTimer;

  UserModel? _currentUser;
  List<OrderanAktifGroup> _activeOrders = [];
  List<ProductModel> _allProducts = [];
  int _totalProducts = 0;
  double _todayOmzet = 0;
  int _todayTrxCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transactionService = widget.transactionService ?? TransactionService();
    _productService = widget.productService ?? ProductService();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BerandaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kembali ke tab Beranda: samakan lagi dengan status terbaru di server.
    if (widget.isActive && !oldWidget.isActive) {
      _refreshTransactionsSilently();
      _startPolling();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopPolling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Aplikasi kembali ke depan: bill bisa saja dilunasi dari perangkat lain.
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refreshTransactionsSilently();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling();
    if (!widget.isActive) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && widget.isActive) {
        _refreshTransactionsSilently();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final user = await TokenManager.getUser();
      final rawTransactions = await _transactionService.getTransactions(
        filter: 'Hari Ini',
        forceRefresh: forceRefresh,
      ).catchError((_) => <TransactionModel>[]);
      final products = await _productService.getProducts(
        forceRefresh: forceRefresh,
      ).catchError((_) => <ProductModel>[]);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _allProducts = products;
          _totalProducts = products.length;
          _isLoading = false;
          _applyTransactionSummary(rawTransactions);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Menyegarkan Orderan Aktif secara senyap (tanpa spinner penuh) dan tanpa
  /// menyentuh daftar produk. Dipakai saat tab kembali aktif atau aplikasi
  /// kembali ke depan; unduhan dipaksa agar perubahan status dari perangkat
  /// lain langsung terlihat.
  Future<void> _refreshTransactionsSilently() async {
    try {
      final rawTransactions = await _transactionService.getTransactions(
        filter: 'Hari Ini',
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _applyTransactionSummary(rawTransactions));
    } catch (_) {
      // Pertahankan data lama bila penyegaran senyap gagal.
    }
  }

  /// Menghitung ulang Orderan Aktif dan metrik hari ini dari daftar transaksi
  /// mentah. Wajib dipanggil di dalam `setState`.
  void _applyTransactionSummary(List<TransactionModel> rawTransactions) {
    _activeOrders = _buildActiveGroups(rawTransactions);

    final completedGroups = _completedTodayGroups(rawTransactions);
    _todayOmzet = completedGroups.fold(0.0, (acc, g) => acc + g.totalHarga);
    _todayTrxCount = completedGroups.length;
  }

  /// Kelompokkan transaksi aktif (selain COMPLETED dan CANCELLED) per idTransaksi.
  List<OrderanAktifGroup> _buildActiveGroups(
    List<TransactionModel> rawTransactions,
  ) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final item in rawTransactions.where((t) => t.isActiveOrder)) {
      grouped.putIfAbsent(item.idTransaksi, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final first = entry.value.first;
      final orderStatus = entry.value
          .map((e) => e.orderStatus)
          .firstWhere((s) => s.isNotEmpty, orElse: () => first.orderStatus);

      return OrderanAktifGroup(
        transactionId: entry.key,
        customerName: first.customerName,
        waktu: first.waktu,
        orderStatus: orderStatus,
        items: entry.value,
      );
    }).toList();
  }

  /// Kelompokkan transaksi selesai hari ini per idTransaksi (bill riil).
  List<TransactionGroup> _completedTodayGroups(
    List<TransactionModel> rawTransactions,
  ) {
    return TransactionGroup.fromTransactionList(rawTransactions)
        .where((g) => g.isCompleted && TanggalFormatter.isToday(g.waktu))
        .toList();
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

  String _formatTodayDate() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _handleIncrementServed(TransactionModel item, OrderanAktifGroup group) async {
    if (item.servedQty >= item.jumlah) return;
    try {
      final newQty = item.servedQty + 1;
      await _transactionService.updateServedQty(group.transactionId, item.id, newQty);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDecrementServed(TransactionModel item, OrderanAktifGroup group) async {
    if (item.servedQty <= 0) return;
    try {
      final newQty = item.servedQty - 1;
      await _transactionService.updateServedQty(group.transactionId, item.id, newQty);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAddItem(OrderanAktifGroup group) async {
    final result = await TambahItemPesananDialog.show(
      context: context,
      customerName: group.customerName,
      products: _allProducts,
    );

    if (result != null && mounted) {
      final ProductModel product = result['product'];
      final int qty = result['quantity'];
      try {
        await _transactionService.addTransactionItem(
          group.transactionId,
          productId: product.id,
          quantity: qty,
          unitPrice: product.price,
          subtotal: product.price * qty,
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} (x$qty) berhasil ditambahkan'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePayAndPrint(OrderanAktifGroup group) async {
    if (!group.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan belum siap bayar (makanan/minuman masih disiapkan)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await PilihMetodePembayaranDialog.show(
      context: context,
      totalPesanan: group.totalHarga,
    );

    if (result != null && mounted) {
      final String paymentMethod = result['paymentMethod'] ?? 'Cash';
      final double discountAmount = result['discountAmount'] ?? 0.0;

      try {
        await _transactionService.completeTransaction(
          group.transactionId,
          paymentMethod: paymentMethod,
          discountAmount: discountAmount,
        );

        if (!mounted) return;

        // Optimistis: bill yang baru dilunasi langsung hilang dari Orderan
        // Aktif, lalu disinkronkan ulang dengan data server.
        setState(() {
          _activeOrders = _activeOrders
              .where((g) => g.transactionId != group.transactionId)
              .toList();
        });
        await _loadData(forceRefresh: true);

        if (mounted) {
          await SalesReceiptDialog.showFromOrderGroup(
            context: context,
            group: group,
            paymentMethod: paymentMethod,
            discountAmount: discountAmount,
            confirmButtonText: 'Cetak',
            autoPrint: false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentGreen = Color(0xFF7CB342);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Kartu Sambutan Pengguna
          AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: theme.colorScheme.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.name.isNotEmpty == true
                            ? _currentUser!.name
                            : 'Admin Toko',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppBadge.role(_currentUser?.role.isNotEmpty == true
                              ? _currentUser!.role
                              : 'ADMIN_TOKO'),
                          const SizedBox(width: 8),
                          Text(
                            _formatTodayDate(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if ((_currentUser?.role == 'OWNER' || widget.onQuickLogout != null) && widget.onQuickLogout != null)
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 20),
                    tooltip: 'Keluar',
                    onPressed: widget.onQuickLogout,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Metrik Finansial
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Omzet Hari Ini',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(_todayOmzet),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaksi',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_todayTrxCount Trx',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu Aktif',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalProducts Menu',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Navigasi Cepat
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: (_currentUser?.role == 'OWNER' || widget.onGoToLabaRugi != null)
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildQuickAction(
                                icon: Icons.analytics_outlined,
                                label: 'Laba Rugi',
                                onTap: widget.onGoToLabaRugi,
                              ),
                              _buildQuickAction(
                                icon: Icons.receipt_long_rounded,
                                label: 'Penjualan',
                                onTap: widget.onGoToPenjualan,
                              ),
                              _buildQuickAction(
                                icon: Icons.calendar_month_outlined,
                                label: 'Lap. Bulanan',
                                onTap: widget.onOpenMonthlyReport,
                              ),
                              _buildQuickAction(
                                icon: Icons.manage_accounts_outlined,
                                label: 'Pengguna',
                                onTap: widget.onGoToUserManagement,
                              ),
                              _buildQuickAction(
                                icon: Icons.account_circle_outlined,
                                label: 'Profil',
                                onTap: widget.onGoToProfil,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Penjualan',
                          onTap: widget.onGoToPenjualan,
                        ),
                      ),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'Barang',
                          onTap: widget.onGoToBarang,
                        ),
                      ),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.account_circle_outlined,
                          label: 'Profil',
                          onTap: widget.onGoToProfil,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // 4. ORDERAN AKTIF (OPEN BILL) - Pengganti Transaksi Selesai Terkini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Orderan Aktif',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_activeOrders.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                tooltip: 'Refresh',
                onPressed: () => _loadData(forceRefresh: true),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Render List Orderan Aktif
          if (_activeOrders.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tidak ada orderan aktif saat ini',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._activeOrders.map((group) {
              return OrderanAktifCard(
                key: ValueKey('orderan-aktif-${group.transactionId}'),
                group: group,
                onIncrementServed: (item) => _handleIncrementServed(item, group),
                onDecrementServed: (item) => _handleDecrementServed(item, group),
                onPrintDapur: () => KitchenReceiptDialog.show(
                  context: context,
                  group: group,
                  autoPrint: false,
                ),
                onAddItem: _currentUser?.role == 'OWNER' ? null : () => _handleAddItem(group),
                // Pelunasan hanya diizinkan API untuk ADMIN_TOKO; tombol
                // dimatikan untuk OWNER agar tidak berujung galat 403.
                onPayAndPrint:
                    _currentUser?.role == 'OWNER' ? null : () => _handlePayAndPrint(group),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
