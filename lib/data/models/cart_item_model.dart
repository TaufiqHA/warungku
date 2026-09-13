import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double unitPrice;
  final String notes;

  CartItemModel({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.notes = '',
  });

  double get subtotal => quantity * unitPrice;

  int? get numericProductId {
    if (product.id.startsWith('PRD-')) {
      return int.tryParse(product.id.substring(4));
    }
    return int.tryParse(product.id);
  }

  Map<String, dynamic> toJson() {
    final numId = numericProductId;
    return {
      'product_id': numId,
      'namaItem': product.name,
      'jumlah': quantity,
      'quantity': quantity,
      'harga': unitPrice,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'catatan': notes,
      'servedQty': 0,
    };
  }
}
