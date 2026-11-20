import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'subscription_access.dart';

Future<Uint8List> buildReportPdf(
    {required String selected,
    required String name,
    required bool admin,
    required List<Map<String, dynamic>> records,
    Map<String, dynamic>? profile}) async {
  String date(dynamic v) => v is Timestamp
      ? v.toDate().toLocal().toString().split('.').first
      : 'Not recorded';
  final headers = selected == 'Subscriptions and payments'
      ? ['Date', 'Account', 'Plan', 'OMR', 'Status', 'Expiry']
      : selected == 'Feedback'
          ? ['Date', 'Account', 'Rating', 'Feedback']
          : ['Date', 'Account', 'Activity'];
  final rows = records.map((d) {
    if (selected == 'Subscriptions and payments') {
      final created = d['createdAt'];
      final end = d['expiresAt'] ??
          (created is Timestamp
              ? Timestamp.fromDate(SubscriptionAccess.expiry(
                  created.toDate(), SubscriptionAccess.planMonths(d)))
              : null);
      return [
        date(created),
        '${d['email'] ?? d['uid']}',
        '${d['plan'] ?? ''}',
        '${d['amount'] ?? ''}',
        '${d['status'] ?? ''}',
        date(end)
      ];
    }
    if (selected == 'Feedback') {
      return [
        date(d['createdAt']),
        '${d['email'] ?? d['uid']}',
        '${d['rating'] ?? ''}/5',
        '${d['message'] ?? ''}'
      ];
    }
    return [
      date(d['createdAt']),
      '${d['email'] ?? d['uid']}',
      '${d['title'] ?? ''}'
    ];
  }).toList();
  final document = pw.Document();
  final font = pw.Font.ttf(await rootBundle.load('assets/fonts/times.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/timesbd.ttf'));
  document.addPage(pw.MultiPage(
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      maxPages: 500,
      footer: (c) =>
          pw.Text('FitVisions | Page ${c.pageNumber} of ${c.pagesCount}'),
      build: (_) => [
            pw.Header(level: 0, text: 'FitVisions - $selected report'),
            pw.Text('Prepared for: $name (${admin ? 'Admin' : 'User'})'),
            if (profile != null) ...[
              pw.Text('Account: ${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'),
              pw.Text('Email: ${profile['email'] ?? ''}'),
              pw.Text('Phone: ${profile['phone'] ?? ''}'),
            ],
            pw.Text('Generated: ${DateTime.now().toLocal()}'),
            pw.Text('Records: ${records.length}. Order: newest to oldest.'),
            if (selected == 'Subscriptions and payments')
              pw.Text('Pending/demo entries are not bank-confirmed revenue.'),
            pw.SizedBox(height: 16),
            if (rows.isEmpty)
              pw.Text('No records found.')
            else
              pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: rows,
                  cellStyle: const pw.TextStyle(fontSize: 9))
          ]));
  return document.save();
}
