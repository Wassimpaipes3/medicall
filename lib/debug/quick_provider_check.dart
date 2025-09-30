import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick diagnostic to check provider data
Future<void> checkProviders() async {
  print('🔍 Checking providers collection...');

  try {
    final firestore = FirebaseFirestore.instance;
    final col = firestore.collection('professionals');

    // Check total documents
    final allDocs = await col.get();
    print('Total providers: ${allDocs.docs.length}');

    // Check available providers
    final available = await col.where('disponible', isEqualTo: true).get();
    print('Available providers: ${available.docs.length}');

    // Show sample data
    if (allDocs.docs.isNotEmpty) {
      final sample = allDocs.docs.first.data();
      print('Sample provider data:');
      print('  disponible: ${sample['disponible']} (${sample['disponible']?.runtimeType})');
      print('  service: ${sample['service']}');
      print('  nom: ${sample['nom']}');
    }

  } catch (e) {
    print('Error: $e');
  }
}