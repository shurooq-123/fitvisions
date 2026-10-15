import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const bg = Color(0xFFCED1C6);
  static const brown = Color(0xFF574543);

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
                const Spacer(flex: 2),

                Image.asset(
                  'images/fv.png',
                  width: 320,
                ),

                const SizedBox(height: 55),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    mainButton(
                      text: 'Login',
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                    const SizedBox(width: 20),
                    mainButton(
                      text: 'Register',
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: 135,
                  height: 43,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/about');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'About us',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget mainButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 127,
      height: 43,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}