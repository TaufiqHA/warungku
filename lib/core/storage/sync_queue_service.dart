import 'package:hive/hive.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Worker pengelola sinkronisasi transaksi offline ke server saat online
class SyncQueueService {
  final ApiClient apiClient;
  final Box unsyncedBox;

  SyncQueueService({
    required this.apiClient,
    required this.unsyncedBox,
  });

  /// Menambahkan transaksi ke antrean sinkronisasi offline
  Future<void> addToQueue(String transactionId, Map<String, dynamic> data) async {
    await unsyncedBox.put(transactionId, data);
  }

  /// Memproses antrean transaksi offline ke server secara FIFO
  Future<int> processQueue() async {
    final keys = unsyncedBox.keys.toList();
    int syncedCount = 0;

    for (var key in keys) {
      final txData = unsyncedBox.get(key);
      if (txData != null && txData is Map) {
        try {
          final response = await apiClient.post(
            ApiEndpoints.transactions,
            data: txData,
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            await unsyncedBox.delete(key);
            syncedCount++;
          }
        } catch (e) {
          // Gagal mengirim transaksi ini, tunda ke siklus sinkronisasi berikutnya
          break;
        }
      }
    }
    return syncedCount;
  }

  int get pendingCount => unsyncedBox.length;
}
