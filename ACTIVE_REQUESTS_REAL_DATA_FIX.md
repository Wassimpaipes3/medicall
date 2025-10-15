# Fixed: Active Requests Now Shows Real Firestore Data

## Problem
The Active Requests section was displaying static mock data (Ahmed Bennani and Fatima Khadra) instead of real pending appointments from Firestore.

## Root Cause
Two conflicting `AppointmentRequest` models existed:
1. **Mock model** in `lib/services/provider/provider_service.dart` - Used for demo data
2. **Firestore model** in `lib/services/provider_dashboard_service.dart` - Connects to real database

The dashboard was loading from `provider_service.getPendingRequests()` which returned hardcoded mock data.

## Solution

### 1. Updated Dashboard to Use Firestore Data
**File:** `lib/screens/provider/provider_dashboard_screen.dart`

Changed data source from mock service to Firestore service:
```dart
// Before (Mock data):
final requests = await _providerService.getPendingRequests();

// After (Real Firestore data):
final requests = await DashboardService.ProviderDashboardService.getPendingRequests();
```

### 2. Fixed Type Declaration
Changed the pending requests list type to use the Firestore model:
```dart
// Before:
List<AppointmentRequest> _pendingRequests = [];  // Mock model

// After:
List<DashboardService.AppointmentRequest> _pendingRequests = [];  // Firestore model
```

### 3. Enhanced Firestore Model
**File:** `lib/services/provider_dashboard_service.dart`

Added convenience getters to match UI expectations:
```dart
class AppointmentRequest {
  // ... existing fields ...
  
  // Added convenience getters for dashboard UI:
  String get patientName => patientFullName;
  String get serviceType => motifConsultation;
  double get estimatedFee => tarif;
}
```

Enhanced `fromFirestore()` factory to handle multiple field name variations:
- **Provider ID:** `idpro`, `professionnelId`
- **Patient ID:** `patientId`, `idpat`
- **Patient Name:** `patientNom` + `patientPrenom`, `nom` + `prenom`
- **Status:** `etat`, `status`
- **Price:** `tarif`, `prix`, `price`
- **Date:** `dateRendezVous`, `createdAt`, `updatedAt`
- **Service:** `motifConsultation`, `service`, `motif`

### 4. Simplified Request Card UI
**File:** `lib/screens/provider/provider_dashboard_screen.dart`

Updated `_buildRequestCard()` to use only available Firestore fields:
- ✅ Patient name from `patientName` getter
- ✅ Service type from `serviceType` getter  
- ✅ Price from `estimatedFee` getter
- ✅ Time from `dateRendezVous`
- ✅ Status badge from `etat`
- ❌ Removed: `patientLocationString` (not in Firestore model)
- ❌ Removed: `estimatedDuration` (not in Firestore model)

## What Now Shows Real Data

### Active Requests Section
- ✅ **Patient names** from Firestore `appointments` collection
- ✅ **Service types** from appointment `motifConsultation` or `service` field
- ✅ **Prices** from `tarif`, `prix`, or `price` field
- ✅ **Appointment times** from `dateRendezVous` or `createdAt`
- ✅ **Status** from `etat` or `status` field
- ✅ **Real-time updates** when appointments change

### Data Requirements

For appointments to appear in Active Requests, they must have:
```javascript
{
  idpro: "provider_uid",              // or professionnelId
  patientNom: "Last Name",            // or nom
  patientPrenom: "First Name",        // or prenom
  status: "pending",                  // or etat: "en_attente"
  motifConsultation: "Consultation",  // or service
  tarif: 100,                         // or prix/price
  dateRendezVous: Timestamp,          // or createdAt/updatedAt
}
```

## Testing

### To See Real Data:
1. **Hot restart** the app
2. Login as provider
3. Check console for: `📋 Loaded X REAL pending requests from Firestore`
4. Active Requests section should show:
   - Real patient names from Firestore
   - Actual appointment details
   - Correct prices and times

### If Still Shows Mock Data:
- Check console logs for request count
- Verify Firestore has appointments with `status: "pending"` or `etat: "en_attente"`
- Ensure `idpro` matches logged-in provider's UID
- Hot restart (not hot reload)

### If Shows "No Active Requests":
This is **correct** if:
- No pending appointments exist in Firestore
- Provider's UID doesn't match any appointment's `idpro`
- All appointments have status other than pending

## Debug Logging

Console output now shows:
```
📋 Loaded 3 REAL pending requests from Firestore
```

This confirms data is coming from Firestore, not mock service.

## Benefits

✅ **Real Data:** Shows actual patient appointment requests
✅ **Live Updates:** Refreshes every 30 seconds with real data
✅ **Field Flexibility:** Works with multiple Firestore field naming conventions
✅ **No More Mock Data:** Ahmed Bennani and Fatima Khadra replaced with real patients
✅ **Type Safety:** Uses correct model throughout the flow

## Summary

The Active Requests section now displays **real pending appointments from Firestore** instead of hardcoded mock data. The dashboard fetches data using `ProviderDashboardService.getPendingRequests()` which queries the `appointments` collection for documents with:
- Matching provider ID (`idpro` or `professionnelId`)
- Pending status (`status: "pending"` or `etat: "en_attente"`)

This ensures providers see their actual incoming appointment requests, not fictional test data! 🎉
