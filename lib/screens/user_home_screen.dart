import 'package:flutter/material.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

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
                const SizedBox(height: 45),

                Image.asset(
                  'images/fv.png',
                  width: 190,
                ),

                const SizedBox(height: 35),

                Container(
                  width: 295,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(58),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'images/fv2.png',
                        width: 245,
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Virtual Fitting Room',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: brown,
                        ),
                      ),

                      const SizedBox(height: 9),

                      const Text(
                        'Try It Before You Buy It',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 28),

                      homeButton(
                        text: 'Start Try-On',
                        onTap: () {
                          Navigator.pushNamed(context, '/tryOnMethod');
                        },
                      ),

                      const SizedBox(height: 14),

                      homeButton(
                        text: 'Subscription',
                        onTap: () {
                          Navigator.pushNamed(context, '/subscription');
                        },
                      ),

                      const SizedBox(height: 14),

                      homeButton(
                        text: 'Payment',
                        onTap: () {
                          Navigator.pushNamed(context, '/payment');
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),
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
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('History page is prototype only'),
                backgroundColor: brown,
              ),
            );
          } else if (index == 2) {
            Navigator.pushNamed(context, '/about');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 24)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Text('🕘', style: TextStyle(fontSize: 24)),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Text('👤', style: TextStyle(fontSize: 24)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget homeButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 165,
      height: 43,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}