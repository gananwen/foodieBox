import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String licensePlate;
  final String imageUrl;
  final double rating;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.licensePlate,
    required this.imageUrl,
    this.rating = 4.5,
  });

  // 从 Firestore (Map) 转换
  factory DriverModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DriverModel(
      id: documentId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // 转换到 Map (用于写入 Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'licensePlate': licensePlate,
      'imageUrl': imageUrl,
    };
  }
}
