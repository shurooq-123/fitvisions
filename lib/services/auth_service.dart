import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final AuthRepository _repository =
      AuthRepository(auth: _auth, firestore: _firestore);

  static String errorMessage(Object error) {
    if (error is AccountSetupException) return error.message;
    if (error is TimeoutException) {
      return 'The server took too long to respond. Check your connection and try again.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'This email already has an account. Try Login or Forgot Password. '
              'If an earlier registration failed, ask the administrator to check your profile.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Choose a stronger password that meets the password requirements.';
        case 'user-disabled':
          return 'This account has been disabled. Contact the administrator.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed':
          return 'Cannot connect to Firebase. Check your internet connection.';
        case 'operation-not-allowed':
          return 'Email/password authentication is not enabled for this Firebase project.';
        default:
          return 'Authentication failed (${error.code}). Please contact the administrator.';
      }
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Your account was authenticated, but access to its profile was denied. '
            'The administrator needs to check Firestore permissions.';
      }
      if (error.code == 'unavailable') {
        return 'The profile database is unavailable. Check your connection and try again.';
      }
      return 'Account data could not be loaded (${error.code}). Please try again.';
    }
    return 'Unable to complete the request. Please try again.';
  }

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
    await _repository.registerUser(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        password: password);
  }

  static Future<String> loginAndGetRole({
    required String email,
    required String password,
  }) async {
    return _repository.loginAndGetRole(email: email, password: password);
  }

  static Future<void> sendResetLink(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> changePassword(String newPassword,
          {required String currentPassword}) =>
      _repository.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
