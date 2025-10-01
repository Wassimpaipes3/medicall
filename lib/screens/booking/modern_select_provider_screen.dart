import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/provider_request_service.dart';
import '../../routes/app_routes.dart';
import 'live_tracking_screen.dart';

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
  String? _creatingRequestFor;
  StreamSubscription<QuerySnapshot>? _providersSubscription;
  Timer? _refreshTimer;
  // UI Colors
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _successColor = Color(0xFF43A047);
  static const Color _errorColor = Color(0xFFE53935);

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

  void _setupRealTimeProviderUpdates() {
    _startProviderStream();
    
    // Refresh stream every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _restartProviderStream();
    });
  }

  void _startProviderStream() {
    setState(() => _loading = true);
    
    final col = FirebaseFirestore.instance.collection('professionals');
    final requestedService = (widget.service).toLowerCase().trim();
    final requestedSpecialty = widget.specialty?.toLowerCase().trim();
    print('[ProviderQuery] service: "$requestedService", specialty: "$requestedSpecialty"');
    Query query = col.where('disponible', whereIn: [true, 'true', 1, '1']);
    
    // Try to add service filter
    try {
      query = query.where('service', isEqualTo: requestedService);
      print('[ProviderQuery] Added service filter: "$requestedService"');
      
      if (requestedSpecialty != null && requestedSpecialty.isNotEmpty) {
        query = query.where('specialite', isEqualTo: requestedSpecialty);
        print('[ProviderQuery] Added specialty filter: "$requestedSpecialty"');
      }
    } catch (e) {
      print('[ProviderQuery] Service filter failed, using disponible only: $e');
    }

    _providersSubscription?.cancel();
    _providersSubscription = query.limit(25).snapshots().listen(
      (snapshot) {
        print('[ProviderQuery] Query result:  [1m${snapshot.docs.length} [0m providers');
        if (snapshot.docs.isEmpty) {
          _tryFallbackStrategies();
        } else {
          _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
        }
      },
      onError: (error) {
        print('[ProviderQuery] Stream error: $error');
        _handleStreamError();
      },
    );
  }

  void _restartProviderStream() {
    _providersSubscription?.cancel();
    _startProviderStream();
  }

  void _updateProviderList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (mounted) {
      final providers = docs.map((doc) => ProviderData.fromFirestore(doc, widget.patientLocation)).toList();
      
      // Sort by distance
      providers.sort((a, b) => a.distance.compareTo(b.distance));
      
      setState(() {
        _providers = providers;
        _loading = false;
      });
    }
  }

  void _tryFallbackStrategies() async {
    final col = FirebaseFirestore.instance.collection('professionals');
    try {
      print('[ProviderQuery] Fallback: disponible only');
      final availableSnapshot = await col.where('disponible', whereIn: [true, 'true', 1, '1']).limit(25).get();
      print('[ProviderQuery] Fallback disponible result: ${availableSnapshot.docs.length}');
      if (availableSnapshot.docs.isNotEmpty) {
        final results = availableSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
        _updateProviderList(results);
        return;
      }
      // Emergency fallback: show all providers
      print('[ProviderQuery] EMERGENCY: Showing all providers (no filters)');
      final allSnapshot = await col.limit(25).get();
      print('[ProviderQuery] Emergency all providers result: ${allSnapshot.docs.length}');
      if (allSnapshot.docs.isNotEmpty) {
        final results = allSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
        _updateProviderList(results);
        return;
      }
      print('[ProviderQuery] All fallback strategies failed');
      _handleStreamError();
    } catch (e) {
      print('[ProviderQuery] Fallback exception: $e');
      _handleStreamError();
    }
  }

  void _handleStreamError() {
    if (mounted) {
      setState(() {
        _loading = false;
        _providers = [];
      });
    }
  }

  Future<void> _selectProvider(ProviderData provider) async {
    setState(() => _creatingRequestFor = provider.id);
    
    try {
      final requestId = await ProviderRequestService.createRequest(
        providerId: provider.providerAuthId,
        service: widget.service,
        specialty: widget.specialty,
        prix: widget.prix,
        paymentMethod: widget.paymentMethod,
        patientLocation: widget.patientLocation,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! Waiting for provider acceptance.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaitingForAcceptanceScreen(requestId: requestId),
        ),
      );
    } catch (e) {
      debugPrint('Error creating request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingRequestFor = null);
    }
  }

  void _showProviderDetails(ProviderData provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProviderDetailsModal(provider: provider),
    );
  }

  void _cancelBooking() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1976D2),
        title: const Text(
          'Select Healthcare Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service: ${widget.service}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
                if (widget.specialty != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Specialty: ${widget.specialty}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Showing providers near you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Providers List
          Expanded(
            child: _loading
                ? _buildLoadingView()
                : _providers.isEmpty
                    ? _buildEmptyView()
                    : _buildProvidersList(),
          ),
          
          // Cancel Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancelBooking,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'assets/animations/loading.json',
              repeat: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Finding available providers...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/empty.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No providers available nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please try again later or expand your search area',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _restartProviderStream,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return InkWell(
          onTap: () => _showProviderDetails(provider),
          borderRadius: BorderRadius.circular(16),
          child: _buildProviderCard(provider),
        );
      },
    );
  }

  Widget _buildProviderCard(ProviderData provider) {
    final isCreatingRequest = _creatingRequestFor == provider.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Picture
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: provider.profilePicture != null
                        ? CachedNetworkImage(
                            imageUrl: provider.profilePicture!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.person, color: Colors.grey),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              child: Text(
                                provider.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            child: Center(
                              child: Text(
                                provider.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Provider Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ),
                          // Availability Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: provider.isAvailable ? _successColor.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: provider.isAvailable ? _successColor.withOpacity(0.25) : Colors.grey.withOpacity(0.2)),
                            ),
                            child: Text(
                              provider.isAvailable ? 'Available' : 'Busy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: provider.isAvailable ? _successColor : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        provider.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          // Rating
                          RatingBarIndicator(
                            rating: provider.rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 16.0,
                            direction: Axis.horizontal,
                          ),
                          
                          const SizedBox(width: 8),
                          
                          Text(
                            '(${provider.rating.toStringAsFixed(1)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Distance
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${provider.distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: _primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${provider.price.toStringAsFixed(0)} DZD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showProviderDetails(provider),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: isCreatingRequest 
                        ? null 
                        : () => _selectProvider(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isCreatingRequest
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Provider Data Model
class ProviderData {
  final String id;
  final String providerAuthId;
  final String name;
  final String specialty;
  final double rating;
  final double price;
  final double distance;
  final bool isAvailable;
  final String? profilePicture;
  final String? bio;
  final String? experience;
  final String? address;
  final String? contact;

  ProviderData({
    required this.id,
    required this.providerAuthId,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.price,
    required this.distance,
    required this.isAvailable,
    this.profilePicture,
    this.bio,
    this.experience,
    this.address,
    this.contact,
  });

  factory ProviderData.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    GeoPoint patientLocation,
  ) {
    final data = doc.data();
    
    // Calculate distance
    double distance = 0.0;
    final providerLocation = data['currentlocation'];
    if (providerLocation is GeoPoint) {
      distance = Geolocator.distanceBetween(
        patientLocation.latitude,
        patientLocation.longitude,
        providerLocation.latitude,
        providerLocation.longitude,
      ) / 1000.0; // Convert to km
    }
    // Robust disponible check
    final disponible = data['disponible'];
    final isAvailable = disponible == true || disponible == 'true' || disponible == 1 || disponible == '1';
    return ProviderData(
      id: doc.id,
      providerAuthId: (data['id_user'] ?? data['userId'] ?? doc.id).toString(),
      name: data['login'] ?? data['nom'] ?? 'Healthcare Provider',
      specialty: data['specialite'] ?? data['specialty'] ?? 'General',
      rating: _parseRating(data['rating']),
      price: _parsePrice(data['price'] ?? data['tarif']),
      distance: distance,
      isAvailable: isAvailable,
      profilePicture: data['profile_picture'] ?? data['photo'],
      bio: data['bio'] ?? data['description'],
      experience: data['experience'] ?? data['experience_years']?.toString(),
      address: data['address'] ?? data['adresse'],
      contact: data['contact'] ?? data['telephone'],
    );
  }

  /// Helper method to safely parse rating from various data types
  static double _parseRating(dynamic rating) {
    if (rating == null) return 4.0;
    
    if (rating is num) {
      return rating.toDouble();
    }
    
    if (rating is String) {
      final parsed = double.tryParse(rating);
      return parsed ?? 4.0;
    }
    
    return 4.0; // Default rating
  }

  /// Helper method to safely parse price from various data types
  static double _parsePrice(dynamic price) {
    if (price == null) return 100.0;
    
    if (price is num) {
      return price.toDouble();
    }
    
    if (price is String) {
      final parsed = double.tryParse(price);
      return parsed ?? 100.0;
    }
    
    return 100.0; // Default price
  }
}

// Provider Details Modal
class ProviderDetailsModal extends StatelessWidget {
  final ProviderData provider;

  const ProviderDetailsModal({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider Header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: provider.profilePicture != null
                              ? CachedNetworkImage(
                                  imageUrl: provider.profilePicture!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    color: const Color(0xFF1565C0).withOpacity(0.1),
                                    child: Center(
                                      child: Text(
                                        provider.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                  child: Center(
                                    child: Text(
                                      provider.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF263238),
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              provider.specialty,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: provider.rating,
                                  itemBuilder: (context, index) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 18.0,
                                ),
                                
                                const SizedBox(width: 8),
                                
                                Text(
                                  '(${provider.rating.toStringAsFixed(1)})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Details Cards
                  _buildDetailCard(
                    'Bio',
                    provider.bio ?? 'No bio available',
                    Icons.person,
                  ),
                  
                  if (provider.experience != null)
                    _buildDetailCard(
                      'Experience',
                      '${provider.experience} years',
                      Icons.work_history,
                    ),
                  
                  _buildDetailCard(
                    'Distance',
                    '${provider.distance.toStringAsFixed(1)} km away',
                    Icons.location_on,
                  ),
                  
                  _buildDetailCard(
                    'Price',
                    '${provider.price.toStringAsFixed(0)} DZD',
                    Icons.monetization_on,
                  ),
                  
                  if (provider.address != null)
                    _buildDetailCard(
                      'Address',
                      provider.address!,
                      Icons.home,
                    ),
                  
                  if (provider.contact != null)
                    _buildDetailCard(
                      'Contact',
                      provider.contact!,
                      Icons.phone,
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Waiting for Acceptance Screen
class WaitingForAcceptanceScreen extends StatelessWidget {
  final String requestId;
  
  const WaitingForAcceptanceScreen({
    super.key, 
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1976D2),
        title: const Text(
          'Waiting for Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('provider_requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Request not found'));
          }

          // Debug logging
          print('🔍 [WaitingScreen] Request data: $data');
          print('🔍 [WaitingScreen] Status: ${data['status']}');
          print('🔍 [WaitingScreen] AppointmentId: ${data['appointmentId']}');

          // Check for acceptance and redirect
          if (data['status'] == 'accepted' && data['appointmentId'] != null) {
            print('✅ [WaitingScreen] Provider accepted! Redirecting to tracking...');
            print('📍 [WaitingScreen] AppointmentId: ${data['appointmentId']}');
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('🚀 [WaitingScreen] Attempting navigation to /tracking with appointmentId: ${data['appointmentId']}');
              print('🔧 [WaitingScreen] Context widget tree check passed');
              
              try {
                Navigator.of(context).pushReplacementNamed(AppRoutes.tracking, arguments: {
                  'appointmentId': data['appointmentId'],
                });
                print('✅ [WaitingScreen] Navigation initiated successfully');
              } catch (e) {
                print('❌ [WaitingScreen] Navigation error: $e');
                print('🔄 [WaitingScreen] Trying fallback with MaterialPageRoute...');
                try {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LiveTrackingScreen(appointmentId: data['appointmentId']),
                    ),
                  );
                  print('✅ [WaitingScreen] Fallback navigation successful');
                } catch (fallbackError) {
                  print('❌ [WaitingScreen] Fallback navigation also failed: $fallbackError');
                }
              }
            });
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF1976D2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['providerName'] ?? 'Healthcare Provider').toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF263238)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (data['service'] ?? 'Service').toString(),
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (data['prix'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('', style: TextStyle()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(width: 200, height: 200, child: Lottie.asset('assets/animations/waiting.json', repeat: true)),
                const SizedBox(height: 24),
                const Text('Waiting for provider to accept your request…', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF263238))),
                const SizedBox(height: 12),
                Text('You will be redirected automatically once the provider accepts.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF1976D2).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                  child: Text('Status: ${data['status']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                ),
                const Spacer(),
                  
                  // Debug info and manual redirect button
                  if (data['status'] == 'accepted' && data['appointmentId'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Provider Accepted!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appointment ID: ${data['appointmentId']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final appointmentId = data['appointmentId'];
                                print('🚀 [WaitingScreen] Manual redirect to /tracking with appointmentId: $appointmentId');
                                
                                if (appointmentId == null || appointmentId.isEmpty) {
                                  print('❌ [WaitingScreen] ERROR: appointmentId is null or empty!');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error: No appointment ID available')),
                                  );
                                  return;
                                }
                                
                                try {
                                  print('📍 [WaitingScreen] Navigating with route: /tracking');
                                  print('📍 [WaitingScreen] Arguments: {appointmentId: $appointmentId}');
                                  
                                  Navigator.of(context).pushReplacementNamed(AppRoutes.tracking, arguments: {
                                    'appointmentId': appointmentId,
                                  });
                                  print('✅ [WaitingScreen] Manual navigation initiated');
                                } catch (e) {
                                  print('❌ [WaitingScreen] Manual navigation error: $e');
                                  print('🔄 [WaitingScreen] Trying fallback...');
                                  
                                  try {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => LiveTrackingScreen(appointmentId: appointmentId),
                                      ),
                                    );
                                    print('✅ [WaitingScreen] Fallback navigation successful');
                                  } catch (fallbackError) {
                                    print('❌ [WaitingScreen] Fallback also failed: $fallbackError');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Navigation failed: $fallbackError')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Go to Live Tracking'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel request?'),
                          content: const Text('Are you sure you want to cancel this request?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep Waiting')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes, Cancel', style: TextStyle(color: Color(0xFFE53935)))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try { await ProviderRequestService.cancelRequest(requestId); } catch (_) {}
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.selectProvider, arguments: {
                            'service': data['service'] ?? 'consultation',
                            'specialty': data['specialty'],
                            'prix': (data['prix'] ?? 0).toDouble(),
                            'paymentMethod': data['paymentMethod'] ?? 'Cash',
                            'patientLocation': data['patientLocation'] ?? const GeoPoint(0,0),
                          });
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}