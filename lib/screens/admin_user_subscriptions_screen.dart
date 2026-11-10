import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subscription_access.dart';

class AdminUserSubscriptionsScreen extends StatefulWidget {
  const AdminUserSubscriptionsScreen({super.key, required this.firestore});

  final FirebaseFirestore firestore;

  @override
  State<AdminUserSubscriptionsScreen> createState() =>
      _AdminUserSubscriptionsScreenState();
}

class _AdminUserSubscriptionsScreenState
    extends State<AdminUserSubscriptionsScreen> {
  static const background = Color(0xFFD5DBCD);
  static const purple = Color(0xFF51227D);
  late final users = widget.firestore.collection('users').snapshots();
  late final payments = widget.firestore.collection('payments').snapshots();
  int? filter;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          title: const Text('Total Users'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: users,
          builder: (context, userSnapshot) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: payments,
            builder: (context, paymentSnapshot) {
              if (userSnapshot.hasError || paymentSnapshot.hasError) {
                return const Center(
                    child: Text('Could not load users and subscriptions.'));
              }
              if (!userSnapshot.hasData || !paymentSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final plans = _latestPlans(paymentSnapshot.data!.docs);
              final visible = userSnapshot.data!.docs
                  .where((user) =>
                      filter == null || (plans[user.id]?.amount ?? 0) == filter)
                  .toList();
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('Latest demo subscription per user · Oman time',
                        textAlign: TextAlign.center),
                  ),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (value, label) in const [
                        (null, 'All users'),
                        (3, '3 OMR'),
                        (7, '7 OMR'),
                        (0, 'No plan'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: filter == value,
                          selectedColor: purple.withValues(alpha: 0.18),
                          backgroundColor: const Color(0xFFF4F4F4),
                          onSelected: (_) => setState(() => filter = value),
                        ),
                    ],
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(
                            child: Text('No users match this filter.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final user = visible[index];
                              return _userRow(context, user.data(), user.id,
                                  plans[user.id]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  Map<String, _Plan> _latestPlans(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> records) {
    final plans = <String, _Plan>{};
    for (final record in records) {
      final data = record.data();
      final uid = data['uid'];
      final amount = data['amount'];
      if (data['status'] != 'pending' ||
          uid is! String ||
          amount is! num ||
          SubscriptionAccess.months(amount) == 0) {
        continue;
      }
      final stamp = data['createdAt'];
      final date = stamp is Timestamp ? stamp.toDate() : null;
      final previous = plans[uid];
      if (previous != null &&
          (date == null || (previous.date?.isAfter(date) ?? false))) {
        continue;
      }
      final label = data['plan'];
      plans[uid] = _Plan(
        amount.toInt(),
        label is String && label.trim().isNotEmpty
            ? label
            : amount == 3
                ? 'Basic Plan'
                : 'Premium Plan',
        date,
        data['email']?.toString() ?? '',
      );
    }
    return plans;
  }

  Widget _userRow(BuildContext context, Map<String, dynamic> profile,
      String uid, _Plan? plan) {
    final name =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    final email = (profile['email'] ?? plan?.email ?? '').toString().trim();
    final contact = email.isEmpty ? uid : email;
    final localizations = MaterialLocalizations.of(context);
    final omanTime = plan?.date?.toUtc().add(const Duration(hours: 4));
    final date = omanTime == null
        ? 'Date unavailable'
        : '${localizations.formatShortDate(omanTime)} · '
            '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(omanTime), alwaysUse24HourFormat: true)}';
    final months = plan == null ? 0 : SubscriptionAccess.months(plan.amount);
    return Card(
      color: const Color(0xFFF4F4F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        leading: const Icon(Icons.person_outline, color: purple),
        title: Text(name.isEmpty ? contact : name),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty && email.isNotEmpty) Text(email),
            if (plan == null)
              const Text('No subscription')
            else ...[
              Text(
                  '${plan.name} · ${plan.amount} OMR · $months ${months == 1 ? 'month' : 'months'}'),
              Text(date),
            ],
          ],
        ),
      ),
    );
  }
}

class _Plan {
  const _Plan(this.amount, this.name, this.date, this.email);

  final int amount;
  final String name;
  final DateTime? date;
  final String email;
}
