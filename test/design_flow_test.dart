// ignore_for_file: subtype_of_sealed_class
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';
import 'package:fitvisions/screens/subscription_screen.dart';
import 'package:fitvisions/screens/payment_screen.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';
import 'package:fitvisions/widgets/measurement_guide.dart';
import 'package:fitvisions/services/avatar_prompt.dart';
import 'package:fitvisions/services/omani_outfit.dart';

class Store extends Mock implements FirebaseFirestore {}

class Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class QueryMock extends Mock implements Query<Map<String, dynamic>> {}

class Snapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class Document extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> tapVisible(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'cancel and failed payment stay locked; successful checkout retains image and permits download to feedback',
      (tester) async {
    final bytes = (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.green, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      image.dispose();
      picture.dispose();
      return data;
    }))!;
    final store = Store(),
        collection = Collection(),
        query = QueryMock(),
        snapshot = Snapshot(),
        doc = Document(),
        premium = Document();
    when(() => store.collection('plans')).thenReturn(collection);
    when(() => collection.orderBy('price', descending: true)).thenReturn(query);
    when(() => query.snapshots()).thenAnswer((_) => Stream.value(snapshot));
    when(() => snapshot.docs).thenReturn([premium, doc]);
    when(() => doc.id).thenReturn('basic');
    when(() => doc.data()).thenReturn({
      'name': 'Basic Plan',
      'price': 3,
      'duration': '1 Month',
      'features': 'Save and edit'
    });
    when(() => premium.id).thenReturn('premium');
    when(() => premium.data()).thenReturn({
      'name': 'Premium Plan',
      'price': 7,
      'duration': '6 Months',
      'features': 'Save and edit',
    });
    int generated = 0, payments = 0, downloads = 0;
    bool failPayment = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('fitvisions/downloads'),
            (call) async {
      downloads++;
      return 'saved.png';
    });
    await tester.pumpWidget(MaterialApp(
        home: AiGenerationScreen(
            title: 'Create Clothes',
            prompt: 'outfit',
            compactDesignResult: true,
            subscriptionCheck: () async => payments > 0,
            generator: (prompt, images) async {
              generated++;
              return bytes;
            }),
        routes: {
          '/subscription': (_) => SubscriptionScreen(
              firestore: store, savePlan: (_) async => 'demo-sub'),
          '/payment': (_) => PaymentScreen(saveRequest: (_) async {
                if (failPayment) throw Exception('offline');
                payments++;
              }),
          '/feedback': (_) =>
              const Scaffold(body: Text('Feedback destination')),
        }));
    expect(find.textContaining('will be sent to Cloudflare AI'), findsNothing);
    await tapVisible(tester, 'Generate');
    expect(find.text('Download'), findsNothing);
    expect(
        find.text('Create a clothing concept from your selected preferences.'),
        findsNothing);
    expect(find.text('Save'), findsOneWidget);
    await tapVisible(tester, 'Edit');
    await tester.tap(find.byIcon(Icons.arrow_back_ios).last);
    await tester.pumpAndSettle();
    expect(find.text('Download'), findsNothing);
    expect(generated, 1);
    await tapVisible(tester, 'Edit');
    expect(find.text('7 OMR / 6 Months'), findsOneWidget);
    expect(find.text('3 OMR / 1 Month'), findsOneWidget);
    await tapVisible(tester, 'Basic Plan');
    final fields = find.byType(TextFormField);
    for (final entry
        in {0: 'Test User', 1: '4242424242424242', 3: '123'}.entries) {
      await tester.ensureVisible(fields.at(entry.key));
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.ensureVisible(fields.at(2));
    await tester.tap(fields.at(2));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'OK');
    await tapVisible(tester, 'Pay');
    expect(find.text('Could not save the request. Please try again.'),
        findsOneWidget);
    expect(payments, 0);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    failPayment = false;
    await tapVisible(tester, 'Pay');
    await tapVisible(tester, 'Continue');
    expect(find.text('Edit avatar'), findsOneWidget);
    expect(find.text('Describe your changes'), findsNothing);
    expect(generated, 1);
    expect(payments, 1);
    await tester.tap(find.byIcon(Icons.arrow_back_ios).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      for (var n = 0; n < 100 && downloads == 0; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(downloads, 1);
    expect(find.text('Feedback destination'), findsOneWidget);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('fitvisions/downloads'), null);
  });
  testWidgets(
      'male outfits have relevant questions and switching removes old options',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    Future<void> select(String key, String value) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    await select('Gender / clothing style', 'Male');
    await select('Outfit type', traditionalOmaniClothes);
    expect(find.text('Headwear'), findsOneWidget);
    expect(find.text('Ankle-length dishdasha and embroidered kumma'),
        findsOneWidget);
    expect(find.text('Neckline'), findsNothing);
    await select('Headwear', 'Kumma');
    await select('Outfit type', 'Sportswear');
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Kumma'), findsNothing);
    expect(find.text('Favourite colour'), findsOneWidget);
    await select('Gender / clothing style', 'Female');
    expect(find.text('Neckline'), findsOneWidget);
    expect(find.text('Activity'), findsNothing);
    await select('Skin tone (optional)', 'Fair');
    expect(find.text('Fair'), findsOneWidget);
  });
  testWidgets('measurement explanation stays hidden until tap', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MeasurementLabel('Waist'))));
    expect(find.text(measurementHelp['Waist']!), findsNothing);
    await tester.tap(find.text('Waist'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is BodyMeasurePainter),
        findsOneWidget);
  });

  testWidgets('Bridal questions and suggestions follow the occasion and age',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    Future<void> select(String key, String value) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    await select('Gender / clothing style', 'Female');
    await select('Age group', 'Adult (65+)');
    await select('Occasion', 'Bridal dress');
    await select('Outfit type', 'Bridal gown');
    final preference = find.byKey(const ValueKey('Outfit preference'));
    await tester.ensureVisible(preference);
    await tester.tap(preference);
    await tester.pumpAndSettle();
    expect(find.text('Timeless bridal gown with comfortable coverage'),
        findsOneWidget);
    expect(find.text('Workwear'), findsNothing);
    expect(find.text('Formal evening outfit'), findsNothing);
    await tester
        .tap(find.text('Timeless bridal gown with comfortable coverage'));
    await tester.pumpAndSettle();
    await select('Age group', 'Adult (18–29)');
    await tester.ensureVisible(preference);
    await tester.tap(preference);
    await tester.pumpAndSettle();
    expect(find.text('Contemporary bridal gown'), findsOneWidget);
    await tester.tap(find.text('Contemporary bridal gown'));
    await tester.pumpAndSettle();
    await select('Outfit type', traditionalOmaniClothes);
    expect(find.text('Below-knee dress, sirwal trousers and lihaf shawl'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('Silhouette')), findsNothing);
    expect(find.byKey(const ValueKey('Outfit preference')), findsNothing);
    final photo = find.text('Personal photo (optional)');
    await tester.ensureVisible(photo);
    expect(
        tester.getTopLeft(photo).dy,
        greaterThan(
            tester.getTopLeft(find.byKey(const ValueKey('Fabric'))).dy));
    expect(find.textContaining('Additional wishes'), findsNothing);
  });

  test('Omani generation keeps the required pieces and optional layers', () {
    final man = omaniOutfitInstructions(true, const {});
    expect(man, contains('embroidered Omani kumma cap'));
    expect(man, contains('ankle-length, collarless Omani dishdasha'));
    expect(man, contains('without a bisht'));
    final formal = omaniOutfitInstructions(true, const {
      'Headwear': 'Kumma with Mussar',
      'Bisht (optional)': 'Add bisht',
    });
    expect(formal, contains('mussar around the kumma'));
    expect(formal, contains('Add an open bisht'));
    final woman = omaniOutfitInstructions(false, const {});
    expect(woman, contains('ending below the knees'));
    expect(woman, contains('separate sirwal trousers'));
    expect(woman, contains('lihaf shawl worn on the head'));
    expect(omaniReferencePaths(false, const {}),
        ['images/omani_women.png', 'images/omani_female_worn.jpg']);
    expect(omaniReferencePaths(true, const {}),
        ['images/omani_men.png', 'images/omani_male_worn.jpg']);
  });

  testWidgets('graduation keeps the dress under the cap and gown',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));

    Future<void> select(String key, String value) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tapVisible(tester, value);
    }

    await select('Gender / clothing style', 'Female');
    await select('Age group', 'Adult (18–29)');
    await select('Occasion', 'Graduation');
    await select('Outfit type', 'Graduation dress');
    await tapVisible(tester, 'No preference');
    await select('Silhouette', 'A-line');
    await select('Length', 'Midi');
    await tapVisible(tester, 'Review design');
    expect(find.text('Generate a preview of your outfit.'), findsNothing);
    await tapVisible(tester, 'Create design');
    final screen =
        tester.widget<AiGenerationScreen>(find.byType(AiGenerationScreen));
    expect(screen.outfitDetails,
        contains('black academic mortarboard with a tassel'));
    expect(
        screen.outfitDetails, contains('open-front academic graduation gown'));
    expect(screen.outfitDetails, contains('clearly visible down to its hem'));
    expect(screen.prompt, contains('Silhouette: A-line'));
    expect(screen.prompt, contains('Length: Midi'));
  });
  test(
      'avatar is a CGI character with measured proportions and optional references',
      () {
    final prompt = avatarPrompt({
      'Height': '175',
      'Weight': '75',
      'Chest': '100',
      'Waist': '85',
      'Hips': '100'
    });
    expect(prompt, contains('3D-rendered'));
    expect(prompt, contains('Height 175 cm'));
    expect(prompt, contains('Weight 75 kg'));
    expect(prompt, contains('no real person identity'));
    expect(avatarPrompt({}, clothing: true, person: true),
        contains('reference image 1'));
    expect(validMeasurements({'Height': 'NaN'}), isFalse);
  });
}
