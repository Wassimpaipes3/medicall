import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';
import '../../services/provider/provider_service.dart';
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../services/provider_request_service.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  List<AppointmentRequest> _pendingRequests = [];
  List<AppointmentRequest> _activeAppointments = [];
  List<AppointmentRequest> _completedAppointments = [];
  
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  Timer? _refreshTimer;

  final List<String> _tabTitles = ['Pending', 'Active', 'Completed'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAppointments();
    _startPeriodicRefresh();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      final pendingRequests = await _providerService.getPendingRequests();
      final activeAppointments = await _providerService.getActiveAppointments();
      final completedAppointments = await _providerService.getCompletedAppointments();

      if (mounted) {
        setState(() {
          _pendingRequests = pendingRequests;
          _activeAppointments = activeAppointments;
          _completedAppointments = completedAppointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _loadAppointments();
      }
    });
  }

  void _handleNavigationTap(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1: // Chat/Messages
        Navigator.pushReplacementNamed(context, AppRoutes.providerMessages);
        break;
      case 2: // Schedule/Appointments - already here
        // Already on appointments, do nothing
        break;
      case 3: // Profile
        Navigator.pushReplacementNamed(context, AppRoutes.providerProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    )
                  : AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _slideAnimation,
                          child: _buildTabContent(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: 2, // Schedule/Appointments tab
        onTap: (index) {
          if (index != 1) {
            _handleNavigationTap(index);
          }
        },
        hasNotification: _pendingRequests.isNotEmpty,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), // Added extra top padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Appointments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const Spacer(),
          
          // Refresh button
          IconButton(
            onPressed: _isLoading ? null : () {
              HapticFeedback.lightImpact();
              _loadAppointments();
            },
            icon: AnimatedRotation(
              turns: _isLoading ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Icon(
                Icons.refresh,
                color: _isLoading ? Colors.grey : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: TabController(
          length: _tabTitles.length,
          vsync: this,
          initialIndex: _selectedTabIndex,
        ),
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
          HapticFeedback.selectionClick();
        },
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: _tabTitles.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final count = index == 0
              ? _pendingRequests.length
              : index == 1
                  ? _activeAppointments.length
                  : _completedAppointments.length;

          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                if (count > 0 && index == 0) ...[
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    List<AppointmentRequest> currentList;
    Widget Function(AppointmentRequest) cardBuilder;

    switch (_selectedTabIndex) {
      case 0:
        currentList = _pendingRequests;
        cardBuilder = _buildPendingRequestCard;
        break;
      case 1:
        currentList = _activeAppointments;
        cardBuilder = _buildActiveAppointmentCard;
        break;
      case 2:
        currentList = _completedAppointments;
        cardBuilder = _buildCompletedAppointmentCard;
        break;
      default:
        currentList = [];
        cardBuilder = _buildPendingRequestCard;
    }

    if (currentList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: currentList.length,
        itemBuilder: (context, index) {
          return cardBuilder(currentList[index]);
        },
      ),
    );
  }

  Widget _buildPendingRequestCard(AppointmentRequest request) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppTheme.primaryColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      const Color(0xFF10B981),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      request.serviceType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Text(
                  '\$${request.estimatedFee}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Location and Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.patientLocationString,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est. ${request.estimatedDuration} minutes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '2.5 km away',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleRequestResponse(request.id, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRequestResponse(request.id, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAppointmentCard(AppointmentRequest appointment) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFF10B981).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'IN PROGRESS',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Patient Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      appointment.serviceType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${appointment.estimatedFee}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'Started',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openNavigation(appointment);
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openContactOptions(appointment);
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedAppointmentCard(AppointmentRequest appointment) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: const Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '${appointment.serviceType} • Completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${appointment.estimatedFee}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'Earned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;

    switch (_selectedTabIndex) {
      case 0:
        title = 'No Pending Requests';
        subtitle = 'New appointment requests will appear here';
        icon = Icons.inbox_outlined;
        break;
      case 1:
        title = 'No Active Appointments';
        subtitle = 'Your active appointments will be shown here';
        icon = Icons.schedule_outlined;
        break;
      case 2:
        title = 'No Completed Appointments';
        subtitle = 'Your completed appointments will be listed here';
        icon = Icons.history_outlined;
        break;
      default:
        title = 'No Data';
        subtitle = 'Nothing to show';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey.shade400,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequestResponse(String requestId, bool accept) async {
    HapticFeedback.mediumImpact();
    
    try {
      // If declining, keep existing local flow
      if (!accept) {
        final success = await _providerService.respondToRequest(requestId, false);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request declined'),
              backgroundColor: Colors.grey,
            ),
          );
          _loadAppointments();
        }
        return;
      }

      // Accepting: create appointment in Firestore and update provider_requests so the patient stream redirects
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accepting request...'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // Try to get provider current GPS position; fall back to 0,0 if not available
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (_) {}
      final providerGeo = GeoPoint(pos?.latitude ?? 0, pos?.longitude ?? 0);

      final appointmentId = await ProviderRequestService.acceptRequestAndCreateAppointment(
        requestId: requestId,
        providerLocation: providerGeo,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request accepted successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        
        // Refresh the list
        _loadAppointments();
        
        // Switch to active tab
        setState(() {
          _selectedTabIndex = 1;
        });
        
        // Navigate to tracking with the real appointmentId
        print('🚀 [AppointmentManagement] Navigating to tracking with appointmentId: $appointmentId');
        Navigator.of(context).pushNamed(AppRoutes.tracking, arguments: {
          'appointmentId': appointmentId,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openNavigation(dynamic appointment) {
    String address = appointment['patientAddress'] ?? 'Unknown Address';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navigation Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Navigate to: $address',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildNavigationOption(
                      icon: Icons.map_outlined,
                      title: 'Google Maps',
                      subtitle: 'Open in Google Maps',
                      onTap: () {
                        Navigator.pop(context);
                        _launchGoogleMaps(address);
                      },
                    ),
                    _buildNavigationOption(
                      icon: Icons.navigation_outlined,
                      title: 'Apple Maps',
                      subtitle: 'Open in Apple Maps',
                      onTap: () {
                        Navigator.pop(context);
                        _launchAppleMaps(address);
                      },
                    ),
                    _buildNavigationOption(
                      icon: Icons.copy_outlined,
                      title: 'Copy Address',
                      subtitle: 'Copy to clipboard',
                      onTap: () {
                        Navigator.pop(context);
                        _copyAddressToClipboard(address);
                      },
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

  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  void _launchGoogleMaps(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Google Maps for: $address'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement actual map launching with url_launcher
  }

  void _launchAppleMaps(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Apple Maps for: $address'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement actual map launching with url_launcher
  }

  void _copyAddressToClipboard(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement clipboard copy functionality
  }

  void _openContactOptions(dynamic appointment) {
    String patientName = appointment['patientName'] ?? 'Patient';
    String patientPhone = appointment['patientPhone'] ?? 'Not Available';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact $patientName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Phone: $patientPhone',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildContactOption(
                      icon: Icons.phone_outlined,
                      title: 'Call Patient',
                      subtitle: 'Make a voice call',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _makePhoneCall(patientPhone);
                      },
                    ),
                    _buildContactOption(
                      icon: Icons.message_outlined,
                      title: 'Send Message',
                      subtitle: 'Send SMS message',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _sendSMS(patientPhone);
                      },
                    ),
                    _buildContactOption(
                      icon: Icons.chat_outlined,
                      title: 'Open Chat',
                      subtitle: 'In-app messaging',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _openInAppChat(appointment);
                      },
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

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement actual phone call functionality with url_launcher
  }

  void _sendSMS(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening SMS for $phoneNumber...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement actual SMS functionality with url_launcher
  }

  void _openInAppChat(dynamic appointment) {
    Navigator.pushNamed(
      context,
      AppRoutes.providerMessages,
      arguments: {
        'patientId': appointment['patientId'],
        'patientName': appointment['patientName'],
      },
    );
  }
}
