import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/route_visibility.dart';
import '../services/notification_service.dart';
import 'prototype_ui.dart';

class PersistentUserNavigation extends StatelessWidget {
  const PersistentUserNavigation({super.key});
  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (_, auth) {
          final user = auth.data;
          if (user == null) return const SizedBox.shrink();
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (_, account) {
                if (account.data?.data()?['role'] == 'admin')
                  return const SizedBox.shrink();
                return ValueListenableBuilder<bool>(
                    valueListenable: RouteVisibility.publicPage,
                    builder: (_, publicPage, __) => publicPage
                        ? const SizedBox.shrink()
                        : ValueListenableBuilder<int>(
                            valueListenable: RouteVisibility.tabIndex,
                            builder: (_, index, __) => PrototypeNav(
                                index: index,
                                navigatorKey: NotificationService.navigator)));
              });
        });
  }
}
