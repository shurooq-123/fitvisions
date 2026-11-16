// ignore_for_file: subtype_of_sealed_class
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitvisions/screens/history_screen.dart';
class LibrarySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class LibraryDoc extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
void main() {
  testWidgets('Original history layout shows results and subscriptions together', (tester) async {
    final snapshot = LibrarySnapshot();
    final docs = <LibraryDoc>[];
    for (final kind in ['avatar', 'clothes', 'subscription']) {
      final doc = LibraryDoc();
      when(() => doc.id).thenReturn(kind);
      when(() => doc.data()).thenReturn({'title': kind, 'kind': kind, 'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1))});
      docs.add(doc);
    }
    when(() => snapshot.docs).thenReturn(docs);
    await tester.pumpWidget(MaterialApp(home: HistoryScreen(history: Stream.value(snapshot))));
    await tester.pumpAndSettle();
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('My Library & History'), findsNothing);
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(find.textContaining('avatar'), findsOneWidget);
    expect(find.textContaining('subscription'), findsOneWidget);
    expect(find.byTooltip('Favorite'), findsNothing);
  });
}
