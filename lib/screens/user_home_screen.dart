import 'package:flutter/material.dart';
import 'try_on_method_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TryOnMethodScreen(dashboard: true);
}
