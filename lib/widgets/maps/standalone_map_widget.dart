import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Standalone models that don't depend on external services
class SimpleLocation {
  final double latitude;
  final double longitude;
  final String address;

  SimpleLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class SimpleProvider {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String address;
  final double latitude;
  final double longitude;
  final double price;
  final bool isAvailable;
  final String estimatedTime;

  SimpleProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.isAvailable,
    required this.estimatedTime,
  });
}

class StandaloneMapWidget extends StatefulWidget {
  final Function(SimpleProvider)? onProviderSelected;
  final Function(SimpleLocation)? onLocationChanged;

  const StandaloneMapWidget({
    super.key,
    this.onProviderSelected,
    this.onLocationChanged,
  });

  @override
  State<StandaloneMapWidget> createState() => _StandaloneMapWidgetState();
}

class _StandaloneMapWidgetState extends State<StandaloneMapWidget> 
    with TickerProviderStateMixin {
  
  // Current state
  SimpleLocation _currentLocation = SimpleLocation(
    latitude: 33.8869,
    longitude: 9.5375,
    address: "Current Location",
  );
  
  List<SimpleProvider> _providers = [];
  SimpleProvider? _selectedProvider;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _providerController;
  late Animation<double> _providerAnimation;
  
  // Timer for simulated updates
  Timer? _updateTimer;

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
    
    _providerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _providerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _providerController, curve: Curves.elasticOut),
    );
    
    // Start animations
    _pulseController.repeat(reverse: true);
    
    // Initialize mock data
    _initializeMockData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _providerController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeMockData() {
    // Generate mock providers near current location
    final random = Random();
    _providers = List.generate(5, (index) {
      final latOffset = (random.nextDouble() - 0.5) * 0.02; // ~1km range
      final lngOffset = (random.nextDouble() - 0.5) * 0.02;
      
      return SimpleProvider(
        id: 'provider_$index',
        name: [
          'Dr. Ahmed Ben Ali',
          'Dr. Sarah Johnson',
          'Dr. Mohamed Triki',
          'Dr. Emily Chen',
          'Dr. Karim Nasri'
        ][index],
        specialty: [
          'General Practice',
          'Cardiology',
          'Pediatrics',
          'Dermatology',
          'Orthopedics'
        ][index],
        rating: 3.5 + random.nextDouble() * 1.5,
        address: 'Medical Center ${index + 1}',
        latitude: _currentLocation.latitude + latOffset,
        longitude: _currentLocation.longitude + lngOffset,
        price: 50 + random.nextDouble() * 100,
        isAvailable: random.nextBool(),
        estimatedTime: '${5 + random.nextInt(25)} min',
      );
    });
    
    setState(() {
      _isLoading = false;
    });
    
    _providerController.forward();
    
    // Start periodic updates
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        final random = Random();
        // Simulate small location changes
        final newLocation = SimpleLocation(
          latitude: _currentLocation.latitude + (random.nextDouble() - 0.5) * 0.001,
          longitude: _currentLocation.longitude + (random.nextDouble() - 0.5) * 0.001,
          address: "Updated Location",
        );
        
        setState(() {
          _currentLocation = newLocation;
        });
        
        widget.onLocationChanged?.call(newLocation);
      }
    });
  }

  void _selectProvider(SimpleProvider provider) {
    setState(() {
      _selectedProvider = provider;
    });
    widget.onProviderSelected?.call(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map background
            _buildMapBackground(),
            
            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),
            
            // Current location marker
            _buildCurrentLocationMarker(),
            
            // Provider markers
            ..._providers.map(_buildProviderMarker),
            
            // Selected provider info
            if (_selectedProvider != null) _buildProviderInfo(),
            
            // Controls
            _buildMapControls(),
            
            // Emergency button
            _buildEmergencyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
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
      child: CustomPaint(
        painter: MapBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading nearby providers...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.5 - 15,
      top: MediaQuery.of(context).size.height * 0.5 - 15,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 30 + (_pulseAnimation.value * 20),
            height: 30 + (_pulseAnimation.value * 20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3 - (_pulseAnimation.value * 0.2)),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderMarker(SimpleProvider provider) {
    final index = _providers.indexOf(provider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Position providers around the center
    final angle = (index * 2 * pi) / _providers.length;
    final radius = 80.0;
    
    final left = screenWidth * 0.5 + (cos(angle) * radius) - 20;
    final top = screenHeight * 0.5 + (sin(angle) * radius) - 20;
    
    final isSelected = _selectedProvider?.id == provider.id;
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _selectProvider(provider),
        child: AnimatedBuilder(
          animation: _providerAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _providerAnimation.value,
              child: Container(
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                decoration: BoxDecoration(
                  color: provider.isAvailable ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: isSelected ? 24 : 20,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedProvider!.isAvailable ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProvider!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedProvider!.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${_selectedProvider!.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, color: Colors.grey, size: 16),
                          Text(
                            ' ${_selectedProvider!.estimatedTime}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_selectedProvider!.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedProvider!.isAvailable ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedProvider!.isAvailable ? 'Available' : 'Busy',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bookAppointment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _callProvider(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.call),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
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
            onPressed: () => _refreshProviders(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.refresh, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _handleEmergency(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Emergency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnCurrentLocation() {
    // Animate to center location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Centered on your location')),
    );
  }

  void _refreshProviders() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate refresh delay
    Future.delayed(const Duration(seconds: 1), () {
      _initializeMockData();
    });
  }

  void _bookAppointment() {
    if (_selectedProvider != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Book Appointment'),
          content: Text(
            'Book an appointment with ${_selectedProvider!.name}?\n\n'
            'Estimated cost: \$${_selectedProvider!.price.toInt()}\n'
            'Estimated time: ${_selectedProvider!.estimatedTime}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment booked with ${_selectedProvider!.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  void _callProvider() {
    if (_selectedProvider != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${_selectedProvider!.name}...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency'),
          ],
        ),
        content: const Text(
          'This will connect you to the nearest emergency services.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting to emergency services...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Call Emergency', style: TextStyle(color: Colors.white)),
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
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Horizontal streets
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

    // Vertical streets
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      streetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
