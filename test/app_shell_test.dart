import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/app_shell.dart';

void main() {
  testWidgets(
      'Signed-in header tooltip has an Overlay above the route navigator',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final mode = ValueNotifier(ThemeMode.light);
    addTearDown(mode.dispose);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (_, value, __) => MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: value,
        builder: (_, child) => AppShell(
            header: Material(
                child: Row(children: [
              const Expanded(child: Text('Signed-in user')),
              IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications),
                  onPressed: () => navigator.currentState!.push(
                      MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                              body: Text('Notification history'))))),
            ])),
            child: child!),
        home: const Scaffold(body: Text('Home page')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.longPress(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();
    expect(find.text('Notification history'), findsOneWidget);
    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(find.text('Notification history'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home page'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
