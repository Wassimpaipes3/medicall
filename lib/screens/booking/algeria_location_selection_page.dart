import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/algeria_location_service.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../widgets/booking/ServiceSummaryPage.dart';
import '../../widgets/booking/LocationSelectionPage.dart' show LocationData;
import '../../core/theme.dart';

class AlgeriaLocationSelectionPage extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;

  const AlgeriaLocationSelectionPage({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
  });

  @override
  State<AlgeriaLocationSelectionPage> createState() => _AlgeriaLocationSelectionPageState();
}

class _AlgeriaLocationSelectionPageState extends State<AlgeriaLocationSelectionPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Location data
  Map<String, dynamic>? _selectedLocation;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _popularCities = [];
  Set<Marker> _markers = {};
  
  // Map state
  LatLng _currentMapCenter = const LatLng(36.7538, 3.0588); // Algiers center
  bool _showMap = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPopularCities();
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

  void _loadPopularCities() {
    _popularCities = AlgeriaLocationService.getAllCities()
        .where((city) => city['population'] > 200000)
        .toList()
      ..sort((a, b) => b['population'].compareTo(a['population']));
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _searchResults = AlgeriaLocationService.searchCities(query);
    });
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _selectedLocation = location;
      _currentMapCenter = LatLng(location['lat'], location['lng']);
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(location['lat'], location['lng']),
          infoWindow: InfoWindow(
            title: location['name'],
            snippet: location['province'],
          ),
        ),
      };
    });
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentMapCenter, 12),
      );
    }
  }

  void _toggleMapView() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  void _onMapTap(LatLng position) {
    // Find nearest city to tapped location
    List<Map<String, dynamic>> nearest = AlgeriaLocationService.findNearestCities(
      position.latitude,
      position.longitude,
      limit: 1,
    );
    
    if (nearest.isNotEmpty) {
      _selectLocation(nearest.first);
    }
  }

  void _proceedToSummary() {
    if (_selectedLocation != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ServiceSummaryPage(
            selectedService: widget.selectedService,
            selectedSpecialty: widget.selectedSpecialty,
            selectedLocation: LocationData(
              name: _selectedLocation!['name'],
              address: '${_selectedLocation!['name']}, ${_selectedLocation!['province']}, Algeria',
              latitude: _selectedLocation!['lat'],
              longitude: _selectedLocation!['lng'],
            ),
            preSelectedDoctor: null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _showMap ? _buildMapView() : _buildLocationSelection(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Location',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your location in Algeria',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleMapView,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showMap ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showMap ? Icons.list : Icons.map,
                size: 20,
                color: _showMap ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelection() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildPopularCities(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search cities or provinces in Algeria...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildPopularCities() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Cities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...(_popularCities.take(10).map((location) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLocationCard(location),
              ))),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    bool isSelected = _selectedLocation != null && 
        _selectedLocation!['name'] == location['name'];

    return GestureDetector(
      onTap: () => _selectLocation(location),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                location['isCapital'] ? Icons.location_city : Icons.place,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${location['province']} Province',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (location['isCapital']) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Capital',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: _currentMapCenter,
        zoom: 6,
      ),
      markers: _markers,
      onTap: _onMapTap,
      mapType: MapType.normal,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_selectedLocation != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedLocation!['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _selectedLocation!['province'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          ElevatedButton(
            onPressed: _selectedLocation != null ? _proceedToSummary : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
