import 'transaction_model.dart';

class TransactionGroup {
  final String idTransaksi;
  final String customerName;
  final String waktu;
  final String dicatatOleh;
  final String paymentMethod;
  final String orderStatus;
  final String catatan;
  final List<TransactionModel> items;

  const TransactionGroup({
    required this.idTransaksi,
    required this.customerName,
    required this.waktu,
    required this.dicatatOleh,
    required this.paymentMethod,
    required this.orderStatus,
    this.catatan = '',
    required this.items,
  });

  double get totalHarga => items.fold(0.0, (sum, item) => sum + item.totalHarga);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.jumlah);
  bool get isMultiItem => items.length > 1;

  bool get isPending {
    final s = orderStatus.trim().toUpperCase();
    return s == 'PENDING' ||
        s == 'PROSES' ||
        s == 'PROCESSING' ||
        s == 'READY' ||
        s == 'SIAP';
  }

  bool get isReady {
    final s = orderStatus.trim().toUpperCase();
    return s == 'READY' || s == 'SIAP';
  }

  bool get isCancelled {
    final s = orderStatus.trim().toUpperCase();
    return s == 'CANCELLED' || s == 'BATAL';
  }

  bool get isCompleted {
    final s = orderStatus.trim().toUpperCase();
    return s == 'COMPLETED' || s == 'SELESAI';
  }

  bool get isActiveOrder => !isCompleted && !isCancelled;

  factory TransactionGroup.fromSingleTransaction(TransactionModel trx) {
    return TransactionGroup(
      idTransaksi: trx.idTransaksi,
      customerName: trx.customerName,
      waktu: trx.waktu,
      dicatatOleh: trx.dicatatOleh,
      paymentMethod: trx.paymentMethod,
      orderStatus: trx.orderStatus,
      catatan: trx.catatan,
      items: [trx],
    );
  }

  static List<TransactionGroup> fromTransactionList(List<TransactionModel> rawList) {
    final Map<String, List<TransactionModel>> map = {};
    for (final t in rawList) {
      final key = t.idTransaksi.isNotEmpty ? t.idTransaksi : (t.id.isNotEmpty ? t.id : t.hashCode.toString());
      map.putIfAbsent(key, () => []).add(t);
    }

    return map.entries.map((entry) {
      final items = entry.value;
      final first = items.first;

      final customer = items.map((e) => e.customerName).firstWhere(
        (c) => c.isNotEmpty && c != '-',
        orElse: () => first.customerName,
      );

      final payment = items.map((e) => e.paymentMethod).firstWhere(
        (p) => p.isNotEmpty,
        orElse: () => first.paymentMethod,
      );

      final orderStatus = items.map((e) => e.orderStatus).firstWhere(
        (s) => s.isNotEmpty,
        orElse: () => first.orderStatus,
      );

      final dicatatOleh = items.map((e) => e.dicatatOleh).firstWhere(
        (d) => d.isNotEmpty,
        orElse: () => first.dicatatOleh,
      );

      final notes = items.map((e) => e.catatan.trim()).where((c) => c.isNotEmpty).toSet().join('; ');

      return TransactionGroup(
        idTransaksi: entry.key,
        customerName: customer,
        waktu: first.waktu,
        dicatatOleh: dicatatOleh,
        paymentMethod: payment,
        orderStatus: orderStatus,
        catatan: notes,
        items: items,
      );
    }).toList();
  }
}
