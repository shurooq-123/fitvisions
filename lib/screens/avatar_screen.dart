import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  @override
  Widget build(BuildContext context) {
    final uid = AppDataService.uid;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: uid == null
            ? const Center(
                child: Text('No user logged in'),
              )
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('measurements')
                    .doc(uid)
                    .get(),
                builder: (context, snapshot) {
                  String? clothImagePath;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    clothImagePath = data['clothImagePath'];
                  }

                  return Center(
                    child: SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          const Text(
                            'Generate Avatar',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 28),

                          Container(
                            width: 290,
                            height: 455,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                Container(
                                  width: 245,
                                  height: 320,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // More realistic simple body prototype
                                      Positioned(
                                        top: 18,
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE8C6A5),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        top: 80,
                                        child: Container(
                                          width: 118,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE6E6E6),
                                            borderRadius:
                                                BorderRadius.circular(55),
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        top: 95,
                                        left: 35,
                                        child: Container(
                                          width: 35,
                                          height: 125,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE6E6E6),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        top: 95,
                                        right: 35,
                                        child: Container(
                                          width: 35,
                                          height: 125,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE6E6E6),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        bottom: 25,
                                        left: 88,
                                        child: Container(
                                          width: 32,
                                          height: 95,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD2D2D2),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        bottom: 25,
                                        right: 88,
                                        child: Container(
                                          width: 32,
                                          height: 95,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD2D2D2),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                      ),

                                      // Uploaded cloth over the body
                                      Positioned(
                                        top: 92,
                                        child: clothImagePath == null ||
                                                clothImagePath.isEmpty
                                            ? Container(
                                                width: 135,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF7F7F7),
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                  border: Border.all(
                                                    color: Colors.black26,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'No cloth\nimage',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Opacity(
                                                opacity: 0.96,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(22),
                                                  child: Image.file(
                                                    File(clothImagePath),
                                                    width: 140,
                                                    height: 135,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        width: 135,
                                                        height: 120,
                                                        color: Colors.white,
                                                        child: const Center(
                                                          child: Text(
                                                            'Image not found',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  'Basic preview until AI try-on is connected.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: 160,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () async {
                                await AppDataService.addHistory(
                                  'Avatar preview generated',
                                );

                                if (!context.mounted) return;

                                Navigator.pushReplacementNamed(
                                  context,
                                  '/feedback',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}