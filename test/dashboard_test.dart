import 'package:fitvisions/screens/admin_login_screen.dart';
import 'package:fitvisions/screens/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('User dashboard fits a phone and opens the try-on flow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: const UserHomeScreen(),
      routes: {
        '/generateAvatar': (_) =>
            const Scaffold(body: Text('Try-on destination'))
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('User Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Generate Avatar'));
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Try-on destination'), findsOneWidget);
  });

  testWidgets('Empty admin credentials cannot open the dashboard',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const AdminLoginScreen(),
      routes: {
        '/adminDashboard': (_) =>
            const Scaffold(body: Text('Admin destination'))
      },
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('Admin destination'), findsNothing);
    expect(
        find.text('Please enter a valid email and password'), findsOneWidget);
  });
}
