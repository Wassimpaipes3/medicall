# Provider Location Service Integration Guide

## Overview
The `ProviderLocationService` provides real-time GPS tracking for healthcare providers in your Flutter app. It automatically updates provider location in Firestore when they are available and handles all the complexity of permissions, error handling, and periodic updates.

## Features
- ✅ **Automatic location tracking** every 10 seconds when provider is available
- ✅ **Permission handling** with proper user prompts
- ✅ **Error handling and retry logic** for robust operation
- ✅ **Firestore integration** with the `professionnels` collection
- ✅ **Availability-based tracking** (only updates when `disponible == true`)
- ✅ **Battery optimization** with distance filtering and smart updates
- ✅ **Easy integration** with simple start/stop methods

## Setup

### 1. Add Dependencies
Add these to your `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.15.0
  geolocator: ^10.1.0
```

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### 3. iOS Permissions
Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your real-time location to patients.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your location while providing services.</string>
```

## Firestore Schema

The service expects your provider documents in the `professionnels` collection with this structure:

```javascript
// Document path: /professionnels/{providerId}
{
  "disponible": true,                    // Required: Controls whether location updates
  "currentLocation": GeoPoint(lat, lng), // Updated automatically by the service
  "lastUpdated": Timestamp,              // Updated automatically by the service  
  "locationAccuracy": 5.2,               // GPS accuracy in meters
  "isLocationActive": true,              // Whether location tracking is currently active
  
  // Your existing provider fields...
  "name": "Dr. Smith",
  "specialty": "General Medicine",
  // etc.
}
```

## Basic Usage

### Quick Start
```dart
import 'package:your_app/services/provider_location_service.dart';

class ProviderScreen extends StatefulWidget {
  @override
  _ProviderScreenState createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen> {
  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    // Check if provider is already available
    final isAvailable = await ProviderLocationService.isProviderAvailable();
    if (isAvailable) {
      ProviderLocationService.startLocationUpdates();
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Stop updates when leaving the screen
    ProviderLocationService.stopLocationUpdates();
    super.dispose();
  }

  // Toggle provider availability
  Future<void> _toggleAvailability() async {
    final currentStatus = await ProviderLocationService.isProviderAvailable();
    final success = await ProviderLocationService.setProviderAvailability(!currentStatus);
    
    if (success) {
      setState(() {
        // Update UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Provider Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: _toggleAvailability,
          child: Text('Toggle Availability'),
        ),
      ),
    );
  }
}
```

## Core Methods

### 1. Start/Stop Location Tracking
```dart
// Start automatic location updates (every 10 seconds)
ProviderLocationService.startLocationUpdates();

// Stop location updates
ProviderLocationService.stopLocationUpdates();

// Check if updates are currently active
bool isActive = ProviderLocationService.isLocationUpdatesActive;
```

### 2. Availability Management
```dart
// Set provider as available (starts location tracking)
bool success = await ProviderLocationService.setProviderAvailability(true);

// Set provider as unavailable (stops location tracking)  
bool success = await ProviderLocationService.setProviderAvailability(false);

// Check current availability status
bool isAvailable = await ProviderLocationService.isProviderAvailable();
```

### 3. Manual Location Updates
```dart
// One-time location update
bool success = await ProviderLocationService.updateProviderLocation();

// Get current location without updating Firestore
Position? position = await ProviderLocationService.getCurrentLocationOnce();
if (position != null) {
  print('Lat: ${position.latitude}, Lng: ${position.longitude}');
}
```

## Advanced Usage

### Custom Update Intervals
To change the update frequency, modify the service:

```dart
// In provider_location_service.dart, change:
static const Duration updateInterval = Duration(seconds: 30); // Update every 30s
```

### Handle Location Updates in Background
```dart
class ProviderApp extends StatefulWidget {
  @override
  _ProviderAppState createState() => _ProviderAppState();
}

class _ProviderAppState extends State<ProviderApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkProviderStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ProviderLocationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is back in foreground - resume location if provider is available
        _checkProviderStatus();
        break;
      case AppLifecycleState.paused:
        // App is in background - continue location updates if needed
        break;
      case AppLifecycleState.detached:
        // App is being terminated - stop location updates
        ProviderLocationService.stopLocationUpdates();
        break;
    }
  }

  Future<void> _checkProviderStatus() async {
    final isAvailable = await ProviderLocationService.isProviderAvailable();
    if (isAvailable && !ProviderLocationService.isLocationUpdatesActive) {
      ProviderLocationService.startLocationUpdates();
    }
  }
}
```

## Integration with Appointment Acceptance

When a provider accepts an appointment, update both the appointment and start location tracking:

```dart
import 'package:your_app/services/appointment_service.dart';
import 'package:your_app/services/provider_location_service.dart';

class AppointmentAcceptanceHandler {
  static Future<bool> acceptAppointment({
    required String appointmentId,
    required String providerId,
  }) async {
    try {
      // Get provider's current location
      final position = await ProviderLocationService.getCurrentLocationOnce();
      if (position == null) {
        throw Exception('Unable to get current location');
      }

      final providerLocation = GeoPoint(position.latitude, position.longitude);

      // Accept appointment with provider's location
      await AppointmentService.acceptAppointmentAndSetLocation(
        appointmentId: appointmentId,
        providerId: providerId,
        providerLocation: providerLocation,
        providerNotes: 'On my way!',
      );

      // Ensure provider is available and location tracking is active
      await ProviderLocationService.setProviderAvailability(true);

      return true;
    } catch (e) {
      print('Error accepting appointment: $e');
      return false;
    }
  }
}
```

## Error Handling

The service includes built-in error handling:

```dart
// The service automatically retries failed location updates up to 3 times
// with a 2-second delay between retries

// You can also handle specific errors:
try {
  final success = await ProviderLocationService.updateProviderLocation();
  if (!success) {
    // Handle failed update (permissions, GPS disabled, etc.)
    _showLocationErrorDialog();
  }
} catch (e) {
  // Handle unexpected errors
  _showErrorMessage('Location update failed: $e');
}
```

## Testing

### Test Location Updates
```dart
// Test single location update
void testLocationUpdate() async {
  print('Testing location update...');
  final success = await ProviderLocationService.updateProviderLocation();
  print('Update result: $success');
}

// Test location permissions
void testPermissions() async {
  final position = await ProviderLocationService.getCurrentLocationOnce();
  if (position != null) {
    print('Location: ${position.latitude}, ${position.longitude}');
  } else {
    print('Failed to get location - check permissions');
  }
}
```

### Monitor Firestore Updates
Watch your provider document in the Firebase Console to see location updates in real-time:

```
Collection: professionnels
Document: {providerId}
Fields to watch:
- currentLocation (should update every 10 seconds)
- lastUpdated (timestamp of last update)
- isLocationActive (true when tracking is active)
```

## Performance Considerations

### Battery Optimization
- **Distance filtering**: Only updates if moved 5+ meters
- **Accuracy settings**: Uses high accuracy but with timeouts
- **Conditional updates**: Only runs when `disponible == true`
- **Smart intervals**: 10-second intervals balance accuracy with battery life

### Data Usage
- **Minimal payload**: Only updates 3 fields in Firestore
- **Efficient queries**: Single document updates, no complex queries
- **Retry logic**: Prevents unnecessary repeated failures

## Troubleshooting

### Common Issues

1. **Location not updating**
   - Check if `disponible == true` in provider document
   - Verify location permissions are granted
   - Ensure GPS is enabled on device
   - Check Firebase Console for error logs

2. **Permission denied errors**
   - Request permissions in app settings
   - Make sure AndroidManifest.xml includes location permissions
   - For iOS, check Info.plist permissions

3. **Updates stop working**
   - Call `ProviderLocationService.startLocationUpdates()` after app resume
   - Check if provider availability changed to false
   - Verify Firebase authentication is still valid

4. **High battery usage**
   - Increase update interval (change `updateInterval` constant)
   - Increase distance filter (change `distanceFilter` in location settings)
   - Stop updates when provider goes offline

### Debug Logs
The service includes extensive logging. Enable debug prints to monitor:
- Location update attempts
- Permission status
- Firestore update results
- Error messages and retry attempts

```dart
// All debug prints start with emojis for easy filtering:
// 📍 - Location updates
// ✅ - Success messages  
// ❌ - Error messages
// ⚠️ - Warning messages
// 🔄 - Retry attempts
```

## Security Considerations

- **Authentication required**: All updates require valid Firebase Auth
- **Provider verification**: Only authenticated provider can update their own location
- **Firestore rules**: Ensure your rules allow providers to update their own documents

Example Firestore security rules:
```javascript
match /professionnels/{providerId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == providerId;
}
```

This comprehensive service provides everything you need for real-time provider location tracking in your healthcare app! 🚀