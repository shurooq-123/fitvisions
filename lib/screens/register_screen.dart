import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../services/phone_validation.dart';
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
  Country phoneCountry = Country.parse('OM');

  Future<void> register() async {
    if (loading) return;
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => loading = true);

      final emailSent = await AuthService.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: internationalMobile(
            mobileController.text.trim(), phoneCountry.countryCode)!,
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailSent
              ? 'Account created successfully. A confirmation email has been sent.'
              : 'Account created successfully. The confirmation email could not be sent. You can log in.'),
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
                                return 'At least 8 chars, uppercase, lowercase, number, special char';
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
                            'Password: At least 8 chars, uppercase, lowercase, number, special character',
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

  Widget phoneField() => Column(children: [
        Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${phoneCountry.name} (+${phoneCountry.phoneCode})',
                  style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  onSelect: (country) => setState(() {
                        phoneCountry = country;
                        mobileController.clear();
                      })),
            )),
        TextFormField(
          controller: mobileController,
          keyboardType: TextInputType.phone,
          maxLength: phoneCountry.countryCode == 'OM' ? 8 : 15,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mobile number is required';
            }
            if (internationalMobile(value, phoneCountry.countryCode) == null) {
              return phoneCountry.countryCode == 'OM'
                  ? 'Enter a valid 8-digit Oman mobile number'
                  : 'Enter a valid mobile number for ${phoneCountry.name}';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixText: '+${phoneCountry.phoneCode} ',
            helperText: phoneCountry.countryCode == 'OM'
                ? '8 digits'
                : 'Local mobile number without country code',
            helperMaxLines: 2,
            errorMaxLines: 3,
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      ]);

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
