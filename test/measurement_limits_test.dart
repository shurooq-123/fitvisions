import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/services/body_size_presets.dart';

void main() {
  test('Each measurement rejects zero one non-finite and outside limits', () {
    for (final e in measurementLimits.entries) {
      for (final bad in [
        '0',
        '1',
        '-1',
        'NaN',
        'Infinity',
        '${e.value.$1 - 0.1}',
        '${e.value.$2 + 0.1}'
      ]) {
        expect(measurementError(e.key, bad), isNotNull,
            reason: '${e.key}: $bad');
      }
      expect(measurementError(e.key, '${e.value.$1}'), isNull);
      expect(measurementError(e.key, '${e.value.$2}'), isNull);
    }
    expect(
        validAvatarMeasurements(
            {'Height': '170', 'Chest': '1', 'Waist': '75', 'Hips': '99'}),
        isFalse);
  });
}
