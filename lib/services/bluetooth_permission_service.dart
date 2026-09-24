import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Status izin Bluetooth runtime (Android 12+ / `BLUETOOTH_CONNECT`).
///
/// Plugin `print_bluetooth_thermal` hanya mengembalikan granted/denied (tidak
/// membedakan penolakan permanen "jangan tanyakan lagi"), jadi status disamakan
/// menjadi [denied] — pesan ke pengguna tetap mengarahkan ke Pengaturan Android.
enum BluetoothPermissionStatus { granted, denied }

/// Pengelola izin Bluetooth runtime tanpa dependency tambahan.
///
/// Sejak Android 12, daftar printer Bluetooth terpasang maupun koneksi printer
/// butuh izin runtime `BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN`. Method native
/// `ispermissionbluetoothgranted` pada plugin `print_bluetooth_thermal` sudah
/// meminta izin tersebut ke sistem (memunculkan dialog izin dan menunggu
/// jawaban pengguna) lalu mengembalikan hasilnya — jadi satu pemanggilan cukup
/// untuk memeriksa sekaligus meminta izin.
class BluetoothPermissionService {
  static final BluetoothPermissionService instance = BluetoothPermissionService._internal();

  BluetoothPermissionService._internal();

  /// Seam pengujian: menggantikan pemanggilan plugin saat meminta izin.
  Future<BluetoothPermissionStatus> Function()? requester;

  /// Seam pengujian: menggantikan pemanggilan plugin saat memeriksa izin.
  Future<BluetoothPermissionStatus> Function()? checker;

  /// Meminta izin Bluetooth.
  ///
  /// Pada Android 12+ dialog izin sistem muncul bila belum pernah dijawab;
  /// bila pengguna memilih "jangan tanyakan lagi" pemanggilan ini langsung
  /// mengembalikan [BluetoothPermissionStatus.denied].
  Future<BluetoothPermissionStatus> request() async {
    if (requester != null) return requester!();
    return _queryPlugin();
  }

  /// Memeriksa status izin Bluetooth.
  ///
  /// Memakai method native yang sama; di Android 12+ pemanggilan pertama bisa
  /// memunculkan dialog izin, setelah itu hasilnya langsung dikembalikan.
  Future<BluetoothPermissionStatus> check() async {
    if (checker != null) return checker!();
    return _queryPlugin();
  }

  Future<BluetoothPermissionStatus> _queryPlugin() async {
    // Pada platform selain Android (mis. pengujian desktop) izin tidak relevan.
    if (!Platform.isAndroid) return BluetoothPermissionStatus.granted;

    try {
      final isGranted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      return isGranted
          ? BluetoothPermissionStatus.granted
          : BluetoothPermissionStatus.denied;
    } catch (e) {
      debugPrint('BluetoothPermissionService: $e');
      // Plugin tidak tersedia -> jangan menghalangi pencetakan.
      return BluetoothPermissionStatus.granted;
    }
  }

  /// Pesan siap pakai untuk ditampilkan pada snackbar / banner.
  static String message(BluetoothPermissionStatus status) {
    switch (status) {
      case BluetoothPermissionStatus.denied:
        return 'Izin Bluetooth belum diberikan. Izinkan akses Bluetooth (atau aktifkan manual di Pengaturan Android → Aplikasi → Warungku → Izin) agar printer thermal bisa dipakai.';
      case BluetoothPermissionStatus.granted:
        return '';
    }
  }
}
