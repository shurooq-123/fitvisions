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
    when(() => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'))).thenAnswer((_) async => credential);
    when(() => auth.createUserWithEmailAndPassword(
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
      email: 'test@example.com',
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

  test('successful registration creates a user profile then signs out',
      () async {
    await register();
    final data =
        verify(() => document.set(captureAny())).captured.single as Map;
    expect(data['role'], 'user');
    expect(data['uid'], 'test-uid');
    expect(data.containsKey('password'), isFalse);
    verify(() => auth.signOut()).called(1);
    verifyNever(() => user.delete());
    verify(() => user.sendEmailVerification()).called(1);
  });

  test('verification email failure retains account and closes session', () async {
    when(() => user.sendEmailVerification())
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(register(), throwsA(isA<AccountSetupException>()
        .having((e) => e.message, 'message', contains('Your account was created'))));
    verifyNever(() => user.delete());
    verify(() => auth.signOut()).called(1);
  });

  test('rejected profile write rolls back only the newly created auth account',
      () async {
    when(() => document.set(any())).thenThrow(FirebaseException(
        plugin: 'cloud_firestore', code: 'permission-denied'));
    await expectLater(
        register(),
        throwsA(isA<AccountSetupException>()
            .having((e) => e.message, 'message', contains('rolled back'))));
    verify(() => user.delete()).called(1);
    verify(() => auth.signOut()).called(1);
  });

  test('failed rollback reports retained account', () async {
    when(() => document.set(any())).thenThrow(FirebaseException(
        plugin: 'cloud_firestore', code: 'permission-denied'));
    when(() => user.delete())
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(
        register(),
        throwsA(isA<AccountSetupException>().having(
            (e) => e.message, 'message', contains('Do not register again'))));
  });

  test('ambiguous write failure does not delete a possibly valid account',
      () async {
    when(() => document.set(any())).thenThrow(TimeoutException('Offline'));
    await expectLater(register(), throwsA(isA<AccountSetupException>()));
    verifyNever(() => user.delete());
  });

  test('duplicate registration never deletes an existing account', () async {
    when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    await expectLater(register(), throwsA(isA<FirebaseAuthException>()));
    verifyNever(() => user.delete());
    verifyNever(() => document.set(any()));
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
}
