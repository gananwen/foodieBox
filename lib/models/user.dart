import 'package:firebase_auth/firebase_auth.dart' as auth; // 使用 'as auth' 避免冲突

// 这个模型代表 'users' 集合中的一个文档
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String role;
  // 你可以按需添加更多字段 (e.g., phoneNumber, profilePictureUrl)

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.role,
  });

  // 从 Firebase User 对象 (Google 登录时) 创建 UserModel
  factory UserModel.fromFirebaseUser(auth.User user) {
    final nameParts = user.displayName?.split(' ') ?? ['New', 'User'];
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      username: user.email?.split('@').first ?? user.uid,
      role: 'User', // 默认角色
    );
  }

  // 从 Firestore (Map) 转换
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? 'User',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'role': role,
    };
  }
}
