import 'package:flutter/material.dart';

class TryOnMethodScreen extends StatefulWidget {
  const TryOnMethodScreen({super.key});

  @override
  State<TryOnMethodScreen> createState() => _TryOnMethodScreenState();
}

class _TryOnMethodScreenState extends State<TryOnMethodScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  int selectedMethod = 0;

  void continueToNextPage() {
    if (selectedMethod == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a try-on method'),
          backgroundColor: brown,
        ),
      );
      return;
    }

    if (selectedMethod == 1) {
      Navigator.pushNamed(context, '/clothMeasurement');
    } else {
      Navigator.pushNamed(context, '/personalClothMeasurement');
    }
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
                const SizedBox(height: 55),
                Image.asset('images/fv.png', width: 145),
                const SizedBox(height: 35),
                const Text(
                  'Choose Your Try-On\nMethod',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 35),
                methodButton(index: 1, text: 'Photo of cloth'),
                const SizedBox(height: 35),
                methodButton(index: 2, text: 'Personal Photo'),
                const Spacer(),
                SizedBox(
                  width: 135,
                  height: 43,
                  child: ElevatedButton(
                    onPressed: continueToNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget methodButton({
    required int index,
    required String text,
  }) {
    final isSelected = selectedMethod == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = index;
        });
      },
      child: Container(
        width: 250,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(40),
          border: isSelected
              ? Border.all(color: brown, width: 2)
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}