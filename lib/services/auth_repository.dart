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
  AuthRepository({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = credential.user!;
    try {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'email': user.email ?? email.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 20));
    } catch (error) {
      // Roll back ONLY the account created by this call, and only when the
      // server definitively rejected the profile write. A timeout is ambiguous.
      var rolledBack = false;
      if (error is FirebaseException &&
          const ['permission-denied', 'unauthenticated', 'invalid-argument']
              .contains(error.code)) {
        try {
          await user.delete();
          rolledBack = true;
        } catch (_) {
          // Tell the user the account remains instead of claiming a rollback.
        }
      }
      await _signOutQuietly();
      throw AccountSetupException(rolledBack
          ? 'Registration could not save your profile. The new account was rolled back. '
              'Ask the administrator to check Firestore permissions before retrying.'
          : 'Your sign-in account was created, but saving your profile could not be confirmed. '
              'Do not register again. Ask the administrator to check your account setup.');
    }
    try {
      await user.sendEmailVerification().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AccountSetupException(
          'Your account was created, but the verification email could not be sent. '
          'Do not register again. Log in and use Send verification email in Profile.');
    } finally {
      // Email delivery failure must not delete a successfully created account.
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
      final doc = await firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));
      if (!doc.exists) {
        throw const AccountSetupException(
          'Your sign-in account exists, but its profile is missing or was removed. '
          'Please contact the administrator to restore or complete your account.',
        );
      }
      final role = doc.data()?['role'];
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

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
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
    await auth.signOut();
  }

  Future<void> _signOutQuietly() async {
    try {
      await auth.signOut();
    } catch (_) {
      // Preserve the original, actionable error.
    }
  }
}
