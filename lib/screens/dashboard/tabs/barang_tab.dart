import 'package:flutter/material.dart';
import '../../../core/utils/angka_ribuan.dart';
import '../../../data/models/product_model.dart';
import '../../../services/product_service.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_text_field.dart';

class BarangTab extends StatefulWidget {
  const BarangTab({super.key});

  @override
  State<BarangTab> createState() => _BarangTabState();
}

class _BarangTabState extends State<BarangTab> {
  final _productService = ProductService();
  final _searchController = TextEditingController();

  List<ProductModel> _products = [];
  final List<String> _customCategories = [];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _productService.getProducts();
      if (mounted) {
        setState(() {
          _products = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _categories {
    final set = <String>{'Semua'};
    for (final p in _products) {
      if (p.category.isNotEmpty) {
        set.add(p.category);
      }
    }
    set.addAll(_customCategories);
    return set.toList();
  }

  List<String> get _availableCategories {
    final set = <String>{};
    for (final p in _products) {
      final c = p.category.trim();
      if (c.isNotEmpty && c.toLowerCase() != 'semua') {
        set.add(c);
      }
    }
    for (final c in _customCategories) {
      final trimmed = c.trim();
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'semua') {
        set.add(trimmed);
      }
    }
    if (set.isEmpty) {
      set.addAll(['Makanan', 'Minuman', 'Lainnya']);
    } else {
      for (final defaultCat in ['Makanan', 'Minuman', 'Lainnya']) {
        if (!set.any((item) => item.toLowerCase() == defaultCat.toLowerCase())) {
          set.add(defaultCat);
        }
      }
    }
    return set.toList();
  }

  List<ProductModel> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((p) {
      final matchesCat = _selectedCategory == 'Semua' || p.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();
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

  void _showAddOrEditDialog({ProductModel? product}) {
    final isEdit = product != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null ? AngkaRibuan.format(product.price) : '',
    );
    final newCategoryController = TextEditingController();
    const newCategoryOption = '_NEW_CATEGORY_';

    final categoriesList = List<String>.from(_availableCategories);
    if (product != null &&
        product.category.trim().isNotEmpty &&
        !categoriesList.any((c) => c.toLowerCase() == product.category.trim().toLowerCase())) {
      categoriesList.add(product.category.trim());
    }

    String selectedCategory = product != null && product.category.trim().isNotEmpty
        ? categoriesList.firstWhere(
            (c) => c.toLowerCase() == product.category.trim().toLowerCase(),
            orElse: () => product.category.trim(),
          )
        : (_selectedCategory != 'Semua' &&
                categoriesList.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase())
            ? categoriesList.firstWhere((c) => c.toLowerCase() == _selectedCategory.toLowerCase())
            : (categoriesList.isNotEmpty ? categoriesList.first : 'Makanan'));

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                isEdit ? 'Ubah Menu' : 'Tambah Menu',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        label: 'Nama Menu',
                        controller: nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Harga (Rp)',
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        hintText: '15.000',
                        inputFormatters: const [RibuanInputFormatter()],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                          final nominal = AngkaRibuan.parse(v);
                          if (nominal == null) return 'Harus berupa angka';
                          if (nominal <= 0) return 'Harga harus lebih dari 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppDropdownField<String>(
                        label: 'Kategori',
                        value: selectedCategory,
                        items: [
                          ...categoriesList.map((cat) => DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat),
                              )),
                          const DropdownMenuItem<String>(
                            value: newCategoryOption,
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 18),
                                SizedBox(width: 6),
                                Text('Tambah Kategori Baru...'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                        validator: (v) => v == null || v.trim().isEmpty ? 'Kategori wajib diisi' : null,
                      ),
                      if (selectedCategory == newCategoryOption) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Nama Kategori Baru',
                          controller: newCategoryController,
                          hintText: 'Misal: Paket Hemat',
                          validator: (v) {
                            if (selectedCategory == newCategoryOption) {
                              if (v == null || v.trim().isEmpty) return 'Kategori baru wajib diisi';
                              if (v.trim().toLowerCase() == 'semua') return 'Nama kategori tidak valid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Batal',
                        isPrimary: false,
                        height: 38,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        text: isEdit ? 'Simpan' : 'Tambah',
                        height: 38,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final price = AngkaRibuan.parse(priceController.text) ?? 0;
                          final finalCategory = selectedCategory == newCategoryOption
                              ? newCategoryController.text.trim()
                              : selectedCategory;
                          Navigator.of(ctx).pop();

                          if (selectedCategory == newCategoryOption &&
                              !_customCategories.any((c) => c.toLowerCase() == finalCategory.toLowerCase())) {
                            setState(() {
                              _customCategories.add(finalCategory);
                            });
                          }

                          try {
                            if (isEdit) {
                              await _productService.updateProduct(
                                id: product.id,
                                name: nameController.text,
                                price: price,
                                category: finalCategory,
                              );
                            } else {
                              await _productService.addProduct(
                                name: nameController.text,
                                price: price,
                                category: finalCategory,
                              );
                            }
                            _loadProducts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Menu berhasil diubah' : 'Menu berhasil ditambahkan'),
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
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  },
);
  }

  void _handleDelete(ProductModel product) async {
    final confirm = await AppDialog.showConfirmation(
      context: context,
      title: 'Hapus Menu',
      message: 'Hapus menu "${product.name}" dari katalog?',
      confirmText: 'Hapus',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(product.id);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu berhasil dihapus'),
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

  Future<void> _showAddOptions() async {
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.restaurant_menu_rounded, color: theme.colorScheme.primary),
                  title: const Text('Tambah Menu', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.of(ctx).pop('menu'),
                ),
                ListTile(
                  leading: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                  title: const Text('Tambah Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.of(ctx).pop('kategori'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'menu') {
      _showAddOrEditDialog();
    } else if (action == 'kategori') {
      _showAddCategoryDialog();
    }
  }

  void _showAddCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final existingCategories = _categories.where((c) => c != 'Semua').toList();

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Tambah Kategori',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Kategori Saat Ini',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (existingCategories.isEmpty)
                    Text(
                      'Belum ada kategori',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: existingCategories.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (context, index) {
                        final category = existingCategories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label_outline_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Nama Kategori Baru',
                    controller: nameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Kategori wajib diisi';
                      if (existingCategories.any((c) => c.toLowerCase() == v.trim().toLowerCase())) {
                        return 'Kategori sudah ada';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    isPrimary: false,
                    height: 38,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Simpan',
                    height: 38,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final categoryName = nameController.text.trim();
                      Navigator.of(ctx).pop();

                      try {
                        await _productService.addCategory(name: categoryName);
                        if (mounted) {
                          setState(() {
                            if (!_customCategories.contains(categoryName)) {
                              _customCategories.add(categoryName);
                            }
                            _selectedCategory = categoryName;
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Kategori berhasil ditambahkan'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Search Bar
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, size: 20),
                  hintText: 'Cari menu...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Kategori
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // List Produk
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (products.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Tidak ada produk di katalog',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...products.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant_menu_rounded,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  AppBadge(
                                    text: p.category,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    textColor: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatRupiah(p.price),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Ubah',
                          onPressed: () => _showAddOrEditDialog(product: p),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                          tooltip: 'Hapus',
                          onPressed: () => _handleDelete(p),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
