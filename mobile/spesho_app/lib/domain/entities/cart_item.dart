import 'product_entity.dart';

class CartItem {
  final ProductEntity product;
  final double quantity;
  final double price;
  final double discount;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  double get subtotal => (quantity * price) - discount;
}
