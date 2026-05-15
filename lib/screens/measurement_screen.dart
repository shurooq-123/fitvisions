import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../widgets/custom_back_button.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final hipController = TextEditingController();

  bool loading = false;

  Future<void> continueNext() async {
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

      await AppDataService.saveMeasurements(
        measurements: {
          'height': heightController.text.trim(),
          'weight': weightController.text.trim(),
          'chest': chestController.text.trim(),
          'waist': waistController.text.trim(),
          'hip': hipController.text.trim(),
        },
      );

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
                  const SizedBox(height: 15),
                  Image.asset(
                    'images/fv.png',
                    width: 160,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 295,
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Measurements',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
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
                        const SizedBox(height: 22),
                        Center(
                          child: SizedBox(
                            width: 150,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: loading ? null : continueNext,
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