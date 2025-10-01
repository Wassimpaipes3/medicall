# 💰 Prix (Price) Flow Documentation

## ✅ Implementation Complete

The app now correctly reads `prix` from the **professionals collection** and propagates it through the entire booking flow!

---

## 🎯 What Changed

### 1. **Display Provider's Actual Prix in Card**
- Reads `prix` field from `professionals` collection
- Displays it in the provider card: "500 DZD" 
- Falls back to `widget.prix` only if not set in professionals

### 2. **Pass Prix to provider_requests**
- When creating a provider request, uses **provider's prix** (not widget.prix)
- Stored in `provider_requests` collection

### 3. **Copy Prix to appointments**
- When provider accepts, prix is copied from provider_requests to appointments
- Maintains consistent pricing throughout the flow

---

## 📊 Complete Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. PROFESSIONALS COLLECTION (Source of Truth)              │
│     ┌────────────────────────────────────────────┐          │
│     │ professionals/[docId]                      │          │
│     │   prix: 500.0  ← Read from here!          │          │
│     │   specialite: "Cardiology"                 │          │
│     │   disponible: true                         │          │
│     │   id_user: "7ftk4BqD..."                   │          │
│     └────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. PROVIDER CARD DISPLAY                                   │
│     ┌────────────────────────────────────────────┐          │
│     │  [PHOTO]  Dr. Ahmed Benali         [●]    │          │
│     │           Cardiology                       │          │
│     │   ⭐ 4.8      📍 2.3 km                    │          │
│     │   ─────────────────────────────────────    │          │
│     │   💰 500 DZD    [  ✓ Book  ]  ← Shows!   │          │
│     └────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. PROVIDER_REQUESTS COLLECTION (Request Created)         │
│     ┌────────────────────────────────────────────┐          │
│     │ provider_requests/[requestId]              │          │
│     │   patientId: "abc123"                      │          │
│     │   providerId: "7ftk4BqD..."                │          │
│     │   prix: 500.0  ← Copied from provider!    │          │
│     │   status: "pending"                        │          │
│     │   paymentMethod: "CCP"                     │          │
│     └────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. APPOINTMENTS COLLECTION (When Provider Accepts)        │
│     ┌────────────────────────────────────────────┐          │
│     │ appointments/[appointmentId]               │          │
│     │   idpat: "abc123"                          │          │
│     │   idpro: "7ftk4BqD..."                     │          │
│     │   prix: 500.0  ← Copied from request!     │          │
│     │   status: "accepted"                       │          │
│     │   paymentMethod: "CCP"                     │          │
│     │   type: "instant"                          │          │
│     └────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Step 1: Read Prix from Professionals Collection

**File:** `polished_select_provider_screen.dart` (Line ~293)

```dart
// Get prix from professionals collection (prioritize 'prix' field)
final providerPrix = _toDouble(data['prix'] ?? data['price'], widget.prix);

providers.add(ProviderData(
  id: doc.id,
  name: name,
  price: providerPrix, // ✅ Use provider's actual prix
  // ... other fields
));

print('💰 Provider prix: $providerPrix DZD (from professionals.prix)');
```

**Console Output:**
```
📄 Professional data from professionals collection:
   prix: 500.0 (double)
   ...
💰 Provider prix: 500.0 DZD (from professionals.prix)
```

---

### Step 2: Display Prix in Provider Card

**File:** `polished_select_provider_screen.dart` (Line ~781)

```dart
Text(
  '${provider.price.toStringAsFixed(0)} DZD',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _primaryColor,
  ),
),
```

**Visual Result:**
```
┌────────────────────────────────────┐
│  [PHOTO]  Dr. Ahmed Benali   [●]  │
│           Cardiology              │
│   ⭐ 4.8      📍 2.3 km           │
│   ─────────────────────────────   │
│   💰 500 DZD    [  ✓ Book  ]     │ ← Shows provider's prix!
└────────────────────────────────────┘
```

---

### Step 3: Pass Prix to Provider Request

**File:** `polished_select_provider_screen.dart` (Line ~336)

```dart
Future<void> _selectProvider(ProviderData provider) async {
  setState(() => _creatingRequestFor = provider.id);

  try {
    // Use the provider's actual prix from professionals collection
    print('💰 Creating request with provider prix: ${provider.price} DZD');
    
    final requestId = await ProviderRequestService.createRequest(
      patientLocation: widget.patientLocation,
      service: widget.service,
      specialty: widget.specialty,
      prix: provider.price, // ✅ Use provider's prix
      paymentMethod: widget.paymentMethod,
      providerId: provider.id,
    );
    // ...
  }
}
```

**Console Output:**
```
💰 Creating request with provider prix: 500.0 DZD
🆕 [ProviderRequestService] Creating request
   💰 prix: 500.0  paymentMethod: CCP
✅ Request created: [requestId]
```

---

### Step 4: Create Provider Request Document

**File:** `provider_request_service.dart` (Line ~90)

```dart
final data = {
  'patientId': user.uid,
  'idpat': user.uid,
  'providerId': providerId,
  'service': service,
  'specialty': specialty,
  'prix': prix, // ✅ Stored in provider_requests
  'paymentMethod': paymentMethod,
  'patientLocation': patientLocation,
  'status': 'pending',
  'appointmentId': null,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
};

final doc = await _firestore.collection('provider_requests').add(data);
```

**Firestore Document:**
```json
{
  "patientId": "abc123",
  "providerId": "7ftk4BqD7McN3Bjm3LFFtiJ6xkV2",
  "prix": 500.0,
  "service": "consultation",
  "paymentMethod": "CCP",
  "status": "pending"
}
```

---

### Step 5: Copy Prix to Appointment (When Provider Accepts)

**File:** `provider_request_service.dart` (Line ~250)

```dart
static Future<String> acceptRequestAndCreateAppointment({
  required String requestId,
  required GeoPoint providerLocation,
}) async {
  return await _firestore.runTransaction((tx) async {
    final snap = await tx.get(reqRef);
    final data = snap.data() as Map<String, dynamic>;
    
    // Build appointment data
    final appointmentData = {
      'idpat': data['patientId'],
      'idpro': data['providerId'],
      'type': 'instant',
      'service': data['service'],
      'patientlocation': data['patientLocation'],
      'providerlocation': providerLocation,
      'status': 'accepted',
      'prix': data['prix'], // ✅ Copied from provider_requests!
      'paymentMethod': data['paymentMethod'],
      'createdAt': FieldValue.serverTimestamp(),
    };

    final appRef = _firestore.collection('appointments').doc();
    tx.set(appRef, appointmentData);
    // ...
  });
}
```

**Firestore Document:**
```json
{
  "idpat": "abc123",
  "idpro": "7ftk4BqD7McN3Bjm3LFFtiJ6xkV2",
  "prix": 500.0,
  "type": "instant",
  "status": "accepted",
  "paymentMethod": "CCP"
}
```

---

## 🎨 Visual Flow

### Before (Incorrect):
```
Payment: 300 DZD (from payment screen)
   ↓
Provider Card: 300 DZD  ❌ Wrong price!
   ↓
provider_requests: prix: 300.0  ❌ Wrong!
   ↓
appointments: prix: 300.0  ❌ Wrong!
```

### After (Correct):
```
professionals: prix: 500.0 (Source of truth)
   ↓
Provider Card: 500 DZD  ✅ Correct!
   ↓
provider_requests: prix: 500.0  ✅ Correct!
   ↓
appointments: prix: 500.0  ✅ Correct!
```

---

## 📋 Firestore Structure

### professionals Collection (Source):
```json
{
  "id_user": "7ftk4BqD7McN3Bjm3LFFtiJ6xkV2",
  "login": "login_7ftk4BqD",
  "profession": "Cardiologist",
  "specialite": "cardiology",
  "prix": 500.0,  ← SOURCE OF TRUTH
  "disponible": true,
  "currentlocation": GeoPoint(36.7538, 3.0588)
}
```

### provider_requests Collection (Copy):
```json
{
  "patientId": "abc123",
  "providerId": "7ftk4BqD7McN3Bjm3LFFtiJ6xkV2",
  "service": "consultation",
  "specialty": "cardiology",
  "prix": 500.0,  ← COPIED FROM professionals
  "paymentMethod": "CCP",
  "status": "pending",
  "createdAt": "2025-10-01T10:30:00Z"
}
```

### appointments Collection (Copy):
```json
{
  "idpat": "abc123",
  "idpro": "7ftk4BqD7McN3Bjm3LFFtiJ6xkV2",
  "type": "instant",
  "service": "consultation",
  "prix": 500.0,  ← COPIED FROM provider_requests
  "paymentMethod": "CCP",
  "status": "accepted",
  "createdAt": "2025-10-01T10:35:00Z"
}
```

---

## 🔍 Debug Output

When you run the app, you'll see:

```
📋 [PolishedSelectProvider] Processing 1 providers
   📄 Professional data from professionals collection:
      id_user: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2
      profession: Cardiologist
      specialite: cardiology
      prix: 500.0 (double)  ← Read from here!
      disponible: true
      ...
   🔍 Fetching user data from users collection for id_user: 7ftk4BqD...
   ✅ Found user data:
      nom: Benali
      prenom: Ahmed
      photo_profile: https://...
   ✅ Final Name: "Dr. Ahmed Benali"
   💰 Provider prix: 500.0 DZD (from professionals.prix)  ← Logged!
✅ [PolishedSelectProvider] Updated UI with 1 providers

[User taps "Book" button]

💰 Creating request with provider prix: 500.0 DZD  ← Passed!
🆕 [ProviderRequestService] Creating request
   👤 patientId: abc123
   🩺 providerId: 7ftk4BqD7McN3Bjm3LFFtiJ6xkV2
   🛠 service: consultation  specialty: cardiology
   💰 prix: 500.0  paymentMethod: CCP  ← Stored!
✅ Request created: [requestId]

[Provider accepts]

✅ Appointment created with prix: 500.0 DZD  ← Copied!
```

---

## ✅ Verification Checklist

### 1. Check professionals Collection:
```
professionals/[docId]
  ✅ prix: 500.0 (number, not string)
```

### 2. Check Provider Card Display:
```
Provider Card shows: "500 DZD"  ✅
```

### 3. Check Console Output:
```
💰 Provider prix: 500.0 DZD (from professionals.prix)  ✅
💰 Creating request with provider prix: 500.0 DZD  ✅
```

### 4. Check provider_requests Document:
```
provider_requests/[requestId]
  ✅ prix: 500.0
```

### 5. Check appointments Document:
```
appointments/[appointmentId]
  ✅ prix: 500.0
```

---

## 🎯 Benefits

### Before:
- ❌ Card showed payment amount (not provider's actual prix)
- ❌ Inconsistent pricing across documents
- ❌ No way to see provider's actual price

### After:
- ✅ Card displays provider's actual prix from professionals collection
- ✅ Consistent pricing throughout the flow
- ✅ Prix is correctly propagated: professionals → provider_requests → appointments
- ✅ Clear debug logs showing prix at each step
- ✅ Each provider can have their own pricing

---

## 💡 Important Notes

### 1. Field Name Priority:
```dart
data['prix'] ?? data['price'] ?? widget.prix
```
- First tries `prix` (French)
- Then tries `price` (English)
- Falls back to `widget.prix` if neither exists

### 2. Type Safety:
```dart
final providerPrix = _toDouble(data['prix'] ?? data['price'], widget.prix);
```
- Safely converts strings to doubles
- Handles null values gracefully
- Prevents crashes from type mismatches

### 3. Data Consistency:
- Prix flows: `professionals` → `provider_requests` → `appointments`
- Each copy maintains the same value
- No manual updates needed

---

## 🚀 Testing

### Step 1: Set Prix in Firestore
```
Go to Firebase Console
→ Firestore Database
→ professionals collection
→ Your provider document
→ Add/Update field: prix = 500 (number)
```

### Step 2: Run the App
```powershell
flutter run
```

### Step 3: Navigate to Provider Selection
```
1. Login as patient
2. Go to Instant Appointment flow
3. Complete payment
4. See provider card
```

### Step 4: Verify Display
```
Provider card should show:
  💰 500 DZD  ✅ (from professionals.prix)
```

### Step 5: Create Request
```
1. Tap "Book" button
2. Check console:
   💰 Creating request with provider prix: 500.0 DZD  ✅
```

### Step 6: Check Firestore
```
provider_requests/[requestId]
  prix: 500.0  ✅

appointments/[appointmentId] (after provider accepts)
  prix: 500.0  ✅
```

---

## 🎉 Summary

**Enhancement Complete:**
- ✅ Card displays prix from professionals collection
- ✅ Prix is stored in provider_requests when creating request
- ✅ Prix is copied to appointments when provider accepts
- ✅ Consistent pricing throughout the entire booking flow
- ✅ Each provider can set their own prix
- ✅ Comprehensive debug logging at each step

**Result:** The app now correctly reads, displays, and propagates provider pricing from the source of truth (professionals collection) through the entire booking flow! 💰✨
