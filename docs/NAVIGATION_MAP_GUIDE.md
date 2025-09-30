# Navigation Map Widget for Medical App

This navigation map implementation provides Google Maps-like navigation features using flutter_map and OpenStreetMap tiles for your medical appointment app.

## Features

✅ **OpenStreetMap Integration**: Free map tiles with no API key required  
✅ **Real-time GPS Tracking**: Live provider location updates with heading  
✅ **Smart Routing**: Multiple routing providers (OSRM, Mapbox, Google Directions)  
✅ **Navigation UI**: Google Maps-style interface with auto-zoom  
✅ **Arrival Detection**: Automatic detection when provider reaches patient  
✅ **Visual Feedback**: Animated markers, pulse effects, and smooth transitions  
✅ **Fallback Support**: Graceful degradation to straight-line routes  

## Quick Start

### 1. Basic Navigation Map

```dart
import 'package:latlong2/latlong.dart';
import '../widgets/maps/navigation_map_widget.dart';

// In your widget
NavigationMapWidget(
  patientLocation: LatLng(36.7538, 3.0588),
  providerLocation: LatLng(36.7400, 3.0500),
  showNavigationMode: true,
  onProviderLocationUpdate: (newLocation, heading) {
    // Update Firestore with real-time location
    print('Provider at: $newLocation, heading: $heading°');
  },
)
```

### 2. Full Navigation Experience

```dart
import '../screens/navigation/navigation_example_screen.dart';

// Navigate to full navigation screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NavigationExampleScreen(
      appointmentId: 'your_appointment_id',
      patientLocation: patientLocation,
      initialProviderLocation: providerLocation,
    ),
  ),
);
```

## Integration with Existing Code

### Replace FlutterMapTrackingWidget

If you're currently using `FlutterMapTrackingWidget`, you can easily upgrade:

```dart
// OLD: Basic tracking
FlutterMapTrackingWidget(
  appointmentId: appointmentId,
  showNearbyProviders: false,
)

// NEW: Enhanced navigation
NavigationMapWidget(
  patientLocation: patientLocation,
  providerLocation: providerLocation,
  showNavigationMode: true,
  onProviderLocationUpdate: _updateLocationInFirestore,
)
```

### Update Live Tracking Screen

```dart
// lib/screens/booking/live_tracking_screen.dart
class LiveTrackingScreen extends StatefulWidget {
  final String appointmentId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigationMapWidget(
        patientLocation: _patientLocation,
        providerLocation: _providerLocation,
        showNavigationMode: true,
        onProviderLocationUpdate: (location, heading) {
          // Update appointment document in Firestore
          FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .update({
            'provider_location': {
              'latitude': location.latitude,
              'longitude': location.longitude,
              'heading': heading,
              'updated_at': FieldValue.serverTimestamp(),
            }
          });
        },
      ),
    );
  }
}
```

## Routing Service Configuration

### Free Option: OSRM (Default)

No configuration needed. Works out of the box with OpenStreetMap routing.

### Enhanced Options: Mapbox or Google

Add your API keys to `navigation_routing_service.dart`:

```dart
// For Mapbox (recommended for production)
static const String? _mapboxToken = 'your_mapbox_token_here';

// For Google Directions
static const String? _googleApiKey = 'your_google_api_key_here';
```

## Map Controls

The navigation map includes several built-in controls:

- **Auto-zoom Toggle**: Tap the GPS icon to enable/disable auto-fitting
- **Manual Zoom**: + and - buttons for manual zoom control
- **Center Route**: Button to fit the entire route in view
- **Tap to Toggle**: Tap anywhere on map to toggle auto-zoom

## Customization Options

### Navigation Arrow Styling

```dart
// Modify _buildNavigationArrow() in NavigationMapWidget
Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: Colors.blue, // Change arrow color
    shape: BoxShape.circle,
  ),
  child: Icon(
    Icons.navigation, // Change arrow icon
    color: Colors.white,
    size: 24,
  ),
)
```

### Route Line Styling

```dart
// Modify polyline in build() method
Polyline(
  points: _routePoints,
  strokeWidth: 5.0,      // Line thickness
  color: Colors.blue,    // Line color
  borderStrokeWidth: 2.0, // Border thickness
  borderColor: Colors.white, // Border color
)
```

### Marker Customization

```dart
// Patient marker (green with pulse animation)
// Provider marker (red or blue navigation arrow)
// Modify _buildPatientMarker() and _buildProviderMarker()
```

## Performance Optimization

### Location Update Frequency

```dart
LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 5, // Update every 5 meters (adjust as needed)
)
```

### Route Refresh Strategy

```dart
// Routes are refreshed when provider moves >50 meters
if (distance > 50) {
  _fetchRoute(); // Adjust threshold as needed
}
```

### Auto-zoom Debouncing

```dart
// Auto-zoom waits 2 seconds after location updates
Timer(const Duration(seconds: 2), () {
  if (_autoZoomEnabled && mounted) {
    _autoFitBounds();
  }
});
```

## Error Handling

The navigation system includes comprehensive error handling:

1. **Routing Fallbacks**: OSRM → Mapbox → Google → Straight line
2. **Network Timeouts**: 10-second timeout for routing requests
3. **GPS Issues**: Graceful handling of location permission denials
4. **Invalid Coordinates**: Validation and fallback to default locations

## Testing

### Sample Locations (Algeria)

```dart
final LatLng algiers = LatLng(36.7538, 3.0588);
final LatLng oran = LatLng(35.6976, -0.6337);
final LatLng constantine = LatLng(36.3650, 6.6147);
```

### Debug Mode

Enable debug prints by setting:

```dart
// In NavigationMapWidget
print('Route fetch error: $e'); // Already included
print('Provider moved to: $newLocation'); // Add as needed
```

## Architecture

```
NavigationMapWidget (UI Layer)
    ↓
NavigationRoutingService (Business Logic)
    ↓
Multiple Routing Providers (Data Layer)
    ├── OSRM (Free)
    ├── Mapbox (Premium)
    └── Google Directions (Premium)
```

## Best Practices

1. **Real-time Updates**: Update Firestore with provider location changes
2. **Battery Optimization**: Use appropriate `distanceFilter` values
3. **User Experience**: Enable auto-zoom by default, allow manual override
4. **Error Handling**: Always provide fallback routes
5. **Network Efficiency**: Cache routes and avoid unnecessary API calls

## Firestore Integration Example

```dart
void _updateProviderLocationInFirestore(LatLng location, double heading) async {
  try {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'provider_location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'heading': heading,
        'updated_at': FieldValue.serverTimestamp(),
      }
    });
  } catch (e) {
    print('Location update failed: $e');
  }
}
```

This navigation system provides a professional, Google Maps-like experience for your medical app while using free OpenStreetMap tiles and robust routing services.