// Mocktail doubles only; production code never implements Firestore classes.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitvisions/services/auth_repository.dart';
import 'package:fitvisions/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockCredential extends Mock implements UserCredential {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockAuth auth;
  late MockFirestore firestore;
  late MockUser user;
  late MockCredential credential;
  late MockCollection collection;
  late MockDocument document;
  late MockSnapshot snapshot;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(const GetOptions());
    registerFallbackValue(EmailAuthProvider.credential(
        email: 'test@example.com', password: 'unused'));
  });
  setUp(() {
    auth = MockAuth();
    firestore = MockFirestore();
    user = MockUser();
    credential = MockCredential();
    collection = MockCollection();
    document = MockDocument();
    snapshot = MockSnapshot();
    repository = AuthRepository(auth: auth, firestore: firestore);
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn('test-uid');
    when(() => user.email).thenReturn('test@example.com');
    when(() => user.emailVerified).thenReturn(false);
    when(() => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'))).thenAnswer((_) async => credential);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => user.delete()).thenAnswer((_) async {});
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => firestore.collection('users')).thenReturn(collection);
    when(() => collection.doc('test-uid')).thenReturn(document);
    when(() => document.get(any())).thenAnswer((_) async => snapshot);
    when(() => document.set(any())).thenAnswer((_) async {});
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn({'role': 'user'});
  });

  Future<void> register() => repository.registerUser(
      firstName: 'Test',
      lastName: 'User',
      phone: '91234567',
      password: 'Aa@12345');

  test('private profile is read only after authentication and by UID',
      () async {
    final signedIn = Completer<UserCredential>();
    when(() => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'))).thenAnswer((_) => signedIn.future);
    final result = repository.loginAndGetRole(
        email: ' Test@example.com ', password: 'Aa@12345');
    verifyNever(() => firestore.collection(any()));
    signedIn.complete(credential);
    expect(await result, 'user');
    verify(() => collection.doc('test-uid')).called(1);
    verify(() => document.get(const GetOptions(source: Source.server)))
        .called(1);
  });

  test('invalid credentials do not query Firestore', () async {
    when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await expectLater(
        repository.loginAndGetRole(email: 'test@example.com', password: 'bad'),
        throwsA(isA<FirebaseAuthException>()));
    verifyNever(() => firestore.collection(any()));
  });

  test('admin is returned only from an existing server profile', () async {
    when(() => snapshot.data()).thenReturn({'role': 'admin'});
    expect(
        await repository.loginAndGetRole(
            email: 'test@example.com', password: 'Aa@12345'),
        'admin');
  });

  test('missing profile signs out and does not grant access', () async {
    when(() => snapshot.exists).thenReturn(false);
    await expectLater(
        repository.loginAndGetRole(
            email: 'test@example.com', password: 'Aa@12345'),
        throwsA(isA<AccountSetupException>()));
    verify(() => auth.signOut()).called(1);
  });

  test('permission error remains distinct from a password error', () async {
    final error =
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    when(() => document.get(any())).thenThrow(error);
    await expectLater(
        repository.loginAndGetRole(
            email: 'test@example.com', password: 'Aa@12345'),
        throwsA(same(error)));
    verify(() => auth.signOut()).called(1);
    expect(AuthService.errorMessage(error), contains('Firestore permissions'));
  });

  test('only a confirmed email can finish registration', () async {
    when(() => auth.currentUser).thenReturn(user);
    await expectLater(register(), throwsA(isA<AccountSetupException>()));
    verifyNever(() => user.updatePassword(any()));
    verifyNever(() => document.set(any()));

    when(() => user.emailVerified).thenReturn(true);
    when(() => snapshot.exists).thenReturn(false);
    when(() => user.updatePassword(any())).thenAnswer((_) async {});
    await register();
    final data = verify(() => document.set(captureAny())).captured.single as Map;
    expect(data['role'], 'user');
    expect(data['uid'], 'test-uid');
    expect(data['email'], 'test@example.com');
    expect(data['requiresEmailVerification'], isTrue);
    expect(data.containsKey('password'), isFalse);
    verify(() => auth.signOut()).called(1);
  });

  test('email-link registration cannot overwrite an existing profile', () async {
    const link = 'https://example.com/link';
    when(() => auth.isSignInWithEmailLink(link)).thenReturn(true);
    when(() => auth.signInWithEmailLink(
        email: 'test@example.com', emailLink: link))
        .thenAnswer((_) async => credential);
    when(() => user.emailVerified).thenReturn(true);
    await expectLater(
        repository.confirmRegistrationEmail('test@example.com', link),
        throwsA(isA<AccountSetupException>()));
    verify(() => auth.signOut()).called(1);
    verifyNever(() => user.updatePassword(any()));
    verifyNever(() => document.set(any()));
  });

  test('unverified new account receives a link and cannot enter', () async {
    when(() => snapshot.data()).thenReturn({
      'role': 'user',
      'requiresEmailVerification': true,
    });
    await expectLater(
      repository.loginAndGetRole(
          email: 'test@example.com', password: 'Aa@12345'),
      throwsA(isA<AccountSetupException>().having(
          (error) => error.message, 'message', contains('Verify your email'))),
    );
    verify(() => user.sendEmailVerification()).called(1);
    verify(() => auth.signOut()).called(1);
  });

  test('verified new account enters without resending a link', () async {
    when(() => snapshot.data()).thenReturn({
      'role': 'user',
      'requiresEmailVerification': true,
    });
    when(() => user.emailVerified).thenReturn(true);
    expect(
        await repository.loginAndGetRole(
            email: 'test@example.com', password: 'Aa@12345'),
        'user');
    verifyNever(() => user.sendEmailVerification());
  });

  test('email validation rejects whitespace and empty domain segments', () {
    expect(AuthService.isValidEmail('user+demo@example.com'), isTrue);
    expect(AuthService.isValidEmail('user name@example.com'), isFalse);
    expect(AuthService.isValidEmail('user@example..com'), isFalse);
  });

  test('password reuse is rejected before updating Firebase', () async {
    when(() => auth.currentUser).thenReturn(user);
    await expectLater(
        repository.changePassword(
            currentPassword: 'Old@12345', newPassword: 'Old@12345'),
        throwsA(isA<AccountSetupException>()));
    verifyNever(() => user.updatePassword(any()));
  });
  test('password change requires reauthentication and signs out after success',
      () async {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.reauthenticateWithCredential(any()))
        .thenAnswer((_) async => credential);
    when(() => user.updatePassword(any())).thenAnswer((_) async {});
    await repository.changePassword(
        currentPassword: 'Old@12345', newPassword: 'New@12345');
    verifyInOrder([
      () => user.reauthenticateWithCredential(any()),
      () => user.updatePassword('New@12345'),
      () => auth.signOut()
    ]);
  });
  test('wrong current password prevents password update', () async {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'wrong-password'));
    await expectLater(
        repository.changePassword(
            currentPassword: 'Wrong@123', newPassword: 'New@12345'),
        throwsA(isA<FirebaseAuthException>()));
    verifyNever(() => user.updatePassword(any()));
  });
  test('password email runs after update and mail failure still signs out', () async {
    var updated = false;
    var notified = false;
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async => credential);
    when(() => user.updatePassword(any())).thenAnswer((_) async { updated = true; });
    final subject = AuthRepository(auth: auth, firestore: firestore,
        notifyPasswordChanged: () async {
          expect(updated, isTrue);
          notified = true;
          throw Exception('SMTP offline');
        });
    expect(await subject.changePassword(currentPassword:'Old@12345',newPassword:'New@12345'), isFalse);
    expect(notified, isTrue);
    verify(() => auth.signOut()).called(1);
  });
  test('failed password update never sends a success notification', () async {
    var notified = false;
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async => credential);
    when(() => user.updatePassword(any())).thenThrow(FirebaseAuthException(code:'network-request-failed'));
    final subject = AuthRepository(auth:auth,firestore:firestore,
        notifyPasswordChanged:() async { notified=true; return true; });
    await expectLater(subject.changePassword(currentPassword:'Old@12345',newPassword:'New@12345'),throwsA(isA<FirebaseAuthException>()));
    expect(notified,isFalse);
  });
}
