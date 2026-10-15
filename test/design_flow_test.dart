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
        doc = Document();
    when(() => store.collection('plans')).thenReturn(collection);
    when(() => collection.orderBy('price', descending: true)).thenReturn(query);
    when(() => query.snapshots()).thenAnswer((_) => Stream.value(snapshot));
    when(() => snapshot.docs).thenReturn([doc]);
    when(() => doc.id).thenReturn('basic');
    when(() => doc.data()).thenReturn({
      'name': 'Basic Plan',
      'price': 3,
      'duration': '1 Month',
      'features': 'Save and edit'
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
    await tapVisible(tester, 'Generate');
    expect(find.text('Download'), findsNothing);
    await tapVisible(tester, 'Edit / Save');
    await tester.tap(find.byIcon(Icons.arrow_back_ios).last);
    await tester.pumpAndSettle();
    expect(find.text('Download'), findsNothing);
    expect(generated, 1);
    await tapVisible(tester, 'Edit / Save');
    await tapVisible(tester, 'Basic Plan');
    await tapVisible(tester, 'Subscribe');
    await tapVisible(tester, 'Pay');
    expect(find.text('Could not save the request. Please try again.'),
        findsOneWidget);
    expect(payments, 0);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    failPayment = false;
    await tapVisible(tester, 'Pay');
    expect(find.text('Demo access unlocked • No real payment'), findsOneWidget);
    expect(generated, 1);
    expect(payments, 1);
    await tester.ensureVisible(find.text('Download'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Download'));
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
    await select('Outfit type', 'Omani formal wear');
    expect(find.text('Headwear'), findsOneWidget);
    expect(find.text('Neckline'), findsNothing);
    await select('Headwear', 'Kumma');
    await select('Outfit type', 'Sportswear');
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Kumma'), findsNothing);
    expect(find.text('Favourite colour'), findsOneWidget);
    await select('Gender / clothing style', 'Female');
    expect(find.text('Neckline'), findsOneWidget);
    expect(find.text('Activity'), findsNothing);
    await select('Skin tone (optional)', 'Not sure — use camera');
    expect(find.text('Take skin photo'), findsOneWidget);
  });
  testWidgets('measurement explanation stays hidden until tap', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MeasurementLabel('Waist'))));
    expect(find.text(measurementHelp['Waist']!), findsNothing);
    await tester.tap(find.text('Waist'));
    await tester.pumpAndSettle();
    expect(find.text(measurementHelp['Waist']!), findsOneWidget);
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
