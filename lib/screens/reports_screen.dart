import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_export.dart';
import 'package:printing/printing.dart';
import '../services/app_data_service.dart';
import '../widgets/prototype_ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool busy = false;
  String? error;
  Uint8List? pdf;
  String selected = 'Activity';
  String? filterUid;
  Future<void> generate() async {
    setState(() {
      busy = true;
      error = null;
      pdf = null;
    });
    try {
      final user = AppDataService.requireUser();
      final db = AppDataService.firestore;
      final profile = (await db
              .collection('users')
              .doc(user.uid)
              .get(const GetOptions(source: Source.server)))
          .data();
      final admin = profile?['role'] == 'admin';
      final name =
          '${profile?['firstName'] ?? ''} ${profile?['lastName'] ?? ''}'.trim();
      final collection = {
        'Activity': 'history',
        'Subscriptions and payments': 'payments',
        'Feedback': 'feedback'
      }[selected]!;
      Query<Map<String, dynamic>> query = db.collection(collection);
      if (!admin) {
        query = query.where('uid', isEqualTo: user.uid);
      } else if (filterUid?.trim().isNotEmpty == true) {
        query = query.where('uid', isEqualTo: filterUid!.trim());
      }
      final records = (await query.get(const GetOptions(source: Source.server)))
          .docs
          .map((d) => d.data())
          .toList()
        ..sort((a, b) => ((b['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0)
            .compareTo(
                (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
      final bytes = await buildReportPdf(
          selected: selected, name: name, admin: admin, records: records);
      if (mounted) setState(() => pdf = bytes);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Could not generate the report. Check your connection and access permissions, then retry.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      nav: false,
      title: 'Reports',
      child: Column(children: [
        DropdownButtonFormField<String>(
            initialValue: selected,
            items: ['Activity', 'Subscriptions and payments', 'Feedback']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: busy
                ? null
                : (v) => setState(() {
                      selected = v!;
                      pdf = null;
                    })),
        const SizedBox(height: 16),
        const Text(
            'Reports contain your records. Administrators can export system-wide records. Keep downloaded reports private.'),
        const SizedBox(height: 16),
        PrototypeButton('Generate report', onPressed: busy ? null : generate),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        if (pdf != null) ...[
          const SizedBox(height: 16),
          const Text('Report ready'),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Save PDF / Print'),
                onPressed: () async {
                  try {
                    await Printing.layoutPdf(
                        onLayout: (_) => pdf!, name: 'FitVisions-report.pdf');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Could not open PDF export. Try Share PDF.')));
                    }
                  }
                }),
            TextButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
                onPressed: () async {
                  try {
                    await Printing.sharePdf(
                        bytes: pdf!, filename: 'FitVisions-report.pdf');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Could not share the report. Please retry.')));
                    }
                  }
                })
          ])
        ]
      ]));
}
