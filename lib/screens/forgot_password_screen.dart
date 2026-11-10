import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/prototype_ui.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/custom_back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const bg = Color(0xFFCED1C6);
  static const brown = Color(0xFF574543);

  final emailController = TextEditingController();
  bool loading = false;

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();
    if (!AuthService.isValidEmail(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.sendResetLink(email);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Check your email'),
          content: const Text(
            'If an account exists, you will receive a FitVisions email. '
            'Open the newest link to choose a different password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'user-not-found') {
        showMessage('If an account exists, check your inbox for a reset link.');
      } else {
        showMessage(AuthService.errorMessage(error));
      }
    } catch (error) {
      if (mounted) showMessage(AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openCopiedResetLink() async {
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final link = clipboard?.text?.trim();
      if (link == null || link.isEmpty) {
        showMessage('Copy the reset link from your FitVisions email first.');
        return;
      }
      await const MethodChannel('fitvisions/password-reset')
          .invokeMethod<void>('openResetLink', link);
    } on PlatformException catch (error) {
      if (!mounted) return;
      showMessage(error.code == 'invalid_link'
          ? 'Copy the reset link from your FitVisions email first.'
          : 'Could not open the reset link.');
    } catch (_) {
      if (mounted) showMessage('Could not open the reset link.');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: brown,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
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
                  TextButton(
                    onPressed: loading ? null : openCopiedResetLink,
                    child: const Text('Open copied reset link'),
                  ),
                  Image.asset('images/fv.png', width: 180),
                  const SizedBox(height: 30),
                  Container(
                    width: 295,
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(58),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'FORGET PASSWORD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Enter your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'name@gmail.com',
                            filled: true,
                            fillColor: Colors.white,
                            border: prototypeFieldBorder,
                            contentPadding: prototypeFieldPadding,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: loading ? null : sendResetLink,
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
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Send Link',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
}
