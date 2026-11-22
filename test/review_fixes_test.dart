import 'package:fitvisions/screens/personal_cloth_measurement_screen.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';
import 'package:fitvisions/screens/payment_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:mocktail/mocktail.dart';
import 'prototype_layout_test.dart'
    show LayoutFirestore, LayoutCollection, records;
import 'package:fitvisions/screens/notifications_screen.dart';
import 'package:fitvisions/screens/history_screen.dart';
import 'package:fitvisions/services/report_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitvisions/services/subscription_access.dart';
import 'package:fitvisions/widgets/measurement_guide.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';
import 'package:fitvisions/services/body_size_presets.dart';
import 'package:fitvisions/screens/admin_plans_screen.dart';
import 'package:fitvisions/services/avatar_prompt.dart';

void main() {
  test('Calendar renewal preserves leap years, UTC and end-of-month boundaries',
      () {
    expect(SubscriptionAccess.expiry(DateTime.utc(2024, 1, 31, 12), 1),
        DateTime.utc(2024, 2, 29, 12));
    expect(SubscriptionAccess.expiry(DateTime.utc(2026, 8, 31), 6),
        DateTime.utc(2027, 2, 28));
    expect(SubscriptionAccess.expiry(DateTime.utc(2026, 12, 15), 1),
        DateTime.utc(2027, 1, 15));
  });
  test(
      'Purchased duration survives changes to catalogue price and expires exactly',
      () {
    final start = DateTime.utc(2026, 1, 31);
    final payment = {
      'amount': 12,
      'durationMonths': 6,
      'status': 'demo_active',
      'createdAt': Timestamp.fromDate(start)
    };
    expect(SubscriptionAccess.active([payment], now: DateTime.utc(2026, 7, 30)),
        isNotNull);
    expect(SubscriptionAccess.active([payment], now: DateTime.utc(2026, 7, 31)),
        isNull);
    expect(
        SubscriptionAccess.active([
          {...payment, 'status': 'cancelled'}
        ], now: start),
        isNull);
  });
  testWidgets(
      'Guide updates value and increase/decrease direction as measurements change',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child:
                    BodyMeasurements(onChanged: (_) {}, avatarSizing: true)))));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), '90');
    await tester.enterText(fields.at(2), '100');
    await tester.pump();
    var label = tester
        .widgetList<MeasurementLabel>(find.byType(MeasurementLabel))
        .firstWhere((w) => w.label == 'Waist');
    expect(label.value, 100);
    expect(label.previous, 90);
    await tester.enterText(fields.at(2), '80');
    await tester.pump();
    label = tester
        .widgetList<MeasurementLabel>(find.byType(MeasurementLabel))
        .firstWhere((w) => w.label == 'Waist');
    expect(label.value, 80);
    expect(label.previous, 100);
  });
  testWidgets(
      'Changing waist regenerates body and clothing with new measurements',
      (tester) async {
    final prompts = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: AiGenerationScreen(
            title: 'Generate Avatar',
            prompt: '',
            avatar: true,
            measuredBodyReference: true,
            avatarGender: AvatarGender.female,
            clothingPhoto: 'images/bridal_satin.png',
            measurements: bodySizePreset('M', 170),
            generator: (prompt, refs) async {
              prompts.add(prompt);
              return refs.first;
            },
            subscriptionCheck: () async => true)));
    final dynamic state = tester.state(find.byType(AiGenerationScreen));
    await tester.runAsync(() async => await state.generate());
    await tester.pump();
    expect(prompts.length, 2);
    state.changeMeasurementUnit(true);
    state.editMeasurement('Waist', '40'); // explicitly select inches
    await tester.runAsync(() async => await state.generate(edit: true));
    await tester.pump();
    expect(prompts.length, 4);
    expect(prompts.last, contains('101.6'));
    expect(find.textContaining('Could not'), findsNothing);
  });

  testWidgets('Admin rejects alphabetic price without writing a plan',
      (tester) async {
    final db = LayoutFirestore();
    final collection = LayoutCollection();
    when(() => db.collection('plans')).thenReturn(collection);
    when(() => collection.orderBy('price', descending: true))
        .thenReturn(collection);
    when(() => collection.snapshots())
        .thenAnswer((_) => Stream.value(records([])));
    await tester.pumpWidget(MaterialApp(home: AdminPlansScreen(firestore: db)));
    await tester.pumpAndSettle();
    final dynamic state = tester.state(find.byType(AdminPlansScreen));
    state.nameController.text = 'Plan';
    state.priceController.text = 'abc';
    state.durationController.text = '1 Month';
    state.featuresController.text = 'Access';
    await state.savePlan();
    await tester.pump();
    expect(find.textContaining('Enter a positive price'), findsOneWidget);
    verifyNever(() => collection.add(any()));
  });
  testWidgets('History toggles newest and oldest and displays time',
      (tester) async {
    final data = records([
      {
        'title': 'Older result',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1, 10, 30))
      },
      {
        'title': 'Newer result',
        'createdAt': Timestamp.fromDate(DateTime(2026, 2, 1, 11, 40))
      }
    ]);
    await tester.pumpWidget(
        MaterialApp(home: HistoryScreen(history: Stream.value(data))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.textContaining('Newer result')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Older result')).dy));
    expect(find.textContaining('11:40'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest').last);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.textContaining('Older result')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Newer result')).dy));
  });
  testWidgets(
      'Opening notifications marks unseen items read; manual unread remains available',
      (tester) async {
    final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    addTearDown(controller.close);
    bool? marked;
    await tester.pumpWidget(MaterialApp(
        home: NotificationsScreen(
            notifications: controller.stream,
            markRead: (id, value) async {
              marked = value;
            })));
    controller.add(records([
      {'title': 'Subscription activated', 'body': 'Test notice', 'read': false}
    ]));
    await tester.pumpAndSettle();
    expect(marked,
        true); // Automatic, without tapping the individual notification.
    controller.add(records([
      {'title': 'Subscription activated', 'body': 'Test notice', 'read': true}
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mark unread'));
    await tester.pump();
    expect(marked, false);
  });
  testWidgets('User and admin reports generate actual PDF bytes',
      (tester) async {
    for (final admin in [false, true]) {
      final bytes = await buildReportPdf(
          selected: 'Activity',
          name: 'Test User',
          admin: admin,
          records: [
            {
              'uid': 'u',
              'title': 'Created avatar',
              'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1))
            }
          ]);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    }
  });

  for (final size in [
    const Size(360, 640),
    const Size(800, 360),
    const Size(1024, 768)
  ]) {
    testWidgets('Forms support $size with enlarged text and scrolling',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in [
        const PersonalClothMeasurementScreen(),
        const CreateClothesScreen(),
        const PaymentScreen()
      ]) {
        await tester.pumpWidget(MaterialApp(
            builder: (_, child) => MediaQuery(
                data: MediaQueryData(
                    size: size, textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
