# 🧹 How to Clean Up Existing Provider Requests

## Problem
You have many old documents in the `provider_requests` collection. The automatic cleanup function (`cleanupExpiredRequests`) only works for **NEW** documents created **AFTER** deployment.

---

## ✅ Solution: One-Time Manual Cleanup

### Option 1: Using Flutter App (Easiest)

1. **Add the cleanup screen to your app** (temporarily):

```dart
// In main.dart, add this import:
import 'package:firstv/screens/debug/cleanup_provider_requests_screen.dart';

// Add this route:
'/cleanup-requests': (context) => const CleanupProviderRequestsScreen(),
```

2. **Navigate to the cleanup screen**:
   - From anywhere in your app, push this route:
   ```dart
   Navigator.pushNamed(context, '/cleanup-requests');
   ```

3. **Tap "Delete All Provider Requests" button**

4. **Result**: All documents deleted! ✅

---

### Option 2: Using Firebase Console

1. Go to: https://console.firebase.google.com/project/nursinghomecare-1807f/firestore

2. Navigate to `provider_requests` collection

3. Click on each document → Delete (⚠️ tedious if you have many!)

---

### Option 3: Using Cloud Function Directly (Advanced)

If you have Firebase Admin SDK setup locally:

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

async function cleanup() {
  const snapshot = await admin.firestore()
    .collection('provider_requests')
    .get();
  
  const batch = admin.firestore().batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  
  console.log(`✅ Deleted ${snapshot.size} documents`);
}

cleanup();
```

---

## 🔍 Verify Automatic Cleanup is Working

After manual cleanup, test the automatic system:

### Test Steps:

1. **Create a new provider request** (book an appointment)

2. **Check Firestore Console** - you should see:
   ```json
   {
     "patientId": "...",
     "providerId": "...",
     "status": "pending",
     "createdAt": "2025-10-03T15:00:00Z",
     "expireAt": "2025-10-03T15:10:00Z"  ⏰ +10 minutes
   }
   ```

3. **Wait 10 minutes**

4. **Cloud Function runs** (every 5 minutes):
   - Check logs: `firebase functions:log --only cleanupExpiredRequests`
   - Expected output: `✅ Deleted 1 expired provider requests`

5. **Check Firestore Console** - document should be gone! 🎉

---

## 📊 Check Cloud Function Logs

```bash
# View recent cleanup logs
firebase functions:log --only cleanupExpiredRequests --limit 20

# Expected output:
# 🧹 No expired provider requests to clean up  (if nothing expired yet)
# ✅ Deleted 3 expired provider requests        (when it finds expired docs)
```

---

## ⚠️ Important Notes

### Why doesn't the function clean old documents automatically?

The scheduled function (`cleanupExpiredRequests`) only checks documents with an `expireAt` field. **Old documents** created before the update don't have this field!

```json
// Old document (won't be auto-deleted):
{
  "patientId": "...",
  "status": "pending",
  "createdAt": "2025-10-01T10:00:00Z"
  // ❌ No expireAt field!
}

// New document (will be auto-deleted after 10 min):
{
  "patientId": "...",
  "status": "pending",
  "createdAt": "2025-10-03T15:00:00Z",
  "expireAt": "2025-10-03T15:10:00Z"  ✅ Has expireAt!
}
```

### Solution Timeline:

```
NOW          → Run manual cleanup (delete all old docs)
FUTURE       → Automatic cleanup works for new docs (10 min TTL)
```

---

## 🎯 Quick Summary

| Task | Method | When |
|------|--------|------|
| **Clean old docs** | Manual cleanup (Option 1, 2, or 3) | **ONE TIME - NOW** |
| **Clean new docs** | Automatic (Cloud Function) | **ONGOING - Every 5 min** |

---

## ✅ Checklist

- [ ] Run manual cleanup to delete existing documents
- [ ] Verify documents were deleted in Firebase Console
- [ ] Create a test request
- [ ] Wait 10+ minutes
- [ ] Check if test request was auto-deleted
- [ ] Check Cloud Function logs for success message
- [ ] Remove cleanup screen from app (optional)

---

## 🚀 After Cleanup

Everything is now automatic! 🎉

- New requests created → `expireAt` field added
- After 10 minutes → Cloud Function deletes them
- No manual cleanup needed anymore

**Happy Coding!** 🔥
