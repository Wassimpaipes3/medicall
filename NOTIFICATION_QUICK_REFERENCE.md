# 🔔 Notification System - Quick Reference

## Where Notifications Come From

**Source**: Firebase Cloud Functions (`functions/src/index.ts`)

**Trigger**: `onAppointmentCreated` - When a new appointment is created

**Code Location**: Line ~234 in `functions/src/index.ts`

---

## Correct Firestore Structure

```javascript
notifications/{notificationId}
├── destinataire: "userId"          // WHO receives it
├── message: "🔔 Full text..."      // WHAT to display
├── type: "appointment"             // TYPE of notification
├── datetime: Timestamp             // WHEN it was created
├── read: false                     // READ status (boolean)
├── senderId: "senderUserId"        // WHO sent it
└── payload: {...}                  // EXTRA data (optional)
```

---

## Flutter App Query

```dart
FirebaseFirestore.instance
  .collection('notifications')
  .where('destinataire', isEqualTo: currentUser.uid)
  .orderBy('datetime', descending: true)
  .limit(50)
  .get()
```

---

## Mark as Read

```dart
FirebaseFirestore.instance
  .collection('notifications')
  .doc(notificationId)
  .update({'read': true})
```

---

## Required Firestore Index

**Collection**: `notifications`

**Fields**:
1. `destinataire` (Ascending)
2. `datetime` (Descending)

**Deploy Command**:
```bash
firebase deploy --only firestore:indexes
```

---

## Notification Types

| Type | Display |
|------|---------|
| `appointment` | 📅 Blue - Calendar |
| `message` | 💬 Purple - Message |
| `report` | 📋 Green - Report |
| `medication` | 💊 Orange - Pills |
| `payment` | 💳 Teal - Payment |
| `booking` | 📖 Indigo - Book |

---

## Security Rules

```javascript
match /notifications/{notifId} {
  // Users can read their own notifications
  allow read: if request.auth != null
    && resource.data.destinataire == request.auth.uid;
  
  // Only Cloud Functions can write
  allow write: if false;
}
```

---

## Test Commands

```bash
# Test in Firestore console
Collection: notifications
Filter: destinataire == YOUR_USER_ID
Order: datetime desc

# Test in Flutter
1. Navigate to notifications screen
2. Pull down to refresh
3. Tap notification to mark as read
4. Tap "Mark All Read" button
```

---

## Common Issues

### Issue: "No notifications found"
**Check**: 
- Is `destinataire` field set to correct user ID?
- Is there at least one appointment created?

### Issue: "Permission denied"
**Check**:
- Are Firestore rules deployed?
- Is user authenticated?
- Does `destinataire` match logged-in user?

### Issue: "Index not found"
**Fix**: 
```bash
firebase deploy --only firestore:indexes
```

---

## File Locations

| File | Purpose |
|------|---------|
| `functions/src/index.ts` | Creates notifications |
| `lib/screens/notifications/notifications_screen.dart` | Displays notifications |
| `firestore.rules` | Security rules |
| `firestore.indexes.json` | Database indexes |

---

## Quick Test

1. **Create appointment** as patient
2. **Check Firestore console** - notification should appear
3. **Open notifications screen** - should load and display
4. **Tap notification** - should mark as read
5. **Refresh Firestore** - `read` field should be `true`

✅ If all steps work = System is working perfectly!
