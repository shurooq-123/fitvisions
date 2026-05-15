import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_users_screen.dart';
import 'admin_system_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);
  static const purple = Color(0xFF51227D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 32,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 22),

            statBox(
              icon: Icons.groups,
              title: 'Total Users',
              valueWidget: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Serif',
                      ),
                    );
                  }

                  return Text(
                    snapshot.data!.docs.length.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            statBox(
              icon: Icons.stacked_line_chart,
              title: 'Total Revenue',
              valueWidget: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .snapshots(),
                builder: (context, snapshot) {
                  double total = 0;

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = data['amount'];

                      if (amount is int) {
                        total += amount.toDouble();
                      } else if (amount is double) {
                        total += amount;
                      }
                    }
                  }

                  return Text(
                    '${total.toStringAsFixed(0)} OMR',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: 250,
              height: 210,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Issues',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Serif',
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('feedback')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text('0');
                          }

                          return Text(
                            snapshot.data!.docs.length.toString(),
                            style: const TextStyle(fontSize: 15),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  dashboardButton(
                    text: 'Manage Users',
                    onTap: () {
                      Navigator.pushNamed(context, '/adminUsers');
                    },
                  ),
                  const SizedBox(height: 16),
                  dashboardButton(
                    text: 'Manage System',
                    onTap: () {
                      Navigator.pushNamed(context, '/adminSystem');
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: 120,
              height: 42,
              child: ElevatedButton(
                onPressed: () async {
                  await AuthService.logout();

                  if (!context.mounted) return;

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
      bottomNavigationBar: adminBottomNav(context, 0),
    );
  }

  static Widget statBox({
    required IconData icon,
    required String title,
    required Widget valueWidget,
  }) {
    return Container(
      width: 250,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: purple, size: 28),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
              ),
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  static Widget dashboardButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 205,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 28),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

Widget adminBottomNav(BuildContext context, int index) {
  const purple = Color(0xFF51227D);

  return BottomNavigationBar(
    currentIndex: index,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
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
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.stacked_line_chart, color: purple),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.groups, color: purple),
        label: 'Users',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings, color: purple),
        label: 'System',
      ),
    ],
  );
}