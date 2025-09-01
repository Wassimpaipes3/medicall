import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../booking/ServiceSelectionPage.dart';
import '../booking/AppointmentConfirmationScreen.dart';

class MapSelectionPage extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;

  const MapSelectionPage({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
  });

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  // Map state
  LatLng _center = const LatLng(40.7128, -74.0060); // Default to NYC
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // UI state
  bool _isLoading = false;
  bool _isSearching = false;
  List<MapSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
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
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      // Add current location marker
      _addMarker(_center, 'Current Location', 'Your current position');
      
    } catch (e) {
      setState(() => _isLoading = false);
      // Keep default location
    }
  }

  void _addMarker(LatLng position, String title, String snippet) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(title),
          position: position,
          infoWindow: InfoWindow(title: title, snippet: snippet),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Location> locations = await locationFromAddress(query);
      
      setState(() {
        _searchResults = locations.map((location) => MapSearchResult(
          name: query,
          address: query,
          latitude: location.latitude,
          longitude: location.longitude,
        )).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      // Handle error silently
    }
  }

  void _selectLocationFromSearch(MapSearchResult result) {
    setState(() {
      _selectedLocation = LatLng(result.latitude, result.longitude);
      _searchResults = [];
      _searchController.clear();
    });
    
    // Move map to selected location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
    );
    
    // Add marker for selected location
    _addMarker(_selectedLocation!, result.name, result.address);
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    
    // Clear previous markers and add new one
    setState(() {
      _markers.clear();
      _addMarker(position, 'Selected Location', 'Tap to confirm this location');
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      // Navigate to appointment confirmation
      final locationData = {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'name': 'Map Selected Location',
        'address': 'Selected from map',
      };
      
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              AppointmentConfirmationScreen(
                selectedService: widget.selectedService,
                selectedSpecialty: widget.selectedSpecialty,
                selectedLocation: locationData,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100, // Added for much lower positioning from top
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF3B82F6)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Search bar
              _buildSearchBar(),
              
              // Search results
              if (_searchResults.isNotEmpty) _buildSearchResults(),
              
              // Map
              Expanded(
                child: _buildMap(),
              ),
              
              // Confirm button
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for a location...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Color(0xFF64748B)),
              ),
              onChanged: _searchLocation,
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Color(0xFF3B82F6)),
            title: Text(result.name),
            subtitle: Text(result.address),
            onTap: () => _selectLocationFromSearch(result),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 15,
              ),
              markers: _markers,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            
            // Current location button
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: "current_location",
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
              ),
            ),
            
            // Location selection indicator
            if (_selectedLocation != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location selected! Tap confirm below.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildConfirmButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _selectedLocation != null ? _confirmLocation : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedLocation != null 
                ? const Color(0xFF3B82F6)
                : Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: _selectedLocation != null ? 4 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedLocation != null 
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
              if (_selectedLocation != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MapSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  MapSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
