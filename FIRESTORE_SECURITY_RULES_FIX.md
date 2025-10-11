# Firestore Security Rules Fix - Saved Locations

## The Error

```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

This error occurs when trying to save locations to `patients/{patientId}/savedLocations` because the Firestore security rules don't allow it.

---

## Solution: Update Firestore Security Rules

### Step-by-Step Instructions

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your project: **medicall** (or your project name)

2. **Navigate to Firestore Rules**
   - Click **Firestore Database** in the left sidebar
   - Click the **Rules** tab at the top

3. **Update the Rules**

Replace your current rules with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== USERS COLLECTION =====
    match /users/{userId} {
      // Users can read and write their own user document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow authenticated users to read other users' basic info (for chat, provider listings, etc.)
      allow read: if request.auth != null;
    }
    
    // ===== PATIENTS COLLECTION =====
    match /patients/{patientId} {
      // Patients can read and write their own patient document
      allow read, write: if request.auth != null && request.auth.uid == patientId;
      
      // IMPORTANT: Saved Locations subcollection
      match /savedLocations/{locationId} {
        // Patients can manage (read, write, update, delete) their own saved locations
        allow read, write: if request.auth != null && request.auth.uid == patientId;
      }
    }
    
    // ===== PROFESSIONALS COLLECTION =====
    match /professionals/{professionalId} {
      // All authenticated users can read professional profiles (for booking)
      allow read: if request.auth != null;
      
      // Only the professional can write to their own document
      allow write: if request.auth != null && request.auth.uid == professionalId;
    }
    
    // ===== CHATS COLLECTION =====
    match /chats/{chatId} {
      // Users can read/write chats they are participants in
      allow read, write: if request.auth != null && 
                           request.auth.uid in resource.data.participants;
      
      // Allow creating new chats
      allow create: if request.auth != null &&
                       request.auth.uid in request.resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // ===== APPOINTMENTS/BOOKINGS COLLECTION =====
    match /appointments/{appointmentId} {
      // Users can read appointments where they are the patient or provider
      allow read: if request.auth != null && 
                     (request.auth.uid == resource.data.patientId ||
                      request.auth.uid == resource.data.providerId);
      
      // Users can create appointments as a patient
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.patientId;
      
      // Patients and providers can update their own appointments
      allow update: if request.auth != null &&
                       (request.auth.uid == resource.data.patientId ||
                        request.auth.uid == resource.data.providerId);
    }
    
    // ===== REQUESTS COLLECTION (for booking requests) =====
    match /requests/{requestId} {
      // Similar to appointments
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
  }
}
```

4. **Click "Publish"** button to save the rules

5. **Test Again**
   - Hot restart your app
   - Try saving a location
   - Should work now! ✅

---

## Quick Fix for Development Only

If you just want to test quickly (⚠️ **NOT for production**):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

This allows any authenticated user to read/write anywhere. **Only use for testing!**

---

## Verify the Fix

### In Console:
After updating rules, you should see in your Flutter app console:

```
💾 Saving location to Firebase: Home
   Patient ID: abc123...
   Collection: patients/abc123.../savedLocations
✅ Location saved successfully
```

### In Firebase Console:
1. Go to Firestore Database → Data tab
2. Navigate to: `patients` → `{your-uid}` → `savedLocations`
3. You should see your saved location documents

---

## What the Rules Do

### Key Rule for Saved Locations:
```javascript
match /patients/{patientId}/savedLocations/{locationId} {
  allow read, write: if request.auth != null && request.auth.uid == patientId;
}
```

**Explanation:**
- `request.auth != null` - User must be authenticated
- `request.auth.uid == patientId` - User can only access their own locations
- This prevents:
  - ❌ Unauthenticated users from accessing locations
  - ❌ Patient A from accessing Patient B's locations
  - ✅ Allows each patient to manage only their own locations

---

## Testing After Fix

1. **Hot restart** the app
2. Go to booking flow → Location selection
3. Try **"Use Current Location"** → Tap **"Save This Location"**
4. Enter name: "Test Location"
5. Tap "Save"
6. Should see: ✅ "Location saved successfully"
7. Check Firebase Console to verify

---

## Common Issues

### Issue 1: Still getting permission error
**Solution:** Make sure you clicked "Publish" in Firebase Console and wait 30 seconds for rules to propagate

### Issue 2: "not-found" error
**Solution:** Make sure the patient document exists in `patients/{uid}`

### Issue 3: Rules not working
**Solution:** 
1. Check that `request.auth != null` (user is logged in)
2. Check that `request.auth.uid` matches the patient ID
3. Try logging out and logging back in

---

## Security Best Practices

✅ **DO:**
- Match user ID with document ID for personal data
- Use `request.auth.uid == patientId` for user-specific collections
- Test rules with Firebase Emulator

❌ **DON'T:**
- Use `allow read, write: if true` in production
- Allow access to other users' data
- Forget to restrict subcollections

---

## Next Steps

After fixing the rules:
1. ✅ Test saving current location
2. ✅ Test saving custom location  
3. ✅ Test loading saved locations
4. ✅ Verify data in Firebase Console
5. ✅ Test on different patient accounts

---

## Need Help?

If you still have issues:
1. Check Firebase Console → Firestore → Rules tab
2. Look for syntax errors (red underlines)
3. Click "Simulate" to test rules
4. Check the Flutter console for detailed error messages

The updated code now shows:
- Better error messages
- Helpful instructions in console
- User-friendly notifications

**Date**: October 11, 2025  
**Status**: ✅ Ready to fix - Update Firestore rules and test!
