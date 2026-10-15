import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/services/dress_reference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All 50 dresses have unique IDs and valid source regions', () {
    expect(dressReferences.length, 50);
    expect(dressReferences.map((r) => r.id).toSet().length, 50);
    expect(dressReferences.map((r) => r.asset).toSet().length, 6);
    for (final ref in dressReferences) {
      expect(ref.bounds.every((v) => v >= 0 && v <= 1), isTrue);
      expect(ref.bounds[2], greaterThan(ref.bounds[0]));
      expect(ref.bounds[3], greaterThan(ref.bounds[1]));
      expect(ref.occasions, isNotEmpty);
    }
  });
  test('Ranking prioritizes matching cut, length, colour and neckline', () {
    final results = rankedDressReferences({
      'Gender / clothing style': 'Female',
      'Favourite colour': 'Black',
      'Length': 'Long',
      'Silhouette': 'Bodycon',
      'Neckline': 'High neck',
      'Sleeves': 'Long sleeves'
    });
    expect(results.first.id, 'black-05');
    expect(rankedDressReferences({'Gender / clothing style': 'Male'}), isEmpty);
    expect(
        rankedDressReferences(
            {'Gender / clothing style': 'Female', 'Occasion': 'Abaya'}),
        isEmpty);
  });
  test('Each reference loads as a separate cropped PNG', () async {
    for (final ref in dressReferences) {
      final bytes = await ref.imageBytes();
      expect(bytes.take(4), [137, 80, 78, 71]);
      expect(bytes.length, greaterThan(100));
    }
  });
}
