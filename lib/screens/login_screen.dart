import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../widgets/custom_back_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool loading = false;

  Future<void> login() async {
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

      // CHECK IF USER EXISTS IN FIRESTORE
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // ADMIN ACCOUNT EXCEPTION
      final isAdmin =
          email.toLowerCase() == 'adminfitv@gmail.com';

      if (userDoc.docs.isEmpty && !isAdmin) {
        showMessage('This account has been removed by admin');
        return;
      }

      final role = await AuthService.loginAndGetRole(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(
          context,
          '/adminDashboard',
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/tryOnMethod',
        );
      }
    } catch (e) {
      showMessage('Incorrect email or password');
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
        child: Center(
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
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
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(58),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'LOGIN',
                            style: TextStyle(fontSize: 21),
                          ),
                        ),

                        const SizedBox(height: 24),

                        label('Email'),

                        field(
                          emailController,
                          'Name@gmail.com',
                          keyboard:
                              TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 10),

                        label('Password'),

                        passwordField(),

                        const SizedBox(height: 8),

                        Align(
                          alignment:
                              Alignment.centerRight,
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
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Center(
                          child: SizedBox(
                            width: 135,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : login,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(7),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                        fontWeight:
                                            FontWeight
                                                .bold,
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
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
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
    TextInputType keyboard =
        TextInputType.text,
  }) {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget passwordField() {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: passwordController,
        obscureText: hidePassword,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              hidePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                hidePassword =
                    !hidePassword;
              });
            },
          ),
        ),
      ),
    );
  }
}