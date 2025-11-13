class Driver {
  final String id;
  final String name;
  final String phone;
  final String licensePlate;
  final String imageUrl;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licensePlate,
    required this.imageUrl,
  });

  // You can add factory constructors later for Firebase
  // factory Driver.fromFirestore(Map<String, dynamic> data) { ... }
}