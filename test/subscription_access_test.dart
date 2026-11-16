import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitvisions/services/subscription_access.dart';

void main() {
  Map<String, dynamic> payment(DateTime start, num amount,
          {String status = 'pending'}) =>
      {
        'createdAt': Timestamp.fromDate(start),
        'amount': amount,
        'status': status,
      };
  test('monthly demo access expires at exact boundary', () {
    final start = DateTime(2026, 1, 31, 14, 25);
    final end = DateTime(2026, 2, 28, 14, 25);
    final record = payment(start, 3);
    final active = SubscriptionAccess.active([record],
        now: end.subtract(const Duration(seconds: 1)));
    expect(active?['startsAt'], start);
    expect(active?['expiresAt'], end);
    expect(SubscriptionAccess.active([record], now: end), isNull);
  });
  test(
      'six months survives a new session and works independently of creation type',
      () {
    final record = payment(DateTime(2026, 1, 1), 7);
    expect(SubscriptionAccess.active([record], now: DateTime(2026, 6, 30)),
        isNotNull);
    expect(
        SubscriptionAccess.active([record], now: DateTime(2026, 7, 1)), isNull);
  });
  test('cancelled, unsupported and future records do not grant access', () {
    final now = DateTime(2026, 2, 1);
    expect(
        SubscriptionAccess.active([
          payment(DateTime(2026, 1, 2), 7, status: 'cancelled'),
          payment(DateTime(2026, 1, 2), 99),
          payment(DateTime(2026, 3, 2), 3),
        ], now: now),
        isNull);
  });
}
