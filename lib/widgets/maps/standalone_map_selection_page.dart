import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class StandaloneMapSelectionPage extends StatefulWidget {
  const StandaloneMapSelectionPage({super.key});

  @override
  State<StandaloneMapSelectionPage> createState() => _StandaloneMapSelectionPageState();
}

class _StandaloneMapSelectionPageState extends State<StandaloneMapSelectionPage>
    with TickerProviderStateMixin {
  
  // Selected location data
  String _selectedAddress = '';
  double _selectedLat = 33.8869;
  double _selectedLng = 9.5375;
  String _selectedLocationName = '';
  bool _locationSelected = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _markerController;
  late Animation<double> _markerAnimation;
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;
  
  // Predefined locations for demo
  final List<Map<String, dynamic>> _predefinedLocations = [
    {
      'name': 'Tunis Medical Center',
      'address': 'Avenue Habib Bourguiba, Tunis',
      'lat': 33.8869,
      'lng': 9.5375,
    },
    {
      'name': 'Carthage Hospital',
      'address': 'Carthage, Tunisia',
      'lat': 33.8928,
      'lng': 9.5647,
    },
    {
      'name': 'La Marsa Clinic',
      'address': 'La Marsa, Tunisia',
      'lat': 33.9110,
      'lng': 9.6474,
    },
    {
      'name': 'Ariana Medical Complex',
      'address': 'Ariana, Tunisia',
      'lat': 33.8702,
      'lng': 9.5473,
    },
    {
      'name': 'Sousse General Hospital',
      'address': 'Sousse, Tunisia',
      'lat': 35.8256,
      'lng': 10.6411,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _markerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerController, curve: Curves.bounceOut),
    );
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Initialize with default location
    _selectLocation('Current Location', 'Your current location', _selectedLat, _selectedLng);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _markerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectLocation(String name, String address, double lat, double lng) {
    setState(() {
      _selectedLocationName = name;
      _selectedAddress = address;
      _selectedLat = lat;
      _selectedLng = lng;
      _locationSelected = true;
    });
    
    _markerController.reset();
    _markerController.forward();
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
      return;
    }
    
    // Filter predefined locations based on search
    final suggestions = _predefinedLocations
        .where((location) => 
            location['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            location['address'].toString().toLowerCase().contains(query.toLowerCase()))
        .map((location) => location['name'].toString())
        .toList();
    
    // Add some mock search results
    final mockResults = [
      'Medical Center $query',
      'Hospital $query',
      'Clinic $query',
    ];
    
    setState(() {
      _searchSuggestions = [...suggestions, ...mockResults].take(5).toList();
      _showSuggestions = _searchSuggestions.isNotEmpty;
    });
  }

  void _confirmLocation() {
    if (_locationSelected) {
      Navigator.of(context).pop({
        'name': _selectedLocationName,
        'address': _selectedAddress,
        'latitude': _selectedLat,
        'longitude': _selectedLng,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100, // Added for much lower positioning from top
        actions: [
          IconButton(
            onPressed: () {
              // Show location help dialog
              _showLocationHelp();
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map background
          _buildMapView(),
          
          // Search overlay
          _buildSearchOverlay(),
          
          // Location confirmation panel
          if (_locationSelected) _buildLocationConfirmationPanel(),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.green[50]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Map background pattern
          CustomPaint(
            painter: MapBackgroundPainter(),
            size: Size.infinite,
          ),
          
          // Center crosshair (selection indicator)
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 40 + (_pulseAnimation.value * 20),
                  height: 40 + (_pulseAnimation.value * 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red.withOpacity(0.8 - (_pulseAnimation.value * 0.4)),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.red,
                    size: 20,
                  ),
                );
              },
            ),
          ),
          
          // Selected location marker
          if (_locationSelected)
            Center(
              child: AnimatedBuilder(
                animation: _markerAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _markerAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Predefined location markers
          ..._predefinedLocations.map(_buildPredefinedLocationMarker),
          
          // Map controls
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _centerOnCurrentLocation(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _refreshMap(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredefinedLocationMarker(Map<String, dynamic> location) {
    final index = _predefinedLocations.indexOf(location);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Position markers around the map
    final random = Random(index);
    final left = 50 + random.nextDouble() * (screenWidth - 100);
    final top = 100 + random.nextDouble() * (screenHeight - 300);
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _selectLocation(
          location['name'],
          location['address'],
          location['lat'],
          location['lng'],
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_hospital,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                location['name'].split(' ').take(2).join(' '),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      right: 80,
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: const InputDecoration(
                hintText: 'Search for a location...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Search suggestions
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: _searchSuggestions.map((suggestion) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 18),
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      _searchController.text = suggestion;
                      _handleLocationSelection(suggestion);
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationConfirmationPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Location info
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLocationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Confirm Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLocationSelection(String suggestion) {
    // Find matching predefined location or create new one
    final predefined = _predefinedLocations.firstWhere(
      (location) => location['name'] == suggestion,
      orElse: () => {
        'name': suggestion,
        'address': 'Custom location: $suggestion',
        'lat': _selectedLat + (Random().nextDouble() - 0.5) * 0.01,
        'lng': _selectedLng + (Random().nextDouble() - 0.5) * 0.01,
      },
    );
    
    _selectLocation(
      predefined['name'],
      predefined['address'],
      predefined['lat'],
      predefined['lng'],
    );
  }

  void _centerOnCurrentLocation() {
    _selectLocation('Current Location', 'Your current location', _selectedLat, _selectedLng);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on your current location'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshMap() {
    setState(() {
      _locationSelected = false;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _selectLocation('Current Location', 'Your current location', _selectedLat, _selectedLng);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLocationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Select Location'),
        content: const Text(
          '1. Use the search bar to find specific locations\n'
          '2. Tap on the blue markers for predefined locations\n'
          '3. The red crosshair shows your selection area\n'
          '4. Confirm your selection using the button below\n\n'
          'This demo works without Google Maps API!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    
    for (int i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Draw some mock streets
    final streetPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Main streets
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      streetPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      streetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
