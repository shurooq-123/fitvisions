import '../services/app_language.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_data_service.dart';
import '../services/notification_service.dart';
import '../widgets/prototype_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.notifications, this.markRead});
  final Stream<QuerySnapshot<Map<String, dynamic>>>? notifications;
  final Future<void> Function(String, bool)? markRead;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final seen = <String>{};
  void markVisibleRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final unread =
        docs.where((d) => d.data()['read'] != true && seen.add(d.id)).toList();
    if (unread.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        for (final doc in unread) {
          if (!mounted) return;
          if (widget.markRead != null) {
            await widget.markRead!(doc.id, true);
          } else {
            await doc.reference.update({'read': true});
          }
        }
      } catch (_) {
        for (final doc in unread) {
          seen.remove(doc.id);
        }
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  AppText('Could not update notification. Please retry.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => PrototypePage(
          nav: false,
          title: 'Notifications',
          child: Column(children: [
            ValueListenableBuilder<String?>(
                valueListenable: NotificationService.status,
                builder: (_, message, __) => message == null
                    ? const SizedBox.shrink()
                    : Column(children: [
                        AppText(message),
                        const TextButton(
                            onPressed: NotificationService.enable,
                            child: AppText('Retry push connection'))
                      ])),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.notifications ??
                    AppDataService.firestore
                        .collection('notifications')
                        .where('uid',
                            isEqualTo: AppDataService.requireUser().uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const AppText(
                        'Could not load notifications. Check your connection and permissions.');
                  }
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs.toList()
                    ..sort((a, b) => ((b.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0)
                        .compareTo((a.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0));
                  markVisibleRead(docs);
                  if (docs.isEmpty)
                    return const AppText('No notifications yet');
                  return Column(
                      children: docs.map((doc) {
                    final d = doc.data();
                    final read = d['read'] == true;
                    final body = '${d['body'] ?? ''}';
                    final parts = body.split('\n\n');
                    final message = parts.length == 2 &&
                            RegExp(r'[\u0600-\u06ff]').hasMatch(parts.first)
                        ? (AppLanguage.locale.value.languageCode == 'ar'
                            ? parts.first
                            : parts.last)
                        : body;
                    final date =
                        (d['createdAt'] as Timestamp?)?.toDate().toLocal();
                    return Card(
                        child: ListTile(
                      leading: Icon(read
                          ? Icons.notifications_none
                          : Icons.notifications_active),
                      title: AppText('${d['title'] ?? 'Notification'}',
                          style: TextStyle(
                              fontWeight:
                                  read ? FontWeight.normal : FontWeight.bold)),
                      subtitle:
                          AppText('${message}\n${date ?? 'Saving date...'}'),
                      trailing: IconButton(
                          tooltip: tr(read ? 'Mark unread' : 'Mark read'),
                          icon: Icon(read
                              ? Icons.mark_email_unread
                              : Icons.mark_email_read),
                          onPressed: () async {
                            try {
                              if (widget.markRead != null) {
                                await widget.markRead!(doc.id, !read);
                              } else {
                                await doc.reference.update({'read': !read});
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: AppText(
                                            'Could not update notification. Please retry.')));
                              }
                            }
                          }),
                    ));
                  }).toList());
                })
          ])));
}
