import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/maps/flutter_map_tracking_widget.dart';
import '../../routes/app_routes.dart';
import 'arrived_confirmation_screen.dart';

/// Enhanced Live Tracking Screen with Arrived & Complete workflow
class EnhancedLiveTrackingScreen extends StatefulWidget {
  final String? appointmentId;
  
  const EnhancedLiveTrackingScreen({
    super.key,
    this.appointmentId,
  });

  @override
  State<EnhancedLiveTrackingScreen> createState() => _EnhancedLiveTrackingScreenState();
}

class _EnhancedLiveTrackingScreenState extends State<EnhancedLiveTrackingScreen> {
  // Distance monitoring
  double? _currentDistance;
  bool _isWithin100Meters = false;
  
  // Location streams
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _appointmentSubscription;
  
  // Appointment data
  Map<String, dynamic>? _appointmentData;
  double? _patientLat;
  double? _patientLng;
  String? _currentUserRole;
  
  // Loading state
  bool _isLoading = false;
  bool _isArrivedButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _appointmentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    if (widget.appointmentId == null) {
      debugPrint('❌ [Tracking] No appointmentId provided');
      return;
    }

    // Determine user role
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ [Tracking] No authenticated user');
      return;
    }

    debugPrint('🔄 [Tracking] Initializing for appointment: ${widget.appointmentId}');
    debugPrint('👤 [Tracking] Current user ID: ${currentUser.uid}');

    // Listen to appointment changes for patient-side redirect
    _appointmentSubscription = FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .snapshots()
        .listen(_handleAppointmentUpdate);

    // Load appointment data to get patient location
    await _loadAppointmentData();

    // Start distance monitoring for provider
    if (_currentUserRole == 'provider') {
      debugPrint('✅ [Tracking] User is PROVIDER - starting distance monitoring');
      if (_patientLat != null && _patientLng != null) {
        debugPrint('📍 [Tracking] Patient location: $_patientLat, $_patientLng');
        _startDistanceMonitoring();
      } else {
        debugPrint('❌ [Tracking] Patient location is NULL - cannot monitor distance');
      }
    } else {
      debugPrint('👥 [Tracking] User is PATIENT - no distance monitoring needed');
    }
  }

  Future<void> _loadAppointmentData() async {
    try {
      debugPrint('📥 [Tracking] Loading appointment data...');
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (doc.exists) {
        _appointmentData = doc.data();
        debugPrint('✅ [Tracking] Appointment data loaded: $_appointmentData');
        
        // Get patient location (try multiple field names)
        final patientLocation = _appointmentData?['patientLocation'];
        if (patientLocation != null) {
          _patientLat = patientLocation['latitude'] ?? patientLocation['lat'];
          _patientLng = patientLocation['longitude'] ?? patientLocation['lng'];
          debugPrint('📍 [Tracking] Patient location found: $_patientLat, $_patientLng');
        } else {
          debugPrint('❌ [Tracking] No patientLocation field in document');
          debugPrint('📋 [Tracking] Available fields: ${_appointmentData?.keys.toList()}');
        }

        // Determine current user role
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final providerId = _appointmentData?['providerId'] ?? _appointmentData?['idpro'];
        final patientId = _appointmentData?['patientId'] ?? _appointmentData?['idpat'];
        
        debugPrint('🔍 [Tracking] Current user: $currentUserId');
        debugPrint('🔍 [Tracking] Provider ID: $providerId');
        debugPrint('🔍 [Tracking] Patient ID: $patientId');
        
        _currentUserRole = currentUserId == providerId ? 'provider' : 'patient';
        debugPrint('👤 [Tracking] Role determined: $_currentUserRole');

        setState(() {});
      } else {
        debugPrint('❌ [Tracking] Appointment document does not exist');
      }
    } catch (e) {
      debugPrint('❌ [Tracking] Error loading appointment data: $e');
    }
  }

  void _handleAppointmentUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final status = data['status'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final patientId = data['patientId'] ?? data['idpat'];

    // --- FIX: Update patient location if it changes ---
    final patientLocation = data['patientLocation'];
    if (patientLocation != null) {
      final newLat = patientLocation['latitude'] ?? patientLocation['lat'];
      final newLng = patientLocation['longitude'] ?? patientLocation['lng'];
      if (newLat != null && newLng != null && (newLat != _patientLat || newLng != _patientLng)) {
        setState(() {
          _patientLat = newLat;
          _patientLng = newLng;
        });
      }
    }
    // --- END FIX ---

    // If patient and status is completed, redirect to rating screen
    if (currentUserId == patientId && status == 'completed') {
      _navigateToRatingScreen(data);
    }

    setState(() {
      _appointmentData = data;
    });
  }

  void _startDistanceMonitoring() {
    debugPrint('📡 [Tracking] Starting distance monitoring stream...');
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen(
      (Position position) {
        debugPrint('📍 [Tracking] Provider position update: ${position.latitude}, ${position.longitude}');
        
        if (_patientLat != null && _patientLng != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _patientLat!,
            _patientLng!,
          );

          debugPrint('📏 [Tracking] Distance calculated: ${distance.toStringAsFixed(1)} meters');
          debugPrint('🎯 [Tracking] Within 100m? ${distance < 100}');

          setState(() {
            _currentDistance = distance;
            _isWithin100Meters = distance < 100;
          });
        } else {
          debugPrint('⚠️ [Tracking] Patient location is NULL - cannot calculate distance');
        }
      },
      onError: (error) {
        debugPrint('❌ [Tracking] Location stream error: $error');
      },
    );
  }

  Future<void> _handleArrivedButtonPress() async {
    if (_isArrivedButtonPressed || widget.appointmentId == null) return;

    setState(() {
      _isLoading = true;
      _isArrivedButtonPressed = true;
    });

    try {
      // Update appointment status to "arrived"
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'etat': 'arrived',
        'arrivedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to arrived confirmation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ArrivedConfirmationScreen(
              appointmentId: widget.appointmentId!,
              appointmentData: _appointmentData ?? {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking as arrived: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _isArrivedButtonPressed = false;
      });
    }
  }

  void _navigateToRatingScreen(Map<String, dynamic> appointmentData) {
    // Show notification dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF43A047), size: 32),
            SizedBox(width: 12),
            Text('Appointment Complete'),
          ],
        ),
        content: const Text(
          'Your appointment has ended. Please rate your provider to help others.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from tracking
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Navigate to rating screen
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.ratingScreen,
                arguments: {
                  'appointmentId': widget.appointmentId,
                  'providerId': appointmentData['providerId'] ?? appointmentData['idpro'],
                  'providerName': appointmentData['providerName'] ?? appointmentData['nom'] ?? 'Provider',
                  'providerSpecialty': appointmentData['specialty'] ?? appointmentData['specialite'] ?? '',
                  'providerPhoto': appointmentData['providerPhoto'] ?? appointmentData['photo_profile'],
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: widget.appointmentId == null
          ? _buildErrorView()
          : Column(
              children: [
                // Map Card (takes most of the space)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Map widget
                          FlutterMapTrackingWidget(
                            appointmentId: widget.appointmentId,
                            showNearbyProviders: false,
                          ),
                          
                          // Debug info (top-left) - Remove in production
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Role: ${_currentUserRole ?? "loading..."}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  if (_currentDistance != null)
                                    Text(
                                      'Distance: ${_currentDistance!.toStringAsFixed(0)}m',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  Text(
                                    'Within 100m: $_isWithin100Meters',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Text(
                                    'Patient Loc: ${_patientLat != null ? "✓" : "✗"}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Distance indicator (top)
                          if (_currentUserRole == 'provider' && _currentDistance != null)
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: _buildDistanceCard(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Arrived button (below the map card) - only for provider
                if (_currentUserRole == 'provider')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildArrivedButton(),
                  ),
              ],
            ),
    );
  }

  Widget _buildErrorView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'No Appointment ID',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Cannot load tracking without appointment ID',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    final distanceInMeters = _currentDistance!;
    final distanceText = distanceInMeters < 1000
        ? '${distanceInMeters.toStringAsFixed(0)} m'
        : '${(distanceInMeters / 1000).toStringAsFixed(1)} km';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isWithin100Meters
                ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                : [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isWithin100Meters ? Icons.check_circle : Icons.navigation,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isWithin100Meters ? 'Almost There!' : 'Distance to Patient',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivedButton() {
    return AnimatedOpacity(
      opacity: !_isArrivedButtonPressed ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: !_isArrivedButtonPressed && !_isLoading
              ? _handleArrivedButtonPress
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: !_isArrivedButtonPressed
                    ? [const Color(0xFF1976D2), const Color(0xFF1565C0)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'I\'ve Arrived',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
