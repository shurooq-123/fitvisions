import '../constants/app_colors.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/history_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../services/history_feed.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.history});
  final Stream<QuerySnapshot>? history;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<Map<String, dynamic>>> feed;
  @override
  void initState() {
    super.initState();
    feed = widget.history != null
        ? widget.history!.map((snapshot) => mergeHistory(
            snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList(),
            []))
        : historyFeed(
            AppDataService.userHistoryStream(),
            AppDataService.firestore
                .collection('subscriptions')
                .where('uid', isEqualTo: AppDataService.requireUser().uid)
                .snapshots());
  }

  String search = '';
  String dateLabel(dynamic value) {
    final date = value is Timestamp
        ? value.toDate().toLocal()
        : value is DateTime
            ? value.toLocal()
            : DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Date unavailable';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${days[date.weekday - 1]}, ${two(date.day)}/${two(date.month)}/${date.year} • ${two(date.hour)}:${two(date.minute)}';
  }

  void showDetails(Map<String, dynamic> data) =>
      showHistoryResult(context, data);

  static const bg = Color(0xFFCED1C6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page(context, bg),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: TextField(
                onChanged: (value) =>
                    setState(() => search = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search history or date',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.field(context, const Color(0xFFEFEFEF)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: feed,
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

                  final items = snapshot.data!
                      .where((item) =>
                          '${item['title'] ?? ''} ${dateLabel(item['createdAt'])}'
                              .toLowerCase()
                              .contains(search))
                      .toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        search.isEmpty
                            ? 'No history yet'
                            : 'No matching history',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final data = items[index];

                      final title = data['title'] ?? 'Activity';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.panel(context),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: InkWell(
                            onTap: () {
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
                                    "$title\n${dateLabel(data['createdAt'])}",
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
          ],
        ),
      ),
      bottomNavigationBar: bottomNav(context),
    );
  }

  Widget bottomNav(BuildContext context) => const PrototypeNav(index: 2);
}
