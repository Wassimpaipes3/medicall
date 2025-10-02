# 🧪 Firestore Permission Testing Guide

## Quick Test to Identify the Issue

### Add Test Button to Rating Screen

Add this import at the top of `rating_screen.dart`:
```dart
import '../../services/firestore_test_service.dart';
```

Add this button temporarily in the build method (after the submit button):
```dart
// TEMPORARY: Test Firestore permissions
if (kDebugMode)
  ElevatedButton(
    onPressed: () async {
      try {
        await FirestoreTestService.testAvisWrite();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Firestore test passed!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Test failed: $e')),
        );
      }
    },
    child: Text('🧪 Test Firestore'),
  ),
```

### Run the Test

1. **Hot reload** your app
2. Navigate to the rating screen
3. Click the **"🧪 Test Firestore"** button
4. **Check the console** for detailed output

### Expected Output (Success):

```
🧪 [FirestoreTest] Starting avis write test...
   User authenticated: true
   User ID: abc123...
   User email: user@example.com
📝 [FirestoreTest] Test 1: Writing test document...
✅ [FirestoreTest] Test 1 PASSED - Document created: xyz789
📝 [FirestoreTest] Test 2: Writing review-like document...
✅ [FirestoreTest] Test 2 PASSED - Review document created: def456
🧹 [FirestoreTest] Cleaning up test documents...
✅ [FirestoreTest] All tests passed!
```

### If Test Fails:

#### Error: "PERMISSION_DENIED"
**Cause**: Firestore rules are still blocking writes
**Solution**: 
1. Go to Firebase Console → Firestore → Rules
2. Verify these exact rules for /avis:
   ```
   match /avis/{id_avis} {
     allow read: if request.auth != null;
     allow create: if request.auth != null;
     allow update, delete: if request.auth != null;
   }
   ```
3. Click "Publish"
4. Wait 60 seconds for rules to propagate

#### Error: "User not authenticated"
**Cause**: User is not logged in
**Solution**: Make sure you're logged in as a patient before testing

#### Error: Network/Connection issues
**Check**: 
- Internet connection
- Firebase project configuration
- `google-services.json` is correct

### Alternative: Manual Firebase Console Test

1. Go to: https://console.firebase.google.com/project/nursinghomecare-1807f/firestore/data
2. Click **"+ Start collection"**
3. Collection ID: `avis`
4. Document ID: `test123`
5. Fields:
   - `idpat` (string): `your-user-id`
   - `idpro` (string): `test-provider`
   - `note` (number): `5`
   - `commentaire` (string): `test`
6. Click **"Save"**

If you can manually create the document, the rules are fine and the issue is in the app code.
If you can't, the rules need to be fixed.

## Next Steps After Testing

1. **If test passes but review submission fails**:
   - Issue is in the ReviewService logic
   - Check provider ID format
   - Check if provider exists in professionals collection

2. **If test fails with permission error**:
   - Rules not deployed correctly
   - Re-deploy with: `firebase deploy --only firestore:rules`
   - Wait 1-2 minutes and try again

3. **If test passes AND review submission works**:
   - Problem was temporary/caching
   - Remove test button
   - Everything is working!
