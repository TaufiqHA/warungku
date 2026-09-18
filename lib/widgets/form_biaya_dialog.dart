import 'package:flutter/material.dart';
import '../core/utils/tanggal_formatter.dart';
import '../data/models/expense_model.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Data hasil formulir biaya operasional sebelum dikirim ke API.
class BiayaFormResult {
  final String kategori;
  final String keterangan;
  final double jumlah;
  final String tanggal;

  const BiayaFormResult({
    required this.kategori,
    required this.keterangan,
    required this.jumlah,
    required this.tanggal,
  });
}

/// Formulir tambah / edit biaya operasional.
///
/// Stateless terhadap API: dialog hanya mengembalikan [BiayaFormResult],
/// pemanggil (tab Biaya Operasional) yang mengeksekusi service & snackbar.
class FormBiayaDialog extends StatefulWidget {
  static const List<String> kategoriOptions = [
    'Bahan Baku',
    'Biaya Operasional',
    'Biaya dll',
  ];

  final ExpenseModel? initial;
  final String pembuat;

  const FormBiayaDialog({
    super.key,
    this.initial,
    required this.pembuat,
  });

  static Future<BiayaFormResult?> show({
    required BuildContext context,
    ExpenseModel? initial,
    required String pembuat,
  }) {
    return showDialog<BiayaFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (_) => FormBiayaDialog(initial: initial, pembuat: pembuat),
    );
  }

  @override
  State<FormBiayaDialog> createState() => _FormBiayaDialogState();
}

class _FormBiayaDialogState extends State<FormBiayaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keteranganController;
  late final TextEditingController _jumlahController;
  late final TextEditingController _tanggalController;
  late final TextEditingController _pembuatController;

  late String _kategori;
  late DateTime _tanggal;
  late List<String> _kategoriTersedia;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _keteranganController = TextEditingController(text: initial?.keterangan ?? '');
    _jumlahController = TextEditingController(
      text: initial != null ? initial.jumlah.toInt().toString() : '',
    );
    _tanggal = TanggalFormatter.parse(initial?.tanggal) ?? DateTime.now();
    _tanggalController = TextEditingController(text: TanggalFormatter.singkat(_tanggal));
    _pembuatController = TextEditingController(text: widget.pembuat);

    _kategoriTersedia = [...FormBiayaDialog.kategoriOptions];
    final kategoriAwal = initial?.kategori.trim();
    _kategori = (kategoriAwal != null && kategoriAwal.isNotEmpty)
        ? kategoriAwal
        : FormBiayaDialog.kategoriOptions.first;
    if (!_kategoriTersedia.any((k) => k.toLowerCase() == _kategori.toLowerCase())) {
      _kategoriTersedia.add(_kategori);
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _jumlahController.dispose();
    _tanggalController.dispose();
    _pembuatController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      setState(() {
        _tanggal = picked;
        _tanggalController.text = TanggalFormatter.singkat(picked);
      });
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      BiayaFormResult(
        kategori: _kategori,
        keterangan: _keteranganController.text.trim(),
        jumlah: double.parse(_jumlahController.text.trim().replaceAll('.', '')),
        tanggal: TanggalFormatter.singkat(_tanggal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Text(
        _isEdit ? 'Ubah Biaya' : 'Tambah Biaya',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _kategoriTersedia.map((k) {
                    return ChoiceChip(
                      label: Text(k),
                      selected: _kategori == k,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _kategori = k);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Keterangan',
                  controller: _keteranganController,
                  hintText: 'Contoh: Beli beras 25kg',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Keterangan wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Jumlah (Rp)',
                  controller: _jumlahController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final raw = (v ?? '').trim().replaceAll('.', '');
                    if (raw.isEmpty) return 'Jumlah wajib diisi';
                    final nominal = double.tryParse(raw);
                    if (nominal == null) return 'Harus berupa angka';
                    if (nominal <= 0) return 'Jumlah harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Tanggal',
                  controller: _tanggalController,
                  readOnly: true,
                  onTap: _pickTanggal,
                  suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Pembuat',
                  controller: _pembuatController,
                  enabled: false,
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                text: _isEdit ? 'Perbarui Biaya' : 'Simpan Biaya',
                height: 38,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
