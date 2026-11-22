import 'persistent_user_navigation.dart';
import 'persistent_navigation_scope.dart';
import '../services/app_language.dart';
import 'package:flutter/material.dart';
import 'account_header.dart';

/// The account header sits above the route Navigator, so it needs its own
/// ancestor Overlay for tooltips. The route Navigator keeps its existing state.
class AppShell extends StatefulWidget {
  const AppShell(
      {super.key,
      required this.child,
      this.header = const AccountHeader(),
      this.footer = const PersistentUserNavigation()});
  final Widget child;
  final Widget header;
  final Widget footer;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final OverlayEntry entry = OverlayEntry(
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: Column(children: [
            widget.header,
            Expanded(child: PersistentNavigationScope(child: widget.child)),
            widget.footer,
          ])),
    ),
  );

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    entry.markNeedsBuild();
  }

  @override
  void dispose() {
    entry.remove();
    entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AppLanguage.observe(context, () => Overlay(initialEntries: [entry]));
}
