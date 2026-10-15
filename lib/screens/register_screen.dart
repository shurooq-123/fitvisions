import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/custom_back_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const bg = Color(0xFFCED1C6);
  static const brown = Color(0xFF574543);

  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  Future<void> register() async {
    if (loading) return;
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => loading = true);

      await AuthService.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: mobileController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Account created. A verification email has been requested. Check your inbox and spam folder.'),
          backgroundColor: brown,
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.errorMessage(e)),
          backgroundColor: brown,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const CustomBackButton(),
                    Image.asset(
                      'images/fv.png',
                      width: 210,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 295,
                      padding: const EdgeInsets.fromLTRB(26, 18, 26, 26),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(58),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'REGISTER',
                              style: TextStyle(fontSize: 21),
                            ),
                          ),
                          const SizedBox(height: 18),
                          label('First Name'),
                          normalField(
                            controller: firstNameController,
                            hint: '',
                            validator: (value) {
                              final name = value!.trim();

                              if (name.isEmpty) {
                                return 'First name is required';
                              }

                              if (!RegExp(
                                r'^[a-zA-Z\u0600-\u06FF]{1,15}$',
                              ).hasMatch(name)) {
                                return 'Only one word and maximum 15 letters';
                              }

                              return null;
                            },
                          ),
                          label('Last Name'),
                          normalField(
                            controller: lastNameController,
                            hint: '',
                            validator: (value) {
                              final name = value!.trim();

                              if (name.isEmpty) {
                                return 'Last name is required';
                              }

                              if (!RegExp(
                                r'^[a-zA-Z\u0600-\u06FF]{1,15}$',
                              ).hasMatch(name)) {
                                return 'Only one word and maximum 15 letters';
                              }

                              return null;
                            },
                          ),
                          label('Mobile Number'),
                          phoneField(),
                          label('Email'),
                          normalField(
                            controller: emailController,
                            hint: 'name@gmail.com',
                            keyboard: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value!.trim();

                              if (email.isEmpty) {
                                return 'Email is required';
                              }

                              if (!AuthService.isValidEmail(email)) {
                                return 'Enter a valid email address';
                              }

                              return null;
                            },
                          ),
                          label('Password'),
                          passwordField(
                            controller: passwordController,
                            hide: hidePassword,
                            onTap: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            validator: (value) {
                              final password = value!.trim();

                              if (password.isEmpty) {
                                return 'Password is required';
                              }

                              if (!AuthService.isValidPassword(password)) {
                                return '8-15 chars, uppercase, lowercase, special char';
                              }

                              return null;
                            },
                          ),
                          label('Confirm Password'),
                          passwordField(
                            controller: confirmPasswordController,
                            hide: hideConfirmPassword,
                            onTap: () {
                              setState(() {
                                hideConfirmPassword = !hideConfirmPassword;
                              });
                            },
                            validator: (value) {
                              final confirmPassword = value!.trim();

                              if (confirmPassword.isEmpty) {
                                return 'Confirm password is required';
                              }

                              if (confirmPassword !=
                                  passwordController.text.trim()) {
                                return 'Passwords do not match';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Password: 8-15 chars, uppercase, lowercase, special character',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 135,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: loading ? null : register,
                                style: ElevatedButton.styleFrom(
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
                                        'Sign up',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget normalField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        errorStyle: const TextStyle(
          fontSize: 10,
          height: 0.9,
        ),
      ),
    );
  }

  Widget phoneField() {
    return TextFormField(
      controller: mobileController,
      keyboardType: TextInputType.number,
      maxLength: 8,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;

          if (text.isEmpty) {
            return newValue;
          }

          if (!text.startsWith('7') && !text.startsWith('9')) {
            return oldValue;
          }

          return newValue;
        }),
      ],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        final phone = value!.trim();

        if (phone.isEmpty) {
          return 'Mobile number is required';
        }

        if (!RegExp(r'^[79][0-9]{7}$').hasMatch(phone)) {
          return 'Number must start with 7 or 9 and contain 8 digits';
        }

        return null;
      },
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Padding(
            padding: EdgeInsets.only(left: 8, right: 4), child: Text('+968 ')),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        counterText: '',
        hintText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: TextStyle(
          fontSize: 10,
          height: 0.9,
        ),
      ),
    );
  }

  Widget passwordField({
    required TextEditingController controller,
    required bool hide,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hide,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        hintText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        errorStyle: const TextStyle(
          fontSize: 10,
          height: 0.9,
        ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            hide ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}
