import '../widgets/prototype_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const bg = Color(0xFFCED1C6);
  static const brown = Color(0xFF574543);
  static const purple = Color(0xFF51227D);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return PrototypePage(
        title: 'Profile',
        index: 1,
        child: user == null
            ? const Text('No user logged in')
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                        'Could not load profile. Please try again.');
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CircularProgressIndicator();
                  }
                  final data =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final name =
                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                          .trim();
                  return Column(children: [
                    PrototypePanel(
                        radius: 30,
                        padding: 12,
                        child: Column(children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(children: [
                                const Icon(Icons.account_circle,
                                    size: 65, color: purple),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(name.isEmpty ? 'User' : name),
                                      const SizedBox(height: 5),
                                      Text(data['email'] ?? user.email ?? '',
                                          style: const TextStyle(fontSize: 12)),
                                      if ((data['phone'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text('+968 ${data['phone']}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                    ]))
                              ])),
                          group([
                            menu(context, Icons.history, 'My History',
                                '/history'),
                            menu(context, Icons.workspace_premium,
                                'Subscription', '/subscription'),
                            menu(context, Icons.payment, 'Payment', '/payment'),
                          ]),
                          const SizedBox(height: 12),
                          if (!user.emailVerified)
                            TextButton.icon(
                              icon: const Icon(Icons.mark_email_unread_outlined),
                              label: const Text('Send verification email'),
                              onPressed: () async {
                                try {
                                  await user.reload();
                                  final current = FirebaseAuth.instance.currentUser;
                                  if (current == null) return;
                                  if (!current.emailVerified) {
                                    await current.sendEmailVerification();
                                  }
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(current.emailVerified
                                        ? 'Your email is already verified.'
                                        : 'Verification email requested. Check your inbox and spam folder.'),
                                  ));
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(AuthService.errorMessage(error)),
                                  ));
                                }
                              },
                            ),
                          group([
                            menu(context, Icons.lock_outline, 'Change Password',
                                '/changePassword'),
                            menu(context, Icons.help_outline, 'Help & support',
                                '/feedback'),
                            menu(context, Icons.info_outline, 'About Us',
                                '/about'),
                          ]),
                        ])),
                    const SizedBox(height: 25),
                    PrototypeButton('Logout', onPressed: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (_) => false);
                    }),
                  ]);
                }));
  }

  Widget group(List<Widget> children) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(25)),
      child: Column(children: children));
  Widget menu(BuildContext context, IconData icon, String text, String route) =>
      ListTile(
          dense: true,
          leading: Icon(icon, color: purple, size: 23),
          title: Text(text,
              style: const TextStyle(fontFamily: 'serif', fontSize: 16)),
          trailing:
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 23),
          onTap: () => Navigator.pushNamed(context, route));
}
