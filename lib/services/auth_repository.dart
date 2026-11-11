import 'password_policy.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSetupException implements Exception {
  const AccountSetupException(this.message);
  final String message;
}

/// Authenticate before accessing the private profile. Never infer admin rights
/// from an email address or treat a profile read failure as a normal user.
class AuthRepository {
  AuthRepository(
      {required this.auth,
      required this.firestore,
      this.notifyPasswordChanged,
      this.notifyRegistration});
  final Future<bool> Function()? notifyRegistration;
  final Future<bool> Function()? notifyPasswordChanged;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Future<void> confirmRegistrationEmail(String email, String link) async {
    if (!auth.isSignInWithEmailLink(link)) {
      throw const AccountSetupException(
          'Open or copy the registration link sent to your email.');
    }
    final credential =
        await auth.signInWithEmailLink(email: email.trim(), emailLink: link);
    try {
      final user = credential.user;
      if (user == null || !user.emailVerified) {
        throw const AccountSetupException('Your email could not be verified.');
      }
      await _ensureNewProfile(user.uid);
    } catch (_) {
      await _signOutQuietly();
      rethrow;
    }
  }

  Future<void> _ensureNewProfile(String uid) async {
    final profile = await firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    if (profile.exists) {
      throw const AccountSetupException(
          'This email already has a FitVisions account. Use Login or Forgot Password.');
    }
  }

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    final user = auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || !user.emailVerified) {
      throw const AccountSetupException(
          'Confirm your email before completing registration.');
    }
    if (!PasswordPolicy.isValid(password)) {
      throw const AccountSetupException(PasswordPolicy.description);
    }
    await _ensureNewProfile(user.uid);
    await user.updatePassword(password).timeout(const Duration(seconds: 20));
    try {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'email': email,
        'role': 'user',
        'requiresEmailVerification': true,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AccountSetupException(
          'Could not confirm that your profile was saved. Try again. If you already have an account, use Login.');
    }
    try {
      await notifyRegistration?.call().timeout(const Duration(seconds: 8));
    } catch (_) {
      // A confirmation notice is best effort once registration is complete.
    } finally {
      await _signOutQuietly();
    }
  }

  Future<String> loginAndGetRole({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    try {
      final user = credential.user!;
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));
      if (!doc.exists) {
        throw const AccountSetupException(
          'Your sign-in account exists, but its profile is missing or was removed. '
          'Please contact the administrator to restore or complete your account.',
        );
      }
      final profile = doc.data();
      if (profile?['requiresEmailVerification'] == true &&
          !user.emailVerified) {
        final sent = await _sendVerificationEmail(user);
        throw AccountSetupException(sent
            ? 'Verify your email before signing in. We sent a new link. Check your inbox or spam folder, open the link, then sign in again.'
            : 'Verify your email before signing in. Open the link already sent to your inbox or spam folder. If you have no link, wait a few minutes and try signing in again to resend it.');
      }
      final role = profile?['role'];
      if (role != 'user' && role != 'admin') {
        throw const AccountSetupException(
          'Your account role is not configured. Please contact the administrator.',
        );
      }
      return role as String;
    } catch (_) {
      await _signOutQuietly();
      rethrow;
    }
  }

  Future<bool> _sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification().timeout(const Duration(seconds: 12));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(
      {required String currentPassword, required String newPassword}) async {
    if (!PasswordPolicy.isValid(newPassword)) {
      throw const AccountSetupException(PasswordPolicy.description);
    }
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw const AccountSetupException(
          'Please sign in again before changing your password.');
    }
    if (currentPassword == newPassword) {
      throw const AccountSetupException(
          'This password has already been used. Please choose a new password.');
    }
    await user.reauthenticateWithCredential(EmailAuthProvider.credential(
        email: user.email!, password: currentPassword));
    await user.updatePassword(newPassword);
    try {
      return await (notifyPasswordChanged?.call() ?? Future.value(false))
          .timeout(const Duration(seconds: 35));
    } catch (_) {
      return false;
    } finally {
      await _signOutQuietly();
    }
  }

  Future<void> _signOutQuietly() async {
    try {
      await auth.signOut();
    } catch (_) {
      // Preserve the original, actionable error.
    }
  }
}
