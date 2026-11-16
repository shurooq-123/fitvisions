import '../constants/app_colors.dart';
import '../widgets/subscription_summary.dart';
import '../widgets/prototype_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../services/subscription_access.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.firestore, this.savePlan});
  final FirebaseFirestore? firestore;
  final Future<String> Function(String)? savePlan;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = '';
  double selectedPrice = 0;
  String selectedPlanId = '';
  bool saving = false;
  bool activated = false;
  late final plansStream = (widget.firestore ?? FirebaseFirestore.instance)
      .collection('plans')
      .orderBy('price', descending: true)
      .snapshots();

  Map<String, dynamic>? get checkoutArguments =>
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  Future<void> continueWithPlan() async {
    if (saving) return;
    if (selectedPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a subscription plan')));
      return;
    }
    setState(() => saving = true);
    try {
      if (widget.savePlan == null &&
          await AppDataService.hasActiveSubscription()) {
        if (!mounted) return;
        final returnToDesign = checkoutArguments?['returnToDesign'] == true;
        if (returnToDesign) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You already have an active subscription.')));
        }
        return;
      }
      final subscriptionId = widget.savePlan == null
          ? await AppDataService.saveSubscription(planId: selectedPlanId)
          : await widget.savePlan!(selectedPlanId);
      if (!mounted) return;
      final returnToDesign = checkoutArguments?['returnToDesign'] == true;
      final avatarAction = checkoutArguments?['avatarAction'];
      final paid = await Navigator.pushNamed(context, '/payment', arguments: {
        'subscriptionId': subscriptionId,
        'plan': selectedPlan,
        'price': selectedPrice,
        'returnToSubscription': true,
      });
      if (!mounted || paid != true) return;
      if (returnToDesign && avatarAction == null) {
        Navigator.pop(context, true);
      } else {
        setState(() => activated = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not save the subscription. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      title: 'Subscription',
      child: Column(children: [
        if (widget.firestore == null) const SubscriptionSummary(),
        const SizedBox(height: 18),
        if (activated && checkoutArguments?['returnToDesign'] == true)
          PrototypeButton('Continue',
              onPressed: () => Navigator.pop(context, true)),
        if (!activated)
          StreamBuilder<QuerySnapshot>(
              stream: plansStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Could not load plans. Please try again.');
                }
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final plans = <num, QueryDocumentSnapshot>{};
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final price = data['price'];
                  if (price is num && SubscriptionAccess.months(price) > 0) {
                    plans.putIfAbsent(price, () => doc);
                  }
                }
                if (plans.isEmpty) {
                  return const Text('No subscription plans available');
                }
                return Column(
                    children: plans.values.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SubscriptionPlanCard(
                          data: data,
                          selected: selectedPlanId == doc.id,
                          onTap: () {
                            if (saving) return;
                            setState(() {
                              selectedPlanId = doc.id;
                              selectedPlan = data['name'] ?? '';
                              selectedPrice =
                                  (data['price'] as num?)?.toDouble() ?? 0;
                            });
                            continueWithPlan();
                          }));
                }).toList());
              }),
        if (saving) const CircularProgressIndicator(),
        const SizedBox(height: 8),
        const Text('Demo subscription • No real charge',
            style: TextStyle(fontSize: 11)),
      ]));
}

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard(
      {super.key,
      required this.data,
      required this.selected,
      required this.onTap});
  final Map<String, dynamic> data;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final amount = price == price.roundToDouble()
        ? price.toInt().toString()
        : price.toString();
    final raw = data['features'];
    final standard = price == 3 || price == 7;
    final features = standard
        ? [
            'Generate Avatar and Design Clothes',
            'Edit your results and download images',
            'One subscription covers both options',
            price == 7
                ? '6 months of access • about 1.17 OMR/month'
                : '1 month of access • 3 OMR/month',
            'No automatic renewal',
            'AI generation subject to service availability',
          ]
        : raw is List
            ? raw.map((v) => v.toString()).toList()
            : '$raw'.split('\n');
    final duration = price == 7
        ? '6 Months'
        : price == 3
            ? '1 Month'
            : data['duration'] ?? '';
    return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(52),
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                decoration: BoxDecoration(
                    color: AppColors.panel(context),
                    borderRadius: BorderRadius.circular(52),
                    border: Border.all(
                        color: selected ? prototypeBrown : Colors.transparent,
                        width: 2)),
                child: Column(children: [
                  Text(data['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('$amount OMR / $duration',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...features.where((v) => v.trim().isNotEmpty).map((v) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check,
                                size: 18, color: AppColors.muted(context)),
                            const SizedBox(width: 3),
                            Expanded(
                                child: Text(
                                    v.replaceFirst(RegExp(r'^\s*[✓✔]\s*'), ''),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted(context)))),
                          ])),
                ]))));
  }
}
