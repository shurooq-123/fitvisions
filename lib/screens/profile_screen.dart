import '../widgets/subscription_summary.dart';
import '../widgets/prototype_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/appearance.dart';
import '../constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return PrototypePage(
        title: 'Profile',
        index: 1,
        child: Column(children: [
          const _AppearanceSwitch(),
          const SizedBox(height: 18),
          user == null
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(children: [
                                  Icon(Icons.account_circle,
                                      size: 65,
                                      color: AppColors.accent(context)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(name.isEmpty ? 'User' : name),
                                        const SizedBox(height: 5),
                                        Text(data['email'] ?? user.email ?? '',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        if ((data['phone'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                              '${data['phone']}'.startsWith('+')
                                                  ? '${data['phone']}'
                                                  : '+968 ${data['phone']}',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                      ]))
                                ])),
                            group(context, [
                              menu(context, Icons.history, 'My History',
                                  '/history'),
                              menu(context, Icons.workspace_premium,
                                  'Subscription', '/subscription',
                                  onTap: () =>
                                      showSubscriptionDetails(context)),
                              menu(
                                  context, Icons.payment, 'Payment', '/payment',
                                  onTap: () => showSubscriptionDetails(context,
                                      showPayment: true)),
                            ]),
                            const SizedBox(height: 12),
                            group(context, [
                              menu(context, Icons.lock_outline,
                                  'Change Password', '/changePassword'),
                              menu(context, Icons.help_outline,
                                  'Help & support', '/feedback'),
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
                  }),
        ]));
  }

  Widget group(BuildContext context, List<Widget> children) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.muted(context)),
          borderRadius: BorderRadius.circular(25)),
      child: Column(children: children));
  Future<void> showSubscriptionDetails(BuildContext context,
      {bool showPayment = false}) {
    return showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(showPayment ? 'Payment details' : 'Subscription'),
              scrollable: true,
              content: SubscriptionSummary(
                showPayment: showPayment,
                onChoosePlan: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushNamed(context, '/subscription');
                },
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close')),
              ],
            ));
  }

  Widget menu(BuildContext context, IconData icon, String text, String route,
          {VoidCallback? onTap}) =>
      ListTile(
          dense: true,
          leading: Icon(icon, color: AppColors.accent(context), size: 23),
          title: Text(text,
              style: const TextStyle(fontFamily: 'serif', fontSize: 16)),
          trailing:
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 23),
          onTap: onTap ?? () => Navigator.pushNamed(context, route));
}

class _AppearanceSwitch extends StatelessWidget {
  const _AppearanceSwitch();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PrototypePanel(
      radius: 24,
      padding: 4,
      child: SwitchListTile(
        title: const Text('Dark mode'),
        subtitle: Text(dark ? 'Dark' : 'Light'),
        secondary:
            Icon(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
        value: dark,
        onChanged: Appearance.setDark,
      ),
    );
  }
}
