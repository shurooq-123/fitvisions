import '../services/app_language.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_export.dart';
import 'package:printing/printing.dart';
import '../services/app_data_service.dart';
import '../widgets/prototype_ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.userId, this.userName});
  final String? userId, userName;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool busy = false;
  String? error;
  Uint8List? pdf;
  String selected = 'Activity';
  String? get filterUid => widget.userId;
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
      if (!admin) throw StateError('Administrator access required');
      final name =
          '${profile?['firstName'] ?? ''} ${profile?['lastName'] ?? ''}'.trim();
      final collection = {
        'Activity': 'history',
        'Subscriptions and payments': 'payments',
        'Feedback': 'feedback'
      }[selected]!;
      Query<Map<String, dynamic>> query = db.collection(collection);
      if (filterUid?.trim().isNotEmpty == true) {
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
      final targetProfile = filterUid == null ? null : (await db.collection('users').doc(filterUid).get(const GetOptions(source: Source.server))).data();
      final bytes = await buildReportPdf(
          selected: selected,
          name: widget.userName ?? name,
          admin: admin,
          records: records, profile: targetProfile);
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
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final uid = AppDataService.uid;
    if (uid == null)
      return const Scaffold(
          body: Center(child: AppText('Administrator access required')));
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            AppDataService.firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          if (snapshot.data?.data()?['role'] != 'admin')
            return const Scaffold(
                body: Center(child: AppText('Administrator access required')));
          return reportContent(context);
        });
  }

  Widget reportContent(BuildContext context) => PrototypePage(
      nav: false,
      title:
          widget.userName == null ? 'Reports' : 'Reports: ${widget.userName}',
      child: Column(children: [
        DropdownButtonFormField<String>(
            initialValue: selected,
            items: ['Activity', 'Subscriptions and payments', 'Feedback']
                .map((s) => DropdownMenuItem(value: s, child: AppText(s)))
                .toList(),
            onChanged: busy
                ? null
                : (v) => setState(() {
                      selected = v!;
                      pdf = null;
                    })),
        const SizedBox(height: 16),
        const AppText(
            'Administrator reports. Keep downloaded reports private.'),
        const SizedBox(height: 16),
        PrototypeButton('Generate report', onPressed: busy ? null : generate),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          AppText(error!, style: const TextStyle(color: Colors.red)),
        if (pdf != null) ...[
          const SizedBox(height: 16),
          const AppText('Report ready'),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                icon: const Icon(Icons.download),
                label: const AppText('Save PDF / Print'),
                onPressed: () async {
                  try {
                    await Printing.layoutPdf(
                        onLayout: (_) => pdf!, name: 'FitVisions-report.pdf');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: AppText(
                              'Could not open PDF export. Try Share PDF.')));
                    }
                  }
                }),
            TextButton.icon(
                icon: const Icon(Icons.share),
                label: const AppText('Share PDF'),
                onPressed: () async {
                  try {
                    await Printing.sharePdf(
                        bytes: pdf!, filename: 'FitVisions-report.pdf');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: AppText(
                              'Could not share the report. Please retry.')));
                    }
                  }
                })
          ])
        ]
      ]));
}
