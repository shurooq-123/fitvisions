import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_data_service.dart';
import '../services/notification_service.dart';
import '../widgets/prototype_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.notifications, this.markRead});
  final Stream<QuerySnapshot<Map<String, dynamic>>>? notifications;
  final Future<void> Function(String, bool)? markRead;
  @override
  Widget build(BuildContext context) => PrototypePage(
      title: 'Notifications',
      child: Column(children: [
        ValueListenableBuilder<String?>(
            valueListenable: NotificationService.status,
            builder: (_, message, __) => message == null
                ? const SizedBox.shrink()
                : Column(children: [
                    Text(message),
                    const TextButton(
                        onPressed: NotificationService.enable,
                        child: Text('Retry push connection'))
                  ])),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: notifications ??
                AppDataService.firestore
                    .collection('notifications')
                    .where('uid', isEqualTo: AppDataService.requireUser().uid)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                    'Could not load notifications. Check your connection and permissions.');
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) => ((b.data()['createdAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0)
                    .compareTo((a.data()['createdAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0));
              if (docs.isEmpty) return const Text('No notifications yet');
              return Column(
                  children: docs.map((doc) {
                final d = doc.data();
                final read = d['read'] == true;
                final date = (d['createdAt'] as Timestamp?)?.toDate().toLocal();
                return Card(
                    child: ListTile(
                  leading: Icon(read
                      ? Icons.notifications_none
                      : Icons.notifications_active),
                  title: Text('${d['title'] ?? 'Notification'}',
                      style: TextStyle(
                          fontWeight:
                              read ? FontWeight.normal : FontWeight.bold)),
                  subtitle:
                      Text('${d['body'] ?? ''}\n${date ?? 'Saving date...'}'),
                  trailing: IconButton(
                      tooltip: read ? 'Mark unread' : 'Mark read',
                      icon: Icon(read
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read),
                      onPressed: () async {
                        try {
                          if (markRead != null) {
                            await markRead!(doc.id, !read);
                          } else {
                            await doc.reference.update({'read': !read});
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not update notification. Please retry.')));
                          }
                        }
                      }),
                ));
              }).toList());
            })
      ]));
}
