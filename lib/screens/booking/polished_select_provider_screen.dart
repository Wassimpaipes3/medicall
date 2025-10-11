import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/provider_request_service.dart';
import '../../routes/app_routes.dart';

/// Polished Material 3 Select Provider Screen
/// Clean, modern UI with beautiful cards and smooth animations
class PolishedSelectProviderScreen extends StatefulWidget {
  final String service;
  final String? specialty;
  final double prix;
  final String paymentMethod;
  final GeoPoint patientLocation;

  const PolishedSelectProviderScreen({
    super.key,
    required this.service,
    this.specialty,
    required this.prix,
    required this.paymentMethod,
    required this.patientLocation,
  });

  @override
  State<PolishedSelectProviderScreen> createState() => _PolishedSelectProviderScreenState();
}

class _PolishedSelectProviderScreenState extends State<PolishedSelectProviderScreen> 
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<ProviderData> _providers = [];
  String? _creatingRequestFor;
  StreamSubscription<QuerySnapshot>? _providersSubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Material 3 Color Palette
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _successColor = Color(0xFF43A047);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1C1B1F);
  static const Color _textSecondary = Color(0xFF49454F);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupRealTimeProviderUpdates();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _providersSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to safely convert to double (handles both numbers and strings)
  double _toDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Helper method to safely convert to int (handles both numbers and strings)
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  void _setupRealTimeProviderUpdates() {
    _startProviderStream();
  }

  void _startProviderStream() {
    setState(() => _loading = true);
    
    print('🔍 [PolishedSelectProvider] Starting provider stream...');
    print('   Service: ${widget.service}');
    print('   Specialty: ${widget.specialty}');
    
    final col = FirebaseFirestore.instance.collection('professionals');
    final requestedService = (widget.service).toLowerCase().trim();
    final requestedSpecialty = widget.specialty?.toLowerCase().trim();
    
    // Determine profession based on service type
    String? requiredProfession;
    String? requiredSpecialty;
    
    if (requestedService.contains('doctor') || 
        requestedService.contains('docteur') || 
        requestedService.contains('medecin') ||
        requestedService.contains('médecin')) {
      requiredProfession = 'medecin';
      requiredSpecialty = 'generaliste';  // ONLY generaliste for doctors
      print('   🩺 Filtering for DOCTORS with GENERALISTE specialty only');
    } else if (requestedService.contains('nurse') || 
               requestedService.contains('infirmier') || 
               requestedService.contains('infirmière')) {
      requiredProfession = 'infirmier';
      // For nurses, use specialty from widget OR show all nurse specialties
      requiredSpecialty = requestedSpecialty;
      print('   💉 Filtering for NURSES - showing all nurse specialties from backend');
    }
    
    print('   Searching for: service="$requestedService", profession="$requiredProfession", specialite="$requiredSpecialty"');
    
    Query query = col.where('disponible', whereIn: [true, 'true', 1, '1']);
    
    try {
      // Filter by profession (doctor or nurse)
      if (requiredProfession != null) {
        query = query.where('profession', isEqualTo: requiredProfession);
        print('   ✅ Added profession filter: $requiredProfession');
      }
      
      // Filter by specialty
      if (requiredSpecialty != null && requiredSpecialty.isNotEmpty) {
        query = query.where('specialite', isEqualTo: requiredSpecialty);
        print('   ✅ Added specialty filter: $requiredSpecialty');
      }
    } catch (e) {
      print('⚠️ Filter failed: $e');
    }

    _providersSubscription?.cancel();
    _providersSubscription = query.limit(25).snapshots().listen(
      (snapshot) {
        print('📥 Query returned ${snapshot.docs.length} providers');
        if (snapshot.docs.isEmpty) {
          print('❌ No providers found, trying fallback...');
          _tryFallbackStrategies();
        } else {
          print('✅ Found providers, updating list...');
          _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
        setState(() => _loading = false);
      },
    );
  }

  void _tryFallbackStrategies() {
    print('🔄 [Fallback Strategy 1] Trying profession-only filter...');
    final col = FirebaseFirestore.instance.collection('professionals');
    final requestedService = (widget.service).toLowerCase().trim();
    
    // Determine profession and specialty based on service type
    String? requiredProfession;
    String? requiredSpecialty;
    
    if (requestedService.contains('doctor') || 
        requestedService.contains('docteur') || 
        requestedService.contains('medecin') ||
        requestedService.contains('médecin')) {
      requiredProfession = 'medecin';
      requiredSpecialty = 'generaliste';  // ONLY generaliste for doctors
      print('   Filtering by profession: medecin, specialty: generaliste');
    } else if (requestedService.contains('nurse') || 
               requestedService.contains('infirmier') || 
               requestedService.contains('infirmière')) {
      requiredProfession = 'infirmier';
      // For nurses, show all specialties from backend
      print('   Filtering by profession: infirmier (all specialties)');
    }
    
    Query query = col.where('disponible', whereIn: [true, 'true', 1, '1']);
    if (requiredProfession != null) {
      query = query.where('profession', isEqualTo: requiredProfession);
      
      // For doctors, also filter by generaliste
      if (requiredSpecialty != null) {
        query = query.where('specialite', isEqualTo: requiredSpecialty);
      }
    }
    
    query.limit(25).get().then((snapshot) {
      print('   Fallback 1 returned ${snapshot.docs.length} providers');
      if (snapshot.docs.isNotEmpty) {
        _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
      } else {
        print('   Still no results, trying fallback 2...');
        _loadAllAvailableProviders();
      }
    }).catchError((e) {
      print('❌ Fallback 1 failed: $e');
      _loadAllAvailableProviders();
    });
  }

  void _loadAllAvailableProviders() {
    print('🔄 [Fallback Strategy 2] Loading ALL available providers by profession...');
    final col = FirebaseFirestore.instance.collection('professionals');
    final requestedService = (widget.service).toLowerCase().trim();
    
    // Filter by profession and specialty even in final fallback
    String? requiredProfession;
    String? requiredSpecialty;
    
    if (requestedService.contains('doctor') || 
        requestedService.contains('docteur') || 
        requestedService.contains('medecin') ||
        requestedService.contains('médecin')) {
      requiredProfession = 'medecin';
      requiredSpecialty = 'generaliste';  // ONLY generaliste for doctors
      print('   Final fallback filtering by profession: medecin, specialty: generaliste');
    } else if (requestedService.contains('nurse') || 
               requestedService.contains('infirmier') || 
               requestedService.contains('infirmière')) {
      requiredProfession = 'infirmier';
      print('   Final fallback filtering by profession: infirmier (all specialties)');
    }
    
    Query query = col.where('disponible', whereIn: [true, 'true', 1, '1']);
    if (requiredProfession != null) {
      query = query.where('profession', isEqualTo: requiredProfession);
      
      // For doctors, also filter by generaliste
      if (requiredSpecialty != null) {
        query = query.where('specialite', isEqualTo: requiredSpecialty);
      }
    }
    
    query.limit(25).get().then((snapshot) {
      print('   Fallback 2 returned ${snapshot.docs.length} providers');
      if (snapshot.docs.isEmpty) {
        print('❌ No available providers found in database for profession: $requiredProfession!');
      }
      _updateProviderList(snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
    }).catchError((e) {
      print('❌ Fallback 2 failed: $e');
      setState(() => _loading = false);
    });
  }

  void _updateProviderList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    print('📋 [PolishedSelectProvider] Processing ${docs.length} providers');
    
    final currentPosition = await _getCurrentPosition();
    final providers = <ProviderData>[];

    for (final doc in docs) {
      final data = doc.data();
      
      // Try multiple location field names
      final location = data['location'] as GeoPoint? ?? 
                      data['currentlocation'] as GeoPoint? ??
                      data['currentLocation'] as GeoPoint?;
      double distance = 0.0;

      if (currentPosition != null && location != null) {
        distance = Geolocator.distanceBetween(
              currentPosition.latitude,
              currentPosition.longitude,
              location.latitude,
              location.longitude,
            ) /
            1000;
      }
      
      // Debug: Print all data to see what's available
      print('   📄 Professional data from professionals collection:');
      data.forEach((key, value) {
        print('      $key: $value (${value.runtimeType})');
      });
      
      // FETCH USER INFO FROM users COLLECTION
      String? userNom;
      String? userPrenom;
      String? userPhotoProfile;
      
      final userId = data['id_user'] as String?;
      if (userId != null && userId.isNotEmpty) {
        print('   🔍 Fetching user data from users collection for id_user: $userId');
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              userNom = userData['nom'] as String?;
              userPrenom = userData['prenom'] as String?;
              userPhotoProfile = userData['photo_profile'] as String?;
              
              print('   ✅ Found user data:');
              print('      nom: $userNom');
              print('      prenom: $userPrenom');
              print('      photo_profile: $userPhotoProfile');
            }
          } else {
            print('   ⚠️ User document not found for id: $userId');
          }
        } catch (e) {
          print('   ❌ Error fetching user data: $e');
        }
      } else {
        print('   ⚠️ No id_user field found in professional document');
      }
      
      // Build full name from users collection
      String? fullNameFromUsers;
      if (userNom != null || userPrenom != null) {
        fullNameFromUsers = [userPrenom, userNom].where((s) => s != null && s.isNotEmpty).join(' ');
        if (fullNameFromUsers.isNotEmpty) {
          // Only add Dr. prefix for doctors, not nurses
          final profession = data["profession"] ?? '';
          final isNurse = profession.contains('nurse') || profession.contains('infirmier');
          fullNameFromUsers = isNurse ? fullNameFromUsers : 'Dr. $fullNameFromUsers';
        }
      }
      
      // Extract profile picture URL (prioritize users collection)
      final profilePicture = userPhotoProfile ?? 
                            data['profilePicture'] as String? ?? 
                            data['photo'] as String? ?? 
                            data['image'] as String? ??
                            data['photoURL'] as String? ??
                            data['profile_picture'] as String? ??
                            data['photoUrl'] as String? ??
                            data['avatar'] as String?;
      
      // Extract name with better fallbacks (prioritize users collection)
      String? rawName = fullNameFromUsers ??
                        data['nom'] as String? ?? 
                        data['name'] as String? ?? 
                        data['fullName'] as String? ??
                        data['displayName'] as String? ??
                        data['firstName'] as String?;
      
      // If no proper name found, check if we should use profession or fallback
      final name = rawName ?? 
                   (data['profession'] != null && data['profession'] != '' 
                     ? 'Dr. ${data["profession"]}' 
                     : null) ??
                   (data['login'] as String?)?.replaceAll('login_', 'Provider ') ??
                   'Unknown Provider';
      
      print('   ✅ Final Name: "$name"');
      print('   ✅ Final Image: "$profilePicture"');

      // Get prix from professionals collection (prioritize 'prix' field)
      final providerPrix = _toDouble(data['prix'] ?? data['price'], widget.prix);
      
      providers.add(ProviderData(
        id: doc.id,
        name: name,
        specialty: data['specialite'] ?? data['specialty'] ?? widget.service,
        rating: _toDouble(data['note'] ?? data['rating'], 4.5),
        price: providerPrix, // Use provider's actual prix from professionals collection
        distance: distance,
        isAvailable: data['disponible'] == true || data['disponible'] == 'true' || data['disponible'] == 1 || data['disponible'] == '1',
        profilePicture: profilePicture,
        bio: data['bio'] ?? data['description'],
        experience: _toInt(data['experience']),
        languages: data['languages'],
        services: data['services'],
        reviews: data['reviews'] ?? data['avis'],
        address: data['adresse'] ?? data['address'],
        contact: data['telephone'] ?? data['phone'],
      ));
      
      print('   💰 Provider prix: $providerPrix DZD (from professionals.prix)');
    }

    providers.sort((a, b) => a.distance.compareTo(b.distance));

    print('✅ [PolishedSelectProvider] Updated UI with ${providers.length} providers');
    
    setState(() {
      _providers = providers;
      _loading = false;
    });
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _selectProvider(ProviderData provider) async {
    setState(() => _creatingRequestFor = provider.id);

    try {
      // Use the provider's actual prix from professionals collection
      print('💰 Creating request with provider prix: ${provider.price} DZD');
      
      final requestId = await ProviderRequestService.createRequest(
        patientLocation: widget.patientLocation,
        service: widget.service,
        specialty: widget.specialty,
        prix: provider.price, // Use provider's prix instead of widget.prix
        paymentMethod: widget.paymentMethod,
        providerId: provider.id,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PolishedWaitingScreen(requestId: requestId),
        ),
      );
    } catch (e) {
      setState(() => _creatingRequestFor = null);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create request: $e'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showProviderDetails(ProviderData provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProviderDetailsSheet(provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: _surfaceColor,
        foregroundColor: _primaryColor,
        title: const Text(
          'Select Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? _buildLoadingState()
          : _providers.isEmpty
              ? _buildEmptyState()
              : _buildProvidersList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding available providers...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No providers available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any available providers for this service at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _setupRealTimeProviderUpdates(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          return _buildProviderCard(_providers[index], index);
        },
      ),
    );
  }

  Widget _buildProviderCard(ProviderData provider, int index) {
    final isCreatingRequest = _creatingRequestFor == provider.id;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showProviderDetails(provider),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar with status indicator
                      Stack(
                        children: [
                          Hero(
                            tag: 'provider-${provider.id}',
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryColor.withOpacity(0.2),
                                    _primaryColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: provider.profilePicture != null && provider.profilePicture!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: provider.profilePicture!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[100],
                                          child: const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          print('❌ Image load error for ${provider.name}: $error');
                                          print('   URL: $url');
                                          return _buildAvatarFallback(provider);
                                        },
                                      )
                                    : _buildAvatarFallback(provider),
                              ),
                            ),
                          ),
                          // Status indicator
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: provider.isAvailable ? _successColor : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: _surfaceColor, width: 2.5),
                              ),
                            ),
                          ),
                        ],
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
                                      color: _textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              provider.specialty,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Row(
                              children: [
                                // Rating
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        provider.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Distance
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: _primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${provider.distance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Availability Badge
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: provider.isAvailable 
                                  ? _successColor.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              provider.isAvailable ? 'Available' : 'Busy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: provider.isAvailable ? _successColor : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.1),
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price and Actions
                  Row(
                    children: [
                      // Price Badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.1),
                                _primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.payments,
                                  size: 16,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${provider.price.toStringAsFixed(0)} DZD',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Book Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isCreatingRequest || !provider.isAvailable
                                ? null
                                : () => _selectProvider(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                              elevation: 0,
                              shadowColor: _primaryColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isCreatingRequest
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Book',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }

  Widget _buildAvatarFallback(ProviderData provider) {
    // Get initials from name (first and last name)
    String initials = '?';
    if (provider.name.isNotEmpty && provider.name != 'Unknown Provider') {
      final nameParts = provider.name.trim().split(' ');
      if (nameParts.length >= 2) {
        // First and last name initials
        initials = '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty) {
        // Just first initial
        initials = nameParts.first[0].toUpperCase();
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.2),
            _primaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProviderDetailsSheet(ProviderData provider) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
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
                    // Provider Header
                    Row(
                      children: [
                        Hero(
                          tag: 'provider-${provider.id}',
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _primaryColor.withOpacity(0.2),
                                  _primaryColor.withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: provider.profilePicture != null
                                  ? CachedNetworkImage(
                                      imageUrl: provider.profilePicture!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => _buildAvatarFallback(provider),
                                    )
                                  : _buildAvatarFallback(provider),
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
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              
                              const SizedBox(height: 6),
                              
                              Text(
                                provider.specialty,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Details Cards
                    if (provider.bio != null) _buildDetailCard(
                      'About',
                      provider.bio!,
                      Icons.info_outline,
                      _primaryColor,
                    ),
                    
                    if (provider.experience != null) _buildDetailCard(
                      'Experience',
                      '${provider.experience} years in practice',
                      Icons.work_history_outlined,
                      const Color(0xFF43A047),
                    ),
                    
                    _buildDetailCard(
                      'Location',
                      '${provider.distance.toStringAsFixed(1)} km away from you',
                      Icons.location_on_outlined,
                      const Color(0xFFE53935),
                    ),
                    
                    _buildDetailCard(
                      'Service Fee',
                      '${provider.price.toStringAsFixed(0)} DZD per consultation',
                      Icons.payments_outlined,
                      const Color(0xFFFB8C00),
                    ),
                    
                    if (provider.languages != null) _buildDetailCard(
                      'Languages',
                      provider.languages!,
                      Icons.language_outlined,
                      const Color(0xFF7B1FA2),
                    ),
                    
                    if (provider.address != null) _buildDetailCard(
                      'Address',
                      provider.address!,
                      Icons.home_outlined,
                      const Color(0xFF0097A7),
                    ),
                    
                    if (provider.contact != null) _buildDetailCard(
                      'Contact',
                      provider.contact!,
                      Icons.phone_outlined,
                      const Color(0xFF1976D2),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Book Now Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: provider.isAvailable
                            ? () {
                                Navigator.of(context).pop();
                                _selectProvider(provider);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              provider.isAvailable ? 'Book Now' : 'Currently Unavailable',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(String title, String content, IconData icon, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.5,
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
  final int? experience;
  final String? languages;
  final String? services;
  final dynamic reviews;
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
    this.languages,
    this.services,
    this.reviews,
    this.address,
    this.contact,
  });
}

// ===== POLISHED WAITING SCREEN =====

class PolishedWaitingScreen extends StatefulWidget {
  final String requestId;
  
  const PolishedWaitingScreen({
    super.key, 
    required this.requestId,
  });

  @override
  State<PolishedWaitingScreen> createState() => _PolishedWaitingScreenState();
}

class _PolishedWaitingScreenState extends State<PolishedWaitingScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCancelling = false;
  bool _hasShownDeclinedDialog = false; // Prevent multiple dialogs
  bool _hasShownExpiredDialog = false; // Prevent multiple expired dialogs

  // Material 3 Colors
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1C1B1F);
  static const Color _textSecondary = Color(0xFF49454F);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleDeclinedRequest(BuildContext context, Map<String, dynamic> data) async {
    // Prevent showing dialog multiple times
    if (_hasShownDeclinedDialog) return;
    _hasShownDeclinedDialog = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: _errorColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Request Declined',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'The provider has declined your request. Please select another available provider to continue.',
          style: TextStyle(
            fontSize: 15,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              
              // Redirect to select provider screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PolishedSelectProviderScreen(
                    service: data['service'] ?? 'consultation',
                    specialty: data['specialty'],
                    prix: _toDouble(data['prix'], 0),
                    paymentMethod: data['paymentMethod'] ?? 'Cash',
                    patientLocation: data['patientLocation'] ?? const GeoPoint(0, 0),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text(
              'Select Another Provider',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _toDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Future<void> _cancelRequest(BuildContext context, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _errorColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Cancel Request?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this appointment request? You can select a different provider afterwards.',
          style: TextStyle(
            fontSize: 15,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: _textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Keep Waiting',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isCancelling = true);
      
      try {
        await ProviderRequestService.cancelRequest(widget.requestId);
        
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PolishedSelectProviderScreen(
              service: data['service'] ?? 'consultation',
              specialty: data['specialty'],
              prix: (data['prix'] ?? 0).toDouble(),
              paymentMethod: data['paymentMethod'] ?? 'Cash',
              patientLocation: data['patientLocation'] ?? const GeoPoint(0, 0),
            ),
          ),
        );
      } catch (e) {
        setState(() => _isCancelling = false);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surfaceColor,
        foregroundColor: _primaryColor,
        title: const Text(
          'Waiting for Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('provider_requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }
          
          // Check if document doesn't exist (deleted/expired)
          if (!snapshot.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showExpiredDialog(context, {});
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time_filled, size: 80, color: _errorColor),
                  const SizedBox(height: 24),
                  const Text(
                    'Request Expired',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The request has been removed',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return _buildErrorState();
          }

          // Check if request has expired based on expireAt timestamp
          final expireAt = data['expireAt'] as Timestamp?;
          if (expireAt != null && expireAt.toDate().isBefore(DateTime.now())) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showExpiredDialog(context, data);
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time_filled, size: 80, color: _errorColor),
                  const SizedBox(height: 24),
                  const Text(
                    'Request Expired',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The 10-minute timeout has passed',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final status = data['status'] as String?;

          // Check for acceptance and auto-redirect to tracking
          if (status == 'accepted' && data['appointmentId'] != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.tracking,
                  arguments: {'appointmentId': data['appointmentId']},
                );
              }
            });
          }

          // Check for decline and show dialog, then redirect to select provider
          if (status == 'declined') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleDeclinedRequest(context, data);
              }
            });
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Provider Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.2),
                                _primaryColor.withOpacity(0.05),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: _primaryColor,
                            size: 32,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['providerName'] ?? 'Healthcare Provider',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Text(
                                data['service'] ?? 'Service',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              if (data['prix'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${data['prix']} DZD',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Animated Illustration
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _primaryColor.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    size: 80,
                                    color: _primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          const Text(
                            'Waiting for provider to\naccept your request...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            'You will be redirected automatically\nonce the provider responds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Status: ${data['status'] ?? 'pending'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : () => _cancelRequest(context, data),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _errorColor,
                        side: const BorderSide(color: _errorColor, width: 2),
                        disabledForegroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(_errorColor),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Cancel Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Request not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The appointment request could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show expired request dialog (Material 3 style)
  Future<void> _showExpiredDialog(BuildContext context, Map<String, dynamic> data) async {
    // Prevent showing dialog multiple times
    if (_hasShownExpiredDialog) return;
    _hasShownExpiredDialog = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.access_time_filled, color: _errorColor, size: 28),
            SizedBox(width: 12),
            Text(
              '⏰ Request Expired',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your request has expired. Please try again with another provider.',
          style: TextStyle(
            fontSize: 15,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              // Stay on current screen (idle)
            },
            style: TextButton.styleFrom(
              foregroundColor: _textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              
              // Redirect to select provider screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PolishedSelectProviderScreen(
                    service: data['service'] ?? 'consultation',
                    specialty: data['specialty'],
                    prix: _toDouble(data['prix'], 0),
                    paymentMethod: data['paymentMethod'] ?? 'Cash',
                    patientLocation: data['patientLocation'] ?? const GeoPoint(0, 0),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
