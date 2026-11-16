import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';
import 'services/appearance.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';

import 'screens/admin_login_screen.dart';
import 'screens/admin_forgot_password_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_system_screen.dart';
import 'screens/admin_plans_screen.dart';

import 'screens/user_home_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/measurement_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/about_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/try_on_method_screen.dart';
import 'screens/create_clothes_screen.dart';
import 'screens/personal_cloth_measurement_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Appearance.load();

  runApp(const FitVisionsApp());
}

class FitVisionsApp extends StatelessWidget {
  const FitVisionsApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: Appearance.mode,
        builder: (context, mode, _) => _buildApp(mode),
      );

  Widget _buildApp(ThemeMode mode) {
    return MaterialApp(
      title: 'FitVisions',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child!,
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        fontFamily: 'TimesNewRoman',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1E1B),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Color(0xFF383B34),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'TimesNewRoman',
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF574543), brightness: Brightness.light),
        inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: Color(0xFFFFFDFC),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFFB8B9AE))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF574543), width: 1.6))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF574543),
                foregroundColor: Colors.white,
                elevation: 0)),
        scaffoldBackgroundColor: const Color(0xFFCED1C6),
      ),
      onGenerateRoute: (settings) {
        final link = Uri.tryParse(settings.name ?? '');
        if (link?.scheme == 'https' &&
            link?.host == 'fitvisions-33e6d.firebaseapp.com' &&
            link?.path == '/login') {
          return MaterialPageRoute<void>(
              settings: settings, builder: (_) => const LoginScreen());
        }
        return null;
      },
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const UserHomeScreen(),
        '/avatar': (context) => const AvatarScreen(),
        '/measurement': (context) => const MeasurementScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/about': (context) => const AboutScreen(),
        '/changePassword': (context) => const ChangePasswordScreen(),
        '/tryOnMethod': (context) => const TryOnMethodScreen(),
        '/generateAvatar': (context) => const PersonalClothMeasurementScreen(),
        '/createClothes': (context) => const CreateClothesScreen(),
        '/clothMeasurement': (context) =>
            const PersonalClothMeasurementScreen(),
        '/personalClothMeasurement': (context) =>
            const PersonalClothMeasurementScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/adminLogin': (context) => const AdminLoginScreen(),
        '/adminForgot': (context) => const AdminForgotPasswordScreen(),
        '/adminDashboard': (context) => const AdminDashboardScreen(),
        '/adminUsers': (context) => const AdminUsersScreen(),
        '/adminSystem': (context) => const AdminSystemScreen(),
        '/adminPlans': (context) => const AdminPlansScreen(),
      },
    );
  }
}
