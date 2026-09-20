import 'package:flutter/material.dart';

class FilterCustomTanggalResult {
  final DateTime startDate;
  final DateTime endDate;
  final String dataType;

  const FilterCustomTanggalResult({
    required this.startDate,
    required this.endDate,
    required this.dataType,
  });
}

class FilterCustomTanggalDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final String initialDataType;

  const FilterCustomTanggalDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialDataType,
  });

  static Future<FilterCustomTanggalResult?> show({
    required BuildContext context,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? initialDataType,
  }) {
    final now = DateTime.now();
    return showDialog<FilterCustomTanggalResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => FilterCustomTanggalDialog(
        initialStartDate: initialStartDate ?? now.subtract(const Duration(days: 7)),
        initialEndDate: initialEndDate ?? now,
        initialDataType: initialDataType ?? 'Tampilkan Semua',
      ),
    );
  }

  @override
  State<FilterCustomTanggalDialog> createState() => _FilterCustomTanggalDialogState();
}

class _FilterCustomTanggalDialogState extends State<FilterCustomTanggalDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedDataType;

  static const List<String> _bulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<Map<String, String>> _options = const [
    {
      'title': 'Tampilkan Semua',
      'subtitle': 'Tampilkan semua data termasuk rincian harian',
    },
    {
      'title': 'Pengeluaran Saja',
      'subtitle': 'Hanya data pengeluaran operasional',
    },
    {
      'title': 'Pemasukan Saja',
      'subtitle': 'Hanya rekap data penjualan masuk',
    },
    {
      'title': 'Laba Rugi Saja',
      'subtitle': 'Hanya rincian transaksi harian',
    },
    {
      'title': 'Rincian Menu Terlaris',
      'subtitle': 'Hanya data menu terlaris berdasarkan tanggal',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedDataType = widget.initialDataType;
  }

  String _formatTanggal(DateTime dt) {
    final tgl = dt.day;
    final bulan = _bulanList[dt.month - 1];
    final tahun = dt.year;
    return '$tgl $bulan $tahun';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              color: theme.colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTanggal(date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Text(
                'Filter Custom Tanggal & Jenis Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 18),

              // Tanggal Mulai
              _buildDateField(
                label: 'Tanggal Mulai *',
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 14),

              // Tanggal Selesai
              _buildDateField(
                label: 'Tanggal Selesai *',
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 18),

              // Jenis Data Title
              Text(
                'Jenis Data',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              RadioGroup<String>(
                groupValue: _selectedDataType,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDataType = val);
                  }
                },
                child: Column(
                  children: _options.map((opt) {
                    final title = opt['title']!;
                    final subtitle = opt['subtitle']!;
                    final isSelected = _selectedDataType == title;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedDataType = title);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<String>(
                              value: title,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Batal & Terapkan
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        FilterCustomTanggalResult(
                          startDate: _startDate,
                          endDate: _endDate,
                          dataType: _selectedDataType,
                        ),
                      );
                    },
                    child: Text(
                      'Terapkan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
