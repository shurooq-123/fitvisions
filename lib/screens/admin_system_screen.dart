import '../widgets/feedback_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key, this.firestore});
  final FirebaseFirestore? firestore;

  static const bg = Color(0xFFD5DBCD);
  static const purple = Color(0xFF51227D);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: bg,
      body: SafeArea(
          child: SingleChildScrollView(
              child: Center(
                  child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios, size: 28))),
              const SizedBox(height: 25),
              const Text('Manage System',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              const Text('Subscription Plans',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              plansCard(context),
              const SizedBox(height: 30),
              const Text('Feedback Issues',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              feedbackList(),
              const SizedBox(height: 24),
            ])),
      )))),
      bottomNavigationBar: adminBottomNav(context, 2));

  void showPayments(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
            child: StreamBuilder<QuerySnapshot>(
                stream: (firestore ?? FirebaseFirestore.instance)
                    .collection('payments')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Could not load payments.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No demo payments yet'));
                  }
                  return ListView(
                      children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                        title: Text('${data['plan'] ?? 'Payment'}'),
                        subtitle: Text(
                            '${data['email'] ?? ''}\n${data['status'] ?? 'Unverified'}'),
                        trailing: Text('${data['amount'] ?? 0} OMR'));
                  }).toList());
                })));
  }

  // ONE BOX ONLY
  Widget plansCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/adminPlans',
        );
      },
      child: Container(
        width: double.infinity,
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Colors.grey,
              size: 30,
            ),
            SizedBox(width: 18),
            Expanded(
              child: Text(
                'Manage Subscription Plans',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget feedbackList() {
    return StreamBuilder<QuerySnapshot>(
      stream: (firestore ?? FirebaseFirestore.instance)
          .collection('feedback')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
              'Could not load feedback. Check your connection and admin permissions.');
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final feedbacks = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map<String, dynamic>)['createdAt'];
            final bt = (b.data() as Map<String, dynamic>)['createdAt'];
            return (bt is Timestamp ? bt.millisecondsSinceEpoch : 0)
                .compareTo(at is Timestamp ? at.millisecondsSinceEpoch : 0);
          });

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

            return FeedbackMessage(data);
          }).toList(),
        );
      },
    );
  }
}
