# 🧪 Quick Test Guide: Message Notifications

## Test Setup

**You need**: 
- 1 Provider account (doctor or nurse)
- 1 Patient account
- Both logged in

---

## ✅ Test 1: Provider → Patient Message (Should Create Notification)

### Steps:

1. **Login as Provider** (Doctor/Nurse)
   ```
   Email: doctor@example.com
   Password: ********
   ```

2. **Open Chat Screen**
   - Navigate to Messages
   - Select a patient
   - Or start a new conversation

3. **Send a Test Message**
   ```
   Type: "Hello! Your test results are ready."
   Send ✓
   ```

4. **Check Firestore Console**
   ```
   Go to: https://console.firebase.google.com/project/nursinghomecare-1807f/firestore
   
   Navigate to: /notifications
   
   Should see NEW document:
   ┌─────────────────────────────────────────────┐
   │ destinataire: [patient_user_id]            │
   │ message: "💬 Dr. Name sent: Hello!..."     │
   │ type: "message"                            │
   │ datetime: [current timestamp]              │
   │ read: false                                │
   │ senderId: [doctor_user_id]                 │
   └─────────────────────────────────────────────┘
   ```

5. **Login as Patient**
   ```
   Email: patient@example.com
   Password: ********
   ```

6. **Open Notifications Screen**
   - Tap notification bell icon in home screen
   - Should see new notification:
   ```
   ┌─────────────────────────────────────────┐
   │ 💬 Dr. Name vous a envoyé un message   │
   │                                         │
   │ Hello! Your test results are ready.     │
   │                                         │
   │ Just now                   [Unread •]  │
   └─────────────────────────────────────────┘
   ```

7. **Pull to Refresh**
   - Swipe down on notifications screen
   - Notification should reload

8. **Tap Notification**
   - Notification should be marked as read
   - Dot indicator should disappear

### ✅ Expected Result:
- Notification created in Firestore ✓
- Notification appears in patient's app ✓
- Can be marked as read ✓

---

## ⏭️ Test 2: Patient → Provider Message (Should NOT Create Notification)

### Steps:

1. **Login as Patient**

2. **Open Chat with Doctor/Nurse**

3. **Send Message**
   ```
   Type: "Thank you doctor!"
   Send ✓
   ```

4. **Check Firestore Console**
   ```
   Navigate to: /notifications
   
   Should NOT see new document for this message
   (No notification should be created)
   ```

5. **Login as Provider**

6. **Check Notifications Screen**
   - Should NOT see notification for patient message
   - Only appointment notifications should appear

### ✅ Expected Result:
- NO notification created ✓
- Provider doesn't receive notification ✓
- This is correct behavior ✓

---

## 🔍 Test 3: Long Message Truncation

### Steps:

1. **Login as Provider**

2. **Send Long Message** (>50 characters)
   ```
   Type: "Your blood test results are excellent and show no signs of any health issues. Please continue with your current treatment plan and schedule a follow-up appointment in 3 months."
   Send ✓
   ```

3. **Check Firestore**
   ```
   /notifications → Latest document
   
   message field should be:
   "💬 Dr. Name sent: Your blood test results are excellent and show n..."
   
   (Truncated to 50 characters + "...")
   ```

4. **Check Patient Notification**
   - Should show truncated message
   - Original full message is in the chat

### ✅ Expected Result:
- Message truncated to 50 chars ✓
- "..." added at the end ✓
- Full message still in chat ✓

---

## 🐛 Troubleshooting

### Problem: No notification created

**Debug Steps**:

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```

2. Look for:
   ```
   💬 New message in chat [chatId] from [senderId]
   📩 Message notification sent to [recipientId]
   ```

3. If you see:
   ```
   ℹ️ Sender is not a provider, skipping notification
   ```
   → Sender is not a doctor/nurse (correct behavior)

4. Check sender's role in Firestore:
   ```
   /users/{senderId}
   role: "doctor" or "nurse" ✓
   role: "patient" ✗ (won't create notification)
   ```

---

### Problem: Notification shows wrong name

**Debug Steps**:

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```

2. Look for:
   ```
   Sender name: [name]
   ```

3. Check `/users/{senderId}` in Firestore:
   ```
   Must have: nom or name field
   ```

4. If missing, update user document:
   ```javascript
   {
     nom: "Dr. Sarah Johnson",
     role: "doctor",
     ...
   }
   ```

---

### Problem: Function not deploying

**Fix**:

1. Check Node version:
   ```bash
   node --version
   ```
   Should be: v18 or v20

2. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

3. Redeploy:
   ```bash
   firebase deploy --only functions:onMessageCreated
   ```

---

## 📊 Quick Check Locations

### Firestore Console:
```
/notifications
├── {notificationId1}
│   ├── destinataire: "patient123"
│   ├── message: "💬 Dr. Smith sent: Hello..."
│   ├── type: "message"
│   ├── datetime: Timestamp
│   ├── read: false
│   └── senderId: "doctor456"
```

### Firebase Functions Console:
```
https://console.firebase.google.com/project/nursinghomecare-1807f/functions

Function: onMessageCreated
Status: Active ✓
Invocations: [check count]
```

### Firebase Functions Logs:
```bash
firebase functions:log --only onMessageCreated

Expected output:
💬 New message in chat [chatId] from [senderId]
   Participants: [id1, id2]
   Recipient: [recipientId]
   Sender name: [name]
   Sender role: [role]
📩 Message notification sent to [recipientId]
```

---

## ⚡ Quick Commands

```bash
# Deploy function
firebase deploy --only functions:onMessageCreated

# Check logs (last 5)
firebase functions:log --only onMessageCreated --limit 5

# Check logs (real-time)
firebase functions:log --only onMessageCreated --follow

# Check all functions status
firebase functions:list

# Redeploy all functions
firebase deploy --only functions
```

---

## ✅ Success Checklist

Before marking as complete, verify:

- [ ] Cloud Function deployed successfully
- [ ] Provider can send message to patient
- [ ] Notification created in Firestore
- [ ] Notification appears in patient's app
- [ ] Notification can be marked as read
- [ ] Patient messages DON'T create notifications
- [ ] Long messages are truncated
- [ ] Notification shows correct sender name
- [ ] Function logs show successful execution

---

## 🎉 All Tests Passed?

If all tests pass:

✅ **Message notification system is working perfectly!**

Patients will now receive notifications when:
- Doctor sends them a message
- Nurse sends them a message

Patients will NOT receive notifications when:
- They send messages to providers (correct)
- Other patients send messages (if applicable)

**System is production-ready!** 🚀
