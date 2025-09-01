# Healthcare Booking System

A modern, beautiful, and animated multi-page booking system for healthcare services built with Flutter.

## Features

### 🏥 Service Selection
- **Doctor Consultation**: Professional medical consultation and treatment
- **Nursing Specialist**: Advanced nursing care and procedures
- **Nursing Technician**: Technical nursing procedures and support
- **Nursing Assistant**: Basic care and patient support

### 📍 Location Management
- Pre-saved locations (Home, Office, Hospital, Clinic)
- Add custom locations manually
- Map integration ready (placeholder implemented)
- Address validation and storage

### 📊 Service Summary
- Detailed service information
- Distance from closest available provider
- Travel time estimates
- Comprehensive pricing breakdown
- Base service fee, travel fee, and service fee

### 💳 Payment Options
- **Cash Payment**: Pay upon service completion
- **Credit/Debit Card**: Secure card payment
- **Mobile Payment**: Mobile wallet integration
- **Bank Transfer**: Direct bank transfer

## Architecture

The system is built with a modular, page-based architecture:

```
ServiceSelectionPage → LocationSelectionPage → ServiceSummaryPage → PaymentPage
```

### File Structure

```
lib/widgets/
├── ServiceSelectionPage.dart      # Service type selection
├── LocationSelectionPage.dart     # Location selection/creation
├── ServiceSummaryPage.dart        # Service details & pricing
├── PaymentPage.dart              # Payment method & confirmation
├── BookNow.dart                  # Main entry point & utilities
└── BookingDemoPage.dart          # Demo showcase page
```

## Usage

### Basic Integration

```dart
import 'package:your_app/widgets/BookNow.dart';

// Show the booking system
showBookingSystem(context);

// Or use the legacy function for backward compatibility
showBookingSheet(context);
```

### Custom Integration

```dart
import 'package:your_app/widgets/ServiceSelectionPage.dart';

// Navigate directly to service selection
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const ServiceSelectionPage(),
  ),
);
```

## Design Features

### 🎨 Modern UI/UX
- Clean, minimalist design
- Consistent color scheme
- Beautiful gradients and shadows
- Responsive layout

### ✨ Smooth Animations
- Fade-in transitions
- Slide animations
- Scale transforms
- Pulse effects
- Elastic animations

### 📱 Mobile-First Design
- Touch-friendly interfaces
- Proper spacing and sizing
- Accessible color contrasts
- Smooth scrolling

## Customization

### Colors
The system uses a consistent color palette that can be easily customized:

```dart
// Primary colors
Color(0xFF3B82F6)  // Blue
Color(0xFF10B981)  // Green
Color(0xFFF59E0B)  // Yellow
Color(0xFFEF4444)  // Red

// Background colors
Color(0xFFF8FAFC)  // Light gray
Color(0xFF1E293B)  // Dark gray
```

### Animations
Animation durations and curves can be adjusted:

```dart
// Fade animation
duration: const Duration(milliseconds: 800)
curve: Curves.easeInOut

// Slide animation
duration: const Duration(milliseconds: 600)
curve: Curves.easeOutCubic
```

## Dependencies

The system requires the following Flutter packages:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # No additional external dependencies required
```

## Future Enhancements

### 🗺️ Map Integration
- Google Maps integration
- Location picker
- Geocoding services
- Route optimization

### 📅 Scheduling
- Calendar integration
- Time slot selection
- Recurring appointments
- Availability checking

### 🔔 Notifications
- Push notifications
- Email confirmations
- SMS reminders
- Status updates

### 💾 Data Persistence
- Local storage
- Cloud synchronization
- Booking history
- User preferences

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.

---

**Built with ❤️ using Flutter**
