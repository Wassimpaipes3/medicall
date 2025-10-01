# Firestore Rules Fix - Decline Permission ✅

## Problem
Provider couldn't decline requests - got **"permission-denied"** error when tapping the Decline button.

## Root Cause
The Firestore security rules for `provider_requests` collection only allowed providers to update status to `'accepted'`, but NOT to `'declined'`.

**Old Rule** ❌:
```javascript
// Updates: patient can cancel while pending; provider can accept
allow update: if request.auth != null && (
  // Patient cancellation
  (resource.data.patientId == request.auth.uid && 
   resource.data.status == 'pending' && 
   request.resource.data.status in ['cancelled','pending']) ||
  // Provider acceptance ONLY
  (resource.data.providerId == request.auth.uid && 
   resource.data.status == 'pending' && 
   request.resource.data.status == 'accepted')  // ❌ Missing 'declined'
);
```

## Solution
Updated the rule to allow providers to set status to **both** `'accepted'` AND `'declined'`.

**New Rule** ✅:
```javascript
// Updates: patient can cancel while pending; provider can accept OR decline
allow update: if request.auth != null && (
  // Patient cancellation
  (resource.data.patientId == request.auth.uid && 
   resource.data.status == 'pending' && 
   request.resource.data.status in ['cancelled','pending']) ||
  // Provider acceptance or decline
  (resource.data.providerId == request.auth.uid && 
   resource.data.status == 'pending' && 
   request.resource.data.status in ['accepted', 'declined'])  // ✅ Now includes 'declined'
);
```

## Changes Made

### 1. Updated `firestore.rules`
- Added `'declined'` to allowed status values for provider updates
- Changed comment from "provider can accept" → "provider can accept OR decline"

### 2. Deployed to Firebase
```bash
firebase deploy --only firestore:rules
```

Result:
```
✅ cloud.firestore: rules file firestore.rules compiled successfully
✅ firestore: released rules firestore.rules to cloud.firestore
✅ Deploy complete!
```

## Rule Logic Breakdown

### Who Can Update `provider_requests`:

#### **Patients** can update when:
- ✅ They own the request (`patientId == auth.uid`)
- ✅ Status is currently `'pending'`
- ✅ New status is `'cancelled'` or `'pending'`

#### **Providers** can update when:
- ✅ They are the target provider (`providerId == auth.uid`)
- ✅ Status is currently `'pending'`
- ✅ New status is `'accepted'` **OR** `'declined'` 👈 **FIXED**

### Who Can Read:
- ✅ Patient who created the request
- ✅ Provider who received the request

### Who Can Create:
- ✅ Any authenticated patient

## Testing

### Test Decline Functionality:
1. **Provider** → Open "Incoming Requests"
2. **Provider** → Tap "Decline" button on any request
3. **Expected** → ✅ Success snackbar appears
4. **Expected** → ✅ Request disappears from list
5. **Expected** → ✅ Firestore document status = 'declined'

### Verify in Firebase Console:
1. Go to Firestore database
2. Open `provider_requests` collection
3. Find the declined request document
4. Check `status` field = `'declined'`
5. Check `updatedAt` timestamp is recent

## Security Validation

The rule is still secure because:
- ✅ Providers can only update requests where they are the target (`providerId == auth.uid`)
- ✅ Can only update from `'pending'` status (can't change already processed requests)
- ✅ Can only set status to `'accepted'` or `'declined'` (can't set arbitrary values)
- ✅ Can't modify other users' requests
- ✅ Patients can still cancel their own pending requests

## Before vs After

### Before:
```
Patient books → Request pending → Provider taps Decline → ❌ Permission denied
```

### After:
```
Patient books → Request pending → Provider taps Decline → ✅ Status updated to 'declined'
```

---

## Summary

✅ **Fixed**: Added `'declined'` to allowed status values in Firestore rules
✅ **Deployed**: Rules successfully deployed to Firebase
✅ **Secure**: Providers can only decline their own pending requests
✅ **Working**: Decline button now functions correctly

The provider can now both accept AND decline incoming requests! 🎉
