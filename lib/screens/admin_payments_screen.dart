import '../services/app_language.dart';
import '../constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key, this.firestore});
  final FirebaseFirestore? firestore;
  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => Scaffold(
            backgroundColor: AppColors.page(context, const Color(0xFFD5DBCD)),
            appBar: AppBar(
                title: const AppText('Subscriptions / Payments'),
                backgroundColor:
                    AppColors.page(context, const Color(0xFFD5DBCD))),
            bottomNavigationBar: adminBottomNav(context, 0),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: (firestore ?? FirebaseFirestore.instance)
                  .collection('payments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: AppText(
                          'Could not load payments. Check your connection.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!.docs
                    .where((d) => ['pending', 'demo_active', 'paid']
                        .contains(d.data()['status']))
                    .toList()
                  ..sort((a, b) => ((b.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0)
                      .compareTo((a.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0));
                final total = rows.fold<double>(
                    0,
                    (runningTotal, d) =>
                        runningTotal +
                        ((d.data()['amount'] as num?)?.toDouble() ?? 0));
                return ListView(padding: const EdgeInsets.all(16), children: [
                  AppText(
                      'Total demo payments: ${total.toStringAsFixed(2)} OMR',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const AppText('Demo payments only — no real money charged.'),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    const AppText('No completed demo payments yet'),
                  ...rows.map((doc) {
                    final data = doc.data();
                    final stamp = data['createdAt'];
                    final date = stamp is Timestamp
                        ? stamp
                            .toDate()
                            .toUtc()
                            .add(const Duration(hours: 4))
                            .toString()
                            .split('.')
                            .first
                        : 'Saving date...';
                    return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        child: ListTile(
                          title: AppText('${data['email'] ?? data['uid']}'),
                          subtitle: AppText('${data['plan']}\n$date (Oman)'),
                          trailing: AppText('${data['amount']} OMR'),
                          isThreeLine: true,
                        ));
                  }),
                ]);
              },
            ),
          ));
}
