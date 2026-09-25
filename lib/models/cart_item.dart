import 'product.dart';

class CartItem {
  final Product product;
  final int qty;

  const CartItem({required this.product, required this.qty});

  double get lineTotal => product.price * qty;

  CartItem copyWith({int? qty}) => CartItem(product: product, qty: qty ?? this.qty);

  Map<String, dynamic> toMap() {
    return {
      'product': {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'unit': product.unit,
        'imageUrl': product.imageUrl,
      },
      'qty': qty,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final pMap = map['product'] as Map<String, dynamic>;
    return CartItem(
      product: Product(
        id: pMap['id'] ?? '',
        name: pMap['name'] ?? '',
        price: (pMap['price'] ?? 0).toDouble(),
        unit: pMap['unit'] ?? '',
        imageUrl: pMap['imageUrl'] ?? '',
      ),
      qty: map['qty']?.toInt() ?? 1,
    );
  }
}
