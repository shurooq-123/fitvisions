import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool isValidEmail(String email) {
    return RegExp
    (r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim());
  }

  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        password.length <= 15 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  static bool isValidSingleName(String name) {
    return RegExp(r'^[a-zA-Z\u0600-\u06FF]+$').hasMatch(name.trim());
  }

  static bool isValidOmanPhone(String phone) {
    return RegExp(r'^[0-9]{8}$').hasMatch(phone.trim());
  }

  static Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> loginAndGetRole({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final doc =
        await _firestore.collection('users').doc(credential.user!.uid).get();

    if (!doc.exists) {
      return 'user';
    }

    return doc.data()?['role'] ?? 'user';
  }

  static Future<void> sendResetLink(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw 'No logged in user';
    }

    await user.updatePassword(newPassword.trim());
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}