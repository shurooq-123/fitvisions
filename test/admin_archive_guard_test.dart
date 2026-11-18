import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'prototype_layout_test.dart' show LayoutFirestore, LayoutCollection, LayoutQuery, records;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitvisions/screens/admin_users_screen.dart';

void main() {
  testWidgets('Active subscription blocks archival without deleting user or payment', (tester) async {
    final db = LayoutFirestore();
    final users = LayoutCollection();
    final payments = LayoutCollection();
    final query = LayoutQuery();
    when(() => db.collection('users')).thenReturn(users);
    when(() => db.collection('payments')).thenReturn(payments);
    when(() => users.snapshots()).thenAnswer((_) => Stream.value(records([{'firstName':'Test','lastName':'User','email':'test@example.com','role':'user'}])));
    when(() => payments.where('uid', isEqualTo:'sample-0')).thenReturn(query);
    when(() => query.get()).thenAnswer((_) async => records([{'uid':'sample-0','createdAt':Timestamp.fromDate(DateTime.now().subtract(const Duration(days:1))),'durationMonths':1,'status':'paid','amount':3}]));
    await tester.pumpWidget(MaterialApp(home:AdminUsersScreen(firestore:db)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.archive_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton,'Archive User'));
    await tester.pumpAndSettle();
    expect(find.text('This user has an active subscription. Wait until it expires.'), findsOneWidget);
    verify(() => query.get()).called(1);
    verifyNever(() => users.doc(any()));
  });
}
