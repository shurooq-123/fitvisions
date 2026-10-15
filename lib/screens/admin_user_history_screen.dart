import '../widgets/history_preview.dart';
import '../widgets/feedback_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserHistoryScreen extends StatelessWidget {
  const AdminUserHistoryScreen(
      {super.key, required this.uid, required this.name, this.firestore});
  final String uid;
  final String name;
  final FirebaseFirestore? firestore;

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFD5DBCD),
        appBar: AppBar(
            backgroundColor: const Color(0xFFD5DBCD),
            elevation: 0,
            title: const Text('User History'),
            bottom: const TabBar(
                tabs: [Tab(text: 'History / Try-ons'), Tab(text: 'Feedback')])),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold))),
          Expanded(
              child: TabBarView(children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: (firestore ?? FirebaseFirestore.instance)
                  .collection('history')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                          'Could not load this history. Check your connection and admin permissions.',
                          textAlign: TextAlign.center));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final at = a.data()['createdAt'];
                    final bt = b.data()['createdAt'];
                    return (bt is Timestamp ? bt.millisecondsSinceEpoch : 0)
                        .compareTo(
                            at is Timestamp ? at.millisecondsSinceEpoch : 0);
                  });
                if (records.isEmpty) {
                  return const Center(
                      child: Text('No history for this user yet'));
                }
                return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (_, index) {
                      final data = records[index].data();
                      final time = data['createdAt'];
                      final date = time is Timestamp
                          ? time.toDate().toLocal().toString().split('.').first
                          : 'Date unavailable';
                      return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: const Color(0xFFF4F4F4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: HistoryPreview(data)),
                              onTap: () => showHistoryResult(context, data),
                              title: Text('${data['title'] ?? 'Activity'}'),
                              subtitle: Text(date)));
                    });
              },
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: (firestore ?? FirebaseFirestore.instance)
                  .collection('feedback')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                          'Could not load feedback. Check your connection and admin permissions.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final at = a.data()['createdAt'];
                    final bt = b.data()['createdAt'];
                    return (bt is Timestamp ? bt.millisecondsSinceEpoch : 0)
                        .compareTo(
                            at is Timestamp ? at.millisecondsSinceEpoch : 0);
                  });
                if (records.isEmpty) {
                  return const Center(
                      child: Text('No feedback for this user yet'));
                }
                return ListView(
                    children: records.map((record) {
                  return FeedbackMessage(record.data());
                }).toList());
              },
            )
          ])),
        ]),
      ));
}
