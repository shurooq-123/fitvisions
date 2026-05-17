import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_data_service.dart';
import '../widgets/custom_back_button.dart';

class PersonalClothMeasurementScreen extends StatefulWidget {
  const PersonalClothMeasurementScreen({super.key});

  @override
  State<PersonalClothMeasurementScreen> createState() =>
      _PersonalClothMeasurementScreenState();
}

class _PersonalClothMeasurementScreenState
    extends State<PersonalClothMeasurementScreen> {

  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final hipController = TextEditingController();

  File? clothImage;
  File? personalImage;

  bool loading = false;

  Future<void> pickClothImage() async {

    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage == null) return;

    setState(() {
      clothImage = File(pickedImage.path);
    });

    await AppDataService.saveUploadedClothPath(
      pickedImage.path,
    );
  }

  Future<void> pickPersonalImage() async {

    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage == null) return;

    setState(() {
      personalImage = File(pickedImage.path);
    });

    await AppDataService.addHistory(
      'Personal image uploaded',
    );
  }

  Future<void> saveData() async {

    if (clothImage == null) {
      showMessage('Please upload cloth image');
      return;
    }

    if (personalImage == null) {
      showMessage('Please upload personal image');
      return;
    }

    if (heightController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty ||
        chestController.text.trim().isEmpty ||
        waistController.text.trim().isEmpty ||
        hipController.text.trim().isEmpty) {

      showMessage('Please enter all measurements');
      return;
    }

    try {

      setState(() => loading = true);

      await AppDataService.saveOrUpdateMeasurements(
        measurements: {

          'measurementType':
              'personalAndCloth',

          'height':
              heightController.text.trim(),

          'weight':
              weightController.text.trim(),

          'chest':
              chestController.text.trim(),

          'waist':
              waistController.text.trim(),

          'hip':
              hipController.text.trim(),

          'clothImagePath':
              clothImage!.path,

          'personalImagePath':
              personalImage!.path,
        },
      );

      await AppDataService.addHistory(
        'Personal + cloth measurements saved',
      );

      if (!mounted) return;

      showMessage(
        'Measurements saved successfully',
      );

      // GO TO SUBSCRIPTION

      Navigator.pushNamed(
        context,
        '/subscription',
      );

    } catch (e) {

      showMessage(e.toString());

    } finally {

      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: brown,
      ),
    );
  }

  @override
  void dispose() {

    heightController.dispose();
    weightController.dispose();
    chestController.dispose();
    waistController.dispose();
    hipController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 320,

            child: SingleChildScrollView(
              child: Column(
                children: [

                  const CustomBackButton(),

                  const SizedBox(height: 10),

                  Image.asset(
                    'images/fv.png',
                    width: 150,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: 295,

                    padding: const EdgeInsets.fromLTRB(
                      22,
                      18,
                      22,
                      24,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),

                      borderRadius:
                          BorderRadius.circular(45),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Center(
                          child: Text(
                            'Personal & Cloth',

                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            uploadBox(
                              title: 'Cloth Image',

                              image: clothImage,

                              onTap: pickClothImage,
                            ),

                            const SizedBox(width: 12),

                            uploadBox(
                              title: 'Personal Image',

                              image: personalImage,

                              onTap: pickPersonalImage,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        label('Height'),
                        field(heightController, 'cm'),

                        label('Weight'),
                        field(weightController, 'kg'),

                        label('Chest'),
                        field(chestController, 'cm'),

                        label('Waist'),
                        field(waistController, 'cm'),

                        label('Hip'),
                        field(hipController, 'cm'),

                        const SizedBox(height: 20),

                        Center(
                          child: SizedBox(
                            width: 150,
                            height: 42,

                            child: ElevatedButton(
                              onPressed:
                                  loading
                                      ? null
                                      : saveData,

                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    brown,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    8,
                                  ),
                                ),
                              ),

                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,

                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,

                                        strokeWidth: 2,
                                      ),
                                    )

                                  : const Text(
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
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget uploadBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 120,
        height: 105,

        decoration: BoxDecoration(
          color: Colors.white,

          border:
              Border.all(color: Colors.black26),

          borderRadius:
              BorderRadius.circular(18),
        ),

        child: image == null

            ? Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.upload_file,
                    size: 28,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    title,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              )

            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(18),

                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget label(String text) {

    return Padding(
      padding: const EdgeInsets.only(
        top: 7,
        bottom: 4,
      ),

      child: Text(
        text,

        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String hint,
  ) {

    return SizedBox(
      height: 32,

      child: TextField(
        controller: controller,

        keyboardType:
            TextInputType.number,

        decoration: InputDecoration(
          hintText: hint,

          filled: true,

          fillColor: Colors.white,

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),

          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }
}