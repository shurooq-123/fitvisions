import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../widgets/custom_back_button.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  Future<void> selectPlan(
    BuildContext context,
    String plan,
    double price,
  ) async {
    await AppDataService.saveSubscription(
      plan: plan,
      price: price,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$plan selected'),
        backgroundColor: brown,
      ),
    );

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'plan': plan,
        'price': price,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              children: [
                const CustomBackButton(),
                const SizedBox(height: 80),
                const Text(
                  'Subscription',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 45),
                planCard(
                  context: context,
                  title: '7 OMR',
                  subtitle: 'For 6 months',
                  plan: '6 Months',
                  price: 7,
                ),
                const SizedBox(height: 25),
                planCard(
                  context: context,
                  title: '3 OMR',
                  subtitle: 'For 2 months',
                  plan: '2 Months',
                  price: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget planCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String plan,
    required double price,
  }) {
    return InkWell(
      onTap: () => selectPlan(context, plan, price),
      child: Container(
        width: 280,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}