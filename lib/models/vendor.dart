class VendorModel {
  final String uid; // 必须和 User.uid 相同
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String businessPhotoUrl; // 你要求的新增字段
  final String businessLicenseUrl;
  final String halalCertificateUrl;
  final bool isApproved; // 管理员审批
  final double rating;
  final List<String> storeHours; // e.g., ["Mon: 9-5", "Tue: 9-5"]

  VendorModel({
    required this.uid,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.businessPhotoUrl,
    required this.businessLicenseUrl,
    this.halalCertificateUrl = '',
    this.isApproved = false, // 默认未批准
    this.rating = 0.0,
    this.storeHours = const [], // 默认为空
  });

  // 从 Firestore (Map) 转换
  factory VendorModel.fromMap(Map<String, dynamic> map) {
    return VendorModel(
      uid: map['uid'] ?? '',
      storeName: map['storeName'] ?? '',
      storeAddress: map['storeAddress'] ?? '',
      storePhone: map['storePhone'] ?? '',
      businessPhotoUrl: map['businessPhotoUrl'] ?? '',
      businessLicenseUrl: map['businessLicenseUrl'] ?? '',
      halalCertificateUrl: map['halalCertificateUrl'] ?? '',
      isApproved: map['isApproved'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      storeHours: List<String>.from(map['storeHours'] ?? []),
    );
  }

  // 转换到 Map (用于写入 Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'businessPhotoUrl': businessPhotoUrl,
      'businessLicenseUrl': businessLicenseUrl,
      'halalCertificateUrl': halalCertificateUrl,
      'isApproved': isApproved,
      'rating': rating,
      'storeHours': storeHours,
    };
  }
}
