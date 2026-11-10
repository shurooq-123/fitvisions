import 'package:flutter/material.dart';
import 'package:fitvisions/services/avatar_prompt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';
import 'package:fitvisions/services/body_size_presets.dart';
import 'package:fitvisions/services/measurement_avatar.dart';

void main() {
  testWidgets(
      'Cloud avatar generates the measured body first and dresses it second',
      (tester) async {
    var generatorCalls = 0;
    final sentPrompts = <String>[];
    final referenceCounts = <int>[];
    String? action;
    bool hasPayment = false;
    await tester.pumpWidget(MaterialApp(
        routes: {
          '/subscription': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            action = args['avatarAction'] as String;
            return Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Return from subscription'),
              ),
            );
          },
        },
        home: AiGenerationScreen(
          title: 'Generate Avatar',
          prompt: '',
          avatar: true,
          measuredBodyReference: true,
          measurementsInInches: true,
          clothingPhoto: 'images/bridal_satin.png',
          personalPhoto: 'images/bridal_satin.png',
          avatarGender: AvatarGender.female,
          garmentType: AvatarGarment.longDress,
          size: '4XL',
          subscriptionCheck: () async => hasPayment,
          measurements: const {
            'Height': '170',
            'Weight': '65',
            'Chest': '132',
            'Waist': '114',
            'Hips': '138',
            'Shoulders': '53.5'
          },
          generator: (prompt, photos) async {
            generatorCalls++;
            sentPrompts.add(prompt);
            referenceCounts.add(photos.length);
            return photos.first;
          },
        )));
    await tester.runAsync(() async {
      await tester.tap(find.text('Generate'));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    expect(generatorCalls, 2);
    expect(referenceCounts, [2, 2]);
    expect(sentPrompts.first, contains('Reference image 0 is the face only'));
    expect(sentPrompts.first,
        contains('Reference image 1 is the measured body-shape guide'));
    expect(sentPrompts.first, contains('adult woman'));
    final sentPrompt = sentPrompts.last;
    expect(sentPrompt, contains('Selected chart size 4XL'));
    expect(sentPrompt, contains('Waist and abdomen circumference 114.0 cm'));
    expect(sentPrompt, contains('Shoulder width across the back 53.5 cm'));
    expect(sentPrompt, contains('prominent abdomen'));
    expect(sentPrompt, contains('one continuous skirt'));
    expect(sentPrompt, contains('Reference image 1 is the outfit only'));
    expect(sentPrompt, isNot(contains('Weight')));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Your measurements'), findsOneWidget);
    expect(find.text('Waist'), findsOneWidget);
    expect(find.text('44.88 in'), findsOneWidget);
    final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
    final previous = find.widgetWithIcon(IconButton, Icons.chevron_left);
    tester.widget<IconButton>(next).onPressed!();
    await tester.pumpAndSettle();
    expect(generatorCalls, 3);
    expect(referenceCounts.last, 1);
    expect(sentPrompts.last, contains('true right-side profile'));
    expect(sentPrompts.last, contains('Preserve the avatar’s facial features'));
    expect(find.text('Right'), findsOneWidget);
    tester.widget<IconButton>(previous).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Front'), findsOneWidget);
    tester.widget<IconButton>(next).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Right'), findsOneWidget);
    expect(generatorCalls, 3);
    Future<void> checkout(String label) async {
      final button = find.widgetWithText(ElevatedButton, label);
      tester.widget<ElevatedButton>(button).onPressed!();
      await tester.pumpAndSettle();
    }

    expect(find.text('Edit measurements / clothing'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Download'), findsNothing);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Avatar options'), findsOneWidget);
    await checkout('Download');
    expect(action, 'download');
    await tester.tap(find.text('Return from subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Edit measurements / clothing'), findsNothing);
    await checkout('Edit');
    expect(action, 'edit');
    hasPayment = true;
    await tester.tap(find.text('Return from subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Edit measurements / clothing'), findsOneWidget);
    expect(find.text('Change clothing colour'), findsOneWidget);
    final height = tester.widget<TextField>(find.byType(TextField).first);
    expect(height.decoration?.suffixText, 'in');
    expect(height.controller?.text, '66.93');
    final unit = find.byType(DropdownButton<bool>);
    tester.widget<DropdownButton<bool>>(unit).onChanged!(false);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .decoration
            ?.suffixText,
        'cm');
    expect(height.controller?.text, '170');
    tester.widget<DropdownButton<bool>>(unit).onChanged!(true);
    await tester.pumpAndSettle();
    expect(height.controller?.text, '66.93');
    await tester.enterText(find.byType(TextField).first, '68');
    await tester.runAsync(() async {
      tester
          .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Apply changes'))
          .onPressed!();
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    expect(generatorCalls, 5);
    expect(sentPrompts.last, contains('Height 172.72 cm'));
    expect(
        sentPrompts.last, contains('Shoulder width across the back 53.5 cm'));
  });

  test('Every size sends actual chest, waist, hip and shoulder values', () {
    for (final row in avatarSizeRows) {
      final values = {
        'Height': '170',
        ...bodySizeMidpoints(row).map((key, value) => MapEntry(key, '$value')),
      };
      final prompt = cloudMeasuredAvatarPrompt(values,
          garment: AvatarGarment.separates,
          hasClothing: true,
          hasPortrait: false,
          size: row.first);
      expect(prompt, contains('Selected chart size ${row.first}'));
      expect(prompt, contains('Chest circumference ${values['Chest']} cm'));
      expect(prompt,
          contains('Waist and abdomen circumference ${values['Waist']} cm'));
      expect(prompt, contains('Hip circumference ${values['Hips']} cm'));
      expect(prompt,
          contains('Shoulder width across the back ${values['Shoulders']} cm'));
    }
  });

  test(
      'L through 5XL have distinct build guidance and height keeps camera scale',
      () {
    const fullness = [
      'slightly full',
      'moderately full',
      'A full build',
      'visibly full',
      'very full build with a prominent abdomen',
      'distinctly very full'
    ];
    for (final (index, row) in avatarSizeRows.skip(3).indexed) {
      final values = {
        'Height': '120',
        ...bodySizeMidpoints(row).map((key, value) => MapEntry(key, '$value')),
      };
      String prompt(double height, bool body) =>
          cloudMeasuredAvatarPrompt({...values, 'Height': '$height'},
              garment: null,
              hasClothing: !body,
              hasPortrait: false,
              bodyReference: body,
              size: row.first);
      expect(prompt(120, true), contains(fullness[index]));
      expect(prompt(120, true), contains('occupy about 41%'));
      expect(prompt(200, false), contains('occupy about 69%'));
      expect(prompt(200, false), contains('very tall adult'));
    }
  });

  test(
      'Both generations and every alternate angle request a blank face without a portrait',
      () {
    const values = {
      'Height': '170',
      'Chest': '132',
      'Waist': '114',
      'Hips': '138'
    };
    for (final isBody in [true, false]) {
      final prompt = cloudMeasuredAvatarPrompt(values,
          garment: AvatarGarment.longDress,
          hasClothing: !isBody,
          hasPortrait: false,
          bodyReference: isBody);
      expect(prompt, contains('smooth, blank face'));
    }
    for (final angle in AvatarViewAngle.values) {
      final prompt = cloudAvatarAnglePrompt(angle, hasPortrait: false);
      expect(prompt, contains(angle.direction));
      expect(prompt, contains('smooth, blank face'));
    }
  });

  test('Gender-selected avatars use natural faces and infer the garment cut',
      () {
    final values = {
      'Height': '170',
      ...bodySizeMidpoints(avatarSizeRows.last)
          .map((key, value) => MapEntry(key, '$value')),
    };
    for (final gender in AvatarGender.values) {
      final body = cloudMeasuredAvatarPrompt(values,
          garment: null,
          hasClothing: false,
          hasPortrait: false,
          gender: gender,
          bodyReference: true,
          hasMeasurementGuide: true);
      expect(body, contains('fictional adult ${gender.subject}'));
      expect(body, contains('natural visible facial features'));
      expect(
          body, contains('Reference image 0 is the measured body-shape guide'));
      expect(body, contains('full hips, upper arms and thighs'));
      final outfit = cloudMeasuredAvatarPrompt(values,
          garment: null, hasClothing: true, hasPortrait: false, gender: gender);
      expect(outfit,
          contains('Read the garment type and length from the outfit photo'));
      expect(outfit, contains('Waist and abdomen circumference 122.0 cm'));
      expect(outfit, contains('Preserve the facial features'));
    }
  });

  test('5XL avatar garment uses the selected torso and shoulder dimensions',
      () {
    final midpoints = bodySizeMidpoints(avatarSizeRows.last);
    expect(avatarSizeRows.last.first, '5XL');
    final input = {
      'Height': '170',
      for (final entry in midpoints.entries) entry.key: entry.value.toString(),
    };
    expect(validAvatarMeasurements(input), isTrue);
    expect(validAvatarMeasurements({...input, 'Height': '49.99'}), isFalse);
    final model = MeasurementAvatar(input, garment: AvatarGarment.longDress);
    expect(model.garmentTop, isNotEmpty);
    for (final entry in midpoints.entries) {
      expect(model.measured[entry.key], closeTo(entry.value, 1e-8));
    }
  });

  test('Every preset shapes the garment around its own dimensions', () {
    double lastWidth = 0;
    for (final row in avatarSizeRows) {
      final values = {
        'Height': '170',
        ...bodySizeMidpoints(row).map((key, value) => MapEntry(key, '$value')),
      };
      final model = MeasurementAvatar(values, garment: AvatarGarment.longDress);
      final width = model.loops['Waist']!.first.x * 2;
      expect(width, greaterThan(lastWidth), reason: row.first);
      lastWidth = width;
      for (final entry in model.measured.entries) {
        expect(entry.value, closeTo(double.parse(values[entry.key]!), 1e-8));
      }
    }
  });
}
