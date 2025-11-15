// 路径: lib/models/order_item.model.dart
class OrderItem {
  final String name;
  final double price;
  final int quantity;
  final String productId;
  final String vendorId;
  final String imageUrl;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.productId,
    required this.vendorId,
    required this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      productId: map['productId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
