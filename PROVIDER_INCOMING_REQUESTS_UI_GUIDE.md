# 📱 Provider Incoming Requests Screen - UI Documentation

## ✅ Implementation Complete

Beautiful Material 3 UI for providers to view and manage incoming patient requests!

---

## 🎨 Screen Overview

### Main Features:
- ✅ **Material 3 Design** - Modern, clean, and intuitive
- ✅ **Real-time Request List** - Shows pending patient requests
- ✅ **Detailed Bottom Sheet** - Extended patient and request details
- ✅ **Empty State** - Friendly message when no requests
- ✅ **Pull-to-Refresh** - Easy manual refresh
- ✅ **Smooth Animations** - Staggered card entrance animations
- ✅ **Distance Calculation** - Shows km from patient location

---

## 📊 Visual Layout

### Main Screen:

```
┌────────────────────────────────────────────┐
│  ←  Incoming Requests              🔄      │ AppBar
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  [👤] Ahmed Benali      [⏰ Pending] │ │
│  │       Generalist Consultation        │ │
│  │                                      │ │
│  │  💰 500 DZD      📍 2.3 km          │ │
│  │  ─────────────────────────────────  │ │
│  │  [❌ Decline]  [✅ Accept Request]  │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  [👤] Sara Mohamed      [⏰ Pending] │ │
│  │       Cardiology Consultation        │ │
│  │                                      │ │
│  │  💰 700 DZD      📍 1.5 km          │ │
│  │  ─────────────────────────────────  │ │
│  │  [❌ Decline]  [✅ Accept Request]  │ │
│  └──────────────────────────────────────┘ │
│                                            │
└────────────────────────────────────────────┘
```

### Empty State:

```
┌────────────────────────────────────────────┐
│  ←  Incoming Requests              🔄      │
├────────────────────────────────────────────┤
│                                            │
│                    ○                       │
│                  ✓                         │
│                                            │
│         No new requests yet                │
│                                            │
│    Stay available to receive instant      │
│    appointments from patients.             │
│                                            │
│            [🔄 Refresh]                    │
│                                            │
└────────────────────────────────────────────┘
```

### Details Bottom Sheet:

```
┌────────────────────────────────────────────┐
│              ────                          │ Handle
├────────────────────────────────────────────┤
│                                            │
│  [👤]  Ahmed Benali                       │
│        [⏰ Pending Request]                │
│                                            │
│  🏥 Service Requested                     │
│     Generalist Consultation               │
│     Cardiology                            │
│                                            │
│  💰 Price                                 │
│     500 DZD                               │
│                                            │
│  📍 Distance from Patient                 │
│     2.3 km away                           │
│                                            │
│  💳 Payment Method                        │
│     Cash                                  │
│                                            │
│  📝 Notes                                 │
│     Patient has chest pain...             │
│                                            │
│  🕐 Requested At                          │
│     5 minutes ago                         │
│                                            │
│  [❌ Decline]  [✅ Accept Request]        │
│                                            │
└────────────────────────────────────────────┘
```

---

## 🎨 Material 3 Color Palette

```dart
Primary:     #1976D2 (Blue)     - Main actions, icons
Success:     #43A047 (Green)    - Accept buttons, positive actions
Error:       #E53935 (Red)      - Decline buttons, negative actions
Pending:     #FFC107 (Amber)    - Status badge
Background:  #FAFAFA (Off-white)- Screen background
Surface:     #FFFFFF (White)    - Card backgrounds
Text:        #1A1A1A (Dark)     - Primary text
Secondary:   #666666 (Gray)     - Secondary text
```

---

## 📋 Request Card Components

### 1. **Header Section**
```
[Avatar] Name                    [Status Badge]
         Service • Specialty
```

**Features:**
- ✅ Patient profile picture or gradient fallback with initials
- ✅ Patient name (from users collection: prenom + nom)
- ✅ Service and specialty display
- ✅ Status badge: "Pending" with amber color

### 2. **Info Row**
```
💰 500 DZD          📍 2.3 km
```

**Features:**
- ✅ Prix from provider_requests.prix
- ✅ Distance calculated using Geolocator (provider ↔ patient)
- ✅ Beautiful colored containers with icons

### 3. **Action Buttons**
```
[❌ Decline]  [✅✅ Accept Request]
```

**Features:**
- ✅ Decline: Red outlined button
- ✅ Accept: Green filled button (wider, more prominent)
- ✅ Loading state with spinner when processing
- ✅ Disabled state during processing

---

## 🔄 User Interactions

### 1. **Tap Card → Open Details**
```dart
onTap: () => _showRequestDetails(request)
```
Opens bottom sheet with extended details

### 2. **Tap Accept → Process Request**
```dart
onPressed: () => _acceptRequest(request)
```
- Shows loading spinner
- Displays success snackbar
- Reloads request list
- TODO: Implement actual accept logic

### 3. **Tap Decline → Reject Request**
```dart
onPressed: () => _declineRequest(request)
```
- Shows loading spinner
- Displays declined snackbar
- Reloads request list
- TODO: Implement actual decline logic

### 4. **Pull Down → Refresh**
```dart
RefreshIndicator(onRefresh: _loadRequests)
```
Reloads all pending requests from Firestore

### 5. **Tap Refresh Icon → Manual Refresh**
```dart
IconButton(icon: Icon(Icons.refresh), onPressed: _loadRequests)
```
Alternative way to refresh the list

---

## 📊 Data Flow

### Loading Requests:

```
1. Query Firestore
   ↓
   provider_requests
   WHERE providerId == currentUserId
   AND status == 'pending'
   ORDER BY createdAt DESC

2. For Each Request:
   ↓
   Fetch patient data from users collection
   - prenom, nom → patientName
   - photo_profile → patientPhoto
   
3. Calculate Distance:
   ↓
   Get provider's current location
   Calculate distance to patient location
   Convert to kilometers

4. Build RequestData Object:
   ↓
   RequestData(
     id, patientName, service,
     prix, distance, paymentMethod, etc.
   )

5. Update UI:
   ↓
   Display cards with smooth animations
```

---

## 🎯 Features Breakdown

### ✅ Implemented (UI Only):

**Main List:**
- ✅ Fetch pending requests from provider_requests collection
- ✅ Display patient avatar (from users.photo_profile)
- ✅ Display patient name (from users.prenom + users.nom)
- ✅ Display service and specialty
- ✅ Display prix from provider_requests.prix
- ✅ Calculate and display distance (km)
- ✅ Status badge (always "Pending" with amber styling)
- ✅ Accept and Decline buttons on each card
- ✅ Smooth staggered entrance animations
- ✅ Pull-to-refresh functionality
- ✅ Empty state with illustration

**Details Bottom Sheet:**
- ✅ Large patient avatar
- ✅ Patient name
- ✅ Pending status badge
- ✅ Service requested with specialty
- ✅ Price display
- ✅ Distance from patient
- ✅ Payment method
- ✅ Notes (if available)
- ✅ Request timestamp ("5 minutes ago")
- ✅ Accept and Decline buttons
- ✅ Draggable sheet with handle
- ✅ Beautiful detail sections with icons

**UI/UX:**
- ✅ Material 3 design language
- ✅ Smooth animations and transitions
- ✅ Loading states
- ✅ Error handling with snackbars
- ✅ Responsive layout
- ✅ Clean typography and spacing

### 🔧 To Implement (Backend Logic):

**Accept Request:**
```dart
// TODO: In _acceptRequest method
// 1. Call ProviderRequestService.acceptRequestAndCreateAppointment()
// 2. Create appointment document
// 3. Update request status to 'accepted'
// 4. Send notification to patient
// 5. Navigate to appointment details or dashboard
```

**Decline Request:**
```dart
// TODO: In _declineRequest method
// 1. Update request status to 'declined'
// 2. Send notification to patient
// 3. Remove from pending list
// 4. Log decline reason (optional)
```

---

## 📱 Usage Example

### Add to Routes:

**lib/routes/app_routes.dart:**
```dart
static const String providerIncomingRequests = '/provider/incoming-requests';

// In route definitions:
case AppRoutes.providerIncomingRequests:
  return MaterialPageRoute(
    builder: (_) => const ProviderIncomingRequestsScreen(),
  );
```

### Navigate to Screen:

```dart
// From provider dashboard
Navigator.pushNamed(
  context,
  AppRoutes.providerIncomingRequests,
);

// Or directly
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ProviderIncomingRequestsScreen(),
  ),
);
```

---

## 🎨 Customization

### Change Colors:

```dart
// Edit color constants in the class
static const Color _primaryColor = Color(0xFF1976D2);    // Blue
static const Color _successColor = Color(0xFF43A047);    // Green
static const Color _errorColor = Color(0xFFE53935);      // Red
static const Color _pendingColor = Color(0xFFFFC107);    // Amber
```

### Change Card Layout:

```dart
// Edit _buildRequestCard method
// Modify padding, spacing, or component order
Padding(
  padding: const EdgeInsets.all(20), // Adjust padding
  child: Column(...),
)
```

### Change Animation Duration:

```dart
// Edit TweenAnimationBuilder
TweenAnimationBuilder<double>(
  duration: Duration(milliseconds: 300), // Adjust speed
  tween: Tween(begin: 0.0, end: 1.0),
  // ...
)
```

---

## 🧪 Testing Checklist

### UI Testing:

- [ ] Screen loads without errors
- [ ] Empty state displays when no requests
- [ ] Request cards display correctly
- [ ] Patient photos load (or show fallback)
- [ ] Price displays in DZD
- [ ] Distance calculates and displays
- [ ] Status badge shows "Pending"
- [ ] Accept button works (shows loading, snackbar)
- [ ] Decline button works (shows loading, snackbar)
- [ ] Pull-to-refresh works
- [ ] Refresh icon works
- [ ] Tap card opens bottom sheet
- [ ] Bottom sheet displays all details
- [ ] Bottom sheet is draggable
- [ ] Accept button in sheet works
- [ ] Decline button in sheet works
- [ ] Animations are smooth
- [ ] Text is readable
- [ ] Layout is responsive

### Data Testing:

- [ ] Queries only pending requests
- [ ] Queries only provider's requests (providerId match)
- [ ] Fetches patient data from users collection
- [ ] Calculates distance correctly
- [ ] Handles missing patient data gracefully
- [ ] Handles missing location data gracefully
- [ ] Handles missing notes field
- [ ] Formats timestamps correctly
- [ ] Handles permission denied for location

### Integration Testing:

- [ ] Accept creates appointment (TODO)
- [ ] Decline updates status (TODO)
- [ ] Notifications sent (TODO)
- [ ] Real-time updates work (TODO)
- [ ] Multiple requests handled correctly
- [ ] Request disappears after accept/decline

---

## 📊 Firestore Query

### Query Used:

```dart
await FirebaseFirestore.instance
  .collection('provider_requests')
  .where('providerId', isEqualTo: currentUserUid)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
  .get();
```

### Required Firestore Index:

```
Collection: provider_requests
Fields:
  - providerId: Ascending
  - status: Ascending
  - createdAt: Descending
```

**Create index in Firebase Console if needed!**

---

## 🎨 UI Components Used

### Flutter Packages:
- ✅ `cached_network_image` - Profile picture loading
- ✅ `geolocator` - Distance calculation
- ✅ `cloud_firestore` - Firestore queries
- ✅ `firebase_auth` - Authentication

### Material 3 Widgets:
- ✅ `Container` - Card containers
- ✅ `Material` + `InkWell` - Touch ripple effect
- ✅ `ElevatedButton` - Accept button
- ✅ `OutlinedButton` - Decline button
- ✅ `DraggableScrollableSheet` - Details bottom sheet
- ✅ `RefreshIndicator` - Pull-to-refresh
- ✅ `TweenAnimationBuilder` - Entrance animations
- ✅ `LinearGradient` - Avatar backgrounds, dividers
- ✅ `BoxShadow` - Card shadows
- ✅ `ClipOval` - Circular avatars
- ✅ `SnackBar` - Success/error messages

---

## 💡 Best Practices Implemented

### 1. **Separation of Concerns**
```dart
// Data model separated
class RequestData { ... }

// UI logic in widget
class _ProviderIncomingRequestsScreenState { ... }
```

### 2. **Error Handling**
```dart
try {
  // Firestore query
} catch (e) {
  print('❌ Error: $e');
  setState(() => _loading = false);
}
```

### 3. **Loading States**
```dart
bool _loading = true;
String? _processingRequestId;

// Show spinner while processing
isProcessing ? CircularProgressIndicator() : Icon(...)
```

### 4. **Null Safety**
```dart
final patientName = request.patientName ?? 'Patient';
final photo = request.patientPhoto;
if (photo != null && photo.isNotEmpty) { ... }
```

### 5. **Type Conversion**
```dart
double _toDouble(dynamic value, double defaultValue) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}
```

### 6. **Responsive Layout**
```dart
Expanded(flex: 2, child: ElevatedButton(...)) // Accept button wider
Expanded(child: OutlinedButton(...))          // Decline button normal
```

### 7. **Accessibility**
```dart
// Semantic labels on buttons
ElevatedButton.icon(
  icon: const Icon(Icons.check),
  label: const Text('Accept'), // Screen readers
)
```

---

## 🎉 Summary

**What's Complete:**
- ✅ Beautiful Material 3 UI design
- ✅ Request list with all details (patient, service, price, distance)
- ✅ Detailed bottom sheet modal
- ✅ Empty state screen
- ✅ Accept and Decline buttons (UI + placeholder logic)
- ✅ Pull-to-refresh functionality
- ✅ Smooth animations and transitions
- ✅ Patient data fetching from users collection
- ✅ Distance calculation from locations
- ✅ Loading and error states
- ✅ Responsive design

**What's Next:**
- 🔧 Implement actual accept logic (create appointment)
- 🔧 Implement actual decline logic (update status)
- 🔧 Add real-time listeners (StreamBuilder)
- 🔧 Add notifications when new requests arrive
- 🔧 Add sound/vibration for new requests
- 🔧 Add request expiration timer
- 🔧 Add filters (by service, distance, price)
- 🔧 Add request history view

**File Location:**
```
lib/screens/provider/provider_incoming_requests_screen.dart
```

**Ready to use!** 🚀 The UI is complete and functional. Just integrate the backend accept/decline logic when ready! ✨
