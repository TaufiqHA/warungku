import 'dart:io';

/// Service untuk koneksi dan pencetakan langsung melalui Network LAN TCP Socket
class NetworkPrinterService {
  NetworkPrinterService._();

  static Future<bool> printOverSocket({
    required String ipAddress,
    required int port,
    required List<int> bytes,
  }) async {
    try {
      final socket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 500));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
