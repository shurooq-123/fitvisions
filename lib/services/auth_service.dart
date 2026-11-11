import 'password_policy.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_repository.dart';
import 'login_notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final AuthRepository _repository = AuthRepository(
      auth: _auth,
      firestore: _firestore,
      notifyRegistration: () =>
          LoginNotificationService.send(registration: true),
      notifyPasswordChanged: () =>
          LoginNotificationService.send(passwordChanged: true));

  static String errorMessage(Object error) {
    if (error is AccountSetupException) return error.message;
    if (error is TimeoutException) {
      return 'The server took too long to respond. Check your connection and try again.';
    }
    if (error is FirebaseAuthException) {
      final detail = (error.message ?? '').toLowerCase();
      if (error.code == 'network-request-failed' ||
          ((error.code == 'internal-error' || error.code == 'unknown') &&
              [
                'connection reset',
                'unreachable host',
                'timed out',
                'network error'
              ].any(detail.contains))) {
        return 'Connection to Firebase was interrupted. Reconnect to the internet and try again. '
            'If you were registering, account creation could not be confirmed; try Login before registering again.';
      }
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
    return RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$').hasMatch(email.trim());
  }

  static bool isValidPassword(String password) =>
      PasswordPolicy.isValid(password);

  static bool isValidSingleName(String name) {
    return RegExp(r'^[a-zA-Z\u0600-\u06FF]+$').hasMatch(name.trim());
  }

  static bool isValidOmanPhone(String phone) {
    return RegExp(r'^[0-9]{8}$').hasMatch(phone.trim());
  }

  static Future<void> requestRegistrationLink(String email, String requestId) =>
      _requestMailLink('/register-confirmation',
          {'email': email.trim(), 'requestId': requestId});

  static Future<({String status, String? link})> registrationStatus(
      String requestId) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client
          .postUrl(Uri.parse('http://127.0.0.1:8789/register-status'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'requestId': requestId}));
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      final result = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        throw const AccountSetupException(
            'Could not check email confirmation.');
      }
      final data = jsonDecode(result) as Map<String, dynamic>;
      return (status: data['status'] as String, link: data['link'] as String?);
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> confirmRegistrationEmail(String email, String link) =>
      _repository.confirmRegistrationEmail(email, link);

  static Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    return _repository.registerUser(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password);
  }

  static Future<String> loginAndGetRole({
    required String email,
    required String password,
  }) async {
    return _repository.loginAndGetRole(email: email, password: password);
  }

  static Future<void> sendResetLink(String email) =>
      _requestMailLink('/forgot-password', {'email': email.trim()});

  static Future<void> _requestMailLink(
      String path, Map<String, String> payload) async {
    if (!kDebugMode) {
      throw const AccountSetupException(
          'The FitVisions email service is unavailable in this build.');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request =
          await client.postUrl(Uri.parse('http://127.0.0.1:8789$path'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      await response.drain<void>().timeout(const Duration(seconds: 5));
      if (response.statusCode == 202) return;
      if (response.statusCode == 429) {
        throw const AccountSetupException(
            'Please wait before requesting another email link.');
      }
      if (response.statusCode == 422) {
        throw const AccountSetupException(
            'This email address cannot receive mail. Check it and try again.');
      }
      if (response.statusCode == 503) {
        throw const AccountSetupException(
            'Connect the FitVisions sender email and try again.');
      }
      throw const AccountSetupException(
          'Could not send the email link. Please try again.');
    } on SocketException {
      throw const AccountSetupException(
          'Connect the phone to the FitVisions mail service and try again.');
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> changePassword(String newPassword,
          {required String currentPassword}) =>
      _repository.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
