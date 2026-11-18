import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/custom_back_button.dart';
import 'package:fitvisions/widgets/account_header.dart';
import 'package:fitvisions/screens/admin_dashboard_screen.dart';

void main() {
  testWidgets('Admin tabs retain dashboard and back returns to it',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    Widget page(BuildContext c, int index, String title) => Scaffold(
        body: Column(children: [Text(title), const CustomBackButton()]),
        bottomNavigationBar: adminBottomNav(c, index));
    await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        initialRoute: '/adminDashboard',
        routes: {
          '/': (c) => const Scaffold(),
          '/adminDashboard': (c) => page(c, 0, 'Dashboard page'),
          '/adminUsers': (c) => page(c, 1, 'Users page'),
          '/adminSystem': (c) => page(c, 2, 'System page'),
        }));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    expect(find.text('Users page'), findsOneWidget);
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(find.text('System page'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard page'), findsOneWidget);
  });
  testWidgets('Root back does not remove the only page', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CustomBackButton())));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomBackButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Long account name remains accessible at narrow width and large text',
      (tester) async {
    const name = 'Hooryaa Mohammed Alhadi Long Profile Name';
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: const SizedBox(width: 180, child: AccountName(name))))));
    expect(find.bySemanticsLabel(name), findsOneWidget);
    expect(find.byTooltip(name), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
