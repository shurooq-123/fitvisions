import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/login_notification_service.dart';
import '../widgets/prototype_ui.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool hidePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (loading) return;
    if (!AuthService.isValidEmail(emailController.text) ||
        passwordController.text.trim().isEmpty) {
      showMessage('Please enter a valid email and password');
      return;
    }
    setState(() => loading = true);
    try {
      final role = await AuthService.loginAndGetRole(
        email: emailController.text,
        password: passwordController.text,
      );
      if (role != 'admin') {
        await AuthService.logout();
        if (mounted) showMessage('This account does not have admin access');
        return;
      }
      final emailSent = await LoginNotificationService.send();
      if (!mounted) return;
      if (!emailSent) showMessage('Signed in, but the login email could not be sent.');
      Navigator.pushReplacementNamed(context, '/adminDashboard');
    } catch (e) {
      if (mounted) {
        showMessage(AuthService.errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      nav: false,
      child: Column(children: [
        const PrototypeLogo(width: 235),
        const SizedBox(height: 25),
        PrototypePanel(
            radius: 58,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(
                  child: Text('Admin Login', style: TextStyle(fontSize: 22))),
              const SizedBox(height: 30),
              const Text('Email'),
              const SizedBox(height: 12),
              SizedBox(
                  height: 34,
                  child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          hintText: 'admin@example.com',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero)))),
              const SizedBox(height: 28),
              const Text('Password'),
              const SizedBox(height: 12),
              SizedBox(
                  height: 34,
                  child: TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero),
                          suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18),
                              onPressed: () => setState(
                                  () => hidePassword = !hidePassword))))),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/adminForgot'),
                      child: const Text('Forget Password ?',
                          style:
                              TextStyle(color: Colors.black87, fontSize: 12)))),
              Center(
                  child: PrototypeButton(loading ? 'Signing in...' : 'LOGIN',
                      onPressed: loading ? null : login)),
              const SizedBox(height: 70),
            ])),
      ]));
}
