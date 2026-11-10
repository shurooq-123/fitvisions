import 'package:flutter/material.dart';
import '../widgets/prototype_ui.dart';

import '../services/auth_service.dart';
import '../services/login_notification_service.dart';
import '../widgets/custom_back_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const bg = Color(0xFFCED1C6);
  static const brown = Color(0xFF574543);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool loading = false;

  Future<void> login() async {
    if (loading) return;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    if (!AuthService.isValidEmail(email)) {
      showMessage('Invalid email format');
      return;
    }

    try {
      setState(() => loading = true);

      final role = await AuthService.loginAndGetRole(
        email: email,
        password: password,
      );

      final emailSent = await LoginNotificationService.send();
      if (!mounted) return;
      if (!emailSent)
        showMessage('Signed in, but the login email could not be sent.');

      if (role == 'admin') {
        Navigator.pushReplacementNamed(
          context,
          '/adminDashboard',
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      }
    } catch (e) {
      if (mounted) showMessage(AuthService.errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: brown,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                children: [
                  const CustomBackButton(),
                  Image.asset(
                    'images/fv.png',
                    width: 190,
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: 295,
                    padding: const EdgeInsets.fromLTRB(
                      26,
                      18,
                      26,
                      26,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(58),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'LOGIN',
                            style: TextStyle(fontSize: 21),
                          ),
                        ),
                        const SizedBox(height: 24),
                        label('Email'),
                        const SizedBox(height: 5),
                        field(
                          emailController,
                          'name@gmail.com',
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        label('Password'),
                        const SizedBox(height: 5),
                        passwordField(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/forgot',
                              );
                            },
                            child: const Text(
                              'Forget Password ?',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: SizedBox(
                            width: 135,
                            child: ElevatedButton(
                              onPressed: loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                backgroundColor: brown,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/register',
                              );
                            },
                            child: const Text(
                              'Don’t have an account? Sign Up',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget field(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: prototypeFieldPadding,
        border: prototypeFieldBorder,
      ),
    );
  }

  Widget passwordField() {
    return TextField(
      controller: passwordController,
      obscureText: hidePassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: prototypeFieldPadding,
        border: prototypeFieldBorder,
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            hidePassword ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
          onPressed: () {
            setState(() {
              hidePassword = !hidePassword;
            });
          },
        ),
      ),
    );
  }
}
