import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);
  static const purple = Color(0xFF51227D);

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();
  final featuresController = TextEditingController();

  String? editingId;
  bool showAddForm = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    createDefaultPlans();
  }

  Future<void> createDefaultPlans() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('plans').get();

    if (snapshot.docs.isNotEmpty) return;

    await FirebaseFirestore.instance.collection('plans').add({
      'name': 'Premium Plan',
      'price': 7,
      'duration': '6 Months',
      'features':
          'Unlimited try-ons\nSave your looks\nNo watermark\nPriority access',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('plans').add({
      'name': 'Basic Plan',
      'price': 3,
      'duration': '1 Month',
      'features':
          'Limited try-ons\nSave your looks\nBasic recommendations\nStandard access',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void clearForm() {
    setState(() {
      editingId = null;
      showAddForm = false;
      nameController.clear();
      priceController.clear();
      durationController.clear();
      featuresController.clear();
    });
  }

  void openAddForm() {
    setState(() {
      editingId = null;
      showAddForm = true;
      nameController.clear();
      priceController.clear();
      durationController.clear();
      featuresController.clear();
    });
  }

  void fillForm(String id, Map<String, dynamic> data) {
    setState(() {
      editingId = id;
      showAddForm = true;
      nameController.text = data['name'] ?? '';
      priceController.text = '${data['price'] ?? ''}';
      durationController.text = data['duration'] ?? '';
      featuresController.text = data['features'] ?? '';
    });
  }

  Future<void> savePlan() async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty ||
        featuresController.text.trim().isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    try {
      setState(() => loading = true);

      final data = {
        'name': nameController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'duration': durationController.text.trim(),
        'features': featuresController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (editingId == null) {
        await FirebaseFirestore.instance.collection('plans').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });

        showMessage('Plan added successfully');
      } else {
        await FirebaseFirestore.instance
            .collection('plans')
            .doc(editingId)
            .update(data);

        showMessage('Plan updated successfully');
      }

      clearForm();
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> deletePlan(String id) async {
    await FirebaseFirestore.instance.collection('plans').doc(id).delete();

    showMessage('Plan deleted successfully');

    if (editingId == id) {
      clearForm();
    }
  }

  void confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Plan'),
          content: Text('Delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await deletePlan(id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
    featuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showForm = showAddForm || editingId != null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 320,
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  const Text(
                    'Subscription Plans',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: 180,
                    height: 43,
                    child: ElevatedButton(
                      onPressed: openAddForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add New Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (showForm) ...[
                    const SizedBox(height: 18),
                    formBox(),
                  ],

                  const SizedBox(height: 20),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('plans')
                        .orderBy('price', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final plans = snapshot.data!.docs;

                      if (plans.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No plans yet'),
                        );
                      }

                      return Column(
                        children: plans.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return planCard(
                            id: doc.id,
                            data: data,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: adminBottomNav(context, 2),
    );
  }

  Widget formBox() {
    return Container(
      width: 295,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: editingId == null ? Colors.transparent : brown,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editingId == null ? 'Add New Plan' : 'Edit Selected Plan',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          label('Plan Name'),
          field(nameController, 'Premium Plan'),

          label('Price'),
          field(priceController, '7'),

          label('Duration'),
          field(durationController, '6 Months'),

          label('Features'),
          TextField(
            controller: featuresController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Unlimited try-ons\nSave your looks\nNo watermark',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: loading ? null : savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
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
                      : Text(
                          editingId == null ? 'Add' : 'Update',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton(
                  onPressed: clearForm,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget planCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final name = data['name'] ?? '';
    final price = data['price'] ?? 0;
    final duration = data['duration'] ?? '';
    final features = data['features'] ?? '';

    return Container(
      width: 295,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: editingId == id ? brown : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: purple,
                size: 28,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                onPressed: () => fillForm(id, data),
                icon: const Icon(Icons.edit),
              ),

              IconButton(
                onPressed: () => confirmDelete(id, name),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '$price OMR / $duration',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            features,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
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