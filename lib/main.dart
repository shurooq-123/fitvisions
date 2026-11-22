import 'screens/ai_assistance_screen.dart';
import 'constants/app_theme.dart';
import 'package:country_picker/country_picker.dart';
import 'services/app_language.dart';
import 'services/route_visibility.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/event_notification_service.dart';
import 'dart:async';
import 'services/notification_service.dart';
import 'widgets/app_shell.dart';
import 'screens/notifications_screen.dart';
import 'screens/reports_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  await AppLanguage.load();

  runApp(const FitVisionsApp());
  unawaited(EventNotificationService.start());
  unawaited(NotificationService.start().catchError((_) {
    NotificationService.status.value =
        'Push notifications unavailable. Retry in Notifications.';
  }));
}

final appRouteObserver = RouteVisibility();

class FitVisionsApp extends StatelessWidget {
  const FitVisionsApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: Appearance.mode,
        builder: (context, mode, _) => ValueListenableBuilder<Locale>(
            valueListenable: AppLanguage.locale,
            builder: (_, locale, __) => _buildApp(mode)),
      );

  Widget _buildApp(ThemeMode mode) {
    return MaterialApp(
      navigatorKey: NotificationService.navigator,
      scaffoldMessengerKey: NotificationService.messenger,
      title: 'FitVisions',
      navigatorObservers: [appRouteObserver],
      locale: AppLanguage.locale.value,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        CountryLocalizations.delegate
      ],
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: AppShell(child: child ?? const SizedBox.shrink()),
      ),
      darkTheme: fashionTheme(Brightness.dark),
      theme: fashionTheme(Brightness.light),
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
      routes: <String, WidgetBuilder>{
        '/helpSupport': (context) => const AiAssistanceScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/home': (context) =>
            const PopScope(canPop: false, child: UserHomeScreen()),
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
        '/adminDashboard': (context) =>
            const PopScope(canPop: false, child: AdminDashboardScreen()),
        '/adminUsers': (context) => const AdminUsersScreen(),
        '/adminSystem': (context) => const AdminSystemScreen(),
        '/adminPlans': (context) => const AdminPlansScreen(),
      },
    );
  }
}
