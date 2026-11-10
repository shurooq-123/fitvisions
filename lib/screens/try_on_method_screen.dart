import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/prototype_ui.dart';
import 'package:flutter/material.dart';

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
  late final Future<String?> userName = loadUserName();

  Future<String?> loadUserName() async {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = profile.data();
      final name =
          '${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    } on FirebaseException {
      // Use the signed-in identity if the profile cannot be read.
    }
    return user.displayName ?? user.email;
  }

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
            child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
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
                    if (widget.dashboard)
                      FutureBuilder<String?>(
                        future: userName,
                        builder: (context, snapshot) => Column(
                          children: [
                            const Text('Welcome',
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.bold)),
                            if (snapshot.data case final name?)
                              Text(name, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    const PrototypeLogo(width: 200, symbolOnly: true),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose Your Try-On\nMethod',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    methodButton(index: 1, text: 'Generate Avatar'),
                    const SizedBox(height: 16),
                    methodButton(index: 2, text: 'Design Clothes'),
                    const SizedBox(height: 24),
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
        continueToNextPage();
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(40),
          border: isSelected ? Border.all(color: brown, width: 2) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19)),
            const SizedBox(height: 6),
            Text(
                const [
                  'Create a 3D-style image from your measurements.',
                  'Design an outfit with your own preferences.',
                ][index - 1],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12))
          ])),
          const SizedBox(width: 18),
          const Icon(Icons.arrow_forward_ios, size: 24)
        ]),
      ),
    );
  }
}
