import '../widgets/prototype_ui.dart';
import 'package:flutter/material.dart';
import 'ready_outfits_screen.dart';

class TryOnMethodScreen extends StatefulWidget {
  const TryOnMethodScreen({super.key, this.dashboard = false});
  final bool dashboard;

  @override
  State<TryOnMethodScreen> createState() => _TryOnMethodScreenState();
}

class _TryOnMethodScreenState extends State<TryOnMethodScreen> {
  static const bg = Color(0xFFCED1C6);
  static const brown = Color(0xFF574543);

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
      Navigator.pushNamed(context, '/generateAvatar');
    } else if (selectedMethod == 2) {
      Navigator.pushNamed(context, '/createClothes');
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadyOutfitsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PrototypeNav(),
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(child: Column(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios))),
                if (widget.dashboard)
                  const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text('User Dashboard',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))),
                const PrototypeLogo(width: 200, symbolOnly: true),
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
                methodButton(index: 1, text: 'Generate Avatar'),
                const SizedBox(height: 35),
                methodButton(index: 2, text: 'Create Clothes'),
                const SizedBox(height: 16),
                methodButton(index: 3, text: 'Ready-made outfits'),
                const SizedBox(height: 20),
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
            )),
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
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(40),
          border: isSelected ? Border.all(color: brown, width: 2) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19))),
          const SizedBox(width: 18),
          const Icon(Icons.arrow_forward_ios, size: 24)
        ]),
      ),
    );
  }
}
