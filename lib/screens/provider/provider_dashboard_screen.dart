import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../models/provider/provider_model.dart';
import '../../services/provider_location_service.dart';

import '../../services/provider/provider_service.dart';
import '../../services/provider_auth_service.dart' as ProviderAuth;
import '../../services/provider_dashboard_service.dart' as DashboardService;
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../widgets/provider/availability_toggle.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_button_layout.dart';
import 'earnings_analytics_screen.dart';
import 'appointments_analytics_screen.dart';
import 'ratings_analytics_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  
  // Animation Controllers (matching patient side)
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;

  // Animations (matching patient side)
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  ProviderUser? _currentProvider;
  ProviderAuth.ProviderProfile? _currentProviderProfile; // New profile from professionals collection
  ProviderStatus _currentStatus = ProviderStatus.offline;
  List<AppointmentRequest> _pendingRequests = [];
  
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isStatusChanging = false;
  Timer? _statusTimer;
  
  // Dashboard stats
  DashboardService.DashboardStats? _dashboardStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProviderData();
    _startStatusUpdates();
    
    // 🆕 NEW: Initialize location tracking if provider is already online
    _initializeLocationTracking();
  }

  /// 🆕 NEW: Initialize location tracking based on current provider status
  Future<void> _initializeLocationTracking() async {
    try {
      print('🔍 Checking if provider should be tracking location...');
      
      // Check if provider is already available in Firestore
      final isAvailable = await ProviderLocationService.isProviderAvailable();
      
      if (isAvailable && _currentStatus == ProviderStatus.online) {
        print('🚀 Provider is online - starting location tracking');
        ProviderLocationService.startLocationUpdates();
      } else {
        print('📱 Provider is offline - location tracking not started');
      }
    } catch (e) {
      print('❌ Error initializing location tracking: $e');
    }
  }

  void _initializeAnimations() {
    // Fade animation for overall screen entry
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Slide animation for content entry
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse animation for status indicators
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Stagger controller for card animations
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize animations (matching patient side patterns)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    _statusTimer?.cancel();
    
    // 🆕 NEW: Stop location tracking when screen is disposed
    ProviderLocationService.dispose();
    
    super.dispose();
  }



  void _handleNavigationTap(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.providerMessages);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.providerAppointments);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.providerProfile);
        break;
    }
  }

  void _navigateToAnalytics(String type) {
    Widget screen;
    
    switch (type) {
      case 'earnings':
        screen = const EarningsAnalyticsScreen();
        break;
      case 'appointments':
        screen = const AppointmentsAnalyticsScreen();
        break;
      case 'ratings':
        screen = const RatingsAnalyticsScreen();
        break;
      default:
        return; // Invalid type, don't navigate
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _loadProviderData() async {
    print('DEBUG: _loadProviderData called');
    try {
      // Load provider profile from professionals collection
      final providerProfile = await ProviderAuth.ProviderAuthService.getCurrentProviderProfile();
      
      if (providerProfile == null) {
        print('DEBUG: No provider profile found or user is not a provider');
        // Redirect to login if not a valid provider
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/provider-login');
        }
        return;
      }
      
      print('DEBUG: Provider profile loaded: ${providerProfile.fullName}');
      print('DEBUG: Specialization: ${providerProfile.specialite}');
      
      // Load legacy provider service data for compatibility
      var provider = await _providerService.getCurrentProvider();
      
      // If no legacy provider data, try auto-login for testing
      if (provider == null) {
        print('DEBUG: No legacy provider found, auto-logging in for testing');
        final loginSuccess = await _providerService.loginProvider('test@provider.com', 'password');
        if (loginSuccess) {
          provider = await _providerService.getCurrentProvider();
          print('DEBUG: Auto-login successful');
        }
      }
      
      final requests = await _providerService.getPendingRequests();
      
      print('DEBUG: Legacy provider loaded: $provider');
      print('DEBUG: Provider status: ${provider?.currentStatus}');
      
      if (mounted) {
        setState(() {
          _currentProvider = provider;
          _currentProviderProfile = providerProfile; // Set the new profile
          _currentStatus = provider?.currentStatus ?? ProviderStatus.offline;
          _pendingRequests = requests;
          _isLoading = false;
        });
        
        // Load real dashboard statistics
        await _loadDashboardStats();
        
        print('DEBUG: State updated. Current status: $_currentStatus');
      }
    } catch (e) {
      print('DEBUG: Error loading provider data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      setState(() => _isLoadingStats = true);
      
      print('📊 Loading real dashboard statistics...');
      final stats = await DashboardService.ProviderDashboardService.getDashboardStats();
      
      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoadingStats = false;
        });
        print('✅ Dashboard stats loaded: ${stats.toString()}');
      }
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');
      if (mounted) {
        setState(() {
          _dashboardStats = const DashboardService.DashboardStats(
            todayEarnings: 0,
            completedTasks: 0,
            pendingTasks: 0,
            averageRating: 0.0,
          );
          _isLoadingStats = false;
        });
      }
    }
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentStatus == ProviderStatus.online) {
        _loadProviderData();
      }
    });
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
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  color: AppTheme.primaryColor,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildDashboardContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleNavigationTap(index);
        },
        hasNotification: _pendingRequests.isNotEmpty,
      ),
      // ✅ Cleanup button removed - collection will auto-recreate when needed
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
      child: Column(
        children: [
          Row(
            children: [
              // Profile Avatar
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
              
              // Provider Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      () {
                        final profession = _currentProviderProfile?.profession ?? _currentProvider?.specialty ?? '';
                        final isNurse = profession.toLowerCase().contains('infirm') || profession.toLowerCase().contains('nurse');
                        final prefix = isNurse ? '' : 'Dr. ';
                        final name = _currentProviderProfile?.fullName ?? _currentProvider?.fullName ?? "Provider";
                        return '$prefix$name';
                      }(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      _currentProviderProfile?.displaySpeciality.toUpperCase() ?? 
                      _currentProvider?.providerType.name.toUpperCase() ?? 'PROFESSIONNEL DE SANTÉ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_currentProviderProfile?.email.isNotEmpty == true)
                      Text(
                        _currentProviderProfile!.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Settings
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showSettingsBottomSheet();
                },
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Availability Toggle
          AvailabilityToggle(
            currentStatus: _currentStatus,
            isLoading: _isStatusChanging,
            onToggle: (isOnline) {
              print('DEBUG: Toggle callback called with isOnline: $isOnline');
              _handleStatusChange(isOnline ? ProviderStatus.online : ProviderStatus.offline);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          

          
          _buildActiveRequests(),
          const SizedBox(height: 24),
          _buildTodaySchedule(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingStats)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Earnings',
                  value: '\$${_dashboardStats?.todayEarnings ?? 0}',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF43A047),
                  onTap: () => _navigateToAnalytics('earnings'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Completed',
                  value: '${_dashboardStats?.completedTasks ?? 0}',
                  icon: Icons.check_circle,
                  color: const Color(0xFF1976D2),
                  onTap: () => _navigateToAnalytics('appointments'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Rating',
                  value: (_dashboardStats?.averageRating ?? 0.0).toStringAsFixed(1),
                  icon: Icons.star,
                  color: const Color(0xFFFF9800),
                  onTap: () => _navigateToAnalytics('ratings'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Pending',
                  value: '${_dashboardStats?.pendingTasks ?? 0}',
                  icon: Icons.schedule,
                  color: const Color(0xFFE53935),
                  onTap: () => _navigateToAnalytics('appointments'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequests() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Active Requests',
        subtitle: 'New appointment requests will appear here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Active Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const Spacer(),
            if (_pendingRequests.isNotEmpty)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
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
          ],
        ),
        const SizedBox(height: 16),
        
        ...(_pendingRequests.take(3).map((request) => _buildRequestCard(request)).toList()),
        
        if (_pendingRequests.length > 3)
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _handleNavigationTap(1); // Navigate to appointments/schedule
            },
            child: const Text('View All Requests'),
          ),
      ],
    );
  }

  Widget _buildRequestCard(AppointmentRequest request) {
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                      request.patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      request.serviceType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${request.estimatedFee}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.patientLocationString,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${request.estimatedDuration} min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons - Using responsive layout
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _handleRequestResponse(request.id, false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _handleRequestResponse(request.id, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            spacing: 12.0,
            minButtonWidth: 100.0,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'No Scheduled Appointments',
          subtitle: 'Your schedule for today is clear',
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Update Schedule',
                icon: Icons.schedule,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _handleNavigationTap(1); // Navigate to schedule/appointments
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'View Earnings',
                icon: Icons.analytics_outlined,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _handleNavigationTap(3); // Navigate to profile (which has earnings)
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Requests',
                icon: Icons.inbox_outlined,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.providerIncomingRequests);
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatusChange(ProviderStatus newStatus) async {
    print('DEBUG: _handleStatusChange called with $newStatus');
    
    if (_isStatusChanging) {
      print('DEBUG: Status already changing, ignoring');
      return; // Prevent multiple rapid taps
    }
    
    setState(() {
      _isStatusChanging = true;
    });

    print('DEBUG: Setting status to $newStatus');

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Update status with animation
      setState(() {
        _currentStatus = newStatus;
      });

      print('DEBUG: Calling backend service');
      // Call backend service
      await _providerService.updateProviderStatus(newStatus);
      
      // 🆕 NEW: Start/stop location tracking based on status
      if (newStatus == ProviderStatus.online) {
        print('🚀 Provider going online - starting location tracking');
        _loadProviderData(); // Refresh data when going online
        
                // Start real-time location tracking
        await ProviderLocationService.setProviderAvailability(true);
        ProviderLocationService.startLocationUpdates(); // Immediately start sharing location
        print('📍 Location tracking started successfully');
      } else {
        print('🛑 Provider going offline - stopping location tracking');
        
        // Stop real-time location tracking
        await ProviderLocationService.setProviderAvailability(false);
        print('📍 Location tracking stopped successfully');
      }

      print('DEBUG: Status change successful');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == ProviderStatus.online 
                      ? Icons.check_circle 
                      : Icons.power_settings_new,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus == ProviderStatus.online 
                        ? 'You are now online and sharing location!'
                        : 'You are now offline - location tracking stopped',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus == ProviderStatus.online 
                ? const Color(0xFF10B981) 
                : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert status on error
      setState(() {
        _currentStatus = newStatus == ProviderStatus.online 
            ? ProviderStatus.offline 
            : ProviderStatus.online;
      });

      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to update status. Please try again.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleStatusChange(newStatus),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStatusChanging = false;
        });
      }
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      'Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildSettingsOption(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.pop(context);
                        _handleNavigationTap(3); // Navigate to profile
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.pop(context);
                        _showNotificationSettings();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.schedule_outlined,
                      title: 'Working Hours',
                      onTap: () {
                        Navigator.pop(context);
                        _showWorkingHoursDialog();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.location_on_outlined,
                      title: 'Service Areas',
                      onTap: () {
                        Navigator.pop(context);
                        _showServiceAreasDialog();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        _showHelpDialog();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.logout,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutConfirmation();
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

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('New Appointments'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Messages'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Earnings Updates'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Working Hours'),
        content: Text('Configure your availability and working hours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showServiceAreasDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Service Areas'),
        content: Text('Manage the areas where you provide services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 16),
                SizedBox(width: 8),
                Text('support@medicall.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16),
                SizedBox(width: 8),
                Text('+1 (555) 123-4567'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/provider-login');
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    HapticFeedback.lightImpact();
    
    try {
      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Refreshing dashboard...'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Simulate API call delay
      await Future.delayed(Duration(seconds: 1));

      // Reload data
      await _loadProviderData();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Dashboard updated!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleRequestResponse(String requestId, bool accept) async {
    try {
      if (accept) {
        // Show confirmation dialog for acceptance
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Accept Request'),
            content: Text('Are you sure you want to accept this appointment request?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: Text('Accept'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // Remove request from pending list
          setState(() {
            _pendingRequests.removeWhere((req) => req.id == requestId);
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request accepted successfully!'),
                backgroundColor: const Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Navigate to appointment management
          _handleNavigationTap(1);
        }
      } else {
        // Show confirmation dialog for decline
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Decline Request'),
            content: Text('Are you sure you want to decline this appointment request?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Decline'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // Remove request from pending list
          setState(() {
            _pendingRequests.removeWhere((req) => req.id == requestId);
          });

          // Show feedback message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request declined'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
