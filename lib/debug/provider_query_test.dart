import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug utility to test provider queries
class ProviderQueryTest {
  static Future<void> runDiagnostics() async {
    print('🔬 [Provider Query Test] Starting diagnostics...');
    
    final firestore = FirebaseFirestore.instance;
    final col = firestore.collection('professionals');
    
    try {
      // Test 1: Check if collection exists and has any documents
      print('\n📊 Test 1: Collection existence check');
      final allDocs = await col.limit(5).get();
      print('   Total documents found: ${allDocs.docs.length}');
      
      if (allDocs.docs.isEmpty) {
        print('   ❌ No documents in professionals collection');
        return;
      }
      
      // Test 2: Show sample document structure
      print('\n📋 Test 2: Sample document structure');
      final sample = allDocs.docs.first;
      final sampleData = sample.data();
      print('   Document ID: ${sample.id}');
      print('   Fields: ${sampleData.keys.toList()}');
      print('   disponible: ${sampleData['disponible']} (${sampleData['disponible']?.runtimeType})');
      print('   service: ${sampleData['service']}');
      print('   specialite: ${sampleData['specialite']}');
      
      // Test 3: Check disponible field values
      print('\n🔍 Test 3: Disponible field analysis');
      final allDisponible = await col.get();
      int trueCount = 0, falseCount = 0, nullCount = 0;
      
      for (final doc in allDisponible.docs) {
        final disponible = doc.data()['disponible'];
        if (disponible == true) trueCount++;
        else if (disponible == false) falseCount++;
        else nullCount++;
      }
      
      print('   disponible = true: $trueCount');
      print('   disponible = false: $falseCount');
      print('   disponible = null: $nullCount');
      
      // Test 4: Query with disponible = true
      print('\n✅ Test 4: Query disponible = true');
      final availableQuery = await col.where('disponible', isEqualTo: true).get();
      print('   Available providers found: ${availableQuery.docs.length}');
      
      if (availableQuery.docs.isNotEmpty) {
        print('   Sample available provider:');
        final availableDoc = availableQuery.docs.first;
        final availableData = availableDoc.data();
        print('     ID: ${availableDoc.id}');
        print('     nom: ${availableData['nom']}');
        print('     login: ${availableData['login']}');
        print('     service: ${availableData['service']}');
        print('     disponible: ${availableData['disponible']}');
      }
      
      // Test 5: Check service field values
      print('\n🛠 Test 5: Service field analysis');
      final services = <String, int>{};
      for (final doc in allDisponible.docs) {
        final service = doc.data()['service']?.toString().toLowerCase() ?? 'null';
        services[service] = (services[service] ?? 0) + 1;
      }
      print('   Available services: ${services.toString()}');
      
    } catch (e) {
      print('❌ Error during diagnostics: $e');
    }
  }
  
  /// Test specific service query
  static Future<void> testServiceQuery(String service, [String? specialty]) async {
    print('\n🎯 Testing specific query:');
    print('   Service: $service');
    print('   Specialty: $specialty');
    
    try {
      final col = FirebaseFirestore.instance.collection('professionals');
      
      // Build query exactly like SelectProviderScreen does
      Query query = col.where('disponible', isEqualTo: true);
      
      final serviceFilter = service.toLowerCase().trim();
      query = query.where('service', isEqualTo: serviceFilter);
      
      if (specialty != null && specialty.isNotEmpty) {
        final specialtyFilter = specialty.toLowerCase().trim();
        query = query.where('specialite', isEqualTo: specialtyFilter);
      }
      
      final result = await query.limit(25).get();
      print('   Results: ${result.docs.length} providers');
      
      for (final doc in result.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('     - ${data['nom'] ?? data['login']}: ${data['service']}/${data['specialite']}');
      }
      
    } catch (e) {
      print('   ❌ Query failed: $e');
    }
  }
}