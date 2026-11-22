import '../widgets/fashion_backdrop.dart';
import '../services/app_language.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const bg = Color(0xFFFAF0F3);
  static const brown = Color(0xFF85465F);

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    return Scaffold(
      backgroundColor: AppColors.page(context, bg),
      body: FashionBackdrop(
          child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: SizedBox(
                  width: 390,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      children: [
                        Image.asset(
                          'images/fv.png',
                          width: constraints.maxHeight < 400 ? 220 : 320,
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            mainButton(
                              text: 'Login',
                              onTap: () {
                                Navigator.pushNamed(context, '/login');
                              },
                            ),
                            mainButton(
                              text: 'Register',
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const AppText(
                              'About us',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget mainButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AppText(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
