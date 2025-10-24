import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
    );
  }

  factory UserModel.fromFirebaseUser(User user, {String role = 'customer'}) {
    final nameParts = (user.displayName ?? '').trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      username: user.email?.split('@').first ?? '',
      role: role,
    );
  }
}
