import 'package:cloud_firestore/cloud_firestore.dart';

/// Keep legacy records without dates visible, after dated records.
int newestRecordFirst(Map<String, dynamic> a, Map<String, dynamic> b) {
  int time(Map<String, dynamic> record) {
    final value = record['createdAt'];
    return value is Timestamp ? value.microsecondsSinceEpoch : 0;
  }

  return time(b).compareTo(time(a));
}
