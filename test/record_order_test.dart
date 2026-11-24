import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/record_order.dart';

void main() {
  test('new registrations precede older and undated legacy records', () {
    final records = <Map<String, dynamic>>[
      {'uid': 'legacy'},
      {'uid': 'old', 'createdAt': Timestamp(100, 0)},
      {'uid': 'new', 'createdAt': Timestamp(200, 0)},
    ]..sort(newestRecordFirst);
    expect(records.map((r) => r['uid']), ['new', 'old', 'legacy']);
  });
}
