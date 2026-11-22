import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/app_shell.dart';
import 'package:fitvisions/widgets/prototype_ui.dart';
import 'package:fitvisions/screens/ai_assistance_screen.dart';

void main() {
  testWidgets(
      'Four tabs stay visible across scrolling, child routes and support without duplication',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        builder: (_, child) => AppShell(
            header: const SizedBox.shrink(),
            footer: PrototypeNav(navigatorKey: nav),
            child: child!),
        routes: {
          '/': (_) => Scaffold(
              body: ListView(
                  children: List.generate(
                      40, (i) => SizedBox(height: 70, child: Text('Row $i')))),
              bottomNavigationBar: const PrototypeNav()),
          '/home': (_) => const Scaffold(body: Text('Home page')),
          '/profile': (_) => const Scaffold(body: Text('Profile page')),
          '/history': (_) => const Scaffold(body: Text('History page')),
          '/helpSupport': (_) => const AiAssistanceScreen(),
        }));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .items
            .length,
        4);
    final position = tester.getTopLeft(find.byType(BottomNavigationBar));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(BottomNavigationBar)), position);
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Payment details'))));
    await tester.pumpAndSettle();
    expect(find.text('Chatbot').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Chatbot'));
    await tester.pumpAndSettle();
    expect(find.text('Help & support'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byType(BottomNavigationBar)).dy,
        lessThanOrEqualTo((tester.view.physicalSize.height - 240) / tester.view.devicePixelRatio));
    expect(tester.takeException(), isNull);
  });
}
