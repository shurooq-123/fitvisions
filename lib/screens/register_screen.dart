import '../widgets/fashion_backdrop.dart';
import '../services/app_language.dart';
import '../constants/app_colors.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../widgets/prototype_ui.dart';
import 'package:country_picker/country_picker.dart';
import '../services/phone_validation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/custom_back_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const bg = Color(0xFFFAF0F3);
  static const brown = Color(0xFF85465F);

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
  bool emailConfirmed = false;
  bool linkSent = false;
  bool checkingConfirmation = false;
  Timer? confirmationTimer;
  static const pendingEmailKey = 'fitvisions.registrationEmail';
  static const pendingRequestKey = 'fitvisions.registrationRequest';
  static ({
    String id,
    String firstName,
    String lastName,
    String phone,
    String password
  })? pendingForm;
  Country phoneCountry = Country.parse('OM');

  @override
  void initState() {
    super.initState();
    _restorePendingRequest();
  }

  Future<void> _restorePendingRequest() async {
    final SharedPreferences preferences;
    try {
      preferences = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }
    final email = preferences.getString(pendingEmailKey);
    final id = preferences.getString(pendingRequestKey);
    if (!mounted || email == null || id == null || loading) return;
    emailController.text = email;
    _waitForConfirmation(id, email, preferences);
  }

  Future<void> _clearPendingRequest(SharedPreferences preferences) async {
    confirmationTimer?.cancel();
    pendingForm = null;
    await preferences.remove(pendingRequestKey);
    await preferences.remove(pendingEmailKey);
    if (mounted) setState(() => linkSent = false);
  }

  Future<void> _cancelWaiting() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted || loading) return;
    await _clearPendingRequest(preferences);
  }

  void _waitForConfirmation(
      String id, String email, SharedPreferences preferences) {
    confirmationTimer?.cancel();
    setState(() => linkSent = true);
    confirmationTimer = Timer.periodic(const Duration(seconds: 5),
        (_) => _checkConfirmation(id, email, preferences));
  }

  Future<void> _checkConfirmation(
      String id, String email, SharedPreferences preferences) async {
    if (!mounted || loading || checkingConfirmation) return;
    checkingConfirmation = true;
    try {
      final result = await AuthService.registrationStatus(id);
      if (!mounted || id != preferences.getString(pendingRequestKey)) return;
      if (result.status == 'pending') return;
      if (result.status == 'declined' || result.status == 'expired') {
        await _clearPendingRequest(preferences);
        if (mounted) {
          _showMessage(result.status == 'declined'
              ? 'Registration cancelled.'
              : 'The confirmation request expired. Press Register to request a new link.');
        }
      } else if (result.status == 'approved' && result.link != null) {
        await _finishConfirmedRegistration(
            id, email, result.link!, preferences);
      }
    } catch (_) {
      // Keep checking if the connection is briefly unavailable.
    } finally {
      checkingConfirmation = false;
    }
  }

  Future<void> _finishConfirmedRegistration(String id, String email,
      String link, SharedPreferences preferences) async {
    confirmationTimer?.cancel();
    setState(() => loading = true);
    try {
      await AuthService.confirmRegistrationEmail(email, link);
      if (!mounted) return;
      emailController.text = email;
      setState(() => emailConfirmed = true);
      final form = pendingForm;
      if (form == null || form.id != id) {
        _showMessage(
            'Email confirmed. Re-enter your details to complete registration.');
        return;
      }
      await _completeRegistration(form.firstName, form.lastName, form.phone,
          form.password, preferences);
    } catch (error) {
      if (mounted) {
        setState(() => linkSent = false);
        _showMessage(AuthService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: AppText(message), backgroundColor: brown),
    );
  }

  Future<void> _completeRegistration(String firstName, String lastName,
      String phone, String password, SharedPreferences preferences) async {
    await AuthService.registerUser(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password);
    pendingForm = null;
    await preferences.remove(pendingRequestKey);
    await preferences.remove(pendingEmailKey);
    if (!mounted) return;
    _showMessage('Registered successfully.');
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (route) => route.settings.name == '/');
  }

  Future<void> register() async {
    if (loading || (linkSent && !emailConfirmed)) return;
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => loading = true);

      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final phone = internationalMobile(
          mobileController.text.trim(), phoneCountry.countryCode)!;
      final password = passwordController.text.trim();
      final preferences = await SharedPreferences.getInstance();
      if (emailConfirmed) {
        await _completeRegistration(
            firstName, lastName, phone, password, preferences);
        return;
      }
      final random = Random.secure();
      final id = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      final email = emailController.text.trim();
      await AuthService.requestRegistrationLink(email, id);
      await preferences.setString(pendingEmailKey, email);
      await preferences.setString(pendingRequestKey, id);
      pendingForm = (
        id: id,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password
      );
      if (mounted) {
        _waitForConfirmation(id, email, preferences);
        _showMessage('Check your email and confirm the request.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    confirmationTimer?.cancel();
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
    AppLanguage.watch(context);
    return Scaffold(
      backgroundColor: AppColors.page(context, bg),
      body: FashionBackdrop(
          child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
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
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                      decoration: BoxDecoration(
                        color: AppColors.panel(context),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: AppText(
                              'REGISTER',
                              style: TextStyle(fontSize: 21),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (emailConfirmed)
                            const AppText(
                                'Email confirmed. Enter your details to finish.'),
                          label('First Name'),
                          normalField(
                            controller: firstNameController,
                            hint: '',
                            validator: (value) {
                              final name = value!.trim();

                              if (name.isEmpty) {
                                return tr('First name is required');
                              }

                              if (!RegExp(
                                r'^[a-zA-Z\u0600-\u06FF]{1,15}$',
                              ).hasMatch(name)) {
                                return tr(
                                    'Only one word and maximum 15 letters');
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
                                return tr('Last name is required');
                              }

                              if (!RegExp(
                                r'^[a-zA-Z\u0600-\u06FF]{1,15}$',
                              ).hasMatch(name)) {
                                return tr(
                                    'Only one word and maximum 15 letters');
                              }

                              return null;
                            },
                          ),
                          label('Mobile Number'),
                          phoneField(),
                          label('Email'),
                          normalField(
                            controller: emailController,
                            readOnly: emailConfirmed,
                            hint: 'name@gmail.com',
                            keyboard: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value!.trim();

                              if (email.isEmpty) {
                                return tr('Email is required');
                              }

                              if (!AuthService.isValidEmail(email)) {
                                return tr('Enter a valid email address');
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
                                return tr('Password is required');
                              }

                              if (!AuthService.isValidPassword(password)) {
                                return tr(
                                    'At least 8 chars, uppercase, lowercase, number, special char');
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
                                return tr('Confirm password is required');
                              }

                              if (confirmPassword !=
                                  passwordController.text.trim()) {
                                return tr('Passwords do not match');
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            'Password: At least 8 chars, uppercase, lowercase, number, special character',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.muted(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 135,
                              child: ElevatedButton(
                                onPressed:
                                    loading || (linkSent && !emailConfirmed)
                                        ? null
                                        : register,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  backgroundColor: brown,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
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
                                    : const AppText(
                                        'Register',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          if (linkSent && !emailConfirmed) ...[
                            const AppText(
                                'Waiting for your email confirmation. You can open it on another device.'),
                            TextButton(
                              onPressed: loading ? null : _cancelWaiting,
                              child: const AppText('Cancel request'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: AppText(
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
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      readOnly: readOnly,
      validator: (value) => trError(validator(value)),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        hintText: trError(hint),
        filled: true,
        fillColor: AppColors.field(context),
        contentPadding: prototypeFieldPadding,
        border: prototypeFieldBorder,
        errorStyle: const TextStyle(
          fontSize: 10,
          height: 1.2,
        ),
      ),
    );
  }

  Widget phoneField() => Column(children: [
        Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: AppText(
                  '${phoneCountry.getTranslatedName(context) ?? phoneCountry.name} (+${phoneCountry.phoneCode})',
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
              return tr('Mobile number is required');
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
            fillColor: AppColors.field(context),
            border: prototypeFieldBorder,
            contentPadding: prototypeFieldPadding,
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
      validator: (value) => trError(validator(value)),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        hintText: trError(''),
        filled: true,
        fillColor: AppColors.field(context),
        contentPadding: prototypeFieldPadding,
        border: prototypeFieldBorder,
        errorStyle: const TextStyle(
          fontSize: 10,
          height: 1.2,
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
