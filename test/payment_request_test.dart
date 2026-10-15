import 'package:fitvisions/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Payment without a subscription redirects to plan selection and collects no card data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: const PaymentScreen(), routes: {
      '/subscription': (_) => const Scaffold(body: Text('Plan selection')),
    }));
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('No money will be charged'), findsOneWidget);
    await tester.ensureVisible(find.text('Choose subscription'));
    await tester.tap(find.text('Choose subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Plan selection'), findsOneWidget);
  });
}
