import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitvisions/services/auth_service.dart';
void main() {
 test('Firebase internal connection reset is described as uncertain network failure', () {
  final text=AuthService.errorMessage(FirebaseAuthException(code:'internal-error',message:'An internal error has occurred. [ Connection reset ]'));
  expect(text, contains('Connection to Firebase was interrupted'));
  expect(text, contains('account creation could not be confirmed'));
 });
 test('Other authentication errors keep their actual classification', () {
  expect(AuthService.errorMessage(FirebaseAuthException(code:'invalid-credential')),contains('Incorrect email or password'));
  expect(AuthService.errorMessage(FirebaseAuthException(code:'internal-error',message:'Other issue')),contains('internal-error'));
 });
}
