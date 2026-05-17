import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState
    extends State<SubscriptionScreen> {

  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);
  static const purple = Color(0xFF51227D);

  String selectedPlan = '';
  double selectedPrice = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 45),

            const Text(
              'Choose Subscription',

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('plans')
                    .snapshots(),

                builder: (context, snapshot) {

                  if (!snapshot.hasData) {

                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final plans = snapshot.data!.docs;

                  if (plans.isEmpty) {

                    return const Center(
                      child: Text(
                        'No subscription plans available',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 22,
                    ),

                    itemCount: plans.length,

                    itemBuilder: (context, index) {

                      final data =
                          plans[index].data()
                              as Map<String, dynamic>;

                      final name =
                          data['name'] ?? '';

                      final price =
                          (data['price'] ?? 0)
                              .toDouble();

                      final duration =
                          data['duration'] ?? '';

                      final features =
                          data['features'] ?? '';

                      final isSelected =
                          selectedPlan == name;

                      return GestureDetector(
                        onTap: () {

                          setState(() {

                            selectedPlan = name;

                            selectedPrice = price;
                          });
                        },

                        child: Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 18,
                          ),

                          padding:
                              const EdgeInsets.all(
                            20,
                          ),

                          decoration: BoxDecoration(
                            color:
                                const Color(
                                    0xFFF4F4F4),

                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),

                            border: isSelected
                                ? Border.all(
                                    color: purple,
                                    width: 2,
                                  )
                                : null,
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Row(
                                children: [

                                  const Icon(
                                    Icons
                                        .workspace_premium,

                                    color: purple,
                                    size: 30,
                                  ),

                                  const SizedBox(
                                      width: 12),

                                  Expanded(
                                    child: Text(
                                      name,

                                      style:
                                          const TextStyle(
                                        fontSize:
                                            20,

                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                  height: 10),

                              Text(
                                '$price OMR / $duration',

                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),

                              const SizedBox(
                                  height: 10),

                              Text(
                                features,

                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  color:
                                      Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                bottom: 25,
              ),

              child: SizedBox(
                width: 170,
                height: 48,

                child: ElevatedButton(
                  onPressed: () {

                    if (selectedPlan.isEmpty) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please choose a subscription plan',
                          ),

                          backgroundColor:
                              brown,
                        ),
                      );

                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/payment',

                      arguments: {

                        'plan':
                            selectedPlan,

                        'price':
                            selectedPrice,
                      },
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: brown,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Continue',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}