import '../constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_user_subscriptions_screen.dart';
import 'admin_system_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.firestore});

  final FirebaseFirestore? firestore;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const bg = Color(0xFFD5DBCD);
  static const brown = Color(0xFF574543);
  static const purple = Color(0xFF51227D);
  static const panel = Color(0xFFF4F4F4);

  late final db = widget.firestore ?? FirebaseFirestore.instance;
  late final users = db.collection('users').snapshots();
  late final payments = db.collection('payments').snapshots();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.page(context, bg),
        bottomNavigationBar: adminBottomNav(context, 0),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _dashboardHeader(context)),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: users,
                      builder: (context, snapshot) => _statBox(
                        Icons.groups,
                        'Total Users',
                        snapshot.data?.docs.length.toString() ??
                            (snapshot.hasError ? 'Unavailable' : '…'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminUserSubscriptionsScreen(firestore: db),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: payments,
                      builder: (context, snapshot) {
                        final total =
                            snapshot.data?.docs.fold<num>(0, (sum, doc) {
                          final data = doc.data();
                          return data['status'] == 'pending' &&
                                  data['amount'] is num
                              ? sum + (data['amount'] as num)
                              : sum;
                        });
                        return _statBox(
                          Icons.stacked_line_chart,
                          'Demo Revenue',
                          total == null
                              ? (snapshot.hasError ? 'Unavailable' : '…')
                              : '${total.toStringAsFixed(2)} OMR',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _managementButtons(context),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 18),
                    _logoutButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _dashboardHeader(BuildContext context) => Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios,
                    size: 32, color: AppColors.ink(context)),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account settings',
                onSelected: (_) =>
                    Navigator.pushNamed(context, '/changePassword'),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'password', child: Text('Change password')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Admin Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
        ],
      );

  Widget _statBox(IconData icon, String label, String value,
          {VoidCallback? onTap}) =>
      SizedBox(
        width: 250,
        child: Material(
          color: AppColors.panel(context, panel),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Icon(icon,
                      color: AppColors.accent(context, purple), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                          ))),
                  Text(value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      )),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppColors.accent(context, purple)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  Widget _managementButtons(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        decoration: BoxDecoration(
            color: AppColors.panel(context, panel),
            borderRadius: BorderRadius.circular(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dashboardButton('Manage Users',
                () => Navigator.pushNamed(context, '/adminUsers')),
            const SizedBox(height: 16),
            _dashboardButton('Manage System',
                () => Navigator.pushNamed(context, '/adminSystem')),
          ],
        ),
      );

  Widget _dashboardButton(String label, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          side: BorderSide(color: AppColors.ink(context)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink(context),
                      fontSize: 16,
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                    ))),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 28),
          ],
        ),
      );

  Widget _logoutButton(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: SizedBox(
            width: 120,
            height: 42,
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
              child: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
}

Widget adminBottomNav(BuildContext context, int index) {
  const purple = Color(0xFF51227D);

  return BottomNavigationBar(
    currentIndex: index,
    selectedItemColor: AppColors.ink(context),
    unselectedItemColor: AppColors.ink(context),
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppColors.panel(context, Colors.white),
    onTap: (i) {
      if (i == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      } else if (i == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminUsersScreen(),
          ),
        );
      } else if (i == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminSystemScreen(),
          ),
        );
      }
    },
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.stacked_line_chart,
            color: AppColors.accent(context, purple)),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.groups, color: AppColors.accent(context, purple)),
        label: 'Users',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings, color: AppColors.accent(context, purple)),
        label: 'System',
      ),
    ],
  );
}
