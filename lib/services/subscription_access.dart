import 'package:cloud_firestore/cloud_firestore.dart';

/// Demo entitlement only: a pending demo request is not a real payment.
class SubscriptionAccess {
  static int months(num amount) => amount == 7
      ? 6
      : amount == 3
          ? 1
          : 0;
  static int planMonths(Map<String, dynamic> plan) {
    final explicit = plan['durationMonths'];
    if (explicit is int && explicit >= 1 && explicit <= 120) return explicit;
    final match = RegExp(r'^(\d+)\s*months?$', caseSensitive: false)
        .firstMatch('${plan['duration'] ?? ''}'.trim());
    if (match != null) {
      final n = int.parse(match[1]!);
      if (n >= 1 && n <= 120) return n;
    }
    return months((plan['price'] as num?) ?? (plan['amount'] as num?) ?? 0);
  }

  static DateTime expiry(DateTime start, int months) {
    final last = DateTime(start.year, start.month + months + 1, 0).day;
    final construct = start.isUtc ? DateTime.utc : DateTime.new;
    return construct(
        start.year,
        start.month + months,
        start.day > last ? last : start.day,
        start.hour,
        start.minute,
        start.second,
        start.millisecond,
        start.microsecond);
  }

  static Map<String, dynamic>? active(Iterable<Map<String, dynamic>> records,
      {DateTime? now}) {
    final time = now ?? DateTime.now();
    Map<String, dynamic>? result;
    for (final record in records) {
      final created = record['createdAt'];
      final count = planMonths(record);
      if (created is! Timestamp ||
          count == 0 ||
          !['pending', 'demo_active', 'paid'].contains(record['status'])) {
        continue;
      }
      final start = record['startsAt'] is Timestamp
          ? (record['startsAt'] as Timestamp).toDate()
          : created.toDate();
      final end = record['expiresAt'] is Timestamp
          ? (record['expiresAt'] as Timestamp).toDate()
          : expiry(start, count);
      if (start.isAfter(time) || !end.isAfter(time)) continue;
      if (result == null || end.isAfter(result['expiresAt'] as DateTime)) {
        result = {...record, 'startsAt': start, 'expiresAt': end};
      }
    }
    return result;
  }
}
