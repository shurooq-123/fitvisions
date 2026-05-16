import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../widgets/custom_back_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  String selectedPlan = '';
  double selectedPrice = 0;

  Future<void> subscribe() async {
    if (selectedPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a subscription plan'),
          backgroundColor: brown,
        ),
      );
      return;
    }

    await AppDataService.saveSubscription(
      plan: selectedPlan,
      price: selectedPrice,
    );

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'plan': selectedPlan,
        'price': selectedPrice,
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
            width: 330,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const CustomBackButton(),

                  const SizedBox(height: 25),

                  const Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  planCard(
                    title: 'Premium Plan',
                    priceText: '7 OMR',
                    periodText: '6 Months',
                    features: const [
                      'Unlimited try-ons',
                      'Save your looks',
                      'No watermark',
                      'Priority access',
                    ],
                    plan: 'Premium Plan',
                    price: 7,
                  ),

                  const SizedBox(height: 18),

                  planCard(
                    title: 'Basic Plan',
                    priceText: '3 OMR',
                    periodText: '1 Month',
                    features: const [
                      'Limited try-ons',
                      'Save your looks',
                      'Basic recommendations',
                      'Standard access',
                    ],
                    plan: 'Basic Plan',
                    price: 3,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: 155,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: subscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Subscribe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget planCard({
    required String title,
    required String priceText,
    required String periodText,
    required List<String> features,
    required String plan,
    required double price,
  }) {
    final isSelected = selectedPlan == plan;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = plan;
          selectedPrice = price;
        });
      },
      child: Container(
        width: 285,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: isSelected ? brown : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '$priceText / $periodText',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '✓ $feature',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}