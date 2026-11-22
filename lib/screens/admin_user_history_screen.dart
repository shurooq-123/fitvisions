import '../services/app_language.dart';
import 'reports_screen.dart';
import '../constants/app_colors.dart';
import '../widgets/history_preview.dart';
import '../widgets/feedback_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserHistoryScreen extends StatefulWidget {
  const AdminUserHistoryScreen(
      {super.key, required this.uid, required this.name, this.firestore});
  final String uid;
  final String name;
  final FirebaseFirestore? firestore;

  @override
  State<AdminUserHistoryScreen> createState() => _AdminUserHistoryScreenState();
}

class _AdminUserHistoryScreenState extends State<AdminUserHistoryScreen> {
  bool newestFirst = true;
  String get uid => widget.uid;
  String get name => widget.name;
  FirebaseFirestore? get firestore => widget.firestore;

  int compareRecords(QueryDocumentSnapshot<Map<String, dynamic>> a,
      QueryDocumentSnapshot<Map<String, dynamic>> b) {
    final at = a.data()['createdAt'];
    final bt = b.data()['createdAt'];
    final order = (at is Timestamp ? at.millisecondsSinceEpoch : 0)
        .compareTo(bt is Timestamp ? bt.millisecondsSinceEpoch : 0);
    return newestFirst ? -order : order;
  }

  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.page(context, const Color(0xFFFAF0F3)),
            appBar: AppBar(
                backgroundColor:
                    AppColors.page(context, const Color(0xFFFAF0F3)),
                elevation: 0,
                title: const AppText('User History'),
                actions: [
                  IconButton(
                      tooltip: 'Download and share reports',
                      icon: const Icon(Icons.description_outlined),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ReportsScreen(userId: uid, userName: name))))
                ],
                bottom: const TabBar(tabs: [
                  Tab(text: 'History / Try-ons'),
                  Tab(text: 'Feedback'),
                  Tab(text: 'Payments')
                ])),
            body: Column(children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<bool>(
                      isExpanded: true,
                      value: newestFirst,
                      items: const [
                        DropdownMenuItem(
                            value: true, child: AppText('Newest to oldest')),
                        DropdownMenuItem(
                            value: false, child: AppText('Oldest to newest')),
                      ],
                      onChanged: (v) =>
                          setState(() => newestFirst = v ?? true))),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppText(name,
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
                          child: AppText(
                              'Could not load this history. Check your connection and admin permissions.',
                              textAlign: TextAlign.center));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final records = snapshot.data!.docs.toList()
                      ..sort(compareRecords);
                    if (records.isEmpty) {
                      return const Center(
                          child: AppText('No history for this user yet'));
                    }
                    return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        itemBuilder: (_, index) {
                          final data = records[index].data();
                          final time = data['createdAt'];
                          final date = time is Timestamp
                              ? time
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .split('.')
                                  .first
                              : 'Date unavailable';
                          return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: AppColors.panel(
                                  context, const Color(0xFFFFFAF8)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: HistoryPreview(data)),
                                  onTap: () => showHistoryResult(context, data),
                                  title:
                                      AppText('${data['title'] ?? 'Activity'}'),
                                  subtitle: AppText(date)));
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
                          child: AppText(
                              'Could not load feedback. Check your connection and admin permissions.'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final records = snapshot.data!.docs.toList()
                      ..sort(compareRecords);
                    if (records.isEmpty) {
                      return const Center(
                          child: AppText('No feedback for this user yet'));
                    }
                    return ListView(
                        children: records.map((record) {
                      return FeedbackMessage(record.data());
                    }).toList());
                  },
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: (firestore ?? FirebaseFirestore.instance)
                      .collection('payments')
                      .where('uid', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: AppText(
                              'Could not load payments. Please retry.'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final records = snapshot.data!.docs.toList()
                      ..sort(compareRecords);
                    if (records.isEmpty) {
                      return const Center(child: AppText('No payments yet'));
                    }
                    return ListView(
                        children: records.map((record) {
                      final data = record.data();
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
                          child: ListTile(
                        title: AppText(
                            '${data['plan'] ?? 'Subscription'} — ${data['amount']} OMR'),
                        subtitle: AppText(
                            '${data['email'] ?? ''}\n$date (Oman)\nDemo payment • No real charge'),
                        isThreeLine: true,
                      ));
                    }).toList());
                  },
                )
              ])),
            ]),
          )));
}
