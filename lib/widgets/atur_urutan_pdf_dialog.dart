import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../services/menu_catalog_pdf_service.dart';
import '../services/product_service.dart';
import 'app_text_field.dart';

class AturUrutanPdfDialog extends StatefulWidget {
  final VoidCallback? onLayoutSaved;
  final List<ProductModel>? initialProducts;

  const AturUrutanPdfDialog({
    super.key,
    this.onLayoutSaved,
    this.initialProducts,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onLayoutSaved,
    List<ProductModel>? initialProducts,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AturUrutanPdfDialog(
        onLayoutSaved: onLayoutSaved,
        initialProducts: initialProducts,
      ),
    );
  }

  @override
  State<AturUrutanPdfDialog> createState() => _AturUrutanPdfDialogState();
}

class _AturUrutanPdfDialogState extends State<AturUrutanPdfDialog> {
  final _productService = ProductService();

  bool _isLoading = true;
  bool _isSaving = false;

  // List kategori (urutan)
  List<String> _categoryOrder = [];

  // Peta nama kategori khusus (jika diedit/di-rename) -> originalCat: newName
  final Map<String, String> _categoryDisplayNames = {};

  // Peta kategori -> list produk di dalamnya
  final Map<String, List<ProductModel>> _productsByCategory = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ambil produk (dari widget atau API)
      List<ProductModel> products = widget.initialProducts ?? [];
      if (products.isEmpty) {
        products = await _productService.getProducts();
      }

      // 2. Ambil konfigurasi layout lokal jika ada
      final localConfig = await _productService.loadLocalLayoutConfig();
      final savedCatOrder = (localConfig['categoryOrder'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final savedCatNames = (localConfig['categoryNames'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {};
      final savedProdOrder = (localConfig['productOrderPerCategory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e.toString()).toList()),
          ) ??
          {};

      // 3. Kelompokkan produk berdasarkan kategori aslinya
      final grouped = <String, List<ProductModel>>{};
      for (final p in products) {
        final cat = p.category.isNotEmpty ? p.category : 'Lainnya';
        grouped.putIfAbsent(cat, () => []).add(p);
      }

      // 4. Susun urutan kategori
      final orderedCategories = <String>[];
      // Masukkan yang ada di savedCatOrder jika masih ada di grouped
      for (final cat in savedCatOrder) {
        if (grouped.containsKey(cat) && !orderedCategories.contains(cat)) {
          orderedCategories.add(cat);
        }
      }
      // Masukkan sisanya yang belum terdaftar
      for (final cat in grouped.keys) {
        if (!orderedCategories.contains(cat)) {
          orderedCategories.add(cat);
        }
      }

      // 5. Susun urutan produk dalam masing-masing kategori
      for (final cat in orderedCategories) {
        final list = grouped[cat] ?? [];
        final savedIds = savedProdOrder[cat] ?? [];

        if (savedIds.isNotEmpty) {
          list.sort((a, b) {
            final idxA = savedIds.indexOf(a.id);
            final idxB = savedIds.indexOf(b.id);
            if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
            if (idxA != -1) return -1;
            if (idxB != -1) return 1;
            return 0;
          });
        }
        _productsByCategory[cat] = list;
      }

      _categoryOrder = orderedCategories;
      _categoryDisplayNames.addAll(savedCatNames);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _moveCategory(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _categoryOrder.length) return;

    setState(() {
      final cat = _categoryOrder.removeAt(index);
      _categoryOrder.insert(newIndex, cat);
    });
  }

  void _moveItem(String category, int index, int delta) {
    final list = _productsByCategory[category];
    if (list == null) return;

    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= list.length) return;

    setState(() {
      final item = list.removeAt(index);
      list.insert(newIndex, item);
    });
  }

  Future<void> _editCategoryName(String category) async {
    final currentName = _categoryDisplayNames[category] ?? category;
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Nama Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: 'Nama Kategori',
            controller: controller,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Nama kategori tidak boleh kosong';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84BD3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _categoryDisplayNames[category] = result;
      });
    }
  }

  List<CategoryMenuData> _buildCategoryMenuData() {
    final data = <CategoryMenuData>[];
    for (final cat in _categoryOrder) {
      final displayName = _categoryDisplayNames[cat] ?? cat;
      final products = _productsByCategory[cat] ?? [];
      data.add(CategoryMenuData(
        categoryName: displayName,
        products: List.unmodifiable(products),
      ));
    }
    return data;
  }

  Future<void> _saveLayout({bool showSnackbar = true}) async {
    setState(() => _isSaving = true);

    try {
      // 1. Simpan ke local storage
      final prodOrderMap = <String, List<String>>{};
      for (final entry in _productsByCategory.entries) {
        prodOrderMap[entry.key] = entry.value.map((p) => p.id).toList();
      }

      await _productService.saveLocalLayoutConfig(
        categoryOrder: _categoryOrder,
        categoryNames: _categoryDisplayNames,
        productOrderPerCategory: prodOrderMap,
      );

      // 2. Simpan ke backend API
      final catPayload = <Map<String, dynamic>>[];
      for (int i = 0; i < _categoryOrder.length; i++) {
        final cat = _categoryOrder[i];
        catPayload.add({
          'name': _categoryDisplayNames[cat] ?? cat,
          'order': i + 1,
        });
      }
      await _productService.saveCategoriesLayout(catPayload);

      final prodPayload = <Map<String, dynamic>>[];
      int pOrder = 1;
      for (final cat in _categoryOrder) {
        for (final p in _productsByCategory[cat] ?? <ProductModel>[]) {
          prodPayload.add({
            'id': p.id,
            'order': pOrder++,
          });
        }
      }
      await _productService.saveProductsLayout(prodPayload);

      widget.onLayoutSaved?.call();

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layout berhasil disimpan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan di perangkat lokal: ${e.toString().replaceFirst('Exception: ', '')}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    await _saveLayout(showSnackbar: false);
    final data = _buildCategoryMenuData();

    if (!mounted) return;
    try {
      await MenuCatalogPdfService.printMenuCatalog(categoryData: data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Modal
              const Text(
                'Atur Urutan & Nama\nKategori PDF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Geser urutan kategori menggunakan tombol panah, atau edit nama kategori dengan tombol edit.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _categoryOrder.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada kategori / produk',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _categoryOrder.length,
                            itemBuilder: (context, catIndex) {
                              final cat = _categoryOrder[catIndex];
                              final displayName = _categoryDisplayNames[cat] ?? cat;
                              final items = _productsByCategory[cat] ?? [];
                              final canMoveUp = catIndex > 0;
                              final canMoveDown = catIndex < _categoryOrder.length - 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F5FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category Header Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF222222),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () => _editCategoryName(cat),
                                                borderRadius: BorderRadius.circular(16),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons.edit,
                                                    size: 18,
                                                    color: Color(0xFF1976D2),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.keyboard_arrow_up),
                                          iconSize: 22,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          color: canMoveUp ? Colors.grey[700] : Colors.grey[350],
                                          onPressed: canMoveUp ? () => _moveCategory(catIndex, -1) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.keyboard_arrow_down),
                                          iconSize: 22,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          color: canMoveDown ? Colors.grey[700] : Colors.grey[350],
                                          onPressed: canMoveDown ? () => _moveCategory(catIndex, 1) : null,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Item List Under Category
                                    ...items.asMap().entries.map((entry) {
                                      final itemIndex = entry.key;
                                      final item = entry.value;
                                      final itemCanUp = itemIndex > 0;
                                      final itemCanDown = itemIndex < items.length - 1;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_up),
                                              iconSize: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              color: itemCanUp ? Colors.grey[600] : Colors.grey[350],
                                              onPressed: itemCanUp ? () => _moveItem(cat, itemIndex, -1) : null,
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_down),
                                              iconSize: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              color: itemCanDown ? Colors.grey[600] : Colors.grey[350],
                                              onPressed: itemCanDown ? () => _moveItem(cat, itemIndex, 1) : null,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 16),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _saveLayout(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF84BD3A), width: 1.5),
                        foregroundColor: const Color(0xFF84BD3A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF84BD3A)),
                            )
                          : const Text(
                              'Simpan Layout',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _exportPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84BD3A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Export PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF84BD3A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
