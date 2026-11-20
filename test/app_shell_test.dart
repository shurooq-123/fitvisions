import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/app_shell.dart';

void main() {
  testWidgets('Shared header stays visible while page scrolls', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => AppShell(header: const Material(child: SizedBox(height:48, child: Text('Fixed account header'))), child:child!),
      home: Scaffold(body: ListView(children: List.generate(60, (i)=>SizedBox(height:60, child:Text('Row $i'))))),
    ));
    final before=tester.getTopLeft(find.text('Fixed account header'));
    await tester.drag(find.byType(ListView),const Offset(0,-700));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Fixed account header')),before);
    expect(find.text('Fixed account header').hitTestable(),findsOneWidget);
  });
  testWidgets('Home ignores system back but explicit pop can leave a child', (tester) async {
    final key=GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey:key, home:const PopScope(canPop:false,child:Scaffold(body:Text('Signed-in home')))));
    await tester.binding.handlePopRoute();await tester.pumpAndSettle();
    expect(find.text('Signed-in home'),findsOneWidget);
    key.currentState!.push(MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('Details'))));
    await tester.pumpAndSettle();key.currentState!.pop();await tester.pumpAndSettle();
    expect(find.text('Signed-in home'),findsOneWidget);
  });

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
