import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firstv/core/theme.dart';
import 'package:firstv/screens/splash/splash_screen.dart';
import 'package:firstv/screens/onboarding/onboarding_screens.dart';
import 'package:firstv/screens/auth/login_screen.dart';
import 'package:firstv/screens/auth/signup_screen.dart';
import 'package:firstv/screens/auth/forget_password_screen.dart';
import 'package:firstv/routes/app_routes.dart';
import 'package:firstv/widgets/navigation/patient_navigation_wrapper.dart';
import 'package:firstv/screens/doctors/all_doctors_screen.dart';
import 'package:firstv/screens/chat/chat_screen.dart';
import 'package:firstv/screens/appointments/appointment_screen.dart';
import 'package:firstv/screens/notifications/notifications_screen.dart';
import 'package:firstv/screens/profile/enhanced_profile_screen.dart';
import 'package:firstv/screens/chat/provider_chat_screen.dart';
import 'package:firstv/screens/booking/live_tracking_screen.dart';
import 'package:firstv/services/notification_service.dart';
import 'package:firstv/middleware/route_guard.dart';
// Provider Screens
import 'package:firstv/screens/provider/provider_dashboard_screen.dart';
import 'package:firstv/screens/provider/provider_login_screen.dart';
import 'package:firstv/screens/provider/provider_navigation_screen.dart';
import 'package:firstv/screens/provider/provider_messages_screen.dart';
import 'package:firstv/screens/provider/provider_earnings_screen.dart';
import 'package:firstv/screens/provider/appointment_management_screen.dart';
import 'package:firstv/screens/provider/enhanced_profile_screen.dart' as ProviderEnhanced;
import 'package:firstv/screens/provider/enhanced_messages_screen.dart';
import 'package:firstv/screens/provider/enhanced_earnings_screen.dart';
import 'package:firstv/screens/provider/enhanced_appointment_management_screen.dart';
import 'package:firstv/screens/booking/polished_select_provider_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstv/screens/provider/provider_requests_screen.dart';
// Booking Flow Imports
import 'package:firstv/widgets/booking/ServiceSelectionPage.dart';
import 'package:firstv/widgets/booking/AppointmentsPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firstv/services/real_time_role_service.dart';
import 'package:firstv/screens/admin/admin_dashboard_screen.dart';

// import 'package:firstv/screens/debug/role_debug_screen.dart';
// import 'package:firstv/screens/test/provider_auth_test_screen.dart';

// Global navigator key for app-wide navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  NotificationService().initializeMockData();
  
  // Initialize Real-Time Role Service with navigator key
  await RealTimeRoleService.initialize(navKey: navigatorKey);
  
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
      navigatorKey: navigatorKey, // Add global navigator key for role monitoring

      // Start with splash screen for proper app flow
      initialRoute: AppRoutes.splash,
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
        AppRoutes.forgetPassword: (context) => const ForgetPasswordScreen(),
        AppRoutes.home: (context) => RouteGuard.patientRouteGuard(
          child: const PatientNavigationWrapper(),
        ),
        AppRoutes.patientNavigation: (context) => RouteGuard.patientRouteGuard(
          child: const PatientNavigationWrapper(),
        ),
        AppRoutes.chatPage: (context) => RouteGuard.patientRouteGuard(
          child: const ChatScreen(),
        ),
        AppRoutes.schedule: (context) => RouteGuard.patientRouteGuard(
          child: const AppointmentScreen(),
        ),
        AppRoutes.doctors: (context) => RouteGuard.patientRouteGuard(
          child: const AllDoctorsScreen(),
        ),
        AppRoutes.notifications: (context) => RouteGuard.patientRouteGuard(
          child: const NotificationsScreen(),
        ),
        AppRoutes.serviceSelection: (context) => const ServiceSelectionPage(),
        AppRoutes.appointments: (context) => const AppointmentsPage(),
        AppRoutes.liveTracking: (context) {
          print('🗺️ [Router] /live-tracking route accessed');
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final appointmentId = args?['appointmentId'] as String?;
          print('📍 [Router] AppointmentId from arguments: $appointmentId');
          return LiveTrackingScreen(appointmentId: appointmentId);
        },
        AppRoutes.selectProvider: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return PolishedSelectProviderScreen(
            service: args?['service'] ?? 'consultation',
            specialty: args?['specialty'],
            prix: (args?['prix'] ?? 0).toDouble(),
            paymentMethod: args?['paymentMethod'] ?? 'Cash',
            patientLocation: args?['patientLocation'] ?? const GeoPoint(0,0),
          );
        },
        AppRoutes.waitingAcceptance: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final requestId = args?['requestId'] as String?;
          return PolishedWaitingScreen(requestId: requestId ?? '');
        },
        // Legacy/alias route used by older booking flow
        '/waiting-for-provider': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final requestId = args?['requestId'] as String?;
          return PolishedWaitingScreen(requestId: requestId ?? '');
        },
        AppRoutes.tracking: (context) {
          print('🗺️ [Router] /tracking route accessed');
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final appointmentId = args?['appointmentId'] as String?;
          print('📍 [Router] AppointmentId from arguments: $appointmentId');
          return LiveTrackingScreen(appointmentId: appointmentId);
        },
        '/profile': (context) => const EnhancedProfileScreen(),
        '/provider-chat': (context) => const ProviderChatScreen(
          providerId: 'provider_1',
          providerName: 'Dr. Sarah Johnson',
        ),
        // Provider Routes (with route guard)
        AppRoutes.providerDashboard: (context) => RouteGuard.providerRouteGuard(
          child: const ProviderDashboardScreen(),
        ),
        AppRoutes.providerLogin: (context) => const ProviderLoginScreen(), // Login screen doesn't need guard
        AppRoutes.providerNavigation: (context) => RouteGuard.providerRouteGuard(
          child: const ProviderNavigationScreen(),
        ),
        AppRoutes.providerProfile: (context) => RouteGuard.providerRouteGuard(
          child: const ProviderEnhanced.EnhancedProfileScreen(),
        ),
        AppRoutes.providerMessages: (context) => RouteGuard.providerRouteGuard(
          child: const ProviderMessagesScreen(),
        ),
        AppRoutes.providerEarnings: (context) => RouteGuard.providerRouteGuard(
          child: const ProviderEarningsScreen(),
        ),
        AppRoutes.providerAppointments: (context) => RouteGuard.providerRouteGuard(
          child: const AppointmentManagementScreen(),
        ),
        AppRoutes.providerRequests: (context) => RouteGuard.providerRouteGuard(
          child: const ProviderRequestsScreen(),
        ),
        // Enhanced Provider Routes (keeping for compatibility)
        AppRoutes.enhancedProfile: (context) => const ProviderEnhanced.EnhancedProfileScreen(),
        AppRoutes.enhancedMessages: (context) => const EnhancedMessagesScreen(),
        AppRoutes.enhancedEarnings: (context) => const EnhancedEarningsScreen(),
        AppRoutes.enhancedAppointmentManagement: (context) => const EnhancedAppointmentManagementScreen(),
        // Admin Routes
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        // Debug Routes (temporarily disabled)
        // '/role-debug': (context) => const RoleDebugScreen(),
        // AppRoutes.providerAuthTest: (context) => const ProviderAuthTestScreen(),

      },
    );
  }
}
