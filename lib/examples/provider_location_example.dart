import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/provider_location_service.dart';

/// Example provider screen showing how to use ProviderLocationService
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  bool _isAvailable = false;
  bool _isLoadingAvailability = false;
  Position? _currentPosition;
  String _locationStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadProviderAvailability();
    _checkCurrentLocation();
  }

  @override
  void dispose() {
    // Stop location updates when screen is disposed
    ProviderLocationService.dispose();
    super.dispose();
  }

  /// Load provider's current availability status
  Future<void> _loadProviderAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
    });

    try {
      final isAvailable = await ProviderLocationService.isProviderAvailable();
      setState(() {
        _isAvailable = isAvailable;
        _locationStatus = isAvailable 
            ? (ProviderLocationService.isLocationUpdatesActive 
                ? 'Location updates active' 
                : 'Available but location inactive')
            : 'Offline';
      });

      // If provider is available, ensure location updates are running
      if (isAvailable && !ProviderLocationService.isLocationUpdatesActive) {
        ProviderLocationService.startLocationUpdates();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load availability status: $e');
    } finally {
      setState(() {
        _isLoadingAvailability = false;
      });
    }
  }

  /// Toggle provider availability
  Future<void> _toggleAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
    });

    try {
      final success = await ProviderLocationService.setProviderAvailability(!_isAvailable);
      if (success) {
        setState(() {
          _isAvailable = !_isAvailable;
          _locationStatus = _isAvailable 
              ? 'Location updates started' 
              : 'Location updates stopped';
        });
        _showSuccessSnackBar(_isAvailable 
            ? 'You are now available for appointments' 
            : 'You are now offline');
      } else {
        _showErrorSnackBar('Failed to update availability');
      }
    } catch (e) {
      _showErrorSnackBar('Error toggling availability: $e');
    } finally {
      setState(() {
        _isLoadingAvailability = false;
      });
    }
  }

  /// Manual location update for testing
  Future<void> _updateLocationManually() async {
    try {
      final success = await ProviderLocationService.updateProviderLocation();
      if (success) {
        _showSuccessSnackBar('Location updated successfully');
        _checkCurrentLocation();
      } else {
        _showErrorSnackBar('Failed to update location');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating location: $e');
    }
  }

  /// Get current location for display
  Future<void> _checkCurrentLocation() async {
    try {
      final position = await ProviderLocationService.getCurrentLocationOnce();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Availability Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isAvailable ? Icons.circle : Icons.circle_outlined,
                          color: _isAvailable ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_isAvailable ? "Available" : "Offline"}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: $_locationStatus',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (ProviderLocationService.isLocationUpdatesActive) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Updates every ${ProviderLocationService.updateIntervalSeconds}s',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Location Card
            if (_currentPosition != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                      Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                      Text('Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                      if (_currentPosition!.speed > 0)
                        Text('Speed: ${_currentPosition!.speed.toStringAsFixed(1)}m/s'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Control Buttons
            ElevatedButton.icon(
              onPressed: _isLoadingAvailability ? null : _toggleAvailability,
              icon: _isLoadingAvailability
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isAvailable ? Icons.stop : Icons.play_arrow),
              label: Text(_isAvailable ? 'Go Offline' : 'Go Online'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAvailable ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _updateLocationManually,
              icon: const Icon(Icons.my_location),
              label: const Text('Update Location Now'),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _checkCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Current Location'),
            ),

            const Spacer(),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Location updates automatically every 10 seconds when online\n'
                      '• Updates only when disponible == true in your profile\n'
                      '• Requires location permissions and GPS enabled\n'
                      '• Location is stored as currentLocation in professionnels collection',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative usage example: Simple toggle widget
class ProviderAvailabilityToggle extends StatefulWidget {
  final Function(bool)? onAvailabilityChanged;

  const ProviderAvailabilityToggle({
    super.key,
    this.onAvailabilityChanged,
  });

  @override
  State<ProviderAvailabilityToggle> createState() => _ProviderAvailabilityToggleState();
}

class _ProviderAvailabilityToggleState extends State<ProviderAvailabilityToggle> {
  bool _isAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final available = await ProviderLocationService.isProviderAvailable();
    setState(() {
      _isAvailable = available;
      _isLoading = false;
    });
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() {
      _isLoading = true;
    });

    final success = await ProviderLocationService.setProviderAvailability(value);
    
    if (success) {
      setState(() {
        _isAvailable = value;
        _isLoading = false;
      });
      widget.onAvailabilityChanged?.call(value);
    } else {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update availability'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return SwitchListTile(
      title: const Text('Available for appointments'),
      subtitle: Text(_isAvailable 
          ? 'Location tracking active' 
          : 'Offline - no location tracking'),
      value: _isAvailable,
      onChanged: _toggleAvailability,
      secondary: Icon(
        _isAvailable ? Icons.location_on : Icons.location_off,
        color: _isAvailable ? Colors.green : Colors.grey,
      ),
    );
  }
}

/// Example of how to use in your main provider app
/*
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider App',
      home: ProviderDashboard(),
    );
  }
}

// Or integrate in existing screens:
class ExistingProviderScreen extends StatefulWidget {
  @override
  _ExistingProviderScreenState createState() => _ExistingProviderScreenState();
}

class _ExistingProviderScreenState extends State<ExistingProviderScreen> {
  @override
  void initState() {
    super.initState();
    
    // Check if provider should be online and start location updates
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    final isAvailable = await ProviderLocationService.isProviderAvailable();
    if (isAvailable) {
      ProviderLocationService.startLocationUpdates();
    }
  }

  @override
  void dispose() {
    // Important: Stop location updates when leaving the app
    ProviderLocationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Your existing UI
          
          // Add the availability toggle
          ProviderAvailabilityToggle(
            onAvailabilityChanged: (isAvailable) {
              // Handle availability change
              print('Provider is now ${isAvailable ? "online" : "offline"}');
            },
          ),
          
          // Your other widgets
        ],
      ),
    );
  }
}
*/