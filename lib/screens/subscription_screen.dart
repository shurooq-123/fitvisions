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
            width: 320,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const CustomBackButton(),

                const SizedBox(height: 70),

                const Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                planCard(
                  title: 'Premium Plan',
                  priceText: '7 OMR /',
                  periodText: '6 Months',
                  features: const [
                    'Unlimited try-ons',
                    'Save your looks',
                    'No watermark',
                    'Priority access',
                    'Advanced AI recommendations',
                  ],
                  plan: 'Premium Plan',
                  price: 7,
                ),

                const SizedBox(height: 32),

                planCard(
                  title: 'Basic Plan',
                  priceText: '3 OMR /',
                  periodText: 'Month',
                  features: const [
                    'Limited try-ons',
                    'Save your looks',
                    'Basic size recommendations',
                    'Standard access',
                  ],
                  plan: 'Basic Plan',
                  price: 3,
                ),

                const Spacer(),

                SizedBox(
                  width: 170,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: subscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Subscribe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black87,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/tryOnMethod');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/history');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 28)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Text('👤', style: TextStyle(fontSize: 28)),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Text('🕘', style: TextStyle(fontSize: 28)),
            label: 'History',
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(55),
          border: isSelected
              ? Border.all(
                  color: brown,
                  width: 3,
                )
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  priceText,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  periodText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '✓ $feature',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
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