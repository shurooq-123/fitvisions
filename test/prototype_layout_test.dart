// Firestore SDK interfaces are mocked only for isolated UI tests.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitvisions/screens/subscription_screen.dart';
import 'package:fitvisions/screens/admin_dashboard_screen.dart';
import 'package:fitvisions/screens/admin_users_screen.dart';
import 'package:fitvisions/screens/admin_system_screen.dart';
import 'package:fitvisions/screens/admin_plans_screen.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';
import 'package:fitvisions/screens/admin_user_history_screen.dart';
import 'package:fitvisions/screens/change_password_screen.dart';
import 'package:fitvisions/screens/history_screen.dart';
import 'package:fitvisions/screens/avatar_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/welcome_screen.dart';
import 'package:fitvisions/screens/login_screen.dart';
import 'package:fitvisions/screens/register_screen.dart';
import 'package:fitvisions/screens/admin_login_screen.dart';
import 'package:fitvisions/screens/forgot_password_screen.dart';
import 'package:fitvisions/screens/user_home_screen.dart';
import 'package:fitvisions/screens/cloth_measurement_screen.dart';
import 'package:fitvisions/screens/personal_cloth_measurement_screen.dart';
import 'package:fitvisions/screens/payment_screen.dart';
import 'package:fitvisions/screens/feedback_screen.dart';
import 'package:fitvisions/screens/about_screen.dart';
import 'package:fitvisions/main.dart';
import 'package:fitvisions/services/appearance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LayoutFirestore extends Mock implements FirebaseFirestore {}

class LayoutCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class LayoutQuery extends Mock implements Query<Map<String, dynamic>> {}

class LayoutSnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class LayoutDocument extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

QuerySnapshot<Map<String, dynamic>> records(List<Map<String, dynamic>> items) {
  final snapshot = LayoutSnapshot();
  final docs = items.asMap().entries.map((e) {
    final doc = LayoutDocument();
    when(() => doc.data()).thenReturn(e.value);
    when(() => doc.id).thenReturn('sample-${e.key}');
    return doc;
  }).toList();
  when(() => snapshot.docs).thenReturn(docs);
  return snapshot;
}

DocumentSnapshot avatarRecord() {
  final doc = LayoutDocument();
  when(() => doc.data()).thenReturn({});
  return doc;
}

void main() {
  testWidgets('appearance changes the app theme and persists on the device',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => Appearance.setDark(false));
    await Appearance.load();
    await tester.pumpWidget(const FitVisionsApp());
    final welcome = find.byType(WelcomeScreen);
    expect(Theme.of(tester.element(welcome)).brightness, Brightness.light);
    await Appearance.setDark(true);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(welcome)).brightness, Brightness.dark);
    Appearance.mode.value = ThemeMode.light;
    await Appearance.load();
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(welcome)).brightness, Brightness.dark);
  });

  final firestore = LayoutFirestore();
  for (final entry in {
    'plans': [
      {
        'name': 'Premium Plan',
        'price': 7,
        'duration': '6 Months',
        'features':
            'Unlimited try-ons\nSave your looks\nNo watermark\nPriority access\nAdvanced AI recommendations'
      },
      {
        'name': 'Basic Plan',
        'price': 3,
        'duration': 'Month',
        'features':
            'Limited try-ons\nSave your looks\nBasic recommendations\nStandard access'
      }
    ],
    'users': [
      {
        'firstName': 'Omar',
        'lastName': 'Al-Mansoori',
        'email': 'demo@example.com'
      },
      {'firstName': 'Sara', 'lastName': 'Ali'},
      {'firstName': 'Mohammed', 'lastName': ''}
    ],
    'history': [
      {
        'title': 'Measurements saved',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30))
      }
    ],
    'payments': <Map<String, dynamic>>[],
    'feedback': <Map<String, dynamic>>[],
  }.entries) {
    final collection = LayoutCollection();
    final query = LayoutQuery();
    when(() => firestore.collection(entry.key)).thenReturn(collection);
    when(() => collection.snapshots())
        .thenAnswer((_) => Stream.value(records(entry.value)));
    when(() => collection.orderBy('price', descending: true)).thenReturn(query);
    when(() => collection.where('uid', isEqualTo: 'sample-0'))
        .thenReturn(query);
    when(() => collection.orderBy('createdAt', descending: true))
        .thenReturn(query);
    when(() => query.snapshots())
        .thenAnswer((_) => Stream.value(records(entry.value)));
  }
  setUpAll(() async {
    final fonts = Platform.environment['PROTOTYPE_QA_FONTS'];
    if (fonts != null) {
      for (final entry in {
        'sans-serif': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
        'serif': 'roboto-regular.ttf'
      }.entries) {
        final loader = FontLoader(entry.key);
        loader.addFont(File('$fonts/${entry.value}')
            .readAsBytes()
            .then((v) => ByteData.sublistView(v)));
        await loader.load();
      }
    }
  });
  testWidgets('total users opens a filterable list with the latest plan',
      (tester) async {
    final db = LayoutFirestore();
    final users = LayoutCollection();
    final payments = LayoutCollection();
    when(() => db.collection('users')).thenReturn(users);
    when(() => db.collection('payments')).thenReturn(payments);
    when(() => users.snapshots()).thenAnswer((_) => Stream.value(records([
          {'firstName': 'Sara', 'lastName': 'Ali'},
          {'firstName': 'Omar', 'lastName': 'Khan'},
          {'firstName': 'Amal', 'lastName': 'Said'},
        ])));
    when(() => payments.snapshots()).thenAnswer((_) => Stream.value(records([
          {
            'uid': 'sample-0',
            'amount': 3,
            'status': 'pending',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1, 9)),
          },
          {
            'uid': 'sample-0',
            'amount': 3,
            'status': 'pending',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 2, 10)),
          },
          {
            'uid': 'sample-1',
            'amount': 7,
            'status': 'pending',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 3, 11, 30)),
          },
          {'uid': 'sample-1', 'amount': 7, 'status': 'selected'},
        ])));

    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(MaterialApp(home: AdminDashboardScreen(firestore: db)));
    await tester.pumpAndSettle();
    expect(find.text('Subscription History'), findsNothing);
    expect(find.text('Subscribers by plan'), findsNothing);
    expect(find.text('13.00 OMR'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Total Users'));
    await tester.pumpAndSettle();
    expect(find.text('Basic Plan · 3 OMR · 1 month'), findsOneWidget);
    expect(find.text('Premium Plan · 7 OMR · 6 months'), findsOneWidget);
    expect(find.text('Nov 2, 2026 · 14:00'), findsOneWidget);
    expect(find.text('Nov 3, 2026 · 15:30'), findsOneWidget);
    expect(find.text('Nov 1, 2026 · 13:00'), findsNothing);
    expect(find.text('Amal Said'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '3 OMR'));
    await tester.pumpAndSettle();
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('Omar Khan'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'No plan'));
    await tester.pumpAndSettle();
    expect(find.text('Amal Said'), findsOneWidget);
    expect(find.text('Sara Ali'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  final screens = <String, Widget>{
    'welcome': const WelcomeScreen(),
    'login': const LoginScreen(),
    'register': const RegisterScreen(),
    'admin-login': const AdminLoginScreen(),
    'forgot-password': const ForgotPasswordScreen(),
    'home': const UserHomeScreen(),
    'create-clothes': const CreateClothesScreen(),
    'measurements': const ClothMeasurementScreen(),
    'personal-measurements': const PersonalClothMeasurementScreen(),
    'payment': const PaymentScreen(),
    'feedback': const FeedbackScreen(),
    'about': const AboutScreen(),
    'subscription': SubscriptionScreen(firestore: firestore),
    'admin-dashboard': AdminDashboardScreen(firestore: firestore),
    'admin-users': AdminUsersScreen(firestore: firestore),
    'admin-user-history': AdminUserHistoryScreen(
        uid: 'sample-0', name: 'Omar Al-Mansoori', firestore: firestore),
    'change-password': const ChangePasswordScreen(),
    'admin-system': AdminSystemScreen(firestore: firestore),
    'admin-plans': AdminPlansScreen(firestore: firestore),
    'history': HistoryScreen(history: Stream.multi((controller) {
      controller.add(records([
        {
          'title': 'Measurements saved',
          'createdAt': Timestamp.fromDate(DateTime(2026, 9, 28))
        },
        {
          'title': 'Avatar preview viewed',
          'createdAt': Timestamp.fromDate(DateTime(2026, 9, 27))
        },
      ]));
      controller.close();
    })),
    'avatar-preview':
        AvatarScreen(measurements: SynchronousFuture(avatarRecord())),
  };
  for (final entry in screens.entries) {
    for (final (width, height, scale, suffix) in [
      (360.0, 640.0, 1.0, '-compact'),
      (360.0, 800.0, 1.0, ''),
      (320.0, 640.0, 1.35, '-large-text'),
      (568.0, 320.0, 1.0, '-landscape'),
      (360.0, 800.0, 1.0, '-dark'),
    ]) {
      testWidgets(
          '${entry.key} fits ${width.toInt()}×${height.toInt()} at text scale $scale$suffix',
          (tester) async {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                    useMaterial3: false,
                    fontFamily: 'sans-serif',
                    brightness:
                        suffix == '-dark' ? Brightness.dark : Brightness.light),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!),
                home: entry.value)));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(
                image.image, tester.element(find.byType(Scaffold).first));
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final output = Platform.environment['PROTOTYPE_QA_OUTPUT'];
        if (output != null) {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File('$output/${entry.key}$suffix.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
