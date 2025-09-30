import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🔍 Testing provider data...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;

    // Test 1: Check professionals collection
    print('\n📊 Testing professionals collection...');
    final professionalsCol = firestore.collection('professionals');
    final allProfessionals = await professionalsCol.get();
    print('   Total professionals: ${allProfessionals.docs.length}');

    // Test 2: Check available professionals
    final availableProfessionals = await professionalsCol.where('disponible', isEqualTo: true).get();
    print('   Available professionals: ${availableProfessionals.docs.length}');

    // Test 3: Check providers collection (just in case)
    print('\n📊 Testing providers collection...');
    final providersCol = firestore.collection('providers');
    final allProviders = await providersCol.get();
    print('   Total providers: ${allProviders.docs.length}');

    final availableProviders = await providersCol.where('disponible', isEqualTo: true).get();
    print('   Available providers: ${availableProviders.docs.length}');

    // Show sample data
    if (allProfessionals.docs.isNotEmpty) {
      print('\n📋 Sample professional data:');
      final sample = allProfessionals.docs.first.data();
      print('   ID: ${allProfessionals.docs.first.id}');
      print('   disponible: ${sample['disponible']} (${sample['disponible']?.runtimeType})');
      print('   service: ${sample['service']}');
      print('   nom: ${sample['nom']}');
      print('   login: ${sample['login']}');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}