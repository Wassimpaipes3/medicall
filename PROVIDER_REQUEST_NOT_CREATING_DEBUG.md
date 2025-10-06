# 🐛 Provider Requests Collection Not Being Created - Debug Guide

## ❓ Issue Description

You reported: "**provider_request collection it didnt create whene patient create requestes**"

This means when patients try to book appointments, documents aren't appearing in the `provider_requests` collection in Firebase Console.

---

## ✅ What SHOULD Happen

### Normal Flow:
```
1. Patient selects provider → Pays
2. App calls ProviderRequestService.createRequest()
3. Document created in provider_requests collection
4. Console log: "✅ Request created: [documentId]"
5. Document visible in Firebase Console
6. Provider sees request in their dashboard
```

---

## 🔍 Possible Causes

### 1. ⚠️ **Auto-Deletion (Most Likely)**

Your code has **TTL (Time-To-Live)** enabled:

**File**: `provider_request_service.dart` (Line 100-101)
```dart
final expireAt = Timestamp.fromDate(now.add(const Duration(minutes: 10)));
// ...
'expireAt': expireAt, // ⏰ Auto-delete after 10 minutes
```

**What This Means:**
- Documents are created ✅
- But **auto-deleted after 10 minutes** ⏰
- If you check Firebase Console **after** 10 minutes → Collection appears empty/gone
- If you check **within 10 minutes** → Documents should be visible

**How to Test:**
1. Create a new request from the app
2. **IMMEDIATELY** check Firebase Console (within 1-2 minutes)
3. If you see the document → TTL is working (deleting old ones)
4. If you DON'T see it → Permission or creation issue

---

### 2. 🔐 **Permission Denied**

**Firestore Rules** might be blocking creation.

**File**: `firestore.rules` (Lines 128-138)
```rules
match /provider_requests/{reqId} {
  allow read: if request.auth != null;
  
  // Patient creates request
  allow create: if request.auth != null &&
    (
      request.resource.data.patientId == request.auth.uid ||
      request.resource.data.idpat == request.auth.uid
    );
}
```

**Check:**
- Is user logged in? (`request.auth != null`)
- Does `patientId` field match authenticated user ID?

**How to Test:**
Look for this error in console:
```
❌ Failed to create provider request: [permission-denied]
🔐 Firestore permission denied. Check rules for provider_requests.
```

---

### 3. 🌐 **Wrong Firebase Project**

You might be looking at the **wrong Firebase project** in Console.

**Your Project ID**: Check `firebase_options.dart` or `google-services.json`

**How to Verify:**
Run this in your app to see project ID:
```dart
ProviderRequestService.debugEnvironment();
```

**Expected Output:**
```
🌐 [ProviderRequestService] projectId=your-project-id
👤 [ProviderRequestService] authUser=abc123
```

Then check if Firebase Console URL matches:
```
https://console.firebase.google.com/project/YOUR-PROJECT-ID-HERE/firestore
```

---

### 4. ❌ **Creation Failing Silently**

Code might be catching error but not showing it.

**Where Creation Happens:**

1. **`polished_select_provider_screen.dart`** (Line 344)
2. **`modern_select_provider_screen.dart`** (Line 163)
3. **`select_provider_screen.dart`** (Line 280)

**Check for:**
```dart
try {
  final requestId = await ProviderRequestService.createRequest(...);
  print('✅ Request created: $requestId'); // ← Should see this
} catch (e) {
  print('❌ Failed: $e'); // ← Or see this error
}
```

---

## 🧪 Debugging Steps

### Step 1: Check If Creation Is Being Called

**Add debug logging:**

In **any booking screen** (`polished_select_provider_screen.dart` line ~344):

```dart
Future<void> _selectProvider(ProviderData provider) async {
  print('🔵 STEP 1: _selectProvider called for provider: ${provider.id}');
  
  setState(() => _creatingRequestFor = provider.id);

  try {
    print('🔵 STEP 2: Calling createRequest()...');
    
    final requestId = await ProviderRequestService.createRequest(
      patientLocation: widget.patientLocation,
      service: widget.service,
      specialty: widget.specialty,
      prix: provider.price,
      paymentMethod: widget.paymentMethod,
      providerId: provider.id,
    );
    
    print('🔵 STEP 3: Request created successfully! ID: $requestId');
    print('🔵 STEP 4: Go to Firebase Console NOW to see document!');

    // ... rest of code
  } catch (e) {
    print('🔵 STEP ERROR: Failed to create request');
    print('❌ Error details: $e');
    print('❌ Error type: ${e.runtimeType}');
    // ... error handling
  }
}
```

---

### Step 2: Check Firebase Console **IMMEDIATELY**

**Timing is Critical!** Documents auto-delete after 10 minutes.

1. **Make a booking** from the app
2. **Within 30 seconds**, go to Firebase Console:
   ```
   Firebase Console → Firestore Database → provider_requests collection
   ```
3. **Look for a new document** with:
   - `status: "pending"`
   - `patientId: [your-user-id]`
   - `createdAt: [current timestamp]`
   - `expireAt: [10 minutes from now]`

**If you see it:** ✅ Creation works! It's just getting auto-deleted after 10 min
**If you DON'T see it:** ❌ Creation is failing (check logs for errors)

---

### Step 3: Check Console Logs

After making a booking request, look for these logs:

**Success Flow:**
```
🆕 [ProviderRequestService] Creating request
🌐 [ProviderRequestService] projectId=your-project-id
👤 [ProviderRequestService] authUser=abc123...
   👤 patientId: abc123
   🩺 providerId: xyz789
   🛠 service: consultation  specialty: general
   💰 prix: 500.0  paymentMethod: CCP
   📍 patientLocation: 36.7538, 3.0588
✅ Request created: [documentId]
```

**Failure Flow:**
```
🆕 [ProviderRequestService] Creating request
...
❌ Failed to create provider request: [permission-denied] ...
🔐 Firestore permission denied. Check rules for provider_requests.
```

---

### Step 4: Temporary Test - Disable Auto-Delete

To prove documents ARE being created, temporarily disable TTL:

**File**: `provider_request_service.dart` (Line 100-115)

**Comment out expireAt:**
```dart
final data = {
  'patientId': user.uid,
  'idpat': user.uid,
  'providerId': providerId,
  'service': service,
  'specialty': specialty,
  'prix': prix,
  'paymentMethod': paymentMethod,
  'patientLocation': patientLocation,
  'status': 'pending',
  'appointmentId': null,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  // 'expireAt': expireAt, // ⚠️ TEMPORARILY COMMENTED OUT
};
```

**Then:**
1. Create a new request
2. Check Firebase Console **anytime** (not just within 10 min)
3. Documents should stay forever now
4. If you see them → TTL was deleting them
5. **REMEMBER TO UNCOMMENT** `expireAt` after testing!

---

## 📱 Quick Test Screen

You can use the built-in test screen to verify:

**File**: `lib/screens/debug/test_provider_request_screen.dart`

**Add to routes** in `main.dart`:
```dart
'/test-provider-request': (context) => const TestProviderRequestScreen(),
```

**Navigate to it** and tap "Create Test Request"

This will:
- Create a test request
- Show console logs
- Display the document ID
- You can immediately check Firebase Console

---

## 🎯 Most Likely Solution

**Based on your symptoms**, the most likely cause is:

### ✅ **Documents ARE Being Created, But Auto-Deleted After 10 Minutes**

**Evidence:**
1. Your code has `expireAt` field (TTL enabled)
2. Firebase auto-deletes expired documents
3. If you check console **after** 10 minutes → looks empty
4. Providers aren't getting notified (documents gone before they see them)

**Solution:**
Either:
1. **Check console IMMEDIATELY** after creating request (within 1-2 min)
2. **Increase TTL** to 30-60 minutes:
   ```dart
   final expireAt = Timestamp.fromDate(now.add(const Duration(minutes: 60)));
   ```
3. **Disable TTL temporarily** for testing (comment out expireAt line)

---

## ✅ Checklist

Run through this checklist:

- [ ] User is logged in when booking?
- [ ] Console logs show "Creating request" message?
- [ ] Console logs show "✅ Request created: [id]"?
- [ ] Checked Firebase Console **within 2 minutes** of booking?
- [ ] Verified correct Firebase project (projectId matches)?
- [ ] Firestore rules allow create (authenticated user)?
- [ ] No permission errors in console?
- [ ] TTL (expireAt) field present in code?

---

## 📞 What Information Do You Need?

To help debug, please provide:

1. **Console logs** when you make a booking (copy full output)
2. **Screenshot** of Firebase Console showing provider_requests collection (or lack thereof)
3. **Timing**: How long after booking did you check console?
4. **Do you see ANY errors** when patient tries to book?
5. **Can you see the document if you check within 30 seconds?**

---

## 💡 Recommended Next Steps

1. **Add debug logging** (Step 1 above)
2. **Make a booking** from patient app
3. **Within 30 seconds**, check Firebase Console
4. **Copy console logs** and share them
5. If you see document → Just TTL issue (increase expireAt duration)
6. If you DON'T see document → Check for permission errors in logs
