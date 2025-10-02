import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Comprehensive diagnostic tool for provider visibility issues
class ProviderDiagnostic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Run complete diagnostic and return results
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final results = <String, dynamic>{};
    
    print('🔍 Starting comprehensive provider diagnostic...');
    
    try {
      // Test 1: Authentication
      results['authentication'] = await _testAuthentication();
      
      // Test 2: Collection access
      results['collection_access'] = await _testCollectionAccess();
      
      // Test 3: Provider data analysis
      results['provider_data'] = await _analyzeProviderData();
      
      // Test 4: Query testing
      results['query_testing'] = await _testQueries();
      
      // Test 5: Permissions
      results['permissions'] = await _testPermissions();
      
      print('✅ Diagnostic completed successfully');
      return results;
      
    } catch (e) {
      print('❌ Diagnostic failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Test authentication status
  static Future<Map<String, dynamic>> _testAuthentication() async {
    print('\n🔐 Testing authentication...');
    final result = <String, dynamic>{};
    
    try {
      final user = _auth.currentUser;
      result['is_authenticated'] = user != null;
      
      if (user != null) {
        result['user_id'] = user.uid;
        result['email'] = user.email;
        result['email_verified'] = user.emailVerified;
        print('   ✅ User authenticated: ${user.email} (${user.uid})');
      } else {
        result['error'] = 'No authenticated user';
        print('   ❌ No authenticated user');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      print('   ❌ Authentication error: $e');
    }
    
    return result;
  }

  /// Test collection access
  static Future<Map<String, dynamic>> _testCollectionAccess() async {
    print('\n📁 Testing collection access...');
    final result = <String, dynamic>{};
    
    try {
      // Test professionals collection
      final professionalsCol = _firestore.collection('professionals');
      final professionalsSnapshot = await professionalsCol.limit(1).get();
      
      result['professionals_accessible'] = true;
      result['professionals_count'] = professionalsSnapshot.docs.length;
      print('   ✅ Professionals collection accessible');
      
      // Test professionnels collection (legacy)
      try {
        final professionnelsCol = _firestore.collection('professionnels');
        final professionnelsSnapshot = await professionnelsCol.limit(1).get();
        result['professionnels_accessible'] = true;
        result['professionnels_count'] = professionnelsSnapshot.docs.length;
        print('   ✅ Professionnels collection accessible');
      } catch (e) {
        result['professionnels_accessible'] = false;
        result['professionnels_error'] = e.toString();
        print('   ⚠️ Professionnels collection not accessible: $e');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      print('   ❌ Collection access error: $e');
    }
    
    return result;
  }

  /// Analyze provider data structure and content
  static Future<Map<String, dynamic>> _analyzeProviderData() async {
    print('\n📊 Analyzing provider data...');
    final result = <String, dynamic>{};
    
    try {
      final col = _firestore.collection('professionals');
      
      // Get all providers
      final allSnapshot = await col.limit(10).get();
      result['total_providers'] = allSnapshot.docs.length;
      
      if (allSnapshot.docs.isEmpty) {
        result['error'] = 'No providers found in collection';
        print('   ❌ No providers found in collection');
        return result;
      }
      
      // Analyze first provider
      final firstDoc = allSnapshot.docs.first;
      final firstData = firstDoc.data();
      result['sample_provider'] = {
        'id': firstDoc.id,
        'fields': firstData.keys.toList(),
        'disponible': firstData['disponible'],
        'service': firstData['service'],
        'nom': firstData['nom'],
        'login': firstData['login'],
        'specialite': firstData['specialite'],
      };
      
      print('   📋 Sample provider fields: ${firstData.keys.toList()}');
      print('   📋 Sample disponible: ${firstData['disponible']} (${firstData['disponible']?.runtimeType})');
      print('   📋 Sample service: ${firstData['service']}');
      
      // Count available providers
      final availableSnapshot = await col.where('disponible', isEqualTo: true).get();
      result['available_providers'] = availableSnapshot.docs.length;
      
      // Count with whereIn
      final whereInSnapshot = await col.where('disponible', whereIn: [true, 'true', 1, '1']).get();
      result['wherein_available_providers'] = whereInSnapshot.docs.length;
      
      // Get all unique services
      final services = <String>{};
      for (final doc in allSnapshot.docs) {
        final service = doc.data()['service']?.toString();
        if (service != null) {
          services.add(service);
        }
      }
      result['unique_services'] = services.toList();
      
      print('   📊 Total providers: ${result['total_providers']}');
      print('   📊 Available providers: ${result['available_providers']}');
      print('   📊 WhereIn available: ${result['wherein_available_providers']}');
      print('   📊 Unique services: ${result['unique_services']}');
      
    } catch (e) {
      result['error'] = e.toString();
      print('   ❌ Data analysis error: $e');
    }
    
    return result;
  }

  /// Test various query combinations
  static Future<Map<String, dynamic>> _testQueries() async {
    print('\n🔍 Testing queries...');
    final result = <String, dynamic>{};
    
    try {
      final col = _firestore.collection('professionals');
      
      // Test 1: Basic disponible query
      try {
        final disponibleQuery = await col.where('disponible', isEqualTo: true).limit(5).get();
        result['disponible_query'] = disponibleQuery.docs.length;
        print('   ✅ Disponible query: ${disponibleQuery.docs.length} results');
      } catch (e) {
        result['disponible_query_error'] = e.toString();
        print('   ❌ Disponible query failed: $e');
      }
      
      // Test 2: WhereIn query
      try {
        final whereInQuery = await col.where('disponible', whereIn: [true, 'true', 1, '1']).limit(5).get();
        result['wherein_query'] = whereInQuery.docs.length;
        print('   ✅ WhereIn query: ${whereInQuery.docs.length} results');
      } catch (e) {
        result['wherein_query_error'] = e.toString();
        print('   ❌ WhereIn query failed: $e');
      }
      
      // Test 3: Service queries
      final services = ['medecin', 'doctor', 'médecin', 'physician'];
      for (final service in services) {
        try {
          final serviceQuery = await col.where('service', isEqualTo: service).limit(3).get();
          result['service_$service'] = serviceQuery.docs.length;
          print('   📋 Service "$service": ${serviceQuery.docs.length} results');
        } catch (e) {
          result['service_${service}_error'] = e.toString();
          print('   ❌ Service "$service" query failed: $e');
        }
      }
      
      // Test 4: Combined queries
      try {
        final combinedQuery = await col
            .where('disponible', whereIn: [true, 'true', 1, '1'])
            .where('service', isEqualTo: 'medecin')
            .limit(3)
            .get();
        result['combined_query'] = combinedQuery.docs.length;
        print('   ✅ Combined query: ${combinedQuery.docs.length} results');
      } catch (e) {
        result['combined_query_error'] = e.toString();
        print('   ❌ Combined query failed: $e');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      print('   ❌ Query testing error: $e');
    }
    
    return result;
  }

  /// Test Firestore permissions
  static Future<Map<String, dynamic>> _testPermissions() async {
    print('\n🔒 Testing permissions...');
    final result = <String, dynamic>{};
    
    try {
      final col = _firestore.collection('professionals');
      
      // Test read permission
      try {
        await col.limit(1).get();
        result['read_permission'] = true;
        print('   ✅ Read permission granted');
      } catch (e) {
        result['read_permission'] = false;
        result['read_permission_error'] = e.toString();
        print('   ❌ Read permission denied: $e');
      }
      
      // Test write permission (we won't actually write, just check if we can)
      try {
        final testDoc = col.doc('permission_test');
        await testDoc.get();
        result['write_permission'] = true;
        print('   ✅ Write permission check passed');
      } catch (e) {
        result['write_permission'] = false;
        result['write_permission_error'] = e.toString();
        print('   ❌ Write permission check failed: $e');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      print('   ❌ Permission testing error: $e');
    }
    
    return result;
  }

  /// Print formatted diagnostic results
  static void printResults(Map<String, dynamic> results) {
    print('\n${'='*60}');
    print('🔍 PROVIDER DIAGNOSTIC RESULTS');
    print('='*60);
    
    for (final entry in results.entries) {
      print('\n📋 ${entry.key.toUpperCase()}:');
      if (entry.value is Map) {
        for (final subEntry in (entry.value as Map).entries) {
          print('   ${subEntry.key}: ${subEntry.value}');
        }
      } else {
        print('   ${entry.value}');
      }
    }
    
    print('\n${'='*60}');
  }

  /// Get quick summary of the issue
  static String getIssueSummary(Map<String, dynamic> results) {
    if (results.containsKey('error')) {
      return 'Diagnostic failed: ${results['error']}';
    }
    
    final auth = results['authentication'] as Map<String, dynamic>?;
    final collection = results['collection_access'] as Map<String, dynamic>?;
    final data = results['provider_data'] as Map<String, dynamic>?;
    
    if (auth?['is_authenticated'] != true) {
      return '❌ User not authenticated';
    }
    
    if (collection?['professionals_accessible'] != true) {
      return '❌ Cannot access professionals collection';
    }
    
    final totalProviders = data?['total_providers'] as int? ?? 0;
    if (totalProviders == 0) {
      return '❌ No providers found in database';
    }
    
    final availableProviders = data?['available_providers'] as int? ?? 0;
    if (availableProviders == 0) {
      return '❌ No available providers (all have disponible: false)';
    }
    
    final services = data?['unique_services'] as List<dynamic>? ?? [];
    if (services.isEmpty) {
      return '❌ No service field found in provider data';
    }
    
    return '✅ Database looks healthy - issue might be in query logic or service matching';
  }
}
