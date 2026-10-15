import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';

// Admin accounts use the same Firebase email/password recovery flow.
class AdminForgotPasswordScreen extends StatelessWidget {
  const AdminForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen();
}
