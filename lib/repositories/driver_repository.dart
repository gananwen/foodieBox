import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';
import 'dart:math'; // 用于随机选择

class DriverRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<DriverModel> get _driversRef {
    return _db.collection('drivers').withConverter<DriverModel>(
          fromFirestore: (snapshot, _) =>
              DriverModel.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (driver, _) => driver.toMap(),
        );
  }

  // 获取一个随机的司机
  Future<DriverModel?> getRandomDriver() async {
    try {
      final snapshot = await _driversRef.get();
      if (snapshot.docs.isEmpty) {
        print("No drivers found in 'drivers' collection.");
        return null;
      }

      // 从所有司机中随机选择一个
      final random = Random();
      final randomDriverDoc =
          snapshot.docs[random.nextInt(snapshot.docs.length)];
      return randomDriverDoc.data();
    } catch (e) {
      print("Error fetching random driver: $e");
      rethrow;
    }
  }
}
