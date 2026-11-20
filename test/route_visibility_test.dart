import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/services/route_visibility.dart';
void main(){
 testWidgets('Public login and welcome hide account header after back navigation', (tester) async {
  final nav=GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(navigatorKey:nav,navigatorObservers:[RouteVisibility()],routes:{'/':(_)=>const Scaffold(),'/login':(_)=>const Scaffold(),'/home':(_)=>const Scaffold()}));
  await tester.pumpAndSettle();expect(RouteVisibility.publicPage.value,isTrue);
  nav.currentState!.pushNamed('/home');await tester.pumpAndSettle();expect(RouteVisibility.publicPage.value,isFalse);
  nav.currentState!.pop();await tester.pumpAndSettle();expect(RouteVisibility.publicPage.value,isTrue);
  nav.currentState!.pushNamed('/login');await tester.pumpAndSettle();expect(RouteVisibility.publicPage.value,isTrue);
 });
}
