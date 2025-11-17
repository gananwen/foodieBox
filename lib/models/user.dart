import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.role,
  });

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
      role: 'User',
    );
  }

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

  // --- (新增) CopyWith 方法 ---
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      role: role ?? this.role,
    );
  }
}
