import '../services/app_language.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key});
  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null) return const SizedBox.shrink();
          return Material(
              color: AppColors.page(context, const Color(0xFFCED1C6)),
              child: SafeArea(
                  bottom: false,
                  child: Row(children: [
                    Expanded(
                        child: StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                            builder: (_, snapshot) {
                              final d = snapshot.data?.data();
                              final name =
                                  '${d?['firstName'] ?? ''} ${d?['lastName'] ?? ''}'
                                      .trim();
                              return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: AccountName(name.isEmpty
                                      ? (user.displayName ?? 'FitVisions')
                                      : name));
                            })),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('uid', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (_, snapshot) {
                          final count = snapshot.data?.docs
                                  .where((d) => d.data()['read'] != true)
                                  .length ??
                              0;
                          return IconButton(
                              tooltip: tr('Notifications ($count unread)'),
                              onPressed: () => NotificationService
                                  .navigator.currentState!
                                  .pushNamed('/notifications'),
                              icon: Badge(
                                  isLabelVisible: count > 0,
                                  label: AppText('$count'),
                                  child: const Icon(
                                      Icons.notifications_outlined)));
                        }),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (_, snapshot) =>
                            snapshot.data?.data()?['role'] == 'admin'
                                ? IconButton(
                                    tooltip: tr('Download and share reports'),
                                    icon:
                                        const Icon(Icons.description_outlined),
                                    onPressed: () => NotificationService
                                        .navigator.currentState!
                                        .pushNamed('/reports'))
                                : const SizedBox.shrink()),
                  ])));
        });
  }
}

/// Keep user-entered names literal in both languages, with the full name
/// available to accessibility services even if the visible text is truncated.
class AccountName extends StatelessWidget {
  const AccountName(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) => Semantics(
        label: name,
        excludeSemantics: true,
        child: Tooltip(
            message: name,
            child: Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600))),
      );
}
