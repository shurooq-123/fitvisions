import '../widgets/fashion_backdrop.dart';
import '../services/app_language.dart';
import '../constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key, this.firestore});
  final FirebaseFirestore? firestore;

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  static const bg = Color(0xFFFAF0F3);
  static const brown = Color(0xFF85465F);
  static const purple = Color(0xFF914C6A);

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
    // Loading this screen must not create database records.
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

    final price = double.tryParse(priceController.text.trim());
    final duration = RegExp(r'^(\d+)\s*months?$', caseSensitive: false)
        .firstMatch(durationController.text.trim());
    if (price == null ||
        !price.isFinite ||
        price <= 0 ||
        !RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(priceController.text.trim())) {
      showMessage('Enter a positive price, with at most 3 decimal places.');
      return;
    }
    if (duration == null ||
        int.parse(duration[1]!) < 1 ||
        int.parse(duration[1]!) > 120) {
      showMessage(
          'Enter a duration from 1 month to 120 months, for example 6 Months.');
      return;
    }
    try {
      setState(() => loading = true);

      final data = {
        'name': nameController.text.trim(),
        'price': price,
        'durationMonths': int.parse(duration[1]!),
        'duration': durationController.text.trim(),
        'features': featuresController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (editingId == null) {
        await (widget.firestore ?? FirebaseFirestore.instance)
            .collection('plans')
            .add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });

        showMessage('Plan added successfully');
      } else {
        final db = widget.firestore ?? FirebaseFirestore.instance;
        final batch = db.batch();
        // Publish a new catalogue entry; purchased subscription snapshots stay intact.
        batch.set(db.collection('plans').doc(),
            {...data, 'createdAt': FieldValue.serverTimestamp()});
        batch.delete(db.collection('plans').doc(editingId));
        await batch.commit();

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
    await (widget.firestore ?? FirebaseFirestore.instance)
        .collection('plans')
        .doc(id)
        .delete();

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
          title: const AppText('Delete Plan'),
          content: AppText('Delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const AppText('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await deletePlan(id);
              },
              child: const AppText('Delete'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(text),
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
    AppLanguage.watch(context);
    final showForm = showAddForm || editingId != null;

    return Scaffold(
      backgroundColor: AppColors.page(context, bg),
      body: FashionBackdrop(
          child: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 320,
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  const AppText(
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
                      child: const AppText(
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
                    stream: (widget.firestore ?? FirebaseFirestore.instance)
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
                          child: AppText('No plans yet'),
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
      )),
      bottomNavigationBar: adminBottomNav(context, 2),
    );
  }

  Widget formBox() {
    return Container(
      width: 295,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel(context, const Color(0xFFFFFAF8)),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: editingId == null ? Colors.transparent : brown,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
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
            decoration: InputDecoration(
              hintText:
                  trError('Unlimited try-ons\nSave your looks\nNo watermark'),
              filled: true,
              fillColor: AppColors.field(context),
              border: const OutlineInputBorder(),
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
                      : AppText(
                          editingId == null ? 'Add' : 'Update',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: clearForm,
                  child: const AppText('Cancel'),
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
    final rawPrice = data['price'] ?? 0;
    final price = rawPrice is num && rawPrice == rawPrice.roundToDouble()
        ? rawPrice.toInt().toString()
        : rawPrice.toString();
    final duration = data['duration'] ?? '';
    final features = data['features'] ?? '';

    return Container(
      width: 295,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel(context, const Color(0xFFFFFAF8)),
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
              Icon(
                Icons.workspace_premium,
                color: AppColors.accent(context, purple),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('Edit plan'),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 48),
                padding: EdgeInsets.zero,
                onPressed: () => fillForm(id, data),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: tr('Delete plan'),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 48),
                padding: EdgeInsets.zero,
                onPressed: () => confirmDelete(id, name),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppText(
            '$price OMR / $duration',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
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
      child: AppText(text),
    );
  }

  Widget field(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: trError(hint),
        filled: true,
        fillColor: AppColors.field(context),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
