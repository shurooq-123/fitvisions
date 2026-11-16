import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitvisions/services/phone_validation.dart';
import 'package:fitvisions/services/auth_service.dart';
import 'package:fitvisions/services/history_feed.dart';

void main() {
  test('Mobile validation follows selected country and normalizes dialing code',
      () {
    expect(internationalMobile('91234567', 'OM'), '+96891234567');
    expect(internationalMobile('9008798', 'OM'), isNull);
    expect(internationalMobile('912345676', 'OM'), isNull);
    expect(internationalMobile('501234567', 'AE'), '+971501234567');
    expect(internationalMobile('9876543210', 'IN'), '+919876543210');
    expect(internationalMobile('07400123456', 'GB'), '+447400123456');
    expect(internationalMobile('123', 'US'), isNull);
  });
  test('Password requires a number as well as existing complexity', () {
    expect(AuthService.isValidPassword('Password!'), isFalse);
    expect(AuthService.isValidPassword('Password1!'), isTrue);
  });
  test('History retains avatar previews and merges subscriptions oldest first',
      () {
    final result = mergeHistory([
      {
        'title': 'Avatar',
        'kind': 'avatar',
        'previewBase64': 'saved',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(20)
      },
      {
        'title': 'Subscription selected: Basic',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(10)
      },
    ], [
      {
        'plan': 'Basic',
        'price': 3,
        'status': 'selected',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(10)
      },
    ]);
    expect(result.length, 2);
    expect(result.first['kind'], 'subscription');
    expect(result.last['previewBase64'], 'saved');
  });
}
