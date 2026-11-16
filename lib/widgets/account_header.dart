import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key});
  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null) return const SizedBox.shrink();
          return Material(
              color: const Color(0xFFCED1C6),
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
                                  child: Text(
                                      name.isEmpty
                                          ? (user.displayName ?? 'FitVisions')
                                          : name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis));
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
                              tooltip: 'Notifications ($count unread)',
                              onPressed: () => NotificationService
                                  .navigator.currentState!
                                  .pushNamed('/notifications'),
                              icon: Badge(
                                  isLabelVisible: count > 0,
                                  label: Text('$count'),
                                  child: const Icon(
                                      Icons.notifications_outlined)));
                        }),
                    IconButton(
                        tooltip: 'Download and share reports',
                        icon: const Icon(Icons.description_outlined),
                        onPressed: () => NotificationService
                            .navigator.currentState!
                            .pushNamed('/reports')),
                  ])));
        });
  }
}
