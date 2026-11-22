import '../widgets/fashion_backdrop.dart';
import '../services/app_language.dart';
import '../constants/app_colors.dart';
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
  static const bg = Color(0xFFFAF0F3);
  static const brown = Color(0xFF85465F);

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
          content: AppText('Please choose a try-on method'),
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
    AppLanguage.watch(context);
    return Scaffold(
      bottomNavigationBar: const PrototypeNav(),
      backgroundColor: AppColors.page(context, bg),
      body: FashionBackdrop(
          child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                          child: AppText('User Dashboard',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold))),
                    if (widget.dashboard)
                      FutureBuilder<String?>(
                        future: userName,
                        builder: (context, snapshot) => Column(
                          children: [
                            const AppText('Welcome',
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.bold)),
                            if (snapshot.data case final name?)
                              AppText(name, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    const PrototypeLogo(width: 200, symbolOnly: true),
                    const SizedBox(height: 20),
                    const AppText(
                      'Choose Your Try-On\nMethod',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, box) {
                      final stacked =
                          MediaQuery.textScalerOf(context).scale(16) > 20 ||
                              box.maxWidth < 280;
                      final width =
                          stacked ? box.maxWidth : (box.maxWidth - 12) / 2;
                      return Wrap(spacing: 12, runSpacing: 12, children: [
                        SizedBox(
                            width: width,
                            child: methodButton(
                                index: 1, text: 'Generate Avatar')),
                        SizedBox(
                            width: width,
                            child:
                                methodButton(index: 2, text: 'Design Clothes')),
                      ]);
                    }),
                    const SizedBox(height: 24),
                  ],
                )),
          ),
        ),
      )),
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
        width: 310,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.panel(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected
                  ? brown
                  : AppColors.adaptive(context, const Color(0xFFE5CED7),
                      const Color(0xFF624554)),
              width: isSelected ? 2 : 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1485465F), blurRadius: 16, offset: Offset(0, 5))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(index == 1 ? Icons.auto_awesome : Icons.checkroom_outlined,
              size: 34, color: AppColors.accent(context)),
          const SizedBox(height: 12),
          AppText(text,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppText(
              const [
                'Create a 3D-style image from your measurements.',
                'Design an outfit with your own preferences.',
              ][index - 1],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, height: 1.35, color: AppColors.muted(context))),
          const SizedBox(height: 10),
          Icon(Icons.chevron_right, size: 22, color: AppColors.accent(context)),
        ]),
      ),
    );
  }
}
