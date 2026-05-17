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
                  String? personImagePath;

                  if (snapshot.hasData &&
                      snapshot.data!.exists) {

                    final data =
                        snapshot.data!.data()
                            as Map<String, dynamic>;

                    clothImagePath =
                        data['clothImagePath'];

                    personImagePath =
                        data['personImagePath'];
                  }

                  return Center(
                    child: SizedBox(
                      width: 320,

                      child: SingleChildScrollView(
                        child: Column(
                          children: [

                            const SizedBox(height: 40),

                            const Text(
                              'Generate Avatar',

                              style: TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 28),

                            Container(
                              width: 295,

                              padding:
                                  const EdgeInsets.all(18),

                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF4F4F4),

                                borderRadius:
                                    BorderRadius.circular(45),
                              ),

                              child: Column(
                                children: [

                                  const Text(
                                    'Preview',

                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // AVATAR AREA

                                  Container(
                                    width: 245,
                                    height: 390,

                                    decoration: BoxDecoration(
                                      color: Colors.white,

                                      borderRadius:
                                          BorderRadius.circular(
                                              32),

                                      boxShadow: const [
                                        BoxShadow(
                                          color:
                                              Colors.black12,

                                          blurRadius: 8,

                                          offset:
                                              Offset(0, 4),
                                        ),
                                      ],
                                    ),

                                    child: Stack(
                                      alignment:
                                          Alignment.center,

                                      children: [

                                        // USER IMAGE

                                        Positioned.fill(
                                          child:
                                              personImagePath ==
                                                      null ||
                                                  personImagePath
                                                      .isEmpty

                                              ? Container(
                                                  decoration:
                                                      BoxDecoration(
                                                    color: Colors
                                                        .grey
                                                        .shade200,

                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                30),
                                                  ),

                                                  child:
                                                      const Center(
                                                    child: Text(
                                                      'No Personal Image',
                                                      style:
                                                          TextStyle(
                                                        fontSize:
                                                            14,
                                                      ),
                                                    ),
                                                  ),
                                                )

                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              30),

                                                  child:
                                                      Image.file(
                                                    File(
                                                        personImagePath),

                                                    fit:
                                                        BoxFit.cover,

                                                    errorBuilder:
                                                        (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {

                                                      return Container(
                                                        color: Colors
                                                            .grey
                                                            .shade200,

                                                        child:
                                                            const Center(
                                                          child:
                                                              Text(
                                                            'Image not found',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                        ),

                                        // CLOTH IMAGE

                                        Positioned(
                                          top: 95,

                                          child:
                                              clothImagePath ==
                                                          null ||
                                                      clothImagePath
                                                          .isEmpty

                                                  ? Container(
                                                      width:
                                                          150,

                                                      height:
                                                          160,

                                                      decoration:
                                                          BoxDecoration(
                                                        color: Colors
                                                            .white
                                                            .withOpacity(
                                                                0.8),

                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                25),

                                                        border:
                                                            Border.all(
                                                          color: Colors
                                                              .black26,
                                                        ),
                                                      ),

                                                      child:
                                                          const Center(
                                                        child:
                                                            Text(
                                                          'No Cloth Image',

                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    )

                                                  : Opacity(
                                                      opacity:
                                                          0.95,

                                                      child:
                                                          ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                25),

                                                        child:
                                                            Image.file(
                                                          File(
                                                              clothImagePath),

                                                          width:
                                                              160,

                                                          height:
                                                              180,

                                                          fit:
                                                              BoxFit.contain,

                                                          errorBuilder:
                                                              (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {

                                                            return Container(
                                                              width:
                                                                  150,

                                                              height:
                                                                  160,

                                                              color:
                                                                  Colors.white,

                                                              child:
                                                                  const Center(
                                                                child:
                                                                    Text(
                                                                  'Image not found',
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
                                    'AI preview generated based on your uploaded measurements and clothing.',

                                    textAlign:
                                        TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 13,

                                      color:
                                          Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            SizedBox(
                              width: 170,
                              height: 46,

                              child: ElevatedButton(
                                onPressed: () async {

                                  await AppDataService
                                      .addHistory(
                                    'Avatar generated',
                                  );

                                  if (!context.mounted)
                                    return;

                                  Navigator
                                      .pushReplacementNamed(
                                    context,
                                    '/feedback',
                                  );
                                },

                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      brown,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(8),
                                  ),
                                ),

                                child: const Text(
                                  'Continue',

                                  style: TextStyle(
                                    color:
                                        Colors.white,

                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}