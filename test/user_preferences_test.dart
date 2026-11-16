import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitvisions/services/user_preferences.dart';
void main() {
  test('Drafts and favorites persist separately for each account', () async {
    SharedPreferences.setMockInitialValues({});
    await UserPreferences.write('clothesDraft', {'answers': {'Size': 'Medium'}, 'notes': 'Long sleeves'}, accountId: 'alice');
    await UserPreferences.write('favorites', {'image1': true}, accountId: 'alice');
    expect((await UserPreferences.read('clothesDraft', accountId: 'alice'))['notes'], 'Long sleeves');
    expect(await UserPreferences.read('clothesDraft', accountId: 'bob'), isEmpty);
    expect((await UserPreferences.read('favorites', accountId: 'alice'))['image1'], true);
  });
}
