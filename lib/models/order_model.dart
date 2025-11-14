import 'package:cloud_firestore/cloud_firestore.dart'; // Fixed: Removed the '9'

// A model for the main order
class OrderModel {
  final String id;
  final String userId;
  final String address;
  final double lat;
  final double lng;
  final String paymentMethod;
  final double subtotal;
  final double total;
  final String status; // e.g., 'received', 'preparing', 'delivering', 'delivered'
  final List<OrderItem> items;
  final Timestamp timestamp;
  final String? driverId; // Nullable: will be assigned when driver is found
  final String? contactName;
  final String? contactPhone;

  OrderModel({
    required this.id,
    required this.userId,
    required this.address,
    required this.lat,
    required this.lng,
    required this.paymentMethod,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.items,
    required this.timestamp,
    this.driverId,
    this.contactName,
    this.contactPhone,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse the list of items
    var itemsList = (map['items'] as List<dynamic>?) ?? [];
    List<OrderItem> parsedItems =
        itemsList.map((item) => OrderItem.fromMap(item)).toList();

    return OrderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      address: map['address'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'received',
      items: parsedItems,
      timestamp: map['timestamp'] ?? Timestamp.now(),
      driverId: map['driverId'], // Can be null
      contactName: map['contactName'],
      contactPhone: map['contactPhone'],
    );
  }
}

// A model for a single item within an order
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