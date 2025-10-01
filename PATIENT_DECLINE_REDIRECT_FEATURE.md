# Provider Decline - Patient Redirect Feature ✅

## Feature Overview
When a provider declines a patient's request, the patient is automatically notified and redirected back to the provider selection screen to choose another provider.

## Implementation

### 1. Real-Time Status Monitoring
The `PolishedWaitingScreen` uses Firebase real-time streams to monitor the request status:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('provider_requests')
      .doc(widget.requestId)
      .snapshots(),
  ...
)
```

### 2. Declined Status Detection
When the provider declines (status changes to 'declined'), the system automatically detects it:

```dart
final status = data['status'] as String?;

// Check for decline and show dialog, then redirect to select provider
if (status == 'declined') {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _handleDeclinedRequest(context, data);
    }
  });
}
```

### 3. User Notification
Shows a Material 3 styled dialog explaining the situation:

```dart
Future<void> _handleDeclinedRequest(BuildContext context, Map<String, dynamic> data) async {
  // Prevent showing dialog multiple times
  if (_hasShownDeclinedDialog) return;
  _hasShownDeclinedDialog = true;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row([
        Icon(Icons.cancel_outlined, color: errorColor),
        Text('Request Declined'),
      ]),
      content: Text(
        'The provider has declined your request. Please select another available provider to continue.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // Close dialog and redirect
          },
          child: Text('Select Another Provider'),
        ),
      ],
    ),
  );
}
```

### 4. Automatic Redirection
After the user acknowledges the dialog, they are automatically redirected to the provider selection screen with the original booking details preserved:

```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => PolishedSelectProviderScreen(
      service: data['service'] ?? 'consultation',
      specialty: data['specialty'],
      prix: _toDouble(data['prix'], 0),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      patientLocation: data['patientLocation'] ?? const GeoPoint(0, 0),
    ),
  ),
);
```

## User Flow

### Complete Flow:
```
1. Patient books service
   ↓
2. Patient selects Provider A
   ↓
3. Request sent → Status: 'pending'
   ↓
4. Patient sees "Waiting for Provider" screen
   ↓
5. Provider A declines → Status: 'declined'
   ↓
6. Real-time stream detects status change
   ↓
7. Dialog appears: "Request Declined"
   ↓
8. Patient taps "Select Another Provider"
   ↓
9. Redirected back to provider list
   ↓
10. Patient selects Provider B
    ↓
11. New request sent → Status: 'pending'
    ↓
12. Provider B accepts → Status: 'accepted'
    ↓
13. Patient redirected to tracking screen ✅
```

## Data Preservation

All booking details are preserved during the redirect:
- ✅ **Service** - The medical service requested (e.g., "consultation", "emergency")
- ✅ **Specialty** - Medical specialty (e.g., "generaliste", "pediatre")
- ✅ **Price** - Payment amount
- ✅ **Payment Method** - How the patient will pay
- ✅ **Patient Location** - GPS coordinates for distance calculation

This means the patient doesn't need to re-enter any information - just select a different provider.

## Key Features

### 1. Real-Time Detection ⚡
- Uses Firebase `.snapshots()` stream
- Instant notification when provider declines
- No polling or manual refresh needed

### 2. Single Dialog Prevention 🛡️
```dart
bool _hasShownDeclinedDialog = false; // Prevent multiple dialogs
```
- Prevents dialog from showing multiple times
- Important because StreamBuilder can rebuild multiple times

### 3. Non-Dismissible Dialog 🔒
```dart
barrierDismissible: false,
```
- User must acknowledge the decline
- Ensures they understand what happened before proceeding

### 4. Preserved Context 💾
- All booking details passed to new screen
- Patient location preserved for distance calculation
- Price and payment method maintained
- Service and specialty retained

## Status Handling

The waiting screen now handles three statuses:

### Status: `'pending'`
- Shows animated waiting UI
- Allow patient to cancel manually
- Continues monitoring for status changes

### Status: `'accepted'`
- Auto-redirect to tracking screen
- Shows appointment ID
- Provider location tracking begins

### Status: `'declined'` ✨ **NEW**
- Show "Request Declined" dialog
- Explain situation to patient
- Redirect to provider selection
- Preserve all booking details

## Technical Details

### Files Modified:
- `lib/screens/booking/polished_select_provider_screen.dart`
  - Added `_handleDeclinedRequest()` method
  - Added `_hasShownDeclinedDialog` flag
  - Added `_toDouble()` helper method
  - Added declined status check in StreamBuilder

### Security:
- Firestore rules already updated to allow provider decline
- Patient can only see their own requests
- Provider can only decline requests targeted to them

### Performance:
- Real-time stream is already established (no new connection)
- Dialog only shown once (prevented by flag)
- Minimal overhead from status checking

## Testing Instructions

### Test Decline Flow:
1. **Patient** → Login and book instant consultation
2. **Patient** → Select any provider
3. **Patient** → See "Waiting for Provider" screen
4. **Provider** → Login and open "Incoming Requests"
5. **Provider** → Tap "Decline" button
6. **Patient** → Should see "Request Declined" dialog appear immediately
7. **Patient** → Tap "Select Another Provider"
8. **Patient** → Should be back at provider list with same booking details
9. **Patient** → Select different provider
10. **Provider** → New provider sees new request
11. **Provider** → New provider accepts
12. **Patient** → Should redirect to tracking screen

### Edge Cases Handled:
- ✅ Multiple StreamBuilder rebuilds → Only show dialog once
- ✅ User navigates away → Dialog won't show (mounted check)
- ✅ Missing booking data → Uses defaults
- ✅ Network issues → Firebase handles reconnection

## Benefits

### For Patients:
- ✅ Immediate notification when declined
- ✅ Clear explanation of what happened
- ✅ Easy to select another provider
- ✅ No need to re-enter booking details
- ✅ Seamless experience

### For Providers:
- ✅ Can decline without guilt (patient automatically helped)
- ✅ Request disappears from their list immediately
- ✅ No manual coordination needed

### For System:
- ✅ Automatic flow - no manual intervention
- ✅ Real-time updates
- ✅ Clean state management
- ✅ Proper error handling

## Future Enhancements

Potential improvements:
1. **Decline Reason** - Provider can optionally specify why (busy, too far, etc.)
2. **Auto-Suggest** - Automatically suggest next best provider
3. **Notification** - Push notification to patient's phone
4. **Analytics** - Track decline rates per provider
5. **Feedback Loop** - Ask patient if they found another provider

---

## Summary

✅ **Real-time detection** - Patient notified instantly when provider declines
✅ **Clear communication** - Dialog explains what happened
✅ **Seamless redirect** - Back to provider list with details preserved
✅ **Single notification** - Dialog only shown once despite stream rebuilds
✅ **Data preservation** - All booking details maintained
✅ **User-friendly** - Simple "Select Another Provider" button

The patient now has a smooth recovery path when a provider declines their request! 🎉
