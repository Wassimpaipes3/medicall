import 'PaymentPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ServiceSelectionPage.dart';
import '../../core/enhanced_theme.dart';
import '../../data/services/location_service.dart';
import '../../data/models/location_models.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool isCustom;

  LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isCustom = false,
  });
}

class LocationSelectionPage extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;
  final Map<String, dynamic>? preSelectedDoctor;

  const LocationSelectionPage({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
    this.preSelectedDoctor,
  });

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage>
    with TickerProviderStateMixin {
  LocationData? _selectedLocation;
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customAddressController = TextEditingController();
  bool _showCustomLocationForm = false;
  bool _isLoading = false;
  
  // Real-time location variables
  final LocationService _locationService = LocationService();
  UserLocation? _currentLocation;
  bool _isGettingCurrentLocation = false;
  String _currentLocationAddress = '';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Dynamic saved locations from Firebase
  List<LocationData> _savedLocations = [];
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    
    // Load saved locations from Firebase
    _loadSavedLocationsFromFirebase();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _customNameController.dispose();
    _customAddressController.dispose();
    super.dispose();
  }

  /// Load saved locations from Firebase for current patient
  Future<void> _loadSavedLocationsFromFirebase() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in, cannot load saved locations');
        setState(() {
          _isLoadingLocations = false;
        });
        return;
      }

      print('🔍 Loading saved locations for patient: ${user.uid}');
      
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('savedLocations')
          .orderBy('createdAt', descending: true)
          .get();

      print('   Found ${locationsSnapshot.docs.length} saved locations');

      final List<LocationData> locations = [];
      for (var doc in locationsSnapshot.docs) {
        final data = doc.data();
        final GeoPoint? geoPoint = data['location'] as GeoPoint?;
        
        locations.add(LocationData(
          name: data['name'] ?? 'Unknown',
          address: data['address'] ?? '',
          latitude: geoPoint?.latitude ?? 0.0,
          longitude: geoPoint?.longitude ?? 0.0,
          isCustom: data['isCustom'] ?? false,
        ));
        print('   📍 ${data['name']}: ${data['address']} (${geoPoint?.latitude}, ${geoPoint?.longitude})');
      }

      setState(() {
        _savedLocations = locations;
        _isLoadingLocations = false;
      });

      print('✅ Loaded ${_savedLocations.length} saved locations successfully');
    } catch (e) {
      print('❌ Error loading saved locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  /// Save location to Firebase for current patient
  Future<void> _saveLocationToFirebase(LocationData location) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in, cannot save location');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('You must be logged in to save locations')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      print('💾 Saving location to Firebase: ${location.name}');
      print('   Patient ID: ${user.uid}');
      print('   Collection: patients/${user.uid}/savedLocations');

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('savedLocations')
          .add({
        'name': location.name,
        'address': location.address,
        'location': GeoPoint(location.latitude, location.longitude),
        'isCustom': location.isCustom,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Location saved successfully with GeoPoint(${location.latitude}, ${location.longitude})');

      // Reload locations
      await _loadSavedLocationsFromFirebase();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Location "${location.name}" saved successfully')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving location: $e');
      
      // Parse the error for better user feedback
      String errorMessage = 'Failed to save location';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules.';
        print('🔒 FIRESTORE PERMISSION ERROR:');
        print('   You need to update your Firestore security rules to allow:');
        print('   patients/{patientId}/savedLocations - write access for authenticated users');
        print('   ');
        print('   Add this rule to your Firestore:');
        print('   match /patients/{patientId}/savedLocations/{locationId} {');
        print('     allow read, write: if request.auth != null && request.auth.uid == patientId;');
        print('   }');
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Patient document not found';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                print('Full error: $e');
              },
            ),
          ),
        );
      }
    }
  }

  /// Get current real-time location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      // Request location permissions
      final hasPermission = await _locationService.requestLocationPermissions();
      if (!hasPermission) {
        _showLocationPermissionDialog();
        return;
      }

      // Get current location
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation != null) {
        setState(() {
          _currentLocation = userLocation;
        });

        // Get address from coordinates
        await _getAddressFromCoordinates(
          userLocation.latitude, 
          userLocation.longitude,
        );

        // Create location data and select it
        final currentLocationData = LocationData(
          name: 'Current Location',
          address: _currentLocationAddress,
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          isCustom: true,
        );

        setState(() {
          _selectedLocation = currentLocationData;
          _showCustomLocationForm = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Current location selected: $_currentLocationAddress'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to get current location. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isGettingCurrentLocation = false;
      });
    }
  }

  /// Get address from coordinates using geocoding
  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _currentLocationAddress = [
            placemark.street,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((component) => component != null && component.isNotEmpty)
           .join(', ');
        });
      } else {
        setState(() {
          _currentLocationAddress = 'Current Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _currentLocationAddress = 'Current Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
      });
    }
  }

  /// Show location permission dialog
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Permission'),
          ],
        ),
        content: const Text(
          'This app needs location permission to use your current location. Please enable location access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEnhancedPreSavedLocations(),
                          const SizedBox(height: 24),
                          _buildEnhancedAddCustomLocationButton(),
                          if (_showCustomLocationForm) ...[
                            const SizedBox(height: 24),
                            _buildEnhancedCustomLocationForm(),
                          ],
                          const SizedBox(height: 32),
                          _buildEnhancedNextButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ).createShader(bounds),
                  child: const Text(
                    'Choose Location',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where would you like to receive care?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPreSavedLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ).createShader(bounds),
          child: const Text(
            'Choose Location',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your current location or choose from saved locations',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        
        // Current Location Button
        _buildCurrentLocationButton(),
        
        // Save Current Location Button (appears after getting location)
        if (_currentLocation != null && _currentLocationAddress.isNotEmpty)
          Column(
            children: [
              const SizedBox(height: 12),
              _buildSaveCurrentLocationButton(),
            ],
          ),
        
        const SizedBox(height: 16),
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 16),
        
        // Saved Locations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Locations',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_isLoadingLocations)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_savedLocations.isEmpty && !_isLoadingLocations)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No saved locations yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your current location or add a custom address below',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else if (_savedLocations.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedLocations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final location = _savedLocations[index];
              final isSelected = _selectedLocation == location;
              return _buildEnhancedLocationCard(location, isSelected);
            },
          ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    final isCurrentLocationSelected = _selectedLocation?.name == 'Current Location';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      transform: isCurrentLocationSelected
          ? (Matrix4.identity()
              ..scale(1.03)
              ..translate(0.0, -3.0))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: _isGettingCurrentLocation ? null : _getCurrentLocation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isCurrentLocationSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentLocationSelected
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: isCurrentLocationSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isCurrentLocationSelected
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isGettingCurrentLocation
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.my_location,
                        color: isCurrentLocationSelected
                            ? Colors.white
                            : const Color(0xFF10B981),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isGettingCurrentLocation
                          ? 'Getting Location...'
                          : 'Use Current Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isCurrentLocationSelected
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isGettingCurrentLocation
                          ? 'Please wait while we get your location'
                          : _currentLocationAddress.isNotEmpty
                              ? _currentLocationAddress
                              : 'Tap to automatically detect your location',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCurrentLocationSelected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isCurrentLocationSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF6366F1),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveCurrentLocationButton() {
    return GestureDetector(
      onTap: () => _showSaveCurrentLocationDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Save This Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveCurrentLocationDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.bookmark_add, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text(
              'Save Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give this location a name:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., Home, Office, Gym',
                prefixIcon: const Icon(Icons.edit_location, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentLocationAddress,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                
                final locationToSave = LocationData(
                  name: nameController.text.trim(),
                  address: _currentLocationAddress,
                  latitude: _currentLocation!.latitude,
                  longitude: _currentLocation!.longitude,
                  isCustom: false,
                );
                
                await _saveLocationToFirebase(locationToSave);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLocationCard(LocationData location, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      transform: isSelected
          ? (Matrix4.identity()
              ..scale(1.03)
              ..translate(0.0, -3.0))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedLocation = location;
            _showCustomLocationForm = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFF59E0B),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                      const Color(0xFF6366F1).withOpacity(0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFF6366F1).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              if (isSelected) ...[
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
              ],
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Enhanced location icon
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? RadialGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9),
                              ],
                            )
                          : RadialGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.15),
                                const Color(0xFF6366F1).withOpacity(0.05),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? Colors.black.withOpacity(0.1)
                              : const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isSelected 
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                  // Floating particle for selected
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Enhanced location details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isSelected 
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.address,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 32 : 20,
                height: isSelected ? 32 : 20,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? RadialGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.95),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF6366F1).withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(isSelected ? 16 : 10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFF6366F1).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.radio_button_unchecked,
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6366F1).withOpacity(0.5),
                  size: isSelected ? 20 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAddCustomLocationButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showCustomLocationForm = !_showCustomLocationForm;
            if (_showCustomLocationForm) {
              _selectedLocation = null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _showCustomLocationForm
                  ? [
                      const Color(0xFFEF4444).withOpacity(0.1),
                      const Color(0xFFDC2626).withOpacity(0.05),
                    ]
                  : [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF059669).withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showCustomLocationForm
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : const Color(0xFF10B981).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (_showCustomLocationForm 
                    ? const Color(0xFFEF4444) 
                    : const Color(0xFF10B981)).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showCustomLocationForm
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (_showCustomLocationForm 
                          ? const Color(0xFFEF4444) 
                          : const Color(0xFF10B981)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _showCustomLocationForm ? Icons.close : Icons.add_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _showCustomLocationForm ? 'Cancel' : 'Add Custom Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _showCustomLocationForm
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCustomLocationForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFAFBFC),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ).createShader(bounds),
              child: const Text(
                'Custom Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Enhanced Name Input
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFF6366F1).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customNameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., My Home, My Office',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.edit_location,
                      color: const Color(0xFF6366F1).withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: const Color(0xFF6366F1).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Enhanced Address Input
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFF6366F1).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customAddressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter the full address',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.location_on,
                      color: const Color(0xFF6366F1).withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: const Color(0xFF6366F1).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Enhanced Save Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _customNameController.text.isNotEmpty &&
                           _customAddressController.text.isNotEmpty && !_isLoading
                    ? _saveCustomLocation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
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

  Widget _buildEnhancedNextButton() {
    final canProceed = _selectedLocation != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        transform: canProceed
            ? (Matrix4.identity()
                ..scale(1.02)
                ..translate(0.0, -2.0))
            : Matrix4.identity(),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: canProceed
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA), // Soft Blue
                      Color(0xFF764BA2), // Purple
                      Color(0xFF6B73FF), // Indigo
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canProceed 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: canProceed
                ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF764BA2).withOpacity(0.3),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                      spreadRadius: -10,
                    ),
                    // Inner glow effect
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                      spreadRadius: -5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canProceed ? _navigateToServiceSummary : null,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Leading Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canProceed 
                            ? Colors.white.withOpacity(0.25)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        canProceed ? Icons.payment_outlined : Icons.location_off_outlined,
                        color: canProceed ? Colors.white : Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Button Text
                    Expanded(
                      child: Text(
                        canProceed ? 'Continue to Payment' : 'Select Location First',
                        textAlign: TextAlign.center,
                        style: EnhancedAppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: canProceed ? Colors.white : Colors.grey.shade500,
                          letterSpacing: 0.3,
                          shadows: canProceed
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Trailing Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canProceed 
                            ? Colors.white.withOpacity(0.25)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: canProceed ? 0 : -0.5,
                        child: Icon(
                          canProceed 
                              ? Icons.arrow_forward_rounded
                              : Icons.close_rounded,
                          color: canProceed ? Colors.white : Colors.grey.shade500,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveCustomLocation() async {
    if (_customNameController.text.isNotEmpty && 
        _customAddressController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Try to geocode the address to get real coordinates
        double latitude = 0.0;
        double longitude = 0.0;
        
        try {
          final locations = await locationFromAddress(_customAddressController.text);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
            print('✅ Geocoded address: $latitude, $longitude');
          }
        } catch (e) {
          // If geocoding fails, use current location or default
          if (_currentLocation != null) {
            latitude = _currentLocation!.latitude;
            longitude = _currentLocation!.longitude;
            print('⚠️ Geocoding failed, using current location');
          } else {
            // Use default coordinates (can be updated)
            latitude = 36.7538 + (0.001 * DateTime.now().millisecond);
            longitude = 3.0588 + (0.001 * DateTime.now().millisecond);
            print('⚠️ Geocoding failed, using default coordinates');
          }
        }
        
        final customLocation = LocationData(
          name: _customNameController.text,
          address: _customAddressController.text,
          latitude: latitude,
          longitude: longitude,
          isCustom: true,
        );

        // Save to Firebase
        await _saveLocationToFirebase(customLocation);

        setState(() {
          _selectedLocation = customLocation;
          _showCustomLocationForm = false;
          _isLoading = false;
        });

        // Clear the form
        _customNameController.clear();
        _customAddressController.clear();
      } catch (e) {
        print('❌ Error in _saveCustomLocation: $e');
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save location. Please try again.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _navigateToServiceSummary() {
    if (_selectedLocation != null) {
      // Navigate directly to Payment Page (skipping summary)
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PaymentPage(
                selectedService: widget.selectedService,
                selectedSpecialty: widget.selectedSpecialty,
                selectedLocation: _selectedLocation!,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }
}
