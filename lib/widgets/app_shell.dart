import '../services/app_language.dart';
import 'package:flutter/material.dart';
import 'account_header.dart';

/// The account header sits above the route Navigator, so it needs its own
/// ancestor Overlay for tooltips. The route Navigator keeps its existing state.
class AppShell extends StatefulWidget {
  const AppShell(
      {super.key, required this.child, this.header = const AccountHeader()});
  final Widget child;
  final Widget header;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final OverlayEntry entry = OverlayEntry(
    builder: (_) => Column(children: [
      widget.header,
      Expanded(child: widget.child),
    ]),
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
