import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_forgot_password_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/measurement_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/about_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/try_on_method_screen.dart';
import 'screens/cloth_measurement_screen.dart';
import 'screens/personal_cloth_measurement_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

import 'screens/admin_users_screen.dart';
import 'screens/admin_system_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const FitVisionsApp());
}

class FitVisionsApp extends StatelessWidget {
  const FitVisionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitVisions',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFD3D9CC),
      ),
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/adminLogin': (context) => const AdminLoginScreen(),
        '/adminForgot': (context) => const AdminForgotPasswordScreen(),
        '/adminDashboard': (context) => const AdminDashboardScreen(),
        '/home': (context) => const UserHomeScreen(),
        '/avatar': (context) => const AvatarScreen(),
        '/measurement': (context) => const MeasurementScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/about': (context) => const AboutScreen(),
        '/changePassword': (context) => const ChangePasswordScreen(),
        '/tryOnMethod': (context) => const TryOnMethodScreen(),
        '/clothMeasurement': (context) => const ClothMeasurementScreen(),
        '/personalClothMeasurement': (context) =>
            const PersonalClothMeasurementScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      
        '/adminUsers': (context) => const AdminUsersScreen(),
        '/adminSystem': (context) => const AdminSystemScreen(),
      },
    );
  }
}