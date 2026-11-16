import 'package:fitvisions/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Payment without a subscription redirects to plan selection and offers editable demo fields',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: const PaymentScreen(), routes: {
      '/subscription': (_) => const Scaffold(body: Text('Plan selection')),
    }));
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.textContaining('No money will be charged'), findsOneWidget);
    await tester.ensureVisible(find.text('Choose subscription'));
    await tester.tap(find.text('Choose subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Plan selection'), findsOneWidget);
  });
  testWidgets('Payment validates input and submits only subscription ID',
      (tester) async {
    String? saved;
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (_) => MaterialPageRoute(
        settings: const RouteSettings(arguments: {'subscriptionId': 'sub-1'}),
        builder: (_) => PaymentScreen(saveRequest: (id) async {
          saved = id;
        }),
      ),
      routes: {'/feedback': (_) => const Scaffold(body: Text('Feedback'))},
    ));
    await tester.ensureVisible(find.text('Pay'));
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    final fields = find.byType(TextFormField);
    for (final entry in {0: '12345', 1: '4242424242424242', 3: '123'}.entries) {
      await tester.ensureVisible(fields.at(entry.key));
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.ensureVisible(find.text('Pay'));
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Card Holder Name'), findsOneWidget);
    expect(saved, isNull);

    for (final entry in {
      1: '-4242424242424242',
      3: '103',
    }.entries) {
      await tester.ensureVisible(fields.at(entry.key));
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    String inputAt(int index) =>
        tester.widget<TextFormField>(fields.at(index)).controller!.text;
    expect(inputAt(1), '4242424242424242');
    expect(inputAt(3), '123');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), '4242424242424240');
    expect(inputAt(1), '4242424242424242');
    await tester.ensureVisible(fields.first);
    await tester.enterText(fields.first, 'Test User');
    await tester.ensureVisible(find.text('Pay'));
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Expiry Date'), findsOneWidget);
    expect(saved, isNull);
    await tester.ensureVisible(fields.at(2));
    expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text, isEmpty);
    await tester.tap(fields.at(2));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    final picker =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    final now = DateTime.now();
    final first = DateTime(now.year, now.month + 1);
    expect(picker.firstDate, first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
        inputAt(2),
        '${first.month.toString().padLeft(2, '0')}/'
        '${(first.year % 100).toString().padLeft(2, '0')}');
    await tester.ensureVisible(find.text('Pay'));
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(saved, 'sub-1');
  });
}
