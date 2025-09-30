import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/provider_request_service.dart';

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
    final requestedService = widget.service.toLowerCase().trim();
    final requestedSpecialty = widget.specialty?.toLowerCase().trim();

    Query query = col.where('disponible', isEqualTo: true);
    
    // Try to add service filter
    try {
      query = query.where('service', isEqualTo: requestedService);
      
      if (requestedSpecialty != null && requestedSpecialty.isNotEmpty) {
        query = query.where('specialite', isEqualTo: requestedSpecialty);
      }
    } catch (e) {
      print('Service filter failed, using disponible only: $e');
    }

    _providersSubscription?.cancel();
    _providersSubscription = query.limit(25).snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          _tryFallbackStrategies();
        } else {
          _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
        }
      },
      onError: (error) {
        print('Stream error: $error');
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
      final snapshot = await col.where('disponible', isEqualTo: true).limit(25).get();
      final results = snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
      _updateProviderList(results);
    } catch (e) {
      print('Fallback failed: $e');
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
        providerId: provider.id,
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
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
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
                    color: Color(0xFF1565C0),
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
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
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
              color: Color(0xFF1565C0),
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
                backgroundColor: const Color(0xFF1565C0),
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
        return _buildProviderCard(provider);
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
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                          // Availability Status
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: provider.isAvailable ? Colors.green : Colors.grey,
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
                  color: Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                Text(
                  '${provider.price.toStringAsFixed(0)} DZD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
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
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
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
                      backgroundColor: const Color(0xFF1565C0),
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

    return ProviderData(
      id: doc.id,
      name: data['login'] ?? data['nom'] ?? 'Healthcare Provider',
      specialty: data['specialite'] ?? data['specialty'] ?? 'General',
      rating: (data['rating'] ?? 4.0).toDouble(),
      price: (data['price'] ?? data['tarif'] ?? 100.0).toDouble(),
      distance: distance,
      isAvailable: data['disponible'] ?? false,
      profilePicture: data['profile_picture'] ?? data['photo'],
      bio: data['bio'] ?? data['description'],
      experience: data['experience'] ?? data['experience_years']?.toString(),
      address: data['address'] ?? data['adresse'],
      contact: data['contact'] ?? data['telephone'],
    );
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
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
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

          if (data['status'] == 'accepted' && data['appointmentId'] != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/tracking', arguments: {
                'appointmentId': data['appointmentId'],
              });
            });
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'assets/animations/waiting.json',
                      repeat: true,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Waiting for provider response',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF263238),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'We\'ve sent your request to the provider. You\'ll be notified once they respond.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Status: ${data['status']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ProviderRequestService.cancelRequest(requestId);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}