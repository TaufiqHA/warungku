class ExpenseModel {
  final String id;
  final String kategori;
  final String keterangan;
  final double jumlah;
  final String tanggal;
  final String pembuat;

  const ExpenseModel({
    required this.id,
    required this.kategori,
    required this.keterangan,
    required this.jumlah,
    required this.tanggal,
    required this.pembuat,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: (json['id'] ?? '').toString(),
      kategori: (json['kategori'] ?? json['category'] ?? 'Lainnya').toString(),
      keterangan: (json['keterangan'] ?? json['description'] ?? '').toString(),
      jumlah: double.tryParse((json['jumlah'] ?? json['amount'] ?? 0).toString()) ?? 0.0,
      tanggal: (json['tanggal'] ?? json['date'] ?? '').toString(),
      pembuat: (json['pembuat'] ?? json['created_by'] ?? '-').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kategori': kategori,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'tanggal': tanggal,
      'pembuat': pembuat,
    };
  }
}
