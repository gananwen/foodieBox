class Driver {
  final String id;
  final String name;
  final String phone;
  final String licensePlate;
  final String imageUrl;
  final double rating;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licensePlate,
    required this.imageUrl,
    this.rating = 4.5,
  });
}
