import '../widgets/prototype_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

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

  Future<void> continueWithPlan() async {
    if (saving) return;
    if (selectedPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a subscription plan')));
      return;
    }
    setState(() => saving = true);
    try {
      final subscriptionId = widget.savePlan == null
          ? await AppDataService.saveSubscription(planId: selectedPlanId)
          : await widget.savePlan!(selectedPlanId);
      if (!mounted) return;
      final returnToDesign = (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?)?['returnToDesign'] ==
          true;
      final paid =
          await Navigator.pushNamed(context, '/payment', arguments: {
        'subscriptionId': subscriptionId,
        'plan': selectedPlan,
        'price': selectedPrice,
        'returnToDesign': returnToDesign,
      });
      if (mounted && returnToDesign && paid == true) {
        Navigator.pop(context, true);
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
        StreamBuilder<QuerySnapshot>(
            stream: (widget.firestore ?? FirebaseFirestore.instance)
                .collection('plans')
                .orderBy('price', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Could not load plans. Please try again.');
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();
              if (snapshot.data!.docs.isEmpty) {
                return const Text('No subscription plans available');
              }
              return Column(
                  children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SubscriptionPlanCard(
                        data: data,
                        selected: selectedPlanId == doc.id,
                        onTap: () => setState(() {
                              selectedPlanId = doc.id;
                              selectedPlan = data['name'] ?? '';
                              selectedPrice =
                                  (data['price'] as num?)?.toDouble() ?? 0;
                            })));
              }).toList());
            }),
        PrototypeButton(saving ? 'Saving...' : 'Subscribe',
            onPressed: saving ? null : continueWithPlan),
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
    final features = raw is List
        ? raw.map((v) => v.toString()).toList()
        : '$raw'.split('\n');
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
                    color: prototypeCard,
                    borderRadius: BorderRadius.circular(52),
                    border: Border.all(
                        color: selected ? prototypeBrown : Colors.transparent,
                        width: 2)),
                child: Column(children: [
                  Text(data['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('$amount OMR / ${data['duration'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...features.where((v) => v.trim().isNotEmpty).map((v) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check,
                                size: 18, color: Colors.black54),
                            const SizedBox(width: 3),
                            Expanded(
                                child: Text(
                                    v.replaceFirst(RegExp(r'^\s*[✓✔]\s*'), ''),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54))),
                          ])),
                ]))));
  }
}
