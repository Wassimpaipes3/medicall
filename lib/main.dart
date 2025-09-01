import 'package:firstv/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firstv/screens/splash/splash_screen.dart';
import 'package:firstv/screens/onboarding/onboarding_screens.dart';
import 'package:firstv/screens/auth/login_screen.dart';
import 'package:firstv/screens/auth/signup_screen.dart';
import 'package:firstv/routes/app_routes.dart';
import 'package:firstv/screens/home/home_screen.dart';
import 'package:firstv/screens/doctors/all_doctors_screen.dart';
import 'package:firstv/screens/notifications/notifications_screen.dart';
import 'package:firstv/screens/profile/enhanced_profile_screen.dart';
import 'package:firstv/screens/chat/provider_chat_screen.dart';
import 'package:firstv/screens/booking/live_tracking_screen.dart';
import 'package:firstv/services/notification_service.dart';
// Booking Flow Imports
import 'package:firstv/widgets/booking/ServiceSelectionPage.dart';
import 'package:firstv/widgets/booking/AppointmentsPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  NotificationService().initializeMockData();
  
  // Enhanced system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Enable full screen mode with enhanced edge-to-edge
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Healthcare App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Set back to home for normal app flow
      initialRoute: AppRoutes.home,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.zero,
          ),
          child: child!,
        );
      },
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignUpScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.doctors: (context) => const AllDoctorsScreen(),
        AppRoutes.notifications: (context) => const NotificationsScreen(),
        AppRoutes.serviceSelection: (context) => const ServiceSelectionPage(),
        AppRoutes.appointments: (context) => const AppointmentsPage(),
  AppRoutes.liveTracking: (context) => const LiveTrackingScreen(),
        '/profile': (context) => const EnhancedProfileScreen(),
        '/provider-chat': (context) => const ProviderChatScreen(
          providerId: 'provider_1',
          providerName: 'Dr. Sarah Johnson',
        ),
      },
    );
  }
}
