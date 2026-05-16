import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAddPlanScreen extends StatefulWidget {
  const AdminAddPlanScreen({super.key});

  @override
  State<AdminAddPlanScreen> createState() => _AdminAddPlanScreenState();
}

class _AdminAddPlanScreenState extends State<AdminAddPlanScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();
  final featuresController = TextEditingController();

  bool loading = false;

  Future<void> addPlan() async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty ||
        featuresController.text.trim().isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    try {
      setState(() => loading = true);

      await FirebaseFirestore.instance.collection('plans').add({
        'name': nameController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'duration': durationController.text.trim(),
        'features': featuresController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('Plan added successfully');
      Navigator.pop(context);
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: brown),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
    featuresController.dispose();
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
                  const SizedBox(height: 35),
                  const Text(
                    'Add Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  formBox(),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: loading ? null : addPlan,
                      style: ElevatedButton.styleFrom(backgroundColor: brown),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
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

  Widget formBox() {
    return Container(
      width: 295,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label('Plan Name'),
          field(nameController, 'Premium Plan'),
          label('Price'),
          field(priceController, '7'),
          label('Duration'),
          field(durationController, '6 Months'),
          label('Features'),
          TextField(
            controller: featuresController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Unlimited try-ons\nSave your looks\nNo watermark',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(text),
    );
  }

  Widget field(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
    );
  }
}