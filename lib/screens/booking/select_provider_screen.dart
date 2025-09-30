import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/provider_request_service.dart';

class SelectProviderScreen extends StatefulWidget {
  final String service; // normalized service name
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
  GoogleMapController? _mapController;
  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _providers = [];
  String? _creatingRequestFor;
  String _queryStrategy = 'initial';
  StreamSubscription<QuerySnapshot>? _providersSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _setupRealTimeProviderUpdates();
  }

  @override
  void dispose() {
    _providersSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Setup real-time provider updates using Firestore streams
  void _setupRealTimeProviderUpdates() {
    print('🔄 [SelectProvider] Setting up real-time provider updates');
    _startProviderStream();
    
    // Refresh stream every 30 seconds to catch any missed updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 [SelectProvider] Refreshing provider stream');
      _restartProviderStream();
    });
  }

  /// Start listening to provider changes in real-time
  void _startProviderStream() {
    setState(() => _loading = true);
    
    final col = FirebaseFirestore.instance.collection('professionals');
    final requestedService = widget.service.toLowerCase().trim();
    final requestedSpecialty = widget.specialty?.toLowerCase().trim();

    // Build primary query: disponible + service match
    Query query = col.where('disponible', isEqualTo: true);
    
    // Try to add service filter
    try {
      query = query.where('service', isEqualTo: requestedService);
      _queryStrategy = 'realtime_service';
      
      // Add specialty filter if provided
      if (requestedSpecialty != null && requestedSpecialty.isNotEmpty) {
        query = query.where('specialite', isEqualTo: requestedSpecialty);
        _queryStrategy = 'realtime_service+specialty';
      }
    } catch (e) {
      print('⚠️ [SelectProvider] Service filter failed, using disponible only: $e');
      _queryStrategy = 'realtime_disponible_only';
    }

    // Listen to real-time updates
    _providersSubscription?.cancel();
    _providersSubscription = query.limit(25).snapshots().listen(
      (snapshot) {
        print('📱 [SelectProvider] Real-time update: ${snapshot.docs.length} providers available');
        
        // If no results with service filter, try fallback strategies
        if (snapshot.docs.isEmpty) {
          _tryFallbackStrategies();
        } else {
          _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
        }
      },
      onError: (error) {
        print('❌ [SelectProvider] Stream error: $error');
        _handleStreamError();
      },
    );
  }

  /// Restart the provider stream (for periodic refresh)
  void _restartProviderStream() {
    _providersSubscription?.cancel();
    _startProviderStream();
  }

  /// Update provider list from stream data
  void _updateProviderList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (mounted) {
      setState(() {
        _providers = docs;
        _loading = false;
      });
      
      // Log provider status for debugging
      if (docs.isNotEmpty) {
        final sample = docs.first.data();
        print('🧪 [SelectProvider] Sample provider: service=${sample['service']} disponible=${sample['disponible']} login=${sample['login']}');
      }
      
      // Update map markers
      _updateMapMarkers();
    }
  }

  /// Try fallback strategies when main query returns empty
  void _tryFallbackStrategies() async {
    print('🔄 [SelectProvider] Trying fallback: disponible only');
    
    final col = FirebaseFirestore.instance.collection('professionals');
    try {
      // Fallback: Just show available providers
      final snapshot = await col.where('disponible', isEqualTo: true).limit(25).get();
      final results = snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
      
      print('🔍 [SelectProvider] Fallback found ${results.length} available providers');
      _updateProviderList(results);
      _queryStrategy = 'fallback_disponible_only';
    } catch (e) {
      print('❌ [SelectProvider] Fallback failed: $e');
      _handleStreamError();
    }
  }

  /// Handle stream errors
  void _handleStreamError() {
    if (mounted) {
      setState(() {
        _loading = false;
        _providers = [];
        _queryStrategy = 'error';
      });
    }
  }

  /// Update map markers when providers change
  void _updateMapMarkers() {
    // Update map camera to show all providers
    if (_providers.isNotEmpty && _mapController != null) {
      final points = <LatLng>[];
      points.add(LatLng(widget.patientLocation.latitude, widget.patientLocation.longitude));
      
      for (final p in _providers) {
        final geo = p.data()['currentlocation'];
        if (geo is GeoPoint) {
          points.add(LatLng(geo.latitude, geo.longitude));
        }
      }
      
      if (points.length > 1) {
        _fitMapToPoints(points);
      }
    }
  }

  /// Fit map to show all points
  Future<void> _fitMapToPoints(List<LatLng> points) async {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    
    for (final pt in points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng), 
      northeast: LatLng(maxLat, maxLng)
    );
    
    await Future.delayed(const Duration(milliseconds: 200));
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  double _distanceKm(GeoPoint? providerLoc) {
    if (providerLoc == null) return 0;
    final p = widget.patientLocation;
    final d = Geolocator.distanceBetween(
      p.latitude, p.longitude, providerLoc.latitude, providerLoc.longitude,
    );
    return d / 1000.0;
  }

  Future<void> _selectProvider(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    // FIX: Use doc.id (which should match auth.uid) instead of id_user field
    final providerId = doc.id;  // This should match the provider's Firebase Auth UID
    
    // Debug: Log provider data to understand the structure
    print('🔍 [SelectProvider] Selected provider data:');
    print('   📄 doc.id: ${doc.id}');
    print('   👤 id_user: ${data['id_user']}');
    print('   🎯 Using providerId: $providerId (fixed to use doc.id)');
    print('   📋 Full data: ${data.keys.toList()}');
    
    setState(() => _creatingRequestFor = providerId);
    try {
      final requestId = await ProviderRequestService.createRequest(
        providerId: providerId,
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

      // Navigate to a lightweight waiting screen (reuse this with a banner)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaitingForAcceptanceScreen(requestId: requestId),
        ),
      );
    } catch (e) {
      debugPrint('Error creating request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingRequestFor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientPos = LatLng(widget.patientLocation.latitude, widget.patientLocation.longitude);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Provider'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Strategy: $_queryStrategy  •  Found: ${_providers.length}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 260,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: patientPos, zoom: 13),
              myLocationEnabled: false,
              markers: {
                Marker(markerId: const MarkerId('patient'), position: patientPos, infoWindow: const InfoWindow(title: 'You')),
                ..._providers.map((p) {
                  final geo = p.data()['currentlocation'];
                  if (geo is GeoPoint) {
                    return Marker(
                      markerId: MarkerId('pro_${p.id}'),
                      position: LatLng(geo.latitude, geo.longitude),
                      infoWindow: InfoWindow(title: p.data()['login'] ?? 'Provider'),
                    );
                  }
                  return const Marker(markerId: MarkerId('x'), position: LatLng(0,0));
                }).where((m) => m.markerId.value != 'x')
              },
              onMapCreated: (c) => _mapController = c,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _providers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No matching providers found'),
                            const SizedBox(height: 8),
                            Text('Tried: $_queryStrategy', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _restartProviderStream,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _providers.length,
                        itemBuilder: (ctx, i) {
                          final data = _providers[i].data();
                          final providerLoc = data['currentlocation'];
                          final distance = _distanceKm(providerLoc is GeoPoint ? providerLoc : null);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(child: Text((data['login'] ?? 'P')[0].toUpperCase())),
                              title: Text(data['login'] ?? 'Provider'),
                              subtitle: Text('Rating: ${data['rating'] ?? 'N/A'} • ${distance.toStringAsFixed(1)} km'),
                              trailing: _creatingRequestFor == (data['id_user'] ?? _providers[i].id)
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : ElevatedButton(
                                      onPressed: () => _selectProvider(_providers[i]),
                                      child: const Text('Request'),
                                    ),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}

/// Simple waiting screen that listens for request acceptance
class WaitingForAcceptanceScreen extends StatelessWidget {
  final String requestId;
  const WaitingForAcceptanceScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waiting for Provider')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('provider_requests').doc(requestId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text('Request not found'));

            if (data['status'] == 'accepted' && data['appointmentId'] != null) {
              // Navigate to tracking screen lazily
              WidgetsBinding.instance.addPostFrameCallback((_) {
                print('🚀 [Patient] Navigating to tracking with appointmentId: ${data['appointmentId']}');
                Navigator.of(context).pushReplacementNamed('/tracking', arguments: {
                  'appointmentId': data['appointmentId'],
                });
              });
            }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Waiting for provider to accept...'),
                const SizedBox(height: 8),
                Text('Status: ${data['status']}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await ProviderRequestService.cancelRequest(requestId);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
