import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/subscription_access.dart';
import 'admin_payments_screen.dart';
import 'admin_system_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.firestore});

  final FirebaseFirestore? firestore;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const bg = Color(0xFFD5DBCD);
  static const brown = Color(0xFF574543);
  static const purple = Color(0xFF51227D);
  static const panel = Color(0xFFF4F4F4);

  late final db = widget.firestore ?? FirebaseFirestore.instance;
  late final users = db.collection('users').snapshots();
  late final payments = db.collection('payments').snapshots();

  int? selectedAmount;
  bool newestFirst = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: adminBottomNav(context, 0),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: users,
          builder: (context, userSnapshot) {
            final profiles = {
              for (final doc in userSnapshot.data?.docs ?? [])
                doc.id: doc.data(),
            };
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: payments,
              builder: (context, paymentSnapshot) {
                final entries = [
                  for (final doc in paymentSnapshot.data?.docs ?? [])
                    if (_SubscriptionEntry.fromRecord(doc.data())
                        case final entry?)
                      entry,
                ];
                final basicCount = entries
                    .where((entry) => entry.amount == 3)
                    .map((entry) => entry.uid)
                    .toSet()
                    .length;
                final premiumCount = entries
                    .where((entry) => entry.amount == 7)
                    .map((entry) => entry.uid)
                    .toSet()
                    .length;
                final total =
                    entries.fold(0, (sum, entry) => sum + entry.amount);
                final visible = entries
                    .where((entry) =>
                        selectedAmount == null ||
                        entry.amount == selectedAmount)
                    .toList()
                  ..sort((a, b) {
                    final first = a.createdAt;
                    final second = b.createdAt;
                    if (first == null) return second == null ? 0 : 1;
                    if (second == null) return -1;
                    return newestFirst
                        ? second.compareTo(first)
                        : first.compareTo(second);
                  });
                final paymentReady =
                    paymentSnapshot.hasData && !paymentSnapshot.hasError;
                final userCount = userSnapshot.hasData && !userSnapshot.hasError
                    ? profiles.length
                    : null;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _dashboardHeader(context)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _statBox(
                              Icons.groups,
                              'Total Users',
                              userCount?.toString() ??
                                  (userSnapshot.hasError ? 'Unavailable' : '…'),
                            ),
                            if (paymentReady) ...[
                              const SizedBox(height: 10),
                              _comparison(context, basicCount, premiumCount),
                            ],
                            const SizedBox(height: 10),
                            _statBox(
                              Icons.stacked_line_chart,
                              'Demo Revenue',
                              paymentReady
                                  ? '${total.toStringAsFixed(2)} OMR'
                                  : paymentSnapshot.hasError
                                      ? 'Unavailable'
                                      : '…',
                            ),
                            const SizedBox(height: 10),
                            _managementButtons(context),
                            const SizedBox(height: 14),
                            Text('Subscription History',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Text('Demo payments · Date and time in Oman'),
                            if (paymentReady) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final (amount, label) in const [
                                    (null, 'All plans'),
                                    (3, '3 OMR'),
                                    (7, '7 OMR'),
                                  ])
                                    ChoiceChip(
                                      label: Text(label),
                                      selected: selectedAmount == amount,
                                      selectedColor:
                                          purple.withValues(alpha: 0.18),
                                      backgroundColor: panel,
                                      onSelected: (_) => setState(
                                          () => selectedAmount = amount),
                                    ),
                                  TextButton.icon(
                                    onPressed: () => setState(
                                        () => newestFirst = !newestFirst),
                                    style: TextButton.styleFrom(
                                        foregroundColor: purple),
                                    icon: const Icon(Icons.swap_vert_rounded),
                                    label: Text(newestFirst
                                        ? 'Newest first'
                                        : 'Oldest first'),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            if (paymentSnapshot.hasError)
                              const Text(
                                  'Could not load subscriptions. Check your connection.')
                            else if (!paymentReady)
                              const Center(child: CircularProgressIndicator())
                            else if (visible.isEmpty)
                              const Text(
                                  'No subscription records for this selection.'),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      sliver: SliverList.builder(
                        itemCount: paymentReady ? visible.length : 0,
                        itemBuilder: (context, index) {
                          final entry = visible[index];
                          return _subscriptionRow(
                              context, entry, profiles[entry.uid]);
                        },
                      ),
                    ),
                    SliverToBoxAdapter(child: _logoutButton(context)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _dashboardHeader(BuildContext context) => Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios,
                    size: 32, color: Colors.black),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account settings',
                onSelected: (_) =>
                    Navigator.pushNamed(context, '/changePassword'),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'password', child: Text('Change password')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Admin Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
        ],
      );

  Widget _statBox(IconData icon, String label, String value) => Container(
        width: 250,
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: panel, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Icon(icon, color: purple, size: 28),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ))),
            Text(value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                )),
          ],
        ),
      );

  Widget _managementButtons(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        decoration: BoxDecoration(
            color: panel, borderRadius: BorderRadius.circular(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dashboardButton('Manage Users',
                () => Navigator.pushNamed(context, '/adminUsers')),
            const SizedBox(height: 16),
            _dashboardButton(
                'Subscriptions / Payments',
                () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AdminPaymentsScreen(firestore: widget.firestore)),
                    )),
            const SizedBox(height: 16),
            _dashboardButton('Manage System',
                () => Navigator.pushNamed(context, '/adminSystem')),
          ],
        ),
      );

  Widget _dashboardButton(String label, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          side: const BorderSide(color: Colors.black),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                    ))),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 28),
          ],
        ),
      );

  Widget _logoutButton(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: SizedBox(
            width: 120,
            height: 42,
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
              child: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );

  Widget _comparison(BuildContext context, int basicCount, int premiumCount) {
    final highest = basicCount > premiumCount ? basicCount : premiumCount;
    final animation = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 550);
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          const Text('Subscribers by plan',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, count, color) in [
                ('Basic · 3 OMR', basicCount, brown),
                ('Premium · 7 OMR', premiumCount, purple),
              ])
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 70,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                                begin: 0,
                                end: highest == 0 ? 0 : 70 * count / highest),
                            duration: animation,
                            curve: Curves.easeOutCubic,
                            builder: (context, height, _) => Container(
                              width: 38,
                              height: height,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('$label\n$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subscriptionRow(BuildContext context, _SubscriptionEntry entry,
      Map<String, dynamic>? profile) {
    final name =
        '${profile?['firstName'] ?? ''} ${profile?['lastName'] ?? ''}'.trim();
    final contact = entry.email.isEmpty ? entry.uid : entry.email;
    final color = entry.amount == 3 ? brown : purple;
    final localizations = MaterialLocalizations.of(context);
    final omanTime = entry.createdAt?.toUtc().add(const Duration(hours: 4));
    final date = omanTime == null
        ? 'Date unavailable'
        : '${localizations.formatShortDate(omanTime)} · '
            '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(omanTime), alwaysUse24HourFormat: true)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        leading: Icon(Icons.receipt_long_rounded, color: color),
        title: Text(name.isEmpty ? contact : name),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty) Text(contact),
            Text('${entry.plan} · $date'),
          ],
        ),
        trailing: Text('${entry.amount} OMR',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SubscriptionEntry {
  const _SubscriptionEntry(
      this.uid, this.email, this.amount, this.plan, this.createdAt);

  final String uid;
  final String email;
  final int amount;
  final String plan;
  final DateTime? createdAt;

  static _SubscriptionEntry? fromRecord(Map<String, dynamic> data) {
    final amount = data['amount'];
    final uid = data['uid'];
    if (data['status'] != 'pending' ||
        uid is! String ||
        uid.isEmpty ||
        amount is! num ||
        SubscriptionAccess.months(amount) == 0) {
      return null;
    }
    final stamp = data['createdAt'];
    final plan = data['plan'];
    return _SubscriptionEntry(
      uid,
      data['email']?.toString() ?? '',
      amount.toInt(),
      plan is String && plan.trim().isNotEmpty
          ? plan
          : amount == 3
              ? 'Basic Plan'
              : 'Premium Plan',
      stamp is Timestamp ? stamp.toDate() : null,
    );
  }
}

Widget adminBottomNav(BuildContext context, int index) {
  const purple = Color(0xFF51227D);

  return BottomNavigationBar(
    currentIndex: index,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    onTap: (i) {
      if (i == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      } else if (i == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminUsersScreen(),
          ),
        );
      } else if (i == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminSystemScreen(),
          ),
        );
      }
    },
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.stacked_line_chart, color: purple),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.groups, color: purple),
        label: 'Users',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings, color: purple),
        label: 'System',
      ),
    ],
  );
}
