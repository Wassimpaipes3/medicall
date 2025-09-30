import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/provider_request_service.dart';
import '../../debug/provider_query_test.dart';

class ProviderData {
  final String id;
  final String name;
  final String service;
  final String specialty;
  final double rating;
  final double distance;
  final bool isAvailable;
  final String imageUrl;

  ProviderData({
    required this.id,
    required this.name,
    required this.service,
    required this.specialty,
    required this.rating,
    required this.distance,
    required this.isAvailable,
    this.imageUrl = '',
  });

  factory ProviderData.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc, GeoPoint patientLocation) {
    final data = doc.data();
    
    // Calculate distance
    double distance = 0.0;
    final providerLocation = data['currentlocation'] as GeoPoint?;
    if (providerLocation != null) {
      distance = Geolocator.distanceBetween(
        patientLocation.latitude,
        patientLocation.longitude,
        providerLocation.latitude,
        providerLocation.longitude,
      ) / 1000.0; // Convert to kilometers
    }

    return ProviderData(
      id: doc.id,
      name: data['nom'] ?? data['login'] ?? 'Unknown Provider',
      service: data['service'] ?? 'Unknown Service',
      specialty: data['specialite'] ?? 'General',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.0,
      distance: distance,
      isAvailable: data['disponible'] ?? false,
      imageUrl: data['profileImageUrl'] ?? '',
    );
  }
}

class SelectProviderScreen extends StatefulWidget {
  final String service;
  final String? specialty;
  final double prix;
  final String paymentMethod;
  final GeoPoint patientLocation;

  const SelectProviderScreen({
    super.key,
    required this.service,
    this.specialty,
    required this.prix,
    required this.paymentMethod,
    required this.patientLocation,
  });

  @override
  State<SelectProviderScreen> createState() => _SelectProviderScreenState();
}

class _SelectProviderScreenState extends State<SelectProviderScreen> {
  bool _loading = true;
  List<ProviderData> _providers = [];
  StreamSubscription<QuerySnapshot>? _providersSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Run quick provider test
    _testProviderAccess();
    _setupRealTimeProviderUpdates();
  }
  
  void _testProviderAccess() async {
    print('🔬 [Quick Test] Checking provider access...');
    try {
      final col = FirebaseFirestore.instance.collection('professionals');
      
      // Check collection access
      final testQuery = await col.limit(1).get();
      print('   Collection accessible: ${testQuery.docs.isNotEmpty}');
      
      if (testQuery.docs.isNotEmpty) {
        final sample = testQuery.docs.first.data();
        print('   Sample provider disponible: ${sample['disponible']}');
        print('   Sample provider service: ${sample['service']}');
      }
      
      // Check available providers
      final availableQuery = await col.where('disponible', isEqualTo: true).limit(3).get();
      print('   Available providers: ${availableQuery.docs.length}');
      
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }

  @override
  void dispose() {
    _providersSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupRealTimeProviderUpdates() {
    _startProviderStream();
    
    // Refresh stream every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _restartProviderStream();
    });
  }

  void _startProviderStream() {
    setState(() => _loading = true);
    
    print('🔍 [SelectProvider] Starting provider stream...');
    print('   Service: ${widget.service}');
    print('   Specialty: ${widget.specialty}');
    
    final col = FirebaseFirestore.instance.collection('professionals');
    final requestedService = widget.service.toLowerCase().trim();
    final requestedSpecialty = widget.specialty?.toLowerCase().trim();

    // Start with base query - available providers
    Query query = col.where('disponible', isEqualTo: true);
    
    // Try flexible service matching
    bool serviceFilterAdded = false;
    try {
      // Try exact match first
      query = query.where('service', isEqualTo: requestedService);
      serviceFilterAdded = true;
      print('   ✅ Added exact service filter: $requestedService');
    } catch (e) {
      print('   ❌ Exact service filter failed: $e');
      // Will try fallback strategies
    }
    
    // Add specialty filter if service filter was successful
    if (serviceFilterAdded && requestedSpecialty != null && requestedSpecialty.isNotEmpty) {
      try {
        query = query.where('specialite', isEqualTo: requestedSpecialty);
        print('   ✅ Added specialty filter: $requestedSpecialty');
      } catch (e) {
        print('   ❌ Specialty filter failed: $e');
      }
    }

    _providersSubscription?.cancel();
    _providersSubscription = query.limit(25).snapshots().listen(
      (snapshot) {
        print('📊 [SelectProvider] Query result: ${snapshot.docs.length} providers');
        
        if (snapshot.docs.isEmpty) {
          print('   🔄 No providers found with filters, trying fallback...');
          _tryFallbackStrategies();
        } else {
          print('   ✅ Found providers, updating UI...');
          _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
        _tryFallbackStrategies();  // Try fallback on stream error
      },
    );
  }

  void _restartProviderStream() {
    _providersSubscription?.cancel();
    _startProviderStream();
  }

  void _updateProviderList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (mounted) {
      print('📋 [SelectProvider] Found ${docs.length} providers');
      
      if (docs.isNotEmpty) {
        // Log first provider as sample
        final sample = docs.first.data();
        print('   Sample: ${sample['nom'] ?? sample['login']} - disponible:${sample['disponible']}');
      }
      
      final providers = docs.map((doc) => ProviderData.fromFirestore(doc, widget.patientLocation)).toList();
      
      // Sort by distance
      providers.sort((a, b) => a.distance.compareTo(b.distance));
      
      setState(() {
        _providers = providers;
        _loading = false;
      });
      
      print('✅ [SelectProvider] Updated UI with ${providers.length} providers');
    }
  }

  void _tryFallbackStrategies() async {
    print('🔄 [SelectProvider] Trying fallback strategies...');
    final col = FirebaseFirestore.instance.collection('professionals');
    
    try {
      // Strategy 1: Check if any providers exist at all
      final totalSnapshot = await col.limit(3).get();
      print('   Strategy 1 - Total providers: ${totalSnapshot.docs.length}');
      
      if (totalSnapshot.docs.isEmpty) {
        print('   ❌ No providers exist in collection');
        _handleStreamError();
        return;
      }
      
      // Strategy 2: Get available providers (no service filter)
      final availableSnapshot = await col.where('disponible', isEqualTo: true).limit(25).get();
      print('   Strategy 2 - Available providers: ${availableSnapshot.docs.length}');
      
      if (availableSnapshot.docs.isNotEmpty) {
        final results = availableSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
        _updateProviderList(results);
        return;
      }
      
      // Strategy 3: Try different boolean representations
      print('   Strategy 3 - Trying boolean variations...');
      final boolVariations = [true, 'true', 1, '1'];
      
      for (final variation in boolVariations) {
        try {
          final varSnapshot = await col.where('disponible', isEqualTo: variation).limit(5).get();
          if (varSnapshot.docs.isNotEmpty) {
            print('   ✅ Found providers with disponible=$variation');
            final results = varSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
            _updateProviderList(results);
            return;
          }
        } catch (e) {
          // Continue to next variation
        }
      }
      
      // Strategy 4: Emergency - show ALL providers regardless of availability
      print('   Strategy 4 - EMERGENCY: Showing all providers...');
      final emergencySnapshot = await col.limit(10).get();
      if (emergencySnapshot.docs.isNotEmpty) {
        print('   🚨 EMERGENCY MODE: Showing ${emergencySnapshot.docs.length} providers regardless of availability');
        final results = emergencySnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
        _updateProviderList(results);
        return;
      }
      
      print('   ❌ All fallback strategies failed');
      _handleStreamError();
      
    } catch (e) {
      print('❌ Fallback exception: $e');
      _handleStreamError();
    }
  }

  void _handleStreamError() {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _selectProvider(ProviderData provider) async {
    try {
      final requestId = await ProviderRequestService.createRequest(
        providerId: provider.id,
        service: widget.service,
        specialty: widget.specialty,
        prix: widget.prix,
        paymentMethod: widget.paymentMethod,
        patientLocation: widget.patientLocation,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent! Waiting for provider acceptance.')),
      );
      
      Navigator.pushNamed(
        context,
        '/waiting-for-provider',
        arguments: {
          'requestId': requestId,
          'providerId': provider.id,
          'providerName': provider.name,
          'service': widget.service,
          'location': widget.patientLocation,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  void _showProviderDetails(ProviderData provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: provider.imageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(provider.imageUrl)
                              : null,
                          child: provider.imageUrl.isEmpty
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${provider.service} • ${provider.specialty}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.star, 'Rating', '${provider.rating.toStringAsFixed(1)} ⭐'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.location_on, 'Distance', '${provider.distance.toStringAsFixed(1)} km away'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, 'Availability', provider.isAvailable ? 'Available now' : 'Busy'),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectProvider(provider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        title: Text(
          'Select ${widget.service}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _restartProviderStream,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Finding available providers...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : _providers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Lottie.asset(
                          'assets/animations/empty.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No providers available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your search or check back later',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _restartProviderStream,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => _showProviderDetails(provider),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: provider.imageUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(provider.imageUrl)
                                          : null,
                                      child: provider.imageUrl.isEmpty
                                          ? const Icon(Icons.person, size: 24)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${provider.service} • ${provider.specialty}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: provider.isAvailable
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: provider.isAvailable
                                              ? Colors.green.shade200
                                              : Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        provider.isAvailable ? 'Available' : 'Busy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: provider.isAvailable
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${provider.distance.toStringAsFixed(1)} km away',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => _selectProvider(provider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1565C0),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Book',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
