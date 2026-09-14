import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/role_guard.dart';
import '../../data/models/auth_model.dart';
import '../../services/excel_export_service.dart';
import '../../services/product_service.dart';
import 'tabs/barang_tab.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/penjualan_tab.dart';
import 'tabs/profil_tab.dart';
import '../../widgets/atur_urutan_pdf_dialog.dart';
import '../../widgets/printer_settings_dialog.dart';

class AdminTokoDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  final UserModel? testUser;

  const AdminTokoDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.testUser,
  });

  @override
  State<AdminTokoDashboardScreen> createState() => _AdminTokoDashboardScreenState();
}

class _AdminTokoDashboardScreenState extends State<AdminTokoDashboardScreen> {
  late int _currentIndex;

  final _productService = ProductService();
  bool _isExportingExcel = false;

  final List<String> _titles = [
    'Beranda Admin Toko',
    'Penjualan',
    'Manajemen Barang',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() => _isExportingExcel = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String detectedExtension = 'xlsx';
      Map<String, dynamic>? result;
      try {
        result = await _productService.exportProducts();
      } catch (_) {
        // Abaikan kegagalan panggilan awal ke server dan lanjut ke fallback jika offline
      }

      final downloadUrl = result?['download_url'] as String?;
      var bytes = result?['bytes'] as Uint8List?;
      var isCsvFallback = false;

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        detectedExtension = ProductService.getExportFileExtension(downloadUrl);
      }

      if ((bytes == null || bytes.isEmpty) && downloadUrl != null && downloadUrl.isNotEmpty) {
        try {
          bytes = await _productService.downloadExportFile(downloadUrl);
        } catch (_) {
          // Fallback jika download langsung dari URL gagal
        }
      }

      // Jika bytes masih kosong (misal server offline atau download gagal), buat fallback data katalog produk
      if (bytes == null || bytes.isEmpty) {
        try {
          final products = await _productService.getProducts();
          final csvBuffer = StringBuffer("sep=,\r\nNo,Nama Produk,Kategori,Harga\n");
          for (int i = 0; i < products.length; i++) {
            final p = products[i];
            csvBuffer.writeln('${i + 1},"${p.name.replaceAll('"', '""')}","${p.category.replaceAll('"', '""')}",${p.price.toInt()}');
          }
          bytes = Uint8List.fromList(utf8.encode(csvBuffer.toString()));
          isCsvFallback = true;
          detectedExtension = 'csv';
        } catch (_) {}
      }

      if (bytes != null && bytes.isNotEmpty) {
        final extension = isCsvFallback ? 'csv' : detectedExtension;
        final openResult = await ExcelExportService.saveAndOpenExcelFile(
          bytes: bytes,
          fileName: 'katalog_produk_${DateTime.now().millisecondsSinceEpoch}.$extension',
        );
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(openResult.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Gagal menyiapkan data ekspor produk'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingExcel = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppRoles.adminToko,
      testUser: widget.testUser,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);

    final tabs = [
      BerandaTab(
        onGoToPenjualan: () => _switchTab(1),
        onGoToBarang: () => _switchTab(2),
        onGoToProfil: () => _switchTab(3),
      ),
      const PenjualanTab(),
      const BarangTab(),
      ProfilTab(
        onLogout: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (_currentIndex == 2) ...[
            IconButton(
              icon: _isExportingExcel
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.table_chart_outlined),
              tooltip: 'Export Excel',
              onPressed: _isExportingExcel ? null : _handleExportExcel,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Cetak Katalog Menu PDF',
              onPressed: () => AturUrutanPdfDialog.show(context),
            ),
          ],
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Pengaturan Printer Thermal',
              onPressed: () => PrinterSettingsDialog.show(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            height: 1,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        elevation: 2,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Penjualan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Barang',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
