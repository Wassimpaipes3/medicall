# 💬 Message Notification System

## Overview

This system automatically sends notifications to patients when a provider (doctor or nurse) sends them a message in the chat.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                   MESSAGE NOTIFICATION FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

1️⃣ PROVIDER SENDS MESSAGE
   ┌─────────────────────┐
   │  Doctor/Nurse       │
   │  Sends Message      │
   │  to Patient         │
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ /chats/{chatId}/messages/{msgId}   │
   │ document created                    │
   └──────────┬──────────────────────────┘
              │
              │
2️⃣ CLOUD FUNCTION TRIGGERED
   ┌──────────▼────────────────────────────────────────┐
   │  Firebase Cloud Function                          │
   │  functions/src/index.ts                           │
   │  onMessageCreated()                               │
   │                                                    │
   │  1. Get chat document to find participants        │
   │  2. Identify recipient (not the sender)           │
   │  3. Get sender's name from /users collection      │
   │  4. Check if sender is doctor/nurse               │
   │  5. Create notification for recipient             │
   └──────────┬────────────────────────────────────────┘
              │
              │
3️⃣ NOTIFICATION CREATED (Only if sender is provider)
   ┌──────────▼────────────────────────────────────────┐
   │  /notifications/{notificationId}                  │
   │                                                    │
   │  {                                                 │
   │    destinataire: "patientUserId",                 │
   │    message: "💬 Dr. Name sent you...",           │
   │    type: "message",                               │
   │    datetime: Timestamp,                           │
   │    read: false,                                   │
   │    senderId: "doctorUserId",                      │
   │    payload: {                                     │
   │      chatId, messageId, action                   │
   │    }                                              │
   │  }                                                 │
   └──────────┬────────────────────────────────────────┘
              │
              │
4️⃣ PATIENT RECEIVES NOTIFICATION
   ┌──────────▼────────────────────────────────────────┐
   │  Patient's NotificationsScreen                    │
   │  Automatically loads new notification             │
   │                                                    │
   │  Display:                                         │
   │  💬 Dr. Sarah Johnson sent you a message:        │
   │     "Your test results look good..."             │
   └───────────────────────────────────────────────────┘
```

---

## Cloud Function Code

**Location**: `functions/src/index.ts`

**Function Name**: `onMessageCreated`

**Trigger**: Firestore document created at `/chats/{chatId}/messages/{messageId}`

### Key Features:

1. **Smart Recipient Detection**
   - Automatically finds the recipient from chat participants
   - Filters out the sender to identify who should receive the notification

2. **Provider-Only Notifications**
   - Only creates notifications when sender is a doctor or nurse
   - Patient-to-provider messages don't trigger notifications
   - Prevents notification spam

3. **Message Truncation**
   - Long messages are truncated to 50 characters
   - Adds "..." for truncated messages
   - Keeps notifications readable

4. **Rich Metadata**
   - Includes chat ID and message ID in payload
   - Allows app to navigate directly to the conversation
   - Tracks sender information

---

## Notification Structure

```javascript
{
  destinataire: "patientUserId",           // WHO receives it
  message: "💬 Dr. Name sent: Hello...",   // WHAT to display
  type: "message",                         // TYPE (message)
  datetime: Timestamp,                     // WHEN it was sent
  read: false,                             // READ status
  senderId: "doctorUserId",                // WHO sent the message
  payload: {                               // EXTRA data
    chatId: "chat123",                     // Chat ID for navigation
    messageId: "msg456",                   // Specific message ID
    action: "new_message"                  // Action type
  }
}
```

---

## Example Scenarios

### Scenario 1: Doctor Sends Message to Patient

**Input**:
- Doctor "Dr. Sarah Johnson" (ID: `doc123`) sends message to Patient (ID: `patient456`)
- Message: "Your test results look good. No further action needed."
- Chat ID: `chat789`

**Cloud Function Process**:
1. ✅ Detects new message in `/chats/chat789/messages/msg001`
2. ✅ Identifies participants: `[doc123, patient456]`
3. ✅ Finds recipient: `patient456` (not the sender)
4. ✅ Gets sender name: "Dr. Sarah Johnson"
5. ✅ Checks sender role: "doctor" ✓
6. ✅ Truncates message: "Your test results look good. No further action..."
7. ✅ Creates notification

**Notification Created**:
```javascript
{
  destinataire: "patient456",
  message: "💬 Dr. Sarah Johnson vous a envoyé un message: Your test results look good. No further action...",
  type: "message",
  datetime: Timestamp(2025-10-12 14:30:00),
  read: false,
  senderId: "doc123",
  payload: {
    chatId: "chat789",
    messageId: "msg001",
    action: "new_message"
  }
}
```

**Patient Sees**:
```
┌─────────────────────────────────────────┐
│ 💬 [Purple Badge]                       │
│                                         │
│ Dr. Sarah Johnson vous a envoyé        │
│ un message                             │
│                                         │
│ Your test results look good. No        │
│ further action...                      │
│                                         │
│ 2 minutes ago              [Unread •]  │
└─────────────────────────────────────────┘
```

---

### Scenario 2: Patient Sends Message to Doctor

**Input**:
- Patient (ID: `patient456`) sends message to Doctor (ID: `doc123`)
- Message: "Thank you doctor!"

**Cloud Function Process**:
1. ✅ Detects new message
2. ✅ Identifies participants: `[patient456, doc123]`
3. ✅ Finds recipient: `doc123`
4. ✅ Gets sender name: "Ahmed Benali"
5. ✅ Checks sender role: "patient" ❌
6. ⏭️ **Skips notification** (sender is not a provider)

**Result**: No notification created ✓

---

## Testing

### Test 1: Provider to Patient Message

```bash
1. Login as Doctor/Nurse
2. Open chat with a patient
3. Send a message: "Hello, how are you feeling?"
4. Check Firestore console:
   /notifications → New document should appear
5. Login as Patient
6. Open notifications screen → Should see new message notification
```

**Expected Result**: ✅ Notification created and displayed

---

### Test 2: Patient to Provider Message

```bash
1. Login as Patient
2. Open chat with a doctor/nurse
3. Send a message: "Thank you!"
4. Check Firestore console:
   /notifications → No new document
5. Provider should NOT receive notification
```

**Expected Result**: ✅ No notification created (correct behavior)

---

### Test 3: Long Message Truncation

```bash
1. Login as Doctor
2. Send long message (>50 characters):
   "Your blood test results are excellent and show no signs of any issues. Continue with your current treatment plan."
3. Check notification in Firestore:
   message field should be truncated:
   "💬 Dr. Name sent: Your blood test results are excellent and show n..."
```

**Expected Result**: ✅ Message truncated to 50 characters

---

## Firestore Security Rules

Notifications are **read-only** for users:

```javascript
match /notifications/{notifId} {
  allow read: if request.auth != null
    && resource.data.destinataire == request.auth.uid;
  
  allow write: if false; // Only Cloud Functions can write
}
```

✅ **Security Guaranteed**: Users cannot create fake notifications

---

## Performance & Limits

| Metric | Value |
|--------|-------|
| **Trigger** | Real-time (instant) |
| **Latency** | < 1 second typically |
| **Cost** | ~$0.40 per 1M invocations |
| **Firestore Writes** | 1 write per provider message |
| **Limits** | 1000 invocations/second per function |

---

## Troubleshooting

### Issue 1: No notification received

**Check**:
1. Is sender a doctor/nurse? (Check user role in `/users` collection)
2. Is Cloud Function deployed? (`firebase deploy --only functions:onMessageCreated`)
3. Check Firebase Functions logs: `firebase functions:log`
4. Is recipient's ID correct in chat participants?

---

### Issue 2: Notification shows wrong sender name

**Check**:
1. Does sender have `nom` or `name` field in `/users` collection?
2. Check Firebase Functions logs for "Sender name: ..."
3. Verify user document structure

---

### Issue 3: Message not truncated

**Check**:
1. Message length > 50 characters?
2. Check notification document in Firestore console
3. Verify Cloud Function logs

---

## Deployment

### Deploy Cloud Function:
```bash
firebase deploy --only functions:onMessageCreated
```

### Deploy All Functions:
```bash
firebase deploy --only functions
```

### Check Logs:
```bash
firebase functions:log
```

### View Function in Console:
https://console.firebase.google.com/project/nursinghomecare-1807f/functions

---

## Future Enhancements

### Possible Improvements:

1. **Push Notifications**
   - Add FCM (Firebase Cloud Messaging) to send push notifications
   - User receives notification even when app is closed

2. **Notification Grouping**
   - Group multiple messages from same sender
   - "Dr. Smith sent you 3 messages"

3. **Custom Notification Sounds**
   - Different sounds for different notification types
   - Silent mode for non-urgent messages

4. **Read Receipts**
   - Mark notification as read when user opens chat
   - Automatic cleanup of old read notifications

5. **Notification Preferences**
   - Allow users to enable/disable message notifications
   - Set quiet hours (no notifications at night)

---

## File Locations

| File | Purpose |
|------|---------|
| `functions/src/index.ts` | Cloud Function code |
| `lib/screens/notifications/notifications_screen.dart` | Displays notifications |
| `lib/services/chat_service.dart` | Sends messages |
| `firestore.rules` | Security rules |

---

## Related Documentation

- [NOTIFICATION_SYSTEM_FIX.md](./NOTIFICATION_SYSTEM_FIX.md) - Main notification system
- [NOTIFICATION_QUICK_REFERENCE.md](./NOTIFICATION_QUICK_REFERENCE.md) - Quick reference
- [NOTIFICATION_FLOW.md](./NOTIFICATION_FLOW.md) - Flow diagrams

---

## Summary

✅ **Deployed**: `onMessageCreated` Cloud Function  
✅ **Feature**: Automatic notifications when providers message patients  
✅ **Security**: Only Cloud Functions can create notifications  
✅ **Smart**: Only provider messages trigger notifications  
✅ **Efficient**: Message truncation prevents long notifications  

**Result**: Patients now receive instant notifications when their doctor or nurse sends them a message! 💬🔔
