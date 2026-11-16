import 'package:cloud_firestore/cloud_firestore.dart';

/// Demo entitlement only: a pending demo request is not a real payment.
class SubscriptionAccess {
  static int months(num amount) => amount == 7
      ? 6
      : amount == 3
          ? 1
          : 0;
  static DateTime expiry(DateTime start, int months) {
    final last = DateTime(start.year, start.month + months + 1, 0).day;
    return DateTime(
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
      final count = months((record['amount'] as num?) ?? 0);
      if (created is! Timestamp ||
          count == 0 ||
          record['status'] != 'pending') {
        continue;
      }
      final start = created.toDate();
      final end = expiry(start, count);
      if (start.isAfter(time) || !end.isAfter(time)) continue;
      if (result == null || end.isAfter(result['expiresAt'] as DateTime)) {
        result = {...record, 'startsAt': start, 'expiresAt': end};
      }
    }
    return result;
  }
}
