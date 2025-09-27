import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../models/provider/provider_model.dart';
import '../../services/provider/provider_service.dart';
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../routes/app_routes.dart';

class ProviderNavigationScreen extends StatefulWidget {
  const ProviderNavigationScreen({super.key});

  @override
  State<ProviderNavigationScreen> createState() => _ProviderNavigationScreenState();
}

class _ProviderNavigationScreenState extends State<ProviderNavigationScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  ProviderUser? _currentProvider;
  AppointmentRequest? _activeAppointment;
  List<AppointmentRequest> _pendingRequests = [];
  
  int _selectedIndex = 2; // Navigation tab
  bool _isLoading = true;
  bool _isNavigating = false;
  
  // Navigation data
  String _patientAddress = '';
  String _estimatedArrival = '';
  double _distanceToPatient = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProviderData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    try {
      final provider = await _providerService.getCurrentProvider();
      final requests = await _providerService.getPendingRequests();
      final activeAppointments = await _providerService.getActiveAppointments();
      
      if (mounted) {
        setState(() {
          _currentProvider = provider;
          _pendingRequests = requests;
          _activeAppointment = activeAppointments.isNotEmpty ? activeAppointments.first : null;
          _isLoading = false;
          
          // Mock navigation data
          if (_activeAppointment != null) {
            _patientAddress = _activeAppointment!.patientLocationString;
            _estimatedArrival = '12 min';
            _distanceToPatient = 2.3;
            _isNavigating = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildNavigationContent(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleNavigation(index);
        },
        hasNotification: _pendingRequests.isNotEmpty,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Icon(
            Icons.navigation,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Navigation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (_isNavigating)
                  Text(
                    'En route to patient',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isNavigating 
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isNavigating 
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              _isNavigating ? 'ACTIVE' : 'STANDBY',
              style: TextStyle(
                color: _isNavigating 
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationContent() {
    if (!_isNavigating || _activeAppointment == null) {
      return _buildNoActiveNavigation();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavigationMap(),
          const SizedBox(height: 24),
          _buildPatientInfo(),
          const SizedBox(height: 24),
          _buildNavigationStats(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildNoActiveNavigation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.grey.shade200, width: 2),
            ),
            child: Icon(
              Icons.location_searching,
              color: Colors.grey.shade400,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Active Navigation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Accept an appointment to start navigation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to appointments
              setState(() {
                _selectedIndex = 1;
              });
              _handleNavigation(1);
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('View Appointments'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMap() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey.shade200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Navigation Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time route to patient',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation controls overlay
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  _buildMapControl(Icons.my_location, 'Center'),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.zoom_in, 'Zoom In'),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.zoom_out, 'Zoom Out'),
                ],
              ),
            ),
            
            // ETA overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ETA: $_estimatedArrival',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_distanceToPatient.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon, String tooltip) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Handle map control action
        },
        borderRadius: BorderRadius.circular(8),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadows,
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
                      _activeAppointment?.patientName ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      _activeAppointment?.serviceType ?? 'Service',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
                ),
                child: Text(
                  '\$${_activeAppointment?.estimatedFee ?? 0}',
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
                      Icons.location_on,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _patientAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _activeAppointment?.patientPhone ?? '+1234567890',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Handle call patient
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.call,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Distance',
            value: '${_distanceToPatient.toStringAsFixed(1)} km',
            icon: Icons.route,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Arrival',
            value: _estimatedArrival,
            icon: Icons.schedule,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Duration',
            value: '${_activeAppointment?.estimatedDuration ?? 30} min',
            icon: Icons.timer,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Call Patient',
                icon: Icons.call,
                color: const Color(0xFF10B981),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Handle call patient
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Send Message',
                icon: Icons.message,
                color: AppTheme.primaryColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to chat
                  setState(() {
                    _selectedIndex = 3;
                  });
                  _handleNavigation(3);
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Open Maps',
                icon: Icons.map,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Open external maps app
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Update Status',
                icon: Icons.location_on,
                color: const Color(0xFFEF4444),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showStatusUpdateDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.directions_car, color: Color(0xFF10B981)),
              title: const Text('En Route'),
              onTap: () {
                Navigator.pop(context);
                _updateLocationStatus('En Route');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFFF59E0B)),
              title: const Text('Arrived'),
              onTap: () {
                Navigator.pop(context);
                _updateLocationStatus('Arrived');
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: AppTheme.primaryColor),
              title: const Text('Service Started'),
              onTap: () {
                Navigator.pop(context);
                _updateLocationStatus('Service Started');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateLocationStatus(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to: $status'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1: // Chat/Messages
        Navigator.pushReplacementNamed(context, AppRoutes.providerMessages);
        break;
      case 2: // Schedule/Appointments
        Navigator.pushReplacementNamed(context, AppRoutes.providerAppointments);
        break;
      case 3: // Profile
        Navigator.pushReplacementNamed(context, AppRoutes.providerProfile);
        break;
    }
  }
}
