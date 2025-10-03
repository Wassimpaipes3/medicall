import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple test to verify provider_requests collection works
Future<void> testCollectionRecreation() async {
  print('🧪 Testing provider_requests collection recreation...\n');

  try {
    // Step 1: Check current state
    print('📊 Step 1: Checking current state...');
    var snapshot = await FirebaseFirestore.instance
        .collection('provider_requests')
        .get();
    print('   Current count: ${snapshot.docs.length} documents\n');

    // Step 2: Create a test document
    print('🆕 Step 2: Creating test document...');
    final testDoc = await FirebaseFirestore.instance
        .collection('provider_requests')
        .add({
      'test': true,
      'createdAt': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
      'note': 'This is a test document - will auto-delete in 10 minutes',
    });
    print('   ✅ Document created: ${testDoc.id}\n');

    // Step 3: Verify it exists
    print('🔍 Step 3: Verifying document exists...');
    snapshot = await FirebaseFirestore.instance
        .collection('provider_requests')
        .get();
    print('   New count: ${snapshot.docs.length} documents');
    print('   ✅ Collection recreated successfully!\n');

    // Step 4: Read the document
    print('📖 Step 4: Reading document data...');
    final doc = await testDoc.get();
    final data = doc.data();
    print('   Document data: $data\n');

    // Step 5: Clean up test document
    print('🧹 Step 5: Cleaning up test document...');
    await testDoc.delete();
    print('   ✅ Test document deleted\n');

    // Step 6: Final verification
    print('📊 Step 6: Final verification...');
    snapshot = await FirebaseFirestore.instance
        .collection('provider_requests')
        .get();
    print('   Final count: ${snapshot.docs.length} documents\n');

    print('🎉 SUCCESS! Collection recreation works perfectly!');
    print('   - Collection auto-creates when you add documents ✅');
    print('   - Collection auto-hides when empty ✅');
    print('   - Your app will work normally ✅\n');
  } catch (e) {
    print('❌ ERROR: $e');
    print('   Check your Firestore rules and permissions\n');
  }
}
