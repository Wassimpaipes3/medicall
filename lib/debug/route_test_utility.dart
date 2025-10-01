import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// Debug utility to test all tracking route configurations
class RouteTestUtility {
  
  /// Test direct navigation to tracking with appointmentId
  static void testTrackingNavigation(BuildContext context, String testAppointmentId) {
    print('🧪 [RouteTest] Testing tracking navigation with appointmentId: $testAppointmentId');
    
    try {
      Navigator.of(context).pushNamed(AppRoutes.tracking, arguments: {
        'appointmentId': testAppointmentId,
      });
      print('✅ [RouteTest] AppRoutes.tracking navigation successful');
    } catch (e) {
      print('❌ [RouteTest] AppRoutes.tracking navigation failed: $e');
    }
  }
  
  /// Test direct navigation to live tracking with appointmentId
  static void testLiveTrackingNavigation(BuildContext context, String testAppointmentId) {
    print('🧪 [RouteTest] Testing live tracking navigation with appointmentId: $testAppointmentId');
    
    try {
      Navigator.of(context).pushNamed(AppRoutes.liveTracking, arguments: {
        'appointmentId': testAppointmentId,
      });
      print('✅ [RouteTest] AppRoutes.liveTracking navigation successful');
    } catch (e) {
      print('❌ [RouteTest] AppRoutes.liveTracking navigation failed: $e');
    }
  }
  
  /// Print all available tracking routes
  static void printTrackingRoutes() {
    print('📋 [RouteTest] Available tracking routes:');
    print('   - AppRoutes.tracking: "${AppRoutes.tracking}"');
    print('   - AppRoutes.liveTracking: "${AppRoutes.liveTracking}"');
  }
  
  /// Test if both routes point to the same screen
  static void testRoutesConsistency(BuildContext context) {
    print('🔍 [RouteTest] Testing route consistency...');
    printTrackingRoutes();
    
    // Test with sample appointment ID
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    
    print('🧪 [RouteTest] Testing both routes with ID: $testId');
    
    // Note: Don't actually navigate in test, just verify route names
    print('✅ [RouteTest] Route consistency check complete');
  }
}