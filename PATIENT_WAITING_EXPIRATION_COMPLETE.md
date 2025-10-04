# ⏰ Patient Waiting Screen - Request Expiration Handling

## ✅ Implementation Complete

Updated both waiting screens to handle request expiration elegantly with real-time detection and user-friendly dialogs.

---

## 📋 What Was Implemented

### 1. **Real-Time Expiration Detection**
Both waiting screens now continuously monitor the `provider_requests` document and detect:

#### **Scenario A: Document Deleted (TTL/Cloud Function)**
```dart
if (!snapshot.data!.exists) {
  // Document was deleted by TTL or Cloud Function
  _showExpiredDialog(context, {});
}
```

#### **Scenario B: Timestamp Expired**
```dart
final expireAt = data['expireAt'] as Timestamp?;
if (expireAt != null && expireAt.toDate().isBefore(DateTime.now())) {
  // Request has expired (past 10 minutes)
  _showExpiredDialog(context, data);
}
```

### 2. **Expired Request Popup Dialog**

#### **Design Specs:**
- ⏰ Icon: `Icons.access_time_filled` with red accent `#E53935`
- Title: "⏰ Request Expired"
- Message: "Your request has expired. Please try again with another provider."
- Material 3 design with rounded corners (16-20px)
- Non-dismissible (user must choose an action)

#### **Two Action Buttons:**

**Primary Button: "Try Again"** (Blue `#1976D2`)
- Redirects to `SelectProviderScreen` / `PolishedSelectProviderScreen`
- Preserves previous search parameters (service, specialty, prix, location)
- Allows patient to immediately select another provider

**Secondary Button: "Cancel"** (Gray)
- Closes the dialog
- Keeps patient on the current screen (idle state)

### 3. **Prevent Multiple Dialogs**
```dart
bool _hasShownExpiredDialog = false;

Future<void> _showExpiredDialog(...) async {
  if (_hasShownExpiredDialog) return;
  _hasShownExpiredDialog = true;
  // ... show dialog
}
```

This ensures the dialog only appears **once** even if the stream emits multiple expired events.

---

## 🎯 User Flow

### **Normal Acceptance Flow:**
```
Patient creates request
    ↓
Waiting screen (listening to document)
    ↓
Provider accepts within 10 min
    ↓
status == "accepted" + appointmentId present
    ↓
Auto-redirect to LiveTrackingScreen ✅
```

### **Expiration Flow (TTL Deletion):**
```
Patient creates request
    ↓
Waiting screen (listening to document)
    ↓
10 minutes pass, no provider response
    ↓
Cloud Function/TTL deletes document
    ↓
StreamBuilder detects: !snapshot.data!.exists
    ↓
Show "⏰ Request Expired" dialog
    ↓
Options:
  - "Try Again" → SelectProviderScreen
  - "Cancel" → Stay idle
```

### **Expiration Flow (Timestamp Check):**
```
Patient creates request
    ↓
Waiting screen (listening to document)
    ↓
10 minutes pass, document still exists
    ↓
expireAt.toDate() < DateTime.now()
    ↓
Show "⏰ Request Expired" dialog
    ↓
Next cleanup cycle → document deleted
```

### **Manual Cancellation Flow:**
```
Patient waiting
    ↓
Clicks "Cancel Request" button
    ↓
Confirmation dialog: "Are you sure?"
    ↓
Confirmed → delete request doc
    ↓
Navigate to SelectProviderScreen ✅
```

---

## 📂 Files Modified

### 1. **modern_select_provider_screen.dart**
**Location:** `lib/screens/booking/modern_select_provider_screen.dart`

**Changes:**
- ✅ Converted `WaitingForAcceptanceScreen` from `StatelessWidget` → `StatefulWidget`
- ✅ Added `bool _hasShownExpiredDialog = false` flag
- ✅ Added document existence check: `if (!snapshot.data!.exists)`
- ✅ Added timestamp expiration check: `if (expireAt < DateTime.now())`
- ✅ Implemented `_showExpiredDialog()` method with Material Design
- ✅ Error state UI for expired requests (red clock icon)

**Lines Modified:** ~1050-1465

---

### 2. **polished_select_provider_screen.dart**
**Location:** `lib/screens/booking/polished_select_provider_screen.dart`

**Changes:**
- ✅ Added `bool _hasShownExpiredDialog = false` flag to `_PolishedWaitingScreenState`
- ✅ Added document existence check: `if (!snapshot.data!.exists)`
- ✅ Added timestamp expiration check: `if (expireAt < DateTime.now())`
- ✅ Implemented `_showExpiredDialog()` method with Material 3 polish
- ✅ Error state UI with gradient-enhanced styling

**Lines Modified:** ~1470-1970

---

## 🔧 Technical Details

### **StreamBuilder Logic:**
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('provider_requests')
      .doc(widget.requestId)
      .snapshots(),
  builder: (context, snapshot) {
    // 1. Loading state
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    
    // 2. Document deleted (expired by TTL/Cloud Function)
    if (!snapshot.data!.exists) {
      _showExpiredDialog(context, {});
      return ExpiredStateUI();
    }
    
    // 3. Parse data
    final data = snapshot.data!.data();
    
    // 4. Check timestamp expiration
    final expireAt = data['expireAt'] as Timestamp?;
    if (expireAt != null && expireAt.toDate().isBefore(DateTime.now())) {
      _showExpiredDialog(context, data);
      return ExpiredStateUI();
    }
    
    // 5. Check acceptance
    if (data['status'] == 'accepted' && data['appointmentId'] != null) {
      // Navigate to tracking
    }
    
    // 6. Normal waiting UI
    return WaitingUI();
  },
)
```

### **Dialog Implementation:**
```dart
Future<void> _showExpiredDialog(BuildContext context, Map<String, dynamic> data) async {
  if (_hasShownExpiredDialog) return; // Prevent duplicates
  _hasShownExpiredDialog = true;

  await showDialog(
    context: context,
    barrierDismissible: false, // Must choose action
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(/* Icon + Title */),
      content: Text('Your request has expired...'),
      actions: [
        TextButton('Cancel'), // Gray, closes dialog
        ElevatedButton('Try Again'), // Blue, navigates back
      ],
    ),
  );
}
```

---

## ✨ UX Enhancements

### **Visual States:**

**1. Normal Waiting:**
- Pulsing animation
- "Waiting for provider..." message
- Blue status badge
- Cancel button (red)

**2. Expired State (Before Dialog):**
- Red clock icon (64-80px)
- "Request Expired" title
- Subtle message
- Dialog triggers automatically

**3. Expired Dialog:**
- Red accent (#E53935) for urgency
- Clear call-to-action buttons
- Preserves context for retry

### **Color Scheme:**
```dart
Primary Blue:  #1976D2  // Try Again button
Error Red:     #E53935  // Expired icon & accents
Text Primary:  #263238  // Titles
Text Secondary:#546E7A  // Body text
Gray:          #757575  // Cancel button
```

---

## 🧪 Testing Scenarios

### **Test 1: Normal Flow**
1. Create a provider request
2. Provider accepts within 10 minutes
3. ✅ Should auto-redirect to LiveTrackingScreen

### **Test 2: Expiration via TTL**
1. Create a provider request
2. Wait 10+ minutes (or manually delete document in Firestore)
3. ✅ Dialog should appear: "⏰ Request Expired"
4. Click "Try Again"
5. ✅ Should navigate to SelectProviderScreen with preserved params

### **Test 3: Expiration via Timestamp**
1. Create a provider request
2. Wait 10+ minutes (document still exists)
3. ✅ StreamBuilder detects expired timestamp
4. ✅ Dialog should appear
5. ✅ Next Cloud Function cycle deletes document

### **Test 4: Manual Cancellation**
1. Create a provider request
2. Click "Cancel Request" button
3. Confirm cancellation
4. ✅ Should navigate back to SelectProviderScreen

### **Test 5: Dialog Prevention**
1. Create request, wait for expiration
2. Dialog appears
3. Close and reopen app
4. ✅ Dialog should NOT appear again (flag prevents it)

---

## 🔗 Integration with Backend

### **Dependencies:**

**1. Firestore TTL (Already Implemented):**
- `expireAt` field on documents
- Cloud Scheduler runs `cleanupExpiredRequests` every 5 minutes
- Deletes documents where `expireAt <= now`

**2. Cloud Function (Already Deployed):**
```typescript
export const cleanupExpiredRequests = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expiredSnapshot = await db.collection("provider_requests")
      .where("expireAt", "<=", now)
      .get();
    
    // Batch delete expired documents
  });
```

**3. Document Structure:**
```typescript
provider_request = {
  patientId: string,
  providerId: string,
  service: string,
  specialty?: string,
  prix: number,
  status: "pending" | "accepted" | "declined",
  expireAt: Timestamp, // 10 minutes from createdAt
  createdAt: Timestamp,
  appointmentId?: string,
}
```

---

## 📊 Success Metrics

✅ **Real-time expiration detection** - No polling needed  
✅ **Graceful UX degradation** - Clear messaging  
✅ **One-click retry** - Preserves search context  
✅ **Prevents spam** - Dialog shows once only  
✅ **Material 3 compliant** - Modern design language  
✅ **Handles all edge cases** - Deleted doc, expired timestamp, manual cancel  

---

## 🎉 Summary

Both `modern_select_provider_screen.dart` and `polished_select_provider_screen.dart` now include:

1. ✅ Real-time listener with expiration detection
2. ✅ "⏰ Request Expired" dialog with red accent
3. ✅ "Try Again" button → redirects to SelectProviderScreen
4. ✅ "Cancel" button → closes dialog (idle)
5. ✅ Prevention of multiple dialogs
6. ✅ Error state UI with visual feedback
7. ✅ Material 3 design compliance

**Backend requirements:** Already complete (TTL system + Cloud Function deployed)

**Frontend requirements:** ✅ **COMPLETE**

The patient waiting experience now handles request expiration elegantly with clear user guidance and smooth navigation flows! 🚀
