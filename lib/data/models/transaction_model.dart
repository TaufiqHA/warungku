class TransactionModel {
  final String idTransaksi;
  final String id;
  final String namaItem;
  final int jumlah;
  final double harga;
  final String waktu;
  final String dicatatOleh;
  final String catatan;
  final String paymentMethod;
  final String orderStatus;
  final String customerName;
  final int servedQty;

  const TransactionModel({
    required this.idTransaksi,
    required this.id,
    required this.namaItem,
    required this.jumlah,
    required this.harga,
    required this.waktu,
    required this.dicatatOleh,
    required this.catatan,
    required this.paymentMethod,
    required this.orderStatus,
    required this.customerName,
    this.servedQty = 0,
  });

  double get totalHarga => harga * jumlah;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      idTransaksi: json['idTransaksi']?.toString() ?? json['id']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      namaItem: json['namaItem'] as String? ?? json['nama_item'] as String? ?? 'Item',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 1,
      harga: (json['harga'] as num?)?.toDouble() ?? 0.0,
      waktu: json['waktu'] as String? ?? DateTime.now().toIso8601String(),
      dicatatOleh: json['dicatatOleh'] as String? ?? json['dicatat_oleh'] as String? ?? 'Admin',
      catatan: json['catatan'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String? ?? 'Tunai',
      orderStatus: json['orderStatus'] as String? ?? json['order_status'] as String? ?? 'COMPLETED',
      customerName: json['customer_name'] as String? ?? json['customerName'] as String? ?? '-',
      servedQty: (json['servedQty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTransaksi': idTransaksi,
      'id': id,
      'namaItem': namaItem,
      'jumlah': jumlah,
      'harga': harga,
      'waktu': waktu,
      'dicatatOleh': dicatatOleh,
      'catatan': catatan,
      'payment_method': paymentMethod,
      'orderStatus': orderStatus,
      'customer_name': customerName,
      'servedQty': servedQty,
    };
  }
}
