import 'package:flutter/material.dart';
import '../services/provider_location_service.dart';

/// Example implementation showing how to use the updateProviderLocation() function
/// This demonstrates proper integration in a Flutter app
class ProviderLocationUsageExample extends StatefulWidget {
  const ProviderLocationUsageExample({Key? key}) : super(key: key);

  @override
  State<ProviderLocationUsageExample> createState() => _ProviderLocationUsageExampleState();
}

class _ProviderLocationUsageExampleState extends State<ProviderLocationUsageExample> {
  bool _isLocationTrackingActive = false;
  String _statusMessage = 'Location tracking not started';
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  @override
  void dispose() {
    // Clean up resources when widget is disposed
    ProviderLocationService.dispose();
    super.dispose();
  }

  /// Check initial status of location tracking
  Future<void> _checkInitialStatus() async {
    final isActive = ProviderLocationService.isLocationUpdatesActive;
    setState(() {
      _isLocationTrackingActive = isActive;
      _statusMessage = isActive ? 'Location tracking is active' : 'Location tracking not started';
    });
  }

  /// Example 1: Test the location update functionality
  Future<void> _testLocationUpdate() async {
    setState(() {
      _statusMessage = 'Testing location update...';
    });

    final success = await ProviderLocationService.testLocationUpdate();
    
    setState(() {
      _statusMessage = success 
          ? '✅ Test passed! Location update is working correctly.'
          : '❌ Test failed! Check console for details.';
    });

    if (success) {
      _showSnackBar('Location update test completed successfully!', Colors.green);
    } else {
      _showSnackBar('Location update test failed. Check console logs.', Colors.red);
    }
  }

  /// Example 2: Update location once (useful for testing)
  Future<void> _updateLocationOnce() async {
    setState(() {
      _statusMessage = 'Updating location once...';
    });

    final success = await ProviderLocationExtension.updateLocationOnce();
    
    setState(() {
      _statusMessage = success 
          ? '✅ Location updated successfully!'
          : '❌ Location update failed!';
      if (success) _updateCount++;
    });

    _showSnackBar(
      success ? 'Location updated successfully!' : 'Location update failed!',
      success ? Colors.green : Colors.red,
    );
  }

  /// Example 3: Start periodic location updates (every 10 seconds)
  Future<void> _startPeriodicUpdates() async {
    setState(() {
      _statusMessage = 'Starting periodic location updates...';
    });

    try {
      // Start comprehensive location tracking
      await ProviderLocationService.startProviderLocationTracking();
      
      setState(() {
        _isLocationTrackingActive = true;
        _statusMessage = '✅ Periodic location updates started (every 10 seconds)';
      });

      _showSnackBar('Location tracking started! Updates every 10 seconds.', Colors.green);
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Failed to start location tracking: $e';
      });
      _showSnackBar('Failed to start location tracking', Colors.red);
    }
  }

  /// Example 4: Stop periodic location updates
  Future<void> _stopPeriodicUpdates() async {
    setState(() {
      _statusMessage = 'Stopping location updates...';
    });

    try {
      await ProviderLocationService.stopProviderLocationTracking();
      
      setState(() {
        _isLocationTrackingActive = false;
        _statusMessage = '✅ Location tracking stopped';
      });

      _showSnackBar('Location tracking stopped successfully!', Colors.orange);
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Failed to stop location tracking: $e';
      });
      _showSnackBar('Failed to stop location tracking', Colors.red);
    }
  }

  /// Example 5: Toggle provider availability
  Future<void> _toggleAvailability() async {
    setState(() {
      _statusMessage = 'Toggling provider availability...';
    });

    final success = await ProviderLocationExtension.toggleAvailability();
    
    if (success) {
      final isAvailable = await ProviderLocationService.isProviderAvailable();
      setState(() {
        _statusMessage = '✅ Provider availability: ${isAvailable ? "Available" : "Unavailable"}';
      });
      _showSnackBar(
        'Provider is now ${isAvailable ? "available" : "unavailable"}',
        isAvailable ? Colors.green : Colors.orange,
      );
    } else {
      setState(() {
        _statusMessage = '❌ Failed to toggle availability';
      });
      _showSnackBar('Failed to toggle availability', Colors.red);
    }
  }

  /// Show snackbar with message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Location Service Example'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isLocationTrackingActive ? Colors.green[50] : Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLocationTrackingActive ? Icons.location_on : Icons.location_off,
                          color: _isLocationTrackingActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_isLocationTrackingActive ? "Active" : "Inactive"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isLocationTrackingActive ? Colors.green[700] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_updateCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Updates performed: $_updateCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            const Text(
              'Location Service Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Test Button
            ElevatedButton.icon(
              onPressed: _testLocationUpdate,
              icon: const Icon(Icons.science),
              label: const Text('Test Location Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Update Once Button
            ElevatedButton.icon(
              onPressed: _updateLocationOnce,
              icon: const Icon(Icons.my_location),
              label: const Text('Update Location Once'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Start/Stop Periodic Updates
            if (!_isLocationTrackingActive)
              ElevatedButton.icon(
                onPressed: _startPeriodicUpdates,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Periodic Updates (10s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _stopPeriodicUpdates,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Periodic Updates'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 12),

            // Toggle Availability Button
            ElevatedButton.icon(
              onPressed: _toggleAvailability,
              icon: const Icon(Icons.toggle_on),
              label: const Text('Toggle Provider Availability'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Information Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Test the location update to verify everything works'),
                    const Text('2. Update location once for immediate testing'),
                    const Text('3. Start periodic updates for continuous tracking'),
                    const Text('4. Stop updates when provider goes offline'),
                    const Text('5. Toggle availability to control when location is updated'),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Location updates only occur when disponible == true',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
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

/// Example of how to integrate location updates in your provider app
class ProviderAppIntegrationExample {
  
  /// Call this when the provider logs in and becomes available
  static Future<void> onProviderLogin() async {
    print('🔐 Provider logged in - starting location tracking...');
    
    // Start location tracking when provider becomes available
    await ProviderLocationService.startProviderLocationTracking();
  }

  /// Call this when the provider logs out or goes offline
  static Future<void> onProviderLogout() async {
    print('🔐 Provider logged out - stopping location tracking...');
    
    // Stop location tracking when provider goes offline
    await ProviderLocationService.stopProviderLocationTracking();
  }

  /// Call this when provider toggles their availability status
  static Future<void> onAvailabilityToggle(bool isAvailable) async {
    print('🔄 Provider availability changed to: $isAvailable');
    
    if (isAvailable) {
      // Provider is now available - start location tracking
      await ProviderLocationService.startProviderLocationTracking();
    } else {
      // Provider is now unavailable - stop location tracking
      await ProviderLocationService.stopProviderLocationTracking();
    }
  }

  /// Example of how to handle app lifecycle changes
  static void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - resume location tracking if provider is available
        print('📱 App resumed - checking if location tracking should resume...');
        ProviderLocationService.isProviderAvailable().then((isAvailable) {
          if (isAvailable && !ProviderLocationService.isLocationUpdatesActive) {
            ProviderLocationService.startLocationUpdates();
          }
        });
        break;
        
      case AppLifecycleState.paused:
        // App went to background - location tracking continues but with reduced frequency
        print('📱 App paused - location tracking continues in background');
        break;
        
      case AppLifecycleState.detached:
        // App is being terminated - stop location tracking
        print('📱 App detached - stopping location tracking...');
        ProviderLocationService.stopLocationUpdates();
        break;
        
      default:
        break;
    }
  }
}
