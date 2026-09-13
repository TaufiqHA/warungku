import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../services/thermal_printer_service.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class PrinterSettingsDialog extends StatefulWidget {
  const PrinterSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PrinterSettingsDialog(),
    );
  }

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  final _service = ThermalPrinterService.instance;
  late TextEditingController _ipController;
  late TextEditingController _portController;

  String _connectionType = 'bluetooth'; // 'bluetooth' or 'network'
  String _selectedMac = '';
  String _selectedPrinterName = '';
  int _paperWidth = 58;

  List<BluetoothInfo> _pairedDevices = [];
  bool _isLoadingDevices = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: '10.0.2.2');
    _portController = TextEditingController(text: '9100');
    _loadConfig();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await _service.getConfig();
    if (mounted) {
      setState(() {
        _connectionType = config.connectionType;
        _selectedMac = config.macAddress;
        _selectedPrinterName = config.printerName;
        _ipController.text = config.ip;
        _portController.text = config.port.toString();
        _paperWidth = config.paperWidth;
      });
    }
    await _loadBluetoothDevices();
  }

  Future<void> _loadBluetoothDevices() async {
    setState(() => _isLoadingDevices = true);
    final devices = await _service.getPairedDevices();
    if (mounted) {
      setState(() {
        _pairedDevices = devices;
        _isLoadingDevices = false;
        if (_selectedMac.isEmpty && devices.isNotEmpty) {
          _selectedMac = devices.first.macAdress;
          _selectedPrinterName = devices.first.name;
        }
      });
    }
  }

  ThermalPrinterConfig _buildCurrentConfig() {
    final ip = _ipController.text.trim().isEmpty ? '10.0.2.2' : _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;
    return ThermalPrinterConfig(
      connectionType: _connectionType,
      macAddress: _selectedMac,
      printerName: _selectedPrinterName,
      ip: ip,
      port: port,
      paperWidth: _paperWidth,
    );
  }

  Future<void> _handleTestPrint() async {
    setState(() => _isTesting = true);
    final config = _buildCurrentConfig();
    final result = await _service.testPrint(customConfig: config);
    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    final config = _buildCurrentConfig();
    await _service.saveConfig(config);
    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan printer thermal berhasil disimpan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentGreen = Color(0xFF7CB342);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.print_rounded, color: accentGreen, size: 24),
          SizedBox(width: 10),
          Text(
            'Pengaturan Printer Thermal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, minWidth: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pilihan Jenis Koneksi (Bluetooth vs Jaringan)
              Text(
                'Tipe Koneksi Printer',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.bluetooth_rounded, size: 16),
                      label: const Center(child: Text('Bluetooth')),
                      selected: _connectionType == 'bluetooth',
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _connectionType = 'bluetooth');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.wifi_rounded, size: 16),
                      label: const Center(child: Text('Jaringan (IP)')),
                      selected: _connectionType == 'network',
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _connectionType = 'network');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form Mode Bluetooth
              if (_connectionType == 'bluetooth') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perangkat Bluetooth Terpasang',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Pindai Ulang',
                      visualDensity: VisualDensity.compact,
                      onPressed: _isLoadingDevices ? null : _loadBluetoothDevices,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isLoadingDevices)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_pairedDevices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Belum ada printer Bluetooth terpasang. Pasangkan (pair) printer di Bluetooth perangkat Anda.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _pairedDevices.any((d) => d.macAdress == _selectedMac)
                            ? _selectedMac
                            : _pairedDevices.first.macAdress,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        items: _pairedDevices.map((d) {
                          return DropdownMenuItem<String>(
                            value: d.macAdress,
                            child: Row(
                              children: [
                                const Icon(Icons.print_rounded, size: 18, color: accentGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${d.name} (${d.macAdress})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = _pairedDevices.firstWhere((d) => d.macAdress == val);
                            setState(() {
                              _selectedMac = val;
                              _selectedPrinterName = match.name;
                            });
                          }
                        },
                      ),
                    ),
                  ),
              ] else ...[
                // Form Mode Network (IP & Port)
                Text(
                  'Konektivitas ESC/POS (LAN / WiFi / Emulator)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Alamat IP Printer',
                  hintText: 'Misal: 10.0.2.2 atau 192.168.1.200',
                  controller: _ipController,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Port Printer (Default 9100)',
                  hintText: '9100',
                  controller: _portController,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),

              // Ukuran Kertas Struk
              Text(
                'Ukuran Kertas Thermal',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('58 mm (Standar)')),
                      selected: _paperWidth == 58,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _paperWidth = 58);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('80 mm (Lebar)')),
                      selected: _paperWidth == 80,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _paperWidth = 80);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Tes Cetak
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _handleTestPrint,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(_isTesting ? 'Menguji Printer...' : 'Tes Cetak Thermal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentGreen,
                  side: const BorderSide(color: accentGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        AppButton(
          text: 'Simpan',
          height: 40,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
