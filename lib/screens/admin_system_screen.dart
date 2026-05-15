import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key});

  static const bg = Color(0xFFD3D9CC);
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
            const SizedBox(height: 25),
            const Text(
              'Manage System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  sectionTitle('Feedback Issues'),
                  const SizedBox(height: 12),
                  feedbackList(),
                  const SizedBox(height: 22),
                  sectionTitle('Clothes'),
                  const SizedBox(height: 12),
                  clothesCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: adminBottomNav(context, 2),
    );
  }

  Widget sectionTitle(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif',
        ),
      ),
    );
  }

  Widget feedbackList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final feedbacks = snapshot.data!.docs;

        if (feedbacks.isEmpty) {
          return Container(
            width: 285,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Center(
              child: Text('No feedback yet'),
            ),
          );
        }

        return Column(
          children: feedbacks.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final email = data['email'] ?? 'Unknown user';
            final message = data['message'] ?? '';

            return Container(
              width: 285,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag, color: purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$email\n$message',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget clothesCard() {
    return Container(
      width: 285,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          row(Icons.add_box, 'Add'),
          row(Icons.edit_square, 'Edit'),
          row(Icons.delete, 'Delete'),
        ],
      ),
    );
  }

  Widget row(IconData icon, String title) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 23),
          const SizedBox(width: 25),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Serif',
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 30,
          ),
        ],
      ),
    );
  }
}