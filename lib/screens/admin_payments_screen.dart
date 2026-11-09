import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key, this.firestore});
  final FirebaseFirestore? firestore;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFD5DBCD),
        appBar: AppBar(
            title: const Text('Subscriptions / Payments'),
            backgroundColor: const Color(0xFFD5DBCD)),
        bottomNavigationBar: adminBottomNav(context, 0),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: (firestore ?? FirebaseFirestore.instance)
              .collection('payments')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child:
                      Text('Could not load payments. Check your connection.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data!.docs
                .where((d) => d.data()['status'] == 'pending')
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
              Text('Total demo payments: ${total.toStringAsFixed(2)} OMR',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Demo payments only — no real money charged.'),
              const SizedBox(height: 16),
              if (rows.isEmpty) const Text('No completed demo payments yet'),
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
                      title: Text('${data['email'] ?? data['uid']}'),
                      subtitle: Text('${data['plan']}\n$date (Oman)'),
                      trailing: Text('${data['amount']} OMR'),
                      isThreeLine: true,
                    ));
              }),
            ]);
          },
        ),
      );
}
