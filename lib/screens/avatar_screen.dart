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
                          const SizedBox(height: 55),

                          const Text(
                            'Generate Avatar',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 35),

                          Container(
                            width: 280,
                            height: 430,
                            padding: const EdgeInsets.all(20),
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

                                const SizedBox(height: 25),

                                SizedBox(
                                  width: 220,
                                  height: 260,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Simple person body placeholder
                                      Positioned(
                                        top: 0,
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE4C7A1),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        top: 65,
                                        child: Container(
                                          width: 115,
                                          height: 155,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8E8E8),
                                            borderRadius:
                                                BorderRadius.circular(55),
                                            border: Border.all(
                                              color: Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        top: 75,
                                        child: clothImagePath == null ||
                                                clothImagePath.isEmpty
                                            ? Container(
                                                width: 105,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(35),
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
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(35),
                                                child: Image.file(
                                                  File(clothImagePath),
                                                  width: 105,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      width: 105,
                                                      height: 120,
                                                      color: Colors.white,
                                                      child: const Center(
                                                        child: Text(
                                                          'Image not found',
                                                          textAlign:
                                                              TextAlign.center,
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

                                      Positioned(
                                        bottom: 0,
                                        left: 78,
                                        child: Container(
                                          width: 28,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        bottom: 0,
                                        right: 78,
                                        child: Container(
                                          width: 28,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                const Text(
                                  'This is a basic preview until AI integration is added.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

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