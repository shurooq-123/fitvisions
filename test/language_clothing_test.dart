import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitvisions/main.dart';
import 'package:fitvisions/services/app_language.dart';
import 'package:fitvisions/services/clothing_compatibility.dart';
import 'package:fitvisions/services/avatar_prompt.dart';
import 'package:fitvisions/screens/welcome_screen.dart';

void main() {
  test(
      'Male and female catalogues reject mismatches, accept unisex, reject unknown',
      () {
    for (final gender in AvatarGender.values) {
      expect(clothingMismatch(gender, gender.name), isNull);
      expect(clothingMismatch(gender, 'unisex'), isNull);
      expect(clothingMismatch(gender, 'unknown'), isNotNull);
      expect(
          clothingMismatch(
              gender, gender == AvatarGender.male ? 'female' : 'male'),
          isNotNull);
    }
  });
  test('Unisex prompt keeps selected gender and entered measurements', () {
    for (final gender in AvatarGender.values) {
      final prompt = cloudMeasuredAvatarPrompt(
          {'Height': '185', 'Chest': '112', 'Waist': '95', 'Hips': '118'},
          garment: null, hasClothing: true, hasPortrait: false, gender: gender);
      expect(prompt, contains('adult ${gender.subject}'));
      expect(prompt, contains('unisex'));
      expect(prompt, contains('Height 185.0 cm'));
      expect(prompt, contains('circumference 95.0 cm'));
    }
  });
  testWidgets(
      'Language persists, switches all app direction and preserves route state',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => AppLanguage.locale.value = const Locale('en'));
    await AppLanguage.load();
    await tester.pumpWidget(const FitVisionsApp());
    await tester.pumpAndSettle();
    final welcome = tester.element(find.byType(WelcomeScreen));
    expect(Directionality.of(welcome), TextDirection.ltr);
    await AppLanguage.set('ar');
    await tester.pumpAndSettle();
    expect(Directionality.of(welcome), TextDirection.rtl);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    AppLanguage.locale.value = const Locale('en');
    await AppLanguage.load();
    expect(AppLanguage.locale.value.languageCode, 'ar');
    await AppLanguage.set('en');
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(Directionality.of(welcome), TextDirection.ltr);
    Navigator.of(welcome).pushNamed('/register');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Sara');
    await AppLanguage.set('ar');
    await tester.pumpAndSettle();
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('الاسم الأول'), findsOneWidget);
  });
}
