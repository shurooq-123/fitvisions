import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_data_service.dart';
import '../widgets/custom_back_button.dart';

class ClothMeasurementScreen extends StatefulWidget {
  const ClothMeasurementScreen({super.key});

  @override
  State<ClothMeasurementScreen> createState() =>
      _ClothMeasurementScreenState();
}

class _ClothMeasurementScreenState extends State<ClothMeasurementScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final shoulderController = TextEditingController();
  final sleeveController = TextEditingController();
  final lengthController = TextEditingController();

  File? clothImage;
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

    await AppDataService.saveUploadedClothPath(pickedImage.path);
  }

  Future<void> saveData() async {
    if (clothImage == null) {
      showMessage('Please upload cloth image');
      return;
    }

    if (chestController.text.trim().isEmpty ||
        waistController.text.trim().isEmpty ||
        shoulderController.text.trim().isEmpty ||
        sleeveController.text.trim().isEmpty ||
        lengthController.text.trim().isEmpty) {
      showMessage('Please enter all cloth measurements');
      return;
    }

    try {
      setState(() => loading = true);

      await AppDataService.saveOrUpdateMeasurements(
        measurements: {
          'measurementType': 'clothOnly',
          'clothChest': chestController.text.trim(),
          'clothWaist': waistController.text.trim(),
          'clothShoulder': shoulderController.text.trim(),
          'clothSleeve': sleeveController.text.trim(),
          'clothLength': lengthController.text.trim(),
          'clothImagePath': clothImage!.path,
        },
      );

      await AppDataService.addHistory('Cloth measurements saved');

      if (!mounted) return;

      showMessage('Measurements saved successfully');

      Navigator.pushNamed(context, '/subscription');
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
    chestController.dispose();
    waistController.dispose();
    shoulderController.dispose();
    sleeveController.dispose();
    lengthController.dispose();
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

                  const SizedBox(height: 12),

                  Image.asset(
                    'images/fv.png',
                    width: 155,
                  ),

                  const SizedBox(height: 15),

                  Container(
                    width: 295,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Cloth Measurements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Center(
                          child: GestureDetector(
                            onTap: pickClothImage,
                            child: Container(
                              width: 150,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: clothImage == null
                                  ? const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          size: 36,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Upload cloth image',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        clothImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        label('Chest'),
                        field(chestController, 'cm'),

                        label('Waist'),
                        field(waistController, 'cm'),

                        label('Shoulder'),
                        field(shoulderController, 'cm'),

                        label('Sleeve'),
                        field(sleeveController, 'cm'),

                        label('Length'),
                        field(lengthController, 'cm'),

                        const SizedBox(height: 22),

                        Center(
                          child: SizedBox(
                            width: 150,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: loading ? null : saveData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget field(TextEditingController controller, String hint) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}