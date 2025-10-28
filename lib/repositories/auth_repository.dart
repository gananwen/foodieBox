import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  // ✅ Email Sign-Up
  Future<User?> signUpWithEmail(
      String email, String password, String fullName, String role) async {
    try {
      if (role.toLowerCase() == 'admin' || role.toLowerCase() == 'vendor') {
        throw Exception('This role cannot sign up via the app.');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        final nameParts = fullName.trim().split(' ');
        final firstName = nameParts.first;
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        final userModel = UserModel(
          uid: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          username: email.split('@').first,
          role: role,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    }
  }

  // ✅ Email Login
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    }
  }

  // ✅ Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // user canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if user exists in Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          final newUser = UserModel.fromFirebaseUser(user);
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
        }
      }

      return user;
    } catch (e) {
      throw Exception("Google Sign-In failed: ${e.toString()}");
    }
  }

  // ✅ Sign Out (both Email + Google)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ✅ Error handler
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
