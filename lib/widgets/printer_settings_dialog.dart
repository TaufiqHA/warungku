import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../services/bluetooth_permission_service.dart';
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
  bool _isConnecting = false;

  bool _btEnabled = true;
  bool _btConnected = false;
  BluetoothPermissionStatus _btPermission = BluetoothPermissionStatus.granted;
  String? _deviceError;

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

  /// Memperbarui indikator status Bluetooth, izin, dan koneksi printer.
  Future<void> _refreshStatus() async {
    final enabled = await _service.isBluetoothEnabled();
    final connected = await _service.isPrinterConnected();
    final permission = await _service.checkPermission();
    if (mounted) {
      setState(() {
        _btEnabled = enabled;
        _btConnected = connected;
        _btPermission = permission;
      });
    }
  }

  Future<void> _loadBluetoothDevices({bool requestPermission = false}) async {
    setState(() => _isLoadingDevices = true);
    final result = await _service.scanPairedDevices(requestPermission: requestPermission);

    if (mounted) {
      setState(() {
        _pairedDevices = result.devices;
        _deviceError = result.errorMessage;
        _isLoadingDevices = false;
        // Pastikan MAC terpilih selalu ada di daftar paired; kalau printer
        // tersimpan sudah tidak terpasang, jatuh ke perangkat pertama.
        if (result.devices.isNotEmpty &&
            !result.devices.any((d) => d.macAdress == _selectedMac)) {
          _selectedMac = result.devices.first.macAdress;
          _selectedPrinterName = result.devices.first.name;
        }
      });
    }
    await _refreshStatus();
  }

  Future<void> _handlePermissionAction() async {
    final permission = await _service.requestPermission();
    if (permission == BluetoothPermissionStatus.granted) {
      await _loadBluetoothDevices(requestPermission: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin Bluetooth diberikan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _refreshStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BluetoothPermissionService.message(permission)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showResult(PrintResult result) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? const Color(0xFF2E7D32)
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleConnect() async {
    setState(() => _isConnecting = true);
    final result = await _service.connectPrinter(overrideConfig: _buildCurrentConfig());
    if (!mounted) return;
    setState(() => _isConnecting = false);
    _showResult(result);
    await _refreshStatus();
  }

  Future<void> _handleDisconnect() async {
    final result = await _service.disconnectPrinter();
    if (!mounted) return;
    _showResult(result);
    await _refreshStatus();
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
    await _refreshStatus();
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

  /// Item status ringkas: ikon + teks kecil (tanpa label terpisah).
  Widget _statusItem(ThemeData theme, IconData icon, String text, bool isOk) {
    final color = isOk ? const Color(0xFF2E7D32) : theme.colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
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
              // Status ringkas satu baris
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _statusItem(
                    theme,
                    Icons.bluetooth_rounded,
                    _btEnabled ? 'Bluetooth aktif' : 'Bluetooth nonaktif',
                    _btEnabled,
                  ),
                  _statusItem(
                    theme,
                    Icons.verified_user_outlined,
                    _btPermission == BluetoothPermissionStatus.granted ? 'Izin diberikan' : 'Izin belum',
                    _btPermission == BluetoothPermissionStatus.granted,
                  ),
                  _statusItem(
                    theme,
                    Icons.cable_rounded,
                    _btConnected ? 'Terhubung' : 'Terputus',
                    _btConnected,
                  ),
                ],
              ),

              // Banner izin Bluetooth (hanya saat izin belum diberikan)
              if (_btPermission != BluetoothPermissionStatus.granted) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Izin Bluetooth diperlukan',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ),
                      TextButton(
                        onPressed: _handlePermissionAction,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Beri Izin Bluetooth', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Pilihan Jenis Koneksi (Bluetooth vs Jaringan)
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
              const SizedBox(height: 14),

              // Form Mode Bluetooth
              if (_connectionType == 'bluetooth') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Printer Bluetooth',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Pindai Ulang',
                      visualDensity: VisualDensity.compact,
                      onPressed: _isLoadingDevices
                          ? null
                          : () => _loadBluetoothDevices(requestPermission: true),
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
                            _deviceError ??
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
                const SizedBox(height: 10),
                AppButton(
                  text: _btConnected ? 'Putuskan' : 'Hubungkan',
                  isLoading: _isConnecting,
                  isPrimary: !_btConnected,
                  height: 44,
                  onPressed: _isConnecting
                      ? null
                      : (_btConnected ? _handleDisconnect : _handleConnect),
                ),
              ] else ...[
                // Form Mode Network (IP & Port)
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
              const SizedBox(height: 14),

              // Ukuran Kertas Struk
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
              const SizedBox(height: 14),

              // Tombol Tes Cetak
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        AppButton(
          text: 'Batal',
          isPrimary: false,
          width: 110,
          height: 42,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: 'Simpan',
          width: 110,
          height: 42,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
