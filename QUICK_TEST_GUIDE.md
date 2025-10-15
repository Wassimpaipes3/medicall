# 🧪 Complete Testing Guide - Appointment Request System

## Quick Start Testing (5 Minutes)

### 1. Create Test Request in Firestore

1. Open Firebase Console → Firestore Database
2. Go to `appointment_requests` collection (create if doesn't exist)
3. Add document with Auto-ID:

```json
{
  "idpat": "test_patient_123",
  "patientName": "John Doe",
  "patientPhone": "+212600000000",
  "idpro": "YOUR_PROVIDER_UID_HERE",
  "service": "Home Visit",
  "prix": 200,
  "serviceFee": 20,
  "paymentMethod": "cash",
  "type": "scheduled",
  "appointmentDate": "October 17, 2025 at 2:30:00 PM UTC+1",
  "appointmentTime": "14:30",
  "patientAddress": "123 Main St, Casablanca",
  "notes": "Test appointment",
  "status": "pending",
  "etat": "en_attente",
  "createdAt": "[Use Firestore Timestamp - Now]",
  "updatedAt": "[Use Firestore Timestamp - Now]"
}
```

**IMPORTANT**: Replace `YOUR_PROVIDER_UID_HERE` with your actual provider's Firebase Auth UID.

### 2. Test in Provider Dashboard

1. **Hot restart** your Flutter app
2. Login as Provider
3. Go to Dashboard
4. **CHECK**: "Active Requests" section shows John Doe's request

### 3. Test Accept Flow

1. Click **"Accept"** button
2. Confirm in dialog
3. **VERIFY**:
   - ✅ Request disappears from "Active Requests"
   - ✅ Success message appears
   - ✅ In Firestore:
     - Request deleted from `appointment_requests`
     - New document in `appointments` with status "accepted"
   - ✅ Shows in "Upcoming Appointments" section

### 4. Test Reject Flow

1. Create another request (repeat step 1)
2. Click **"Decline"** button
3. Confirm in dialog
4. **VERIFY**:
   - ✅ Request disappears
   - ✅ Deleted from `appointment_requests` (check Firestore)
   - ✅ NOT in `appointments` collection

---

## Detailed Test Cases

### Test 1: Request Appears in Dashboard ✅

**Steps**:
1. Add request to Firestore (see Quick Start)
2. Open provider dashboard

**Expected**:
- Shows in "Active Requests" section
- Displays: Patient name, service, date, time, amount
- Has Accept/Decline buttons

---

### Test 2: Accept Request ✅

**Steps**:
1. Click "Accept" on a request
2. Click "Accept" in confirmation dialog

**Expected**:
- Loading dialog appears
- Success message: "✅ Accepted appointment with [Name]"
- Request removed from "Active Requests"
- In Firestore:
  ```
  appointment_requests/[id] → DELETED
  appointments/[new_id] → CREATED with status: "accepted"
  ```
- Shows in "Upcoming Appointments" section

---

### Test 3: Reject Request ✅

**Steps**:
1. Click "Decline" on a request
2. Click "Decline" in confirmation dialog

**Expected**:
- Loading dialog appears
- Success message: "Declined appointment with [Name]"
- Request removed from "Active Requests"
- In Firestore:
  ```
  appointment_requests/[id] → DELETED
  appointments/[id] → NOT CREATED
  ```

---

### Test 4: Real-time Updates ✅

**Steps**:
1. Keep provider dashboard open
2. Manually add request in Firestore Console

**Expected**:
- Request appears immediately (within 1-2 seconds)
- No page refresh needed

---

### Test 5: Future Date Display ✅

**Steps**:
1. Create request with date: Oct 17, 2025
2. Accept request
3. Go to "Upcoming Appointments"

**Expected**:
- Shows date "17/10/2025"
- Shows time "14:30"
- Gray/Blue badge (not TODAY)

---

### Test 6: Today's Appointment Display ✅

**Steps**:
1. Create request with today's date
2. Accept request

**Expected**:
- Shows green "TODAY" badge
- Green border on card

---

## Troubleshooting

### Issue: No Requests Appear

**Check**:
1. Is `idpro` field = your provider's UID?
2. Is `status` = "pending"?
3. Check Flutter logs: `flutter logs`
4. Check Firestore rules

**Solution**:
```dart
// Get your provider UID
print('Provider UID: ${FirebaseAuth.instance.currentUser?.uid}');
```

---

### Issue: Accept/Reject Doesn't Work

**Check**:
1. Internet connection
2. Firestore rules (see below)
3. Firebase Functions logs: `firebase functions:log`

**Firestore Rules Required**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /appointment_requests/{requestId} {
      allow read: if request.auth != null;
      allow delete: if request.auth != null;
    }
    match /appointments/{appointmentId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

---

### Issue: Real-time Updates Don't Work

**Check**:
1. Are streams subscribed? (Check initState)
2. Check dispose() isn't canceling streams early
3. Restart app

---

## Manual Testing Checklist

- [ ] Request appears in dashboard
- [ ] Accept button works
- [ ] Request moves to appointments collection
- [ ] Shows in "Upcoming Appointments"
- [ ] Decline button works
- [ ] Request is deleted
- [ ] Real-time updates work
- [ ] Future dates display correctly
- [ ] TODAY badge shows for today
- [ ] Loading dialogs appear
- [ ] Success messages show
- [ ] Error handling works (test offline)

---

## Cloud Functions Testing (Optional)

### Deploy Cloud Functions:
```powershell
cd functions
npm install
firebase deploy --only functions
```

### Test Auto-Cleanup:

1. Create request with old timestamp (15 minutes ago)
2. Wait 5-10 minutes
3. Check Firebase logs:
```powershell
firebase functions:log
```
4. Verify request is deleted

---

## Production Checklist

Before production:
- [ ] All manual tests pass
- [ ] Cloud Functions deployed
- [ ] Firestore rules deployed
- [ ] Real provider/patient accounts tested
- [ ] Notifications configured
- [ ] Error monitoring setup

---

## Quick Debug Commands

```powershell
# View Flutter logs
flutter logs

# View Firebase Functions logs
firebase functions:log

# Hot restart app
r (in Flutter console)

# Full restart
R (in Flutter console)
```

---

## Success Criteria ✅

System works correctly when:
1. ✅ Requests appear in dashboard immediately
2. ✅ Accept moves request to appointments
3. ✅ Decline deletes request
4. ✅ Real-time updates work
5. ✅ Future dates display correctly
6. ✅ No errors in logs

**Status**: Ready for testing! 🚀

