import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminPlansScreen extends StatelessWidget {
  const AdminPlansScreen({super.key});

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
            const SizedBox(height: 35),
            const Text(
              'Subscription Plans',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 170,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/adminAddPlan');
                },
                style: ElevatedButton.styleFrom(backgroundColor: brown),
                child: const Text(
                  'Add Plan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('plans')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final plans = snapshot.data!.docs;

                  if (plans.isEmpty) {
                    return const Center(child: Text('No plans yet'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final doc = plans[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium,
                                color: purple, size: 30),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                '${data['name'] ?? ''}\n${data['price'] ?? 0} OMR / ${data['duration'] ?? ''}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/adminEditPlan',
                                  arguments: {
                                    'id': doc.id,
                                    'data': data,
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/adminDeletePlan',
                                  arguments: {
                                    'id': doc.id,
                                    'name': data['name'] ?? '',
                                  },
                                );
                              },
                              icon: const Icon(Icons.delete),
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
      bottomNavigationBar: adminBottomNav(context, 2),
    );
  }
}