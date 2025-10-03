import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time cleanup helper for provider_requests collection
/// Use this to manually delete all existing documents
class ProviderRequestCleanupHelper {
  static final _functions = FirebaseFunctions.instance;

  /// Manually trigger cleanup of EXPIRED provider_requests
  /// This will delete expired documents but preserve active ones
  static Future<Map<String, dynamic>> cleanupAllRequests() async {
    try {
      debugPrint('🧹 Calling manual cleanup function...');
      
      final callable = _functions.httpsCallable('manualCleanupProviderRequests');
      final result = await callable.call();
      
      final data = result.data as Map<String, dynamic>;
      
      debugPrint('✅ Cleanup result: ${data['message']}');
      debugPrint('�️ Deleted: ${data['deleted']} expired documents');
      debugPrint('✨ Preserved: ${data['preserved'] ?? 0} active documents');
      
      return {
        'success': data['success'] ?? false,
        'deleted': data['deleted'] ?? 0,
        'preserved': data['preserved'] ?? 0,
        'message': data['message'] ?? 'Unknown result',
      };
    } catch (e) {
      debugPrint('❌ Manual cleanup failed: $e');
      rethrow;
    }
  }

  /// Check how many provider_requests currently exist
  static Future<int> countProviderRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('provider_requests')
          .get();
      
      debugPrint('📊 Current provider_requests count: ${snapshot.docs.length}');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Failed to count requests: $e');
      return -1;
    }
  }
}
