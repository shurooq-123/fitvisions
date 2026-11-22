import 'package:flutter/material.dart';

/// Marks route content whose bottom navigation is supplied by the app shell.
class PersistentNavigationScope extends InheritedWidget {
  const PersistentNavigationScope({super.key, required super.child});
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PersistentNavigationScope>() !=
      null;
  @override
  bool updateShouldNotify(PersistentNavigationScope oldWidget) => false;
}
