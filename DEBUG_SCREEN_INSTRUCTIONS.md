# 🔍 How to Use the Firestore Debug Screen

## Quick Setup

### Step 1: Add Debug Screen to Your App

The debug screen has been created at:
```
lib/screens/debug/firestore_debug_screen.dart
```

### Step 2: Add Route or Navigation

**Option A: Add temporary button in your app**

In your `PatientChatScreen` or any screen, add a debug button:

```dart
// Add this to your AppBar actions
actions: [
  IconButton(
    icon: Icon(Icons.bug_report),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FirestoreDebugScreen(),
        ),
      );
    },
  ),
],
```

**Option B: Add to navigation drawer**

```dart
ListTile(
  leading: Icon(Icons.bug_report),
  title: Text('Debug Firestore'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirestoreDebugScreen(),
      ),
    );
  },
),
```

### Step 3: Import the Screen

At the top of your file:
```dart
import 'package:firstv/screens/debug/firestore_debug_screen.dart';
```

---

## How to Use

### 1. Check Current User
- Click **"Check Current User"** button
- Verify your user ID matches what you expect
- Copy the UID for comparison

**Expected Output:**
```
✅ Current User:
   UID: Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   Email: patient@example.com
   Display Name: Patient Name
```

---

### 2. Check All Chats
- Click **"Check All Chats"** button
- See ALL chats in the Firestore database
- Verify if your chat exists

**Expected Output:**
```
✅ Found 5 chats:

📝 Chat ID: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2_Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   Participants: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2, Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   Last Message: Hello Doctor!
```

**If you see:**
```
⚠️ No chats found in Firestore!
```
This means messages are NOT being written to Firestore!

---

### 3. Check My Chats
- Click **"Check My Chats"** button
- See only chats where YOU are a participant
- Check message counts

**Expected Output:**
```
✅ Found 2 chats for you:

📝 Chat ID: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2_Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   With: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2
   Last Message: Hello Doctor!
   Participants: Mk5GRsJy3dTHi75Vid7bp7Q3VLg2, 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2
   📨 Messages: 3
   Recent messages:
      - Hello Doctor!...
      - How are you today?...
      - I need help with...
```

---

### 4. Check Specific Chat
- Click **"Check Specific Chat"** button
- Checks the exact chat from your logs
- Shows all messages in that chat

**Expected Output:**
```
✅ Chat document EXISTS!

Chat ID: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2_Mk5GRsJy3dTHi75Vid7bp7Q3VLg2

Data:
   Participants: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2
                 Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   Last Message: Hello Doctor!
   Last Sender: Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   Created: Timestamp(...)

📨 Messages in chat: 3

Messages:

   Message ID: lseEHLjQKba0VfEXvbU6
   Sender: Mk5GRsJy3dTHi75Vid7bp7Q3VLg2
   Text: Hello Doctor!
   Seen: false
   Type: text
```

**If you see:**
```
❌ Chat document does NOT exist!
```
This means the write to Firestore failed!

---

## What to Look For

### ✅ Good Signs:
- Chat document exists
- Participants array has 2 users
- Messages subcollection has messages
- Message counts match what you sent
- Both user IDs are in participants

### ❌ Bad Signs:
- "No chats found" - Writes are failing
- "Chat document does NOT exist" - Permission or write failure
- "No messages in subcollection" - Message writes failing
- Wrong participant IDs - User ID mismatch
- Empty results - Query issue

---

## Common Issues & Solutions

### Issue 1: No Chats Found
**Diagnosis:** Messages not being written to Firestore

**Solutions:**
1. Check network connectivity
2. Check Firestore rules allow writes
3. Check if offline persistence is enabled
4. Look for error logs in Flutter console

---

### Issue 2: Chat Exists But No Messages
**Diagnosis:** Chat document created, but message writes failing

**Solutions:**
1. Check message collection security rules
2. Verify message write permissions
3. Check if `senderId` matches auth user

---

### Issue 3: Wrong User ID
**Diagnosis:** Logged in with different user than expected

**Solutions:**
1. Check authentication code
2. Verify correct user is logged in
3. Compare UIDs carefully (they're long!)

---

### Issue 4: Participants Array Wrong
**Diagnosis:** `_ensureChatExists()` not working correctly

**Solutions:**
1. Check `_getChatId()` logic
2. Verify participants are sorted correctly
3. Check if both users are added

---

## Next Steps After Debugging

### If Chat Exists in Firestore:
✅ Write is working  
❌ Provider query is wrong  
→ Check provider's query code  
→ Verify provider's user ID

### If Chat Does NOT Exist:
❌ Write is failing  
→ Check Firestore rules  
→ Check network connectivity  
→ Look for permission errors in logs

### If Messages Missing:
❌ Message writes failing  
→ Check message subcollection rules  
→ Verify `senderId` field  
→ Check message permissions

---

## Quick Test

1. **Run your app**
2. **Send a message** from patient to provider
3. **Open debug screen** (click debug button)
4. **Click "Check Specific Chat"**
5. **Look for the message you just sent**

**If you see the message:** ✅ Firestore writes working!  
**If you don't see it:** ❌ Write is failing, check rules

---

## Remove After Debugging

Once you've figured out the issue, remove the debug screen:

1. Delete `lib/screens/debug/firestore_debug_screen.dart`
2. Remove the debug button from your UI
3. Remove the import statement

---

**This tool will help you quickly identify if the problem is:**
- ✅ Firestore writes (messages not being written)
- ✅ Provider query (messages exist but provider can't see them)
- ✅ User IDs (mismatch causing permission issues)
- ✅ Participants array (not set correctly)
