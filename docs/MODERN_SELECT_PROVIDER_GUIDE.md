# Modern SelectProviderScreen Documentation

## Overview

The new `ModernSelectProviderScreen` is a complete redesign of the provider selection interface for your Flutter medical booking app. It features a modern, clean healthcare UI without Google Maps, focusing on user experience and professional medical aesthetics.

## 🎨 Design Features

### Healthcare Theme
- **Color Scheme**: Blue (#1565C0) and white professional medical theme
- **Typography**: Clear, readable fonts with proper hierarchy
- **Cards**: Rounded corners with subtle shadows for modern look
- **Responsive**: Works on both small and large screens

### UI Components
- **Provider Cards**: Clean card-based layout with all essential information
- **Profile Pictures**: Circular avatars with fallback initials
- **Star Ratings**: Interactive star ratings using flutter_rating_bar
- **Distance Display**: Real-time distance calculation from patient location
- **Availability Status**: Green/gray dots for online/offline status
- **Loading States**: Lottie animations for professional loading experience
- **Empty States**: Friendly empty state with illustrations

## 📱 Screen Components

### 1. Header Section
```dart
Container(
  color: Colors.white,
  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Service: ${widget.service}'),
      if (widget.specialty != null) Text('Specialty: ${widget.specialty}'),
      Text('Showing providers near you'),
    ],
  ),
)
```

### 2. Provider Card Layout
```dart
Container(
  margin: const EdgeInsets.only(bottom: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(...)],
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        // Profile picture + basic info
        Row(
          children: [
            CircleAvatar(...), // Profile picture
            Expanded(child: ProviderInfo(...)), // Name, specialty, rating
            AvailabilityDot(...), // Online status
          ],
        ),
        // Price display
        PriceRow(...),
        // Action buttons
        Row(
          children: [
            OutlinedButton("View Details"),
            ElevatedButton("Select"),
          ],
        ),
      ],
    ),
  ),
)
```

### 3. Provider Details Modal
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => ProviderDetailsModal(provider: provider),
);
```

## 🔧 Technical Implementation

### Real-Time Provider Updates
```dart
void _startProviderStream() {
  final query = FirebaseFirestore.instance
      .collection('professionals')
      .where('disponible', isEqualTo: true);
  
  _providersSubscription = query.snapshots().listen((snapshot) {
    _updateProviderList(snapshot.docs);
  });
}
```

### Distance Calculation
```dart
double _calculateDistance(GeoPoint providerLocation, GeoPoint patientLocation) {
  return Geolocator.distanceBetween(
    patientLocation.latitude,
    patientLocation.longitude,
    providerLocation.latitude,
    providerLocation.longitude,
  ) / 1000.0; // Convert to km
}
```

### Provider Data Model
```dart
class ProviderData {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final double price;
  final double distance;
  final bool isAvailable;
  final String? profilePicture;
  final String? bio;
  final String? experience;
  final String? address;
  final String? contact;

  factory ProviderData.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    GeoPoint patientLocation,
  ) {
    // Implementation handles field mapping and distance calculation
  }
}
```

## 📋 Required Firestore Fields

### Minimum Required Fields
```javascript
// professionals collection document
{
  "login": "Dr. John Smith",           // Provider name
  "specialite": "Cardiology",         // Medical specialty  
  "disponible": true,                 // Availability status
  "currentlocation": GeoPoint(lat, lng), // Provider location
  "rating": 4.5,                      // Rating (1-5)
  "price": 150.0,                     // Service price in DZD
}
```

### Optional Enhanced Fields
```javascript
{
  "profile_picture": "https://...",    // Profile image URL
  "bio": "Experienced cardiologist...", // Professional bio
  "experience": "10",                  // Years of experience
  "address": "123 Medical Center St",  // Practice address
  "contact": "+213555123456",          // Phone number
  "nom": "Dr. John Smith",            // Alternative name field
  "specialty": "Cardiology",          // Alternative specialty field
  "tarif": 150.0,                     // Alternative price field
}
```

## 🎬 Animation Assets

### Required Lottie Files
Place these in `assets/animations/`:

1. **loading.json** - Spinning animation for provider search
2. **empty.json** - Medical illustration for no results
3. **waiting.json** - Clock animation for waiting screen

### Asset Configuration
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/animations/
```

## 🚀 Integration Guide

### 1. Replace Existing Import
```dart
// OLD
import 'your_old_select_provider_screen.dart';

// NEW  
import 'lib/screens/booking/modern_select_provider_screen.dart';
```

### 2. Navigation Usage
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SelectProviderScreen(
      service: 'consultation',           // Required: service type
      specialty: 'cardiology',           // Optional: medical specialty
      prix: 150.0,                       // Required: service price
      paymentMethod: 'cash',             // Required: payment method
      patientLocation: GeoPoint(36.7538, 3.0588), // Required: patient location
    ),
  ),
);
```

### 3. Dependencies
```yaml
# pubspec.yaml
dependencies:
  flutter_rating_bar: ^4.0.1
  lottie: ^3.3.1
  cached_network_image: ^3.3.0
  geolocator: ^14.0.2
  cloud_firestore: ^6.0.1
```

## 🎯 User Flow

1. **Screen Opens**: Shows loading animation while fetching providers
2. **Provider Display**: Lists available providers sorted by distance
3. **Provider Selection**: User can view details or directly select
4. **Details Modal**: Shows comprehensive provider information
5. **Selection Confirmation**: Creates provider request and shows waiting screen
6. **Real-time Updates**: Screen updates as providers go online/offline

## 📱 Responsive Design

### Mobile (< 600px)
- Single column layout
- Compact provider cards
- Touch-friendly button sizes
- Optimized spacing

### Tablet (≥ 600px)  
- Maintains single column for consistency
- Larger cards with more spacing
- Enhanced typography scale
- Better use of available space

## 🎨 Customization Options

### Theme Colors
```dart
// Primary blue color
const Color(0xFF1565C0)

// Background color
const Color(0xFFF8FAFB)

// Text colors
const Color(0xFF263238) // Dark text
Colors.grey[600]        // Secondary text
Colors.grey[700]        // Body text
```

### Card Styling
```dart
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
)
```

### Button Styles
```dart
// Primary button
ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF1565C0),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
)

// Secondary button
OutlinedButton.styleFrom(
  side: const BorderSide(color: Color(0xFF1565C0)),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
)
```

## 🔍 Troubleshooting

### Common Issues

1. **Empty Provider List**
   - Check Firestore security rules
   - Verify `disponible: true` filter
   - Ensure correct collection name (`professionals`)

2. **Distance Not Calculating**
   - Verify `currentlocation` field exists as GeoPoint
   - Check location permissions
   - Ensure valid coordinates

3. **Animations Not Loading**
   - Verify asset paths in pubspec.yaml
   - Check Lottie file format validity
   - Ensure animations directory exists

4. **Rating Stars Not Showing**
   - Confirm flutter_rating_bar dependency
   - Check rating field is numeric (double/int)
   - Verify rating value is between 0-5

## 📈 Performance Optimizations

### Stream Management
```dart
@override
void dispose() {
  _providersSubscription?.cancel();
  _refreshTimer?.cancel();
  super.dispose();
}
```

### Image Caching
```dart
CachedNetworkImage(
  imageUrl: provider.profilePicture!,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => FallbackAvatar(),
)
```

### Debounced Updates
```dart
Timer? _refreshTimer;

void _scheduleRefresh() {
  _refreshTimer?.cancel();
  _refreshTimer = Timer(const Duration(seconds: 30), () {
    _restartProviderStream();
  });
}
```

This modern implementation provides a professional, user-friendly interface that aligns with healthcare industry standards while maintaining excellent performance and user experience.