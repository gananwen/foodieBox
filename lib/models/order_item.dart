// 这个模型代表 'items' 数组中的一个对象
class OrderItemModel {
  final String name;
  final double price;
  // final int quantity; // 你的 'items' 数组中没有 quantity，但你可能需要它
  // final String productId; // 你也可能需要 productId

  OrderItemModel({
    required this.name,
    required this.price,
  });

  // 从 Firestore (Map) 转换
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  // (这个模型是只读的，所以我们不需要 toMap)
}
