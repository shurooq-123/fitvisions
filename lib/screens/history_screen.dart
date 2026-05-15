import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const bg = Color(0xFFD3D9CC);
  static const purple = Color(0xFF51227D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 55),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: AppDataService.userHistoryStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final items = snapshot.data!.docs;

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final data =
                          items[index].data() as Map<String, dynamic>;

                      final title = data['title'] ?? 'Activity';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history,
                              color: purple,
                              size: 28,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNav(context),
    );
  }

  Widget bottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/tryOnMethod');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/profile');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/history');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Text('🏠', style: TextStyle(fontSize: 28)),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Text('👤', style: TextStyle(fontSize: 28)),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Text('🕘', style: TextStyle(fontSize: 28)),
          label: 'History',
        ),
      ],
    );
  }
}