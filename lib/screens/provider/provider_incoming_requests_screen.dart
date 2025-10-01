import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/provider_request_service.dart';
import '../../routes/app_routes.dart';

/// Provider Incoming Requests Screen
/// Shows pending patient requests with Material 3 design
class ProviderIncomingRequestsScreen extends StatefulWidget {
  const ProviderIncomingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderIncomingRequestsScreen> createState() =>
      _ProviderIncomingRequestsScreenState();
}

class _ProviderIncomingRequestsScreenState
    extends State<ProviderIncomingRequestsScreen> {
  // Material 3 Colors
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _successColor = Color(0xFF43A047);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _pendingColor = Color(0xFFFFC107);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  List<RequestData> _requests = [];
  String? _processingRequestId;
  StreamSubscription<List<ProviderRequest>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('🔍 [Provider Requests] Setting up real-time listener for provider: ${user.uid}');

    // Cancel existing subscription
    await _requestsSubscription?.cancel();

    // Set up real-time listener via service (handles providerId/auth)
    _requestsSubscription = ProviderRequestService
        .listenProviderPendingRequests()
        .listen((providerRequests) async {
      print('📋 [Provider Requests] Real-time update: ${providerRequests.length} pending requests');

      try {
        // Sort client-side by createdAt desc
        final sorted = [...providerRequests]
          ..sort((a, b) => (b.createdAt).compareTo(a.createdAt));

        final requests = <RequestData>[];

        for (final r in sorted) {
          // Fetch patient info from users collection
          String? patientName;
          String? patientPhoto;

          if (r.patientId.isNotEmpty) {
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(r.patientId)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data();
                if (userData != null) {
                  final prenom = userData['prenom'] as String?;
                  final nom = userData['nom'] as String?;
                  patientName = [prenom, nom]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' ');
                  patientPhoto = userData['photo_profile'] as String?;
                }
              }
            } catch (e) {
              print('⚠️ Error fetching patient data: $e');
            }
          }

          // Calculate distance
          double? distance;
          final patientLocation = r.patientLocation;
          if (patientLocation.latitude != 0 || patientLocation.longitude != 0) {
            try {
              final providerPosition = await Geolocator.getCurrentPosition();
              distance = Geolocator.distanceBetween(
                    providerPosition.latitude,
                    providerPosition.longitude,
                    patientLocation.latitude,
                    patientLocation.longitude,
                  ) /
                  1000; // km
            } catch (e) {
              print('⚠️ Error calculating distance: $e');
            }
          }

          requests.add(RequestData(
            id: r.id,
            patientId: r.patientId,
            patientName: patientName ?? 'Patient',
            patientPhoto: patientPhoto,
            service: r.service,
            specialty: r.specialty,
            prix: r.prix,
            distance: distance,
            patientLocation: GeoPoint(r.patientLocation.latitude, r.patientLocation.longitude),
            paymentMethod: r.paymentMethod,
            notes: null,
            createdAt: r.createdAt,
            status: r.status,
          ));
        }

        if (mounted) {
          setState(() {
            _requests = requests;
            _loading = false;
          });
        }

        print('✅ [Provider Requests] Loaded ${requests.length} requests in real-time');
      } catch (e) {
        print('❌ [Provider Requests] Error processing requests: $e');
        if (mounted) setState(() => _loading = false);
      }
    }, onError: (error) {
      print('❌ [Provider Requests] Stream error: $error');
      if (mounted) setState(() => _loading = false);
    });
  }

  // removed unused _toDouble helper after refactor

  Future<void> _acceptRequest(RequestData request) async {
    setState(() => _processingRequestId = request.id);

    try {
      print('✅ [Provider Requests] Accepting request: ${request.id}');
      
      // Get provider current location (fallback to 0,0 if unavailable)
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (e) {
        print('⚠️ [Provider Requests] Could not get location: $e');
      }
      final providerGeo = GeoPoint(pos?.latitude ?? 0, pos?.longitude ?? 0);

      // Accept request and create appointment
      final appointmentId = await ProviderRequestService.acceptRequestAndCreateAppointment(
        requestId: request.id,
        providerLocation: providerGeo,
      );
      
      if (!mounted) return;
      
      print('🚀 [Provider Requests] Navigating to tracking with appointmentId: $appointmentId');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Request accepted! Navigating to appointment...')),
            ],
          ),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to tracking (replace so provider can't go back to requests)
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.tracking,
        arguments: {'appointmentId': appointmentId},
      );
    } catch (e) {
      print('❌ [Provider Requests] Error accepting request: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to accept: $e')),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
    }
  }

  Future<void> _declineRequest(RequestData request) async {
    setState(() => _processingRequestId = request.id);

    try {
      print('❌ [Provider Requests] Declining request: ${request.id}');
      
      // Update request status to declined
      await _firestore
          .collection('provider_requests')
          .doc(request.id)
          .update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 12),
              Text('Request declined'),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Reload requests to remove declined one
      _loadRequests();
    } catch (e) {
      print('❌ [Provider Requests] Error declining request: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to decline: $e')),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
    }
  }

  void _showRequestDetails(RequestData request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsBottomSheet(request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Incoming Requests',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _surfaceColor,
        elevation: 0,
        foregroundColor: _textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : _buildRequestsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: _primaryColor.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            const Text(
              'No new requests yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Stay available to receive instant appointments from patients.',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Refresh Button
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request, index);
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestData request, int index) {
    final isProcessing = _processingRequestId == request.id;

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
            onTap: () => _showRequestDetails(request),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar + Info + Status Badge
                  Row(
                    children: [
                      // Patient Avatar
                      Container(
                        width: 60,
                        height: 60,
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
                        ),
                        child: ClipOval(
                          child: request.patientPhoto != null &&
                                  request.patientPhoto!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: request.patientPhoto!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildAvatarFallback(request.patientName),
                                )
                              : _buildAvatarFallback(request.patientName),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Patient Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.patientName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.specialty != null
                                  ? '${request.service} • ${request.specialty}'
                                  : request.service,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _pendingColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: _pendingColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _pendingColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info Row: Price + Distance
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.payments,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${request.prix.toStringAsFixed(0)} DZD',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (request.distance != null) ...[
                        const SizedBox(width: 12),
                        // Distance
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _successColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: _successColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${request.distance!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

                  // Action Buttons
                  Row(
                    children: [
                      // Decline Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isProcessing ? null : () => _declineRequest(request),
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.close, size: 18),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _errorColor,
                            side: BorderSide(color: _errorColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Accept Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              isProcessing ? null : () => _acceptRequest(request),
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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

  Widget _buildAvatarFallback(String name) {
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.8),
            _primaryColor.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsBottomSheet(RequestData request) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header: Avatar + Name
                    Row(
                      children: [
                        Container(
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
                          ),
                          child: ClipOval(
                            child: request.patientPhoto != null &&
                                    request.patientPhoto!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: request.patientPhoto!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        _buildAvatarFallback(request.patientName),
                                  )
                                : _buildAvatarFallback(request.patientName),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.patientName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _pendingColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Pending Request',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _pendingColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Service Details
                    _buildDetailSection(
                      icon: Icons.medical_services,
                      title: 'Service Requested',
                      content: request.specialty != null
                          ? '${request.service}\n${request.specialty}'
                          : request.service,
                      color: _primaryColor,
                    ),

                    const SizedBox(height: 16),

                    // Price
                    _buildDetailSection(
                      icon: Icons.payments,
                      title: 'Price',
                      content: '${request.prix.toStringAsFixed(0)} DZD',
                      color: _primaryColor,
                    ),

                    const SizedBox(height: 16),

                    // Distance
                    if (request.distance != null)
                      _buildDetailSection(
                        icon: Icons.location_on,
                        title: 'Distance from Patient',
                        content: '${request.distance!.toStringAsFixed(1)} km away',
                        color: _successColor,
                      ),

                    const SizedBox(height: 16),

                    // Payment Method
                    _buildDetailSection(
                      icon: Icons.payment,
                      title: 'Payment Method',
                      content: request.paymentMethod,
                      color: _primaryColor,
                    ),

                    if (request.notes != null && request.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        icon: Icons.note,
                        title: 'Notes',
                        content: request.notes!,
                        color: _textSecondary,
                      ),
                    ],

                    if (request.createdAt != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        icon: Icons.access_time,
                        title: 'Requested At',
                        content: _formatDateTime(request.createdAt!),
                        color: _textSecondary,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        // Decline
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _declineRequest(request);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _errorColor,
                              side: BorderSide(color: _errorColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Accept
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _acceptRequest(request);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Accept Request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Data model for incoming requests
class RequestData {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientPhoto;
  final String service;
  final String? specialty;
  final double prix;
  final double? distance;
  final GeoPoint? patientLocation;
  final String paymentMethod;
  final String? notes;
  final DateTime? createdAt;
  final String status;

  RequestData({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientPhoto,
    required this.service,
    this.specialty,
    required this.prix,
    this.distance,
    this.patientLocation,
    required this.paymentMethod,
    this.notes,
    this.createdAt,
    required this.status,
  });
}
