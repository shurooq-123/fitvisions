import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:fitvisions/services/ai_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fitvisions/screens/measurement_avatar_screen.dart';
import 'package:fitvisions/services/measurement_avatar.dart';
import 'package:fitvisions/widgets/measurement_avatar_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Measured preview updates dimensions without calling AI',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MeasurementAvatarScreen(measurements: {
      'Height': '170',
      'Chest': '96',
      'Waist': '78',
      'Hips': '102'
    })));
    final chest = find.widgetWithText(TextFormField, 'Chest');
    await tester.ensureVisible(chest);
    await tester.enterText(chest, '110');
    await tester.ensureVisible(find.text('Update body'));
    await tester.tap(find.text('Update body'));
    await tester.pumpAndSettle();
    expect(find.text('Chest: 110.00 cm on mesh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Measured torso loops and mesh height match the inputs across shapes',
      () {
    for (final h in [145, 170, 198]) {
      for (final c in [78, 96, 128]) {
        for (final ratio in [.5, .68, .9]) {
          final input = {
            'Height': '$h',
            'Chest': '$c',
            'Waist': '${c - 16}',
            'Hips': '${c + 6}'
          };
          final model = MeasurementAvatar(input, depthRatio: ratio);
          for (final e in model.measured.entries) {
            expect(e.value, closeTo(double.parse(input[e.key]!), 1e-8));
          }
          expect(
              model.triangles.every((t) => [t.a, t.b, t.c]
                  .every((p) => p.x.isFinite && p.y.isFinite && p.z.isFinite)),
              true);
        }
      }
    }
  });
  test(
      'Invalid inputs are rejected and weight is not mistaken for a unique shape',
      () {
    expect(
        () => MeasurementAvatar(
            {'Height': 'NaN', 'Chest': '90', 'Waist': '70', 'Hips': '95'}),
        throwsArgumentError);
    final a = MeasurementAvatar({
      'Height': '170',
      'Chest': '96',
      'Waist': '78',
      'Hips': '102',
      'Weight': '60'
    });
    final b = MeasurementAvatar({
      'Height': '170',
      'Chest': '96',
      'Waist': '78',
      'Hips': '102',
      'Weight': '90'
    });
    expect(a.toObj(), b.toObj());
  });
  test('Render reproducible local front and side images and an audit report',
      () async {
    final dir = Directory('output/measured-avatar')
      ..createSync(recursive: true);
    final report = <Map<String, dynamic>>[];
    for (final row in [
      ['small', 155, 84, 66, 90],
      ['medium', 170, 96, 78, 102],
      ['large', 190, 120, 100, 126]
    ]) {
      final values = {
        'Height': '${row[1]}',
        'Chest': '${row[2]}',
        'Waist': '${row[3]}',
        'Hips': '${row[4]}'
      };
      final model = MeasurementAvatar(values);
      await File('${dir.path}/${row[0]}-front.png')
          .writeAsBytes(await renderMeasurementAvatar(model));
      await File('${dir.path}/${row[0]}-side.png').writeAsBytes(
          await renderMeasurementAvatar(model, angle: math.pi / 2));
      await File('${dir.path}/${row[0]}.obj').writeAsString(model.toObj());
      report.add({
        'case': row[0],
        'inputCm': values,
        'measuredCm': model.measured,
        'errorsCm': {
          for (final e in model.measured.entries)
            e.key: (e.value - double.parse(values[e.key]!)).abs()
        },
        'triangles': model.triangles.length,
        'depthRatio': model.depthRatio
      });
    }
    final body = await File('${dir.path}/medium-front.png').readAsBytes();
    final garment = (await rootBundle.load('images/traditional_male.png'))
        .buffer
        .asUint8List();
    await File('${dir.path}/synthetic-comparison-input.json')
        .writeAsString(jsonEncode({
      'case': 'synthetic-medium-omani-outfit',
      'prompt':
          'Create one fully clothed 3D-style fashion mannequin. Reference 0 is a geometric body: height 170 cm, chest 96 cm, waist 78 cm, hips 102 cm. Preserve its standing pose and silhouette. Reference 1 is an Omani dishdasha: preserve the collarless cut, tassel, colour and garment details. Neutral featureless mannequin head, no real-person identity. Full body, plain background, no text.',
      'images': [
        await AiGenerationService.reference(body),
        await AiGenerationService.reference(garment)
      ]
    }));
    await File('${dir.path}/geometry-audit.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Synthetic mannequin geometry only; not real human likeness or fit accuracy.',
      'cases': report,
      'cloudComparison':
          'Cloud comparisons are separate from this local test; consult output/avatar-model-comparison/RESULTS.md.'
    }));
  });
}
