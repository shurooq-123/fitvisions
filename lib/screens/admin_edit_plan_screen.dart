import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEditPlanScreen extends StatefulWidget {
  const AdminEditPlanScreen({super.key});

  @override
  State<AdminEditPlanScreen> createState() => _AdminEditPlanScreenState();
}

class _AdminEditPlanScreenState extends State<AdminEditPlanScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();
  final featuresController = TextEditingController();

  bool loaded = false;
  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      final data = args['data'] as Map<String, dynamic>;

      nameController.text = data['name'] ?? '';
      priceController.text = '${data['price'] ?? ''}';
      durationController.text = data['duration'] ?? '';
      featuresController.text = data['features'] ?? '';

      loaded = true;
    }
  }

  Future<void> updatePlan() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final id = args['id'];

    try {
      setState(() => loading = true);

      await FirebaseFirestore.instance.collection('plans').doc(id).update({
        'name': nameController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'duration': durationController.text.trim(),
        'features': featuresController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('Plan updated successfully');
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
                    'Edit Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  formBox(),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: loading ? null : updatePlan,
                      style: ElevatedButton.styleFrom(backgroundColor: brown),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Update',
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
          field(nameController),
          label('Price'),
          field(priceController),
          label('Duration'),
          field(durationController),
          label('Features'),
          TextField(
            controller: featuresController,
            maxLines: 5,
            decoration: const InputDecoration(
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

  Widget field(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    );
  }
}