class VendorModel {
  final String uid; // 必须和 User.uid 相同
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String vendorType; // <-- (来自你的注册页面)
  final String businessPhotoUrl;
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
    required this.vendorType, // <-- (来自你的注册页面)
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
      vendorType: map['vendorType'] ?? 'Grocery', // <-- (添加了默认值)
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
      'vendorType': vendorType, // <-- (添加)
      'businessPhotoUrl': businessPhotoUrl,
      'businessLicenseUrl': businessLicenseUrl,
      'halalCertificateUrl': halalCertificateUrl,
      'isApproved': isApproved,
      'rating': rating,
      'storeHours': storeHours,
    };
  }

  // --- (FIX) 这就是你缺少的另一个方法 ---
  VendorModel copyWith({
    String? uid,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? vendorType,
    String? businessPhotoUrl,
    String? businessLicenseUrl,
    String? halalCertificateUrl,
    bool? isApproved,
    double? rating,
    List<String>? storeHours,
  }) {
    return VendorModel(
      uid: uid ?? this.uid,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      vendorType: vendorType ?? this.vendorType,
      businessPhotoUrl: businessPhotoUrl ?? this.businessPhotoUrl,
      businessLicenseUrl: businessLicenseUrl ?? this.businessLicenseUrl,
      halalCertificateUrl: halalCertificateUrl ?? this.halalCertificateUrl,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      storeHours: storeHours ?? this.storeHours,
    );
  }
}
