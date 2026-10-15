import '../widgets/prototype_ui.dart';
import '../widgets/history_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.history});
  final Stream<QuerySnapshot>? history;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic>? selected;
  void showDetails(Map<String, dynamic> data) =>
      showHistoryResult(context, data);

  static const bg = Color(0xFFCED1C6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios, size: 30))),
            const SizedBox(height: 25),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.history ?? AppDataService.userHistoryStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text(
                            'Could not load history. Check your connection and try again.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final items = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aTime = (a.data()
                          as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTime = (b.data()
                          as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      return (bTime?.millisecondsSinceEpoch ?? 0)
                          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
                    });

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final data = items[index].data() as Map<String, dynamic>;

                      final title = data['title'] ?? 'Activity';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: InkWell(
                            onTap: () {
                              setState(() => selected = data);
                              showDetails(data);
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 65,
                                    height: 65,
                                    child: HistoryPreview(data)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "$title\n${data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toString().split(' ').first : ''}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.grey, size: 24),
                              ],
                            )),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 220,
                  child: TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEFEFEF),
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder()),
                    onPressed: () {
                      if (selected != null) {
                        showDetails(selected!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Select a history item to view its details.')));
                      }
                    },
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('View Details'),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey)
                        ]),
                  ),
                )),
          ],
        ),
      ),
      bottomNavigationBar: bottomNav(context),
    );
  }

  Widget bottomNav(BuildContext context) => const PrototypeNav(index: 2);
}
