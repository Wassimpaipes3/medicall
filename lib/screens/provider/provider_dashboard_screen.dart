import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../models/provider/provider_model.dart';
import '../../services/provider_location_service.dart';

import '../../services/provider/provider_service.dart';
import '../../services/provider_auth_service.dart' as ProviderAuth;
import '../../services/provider_dashboard_service.dart' as DashboardService;
import '../../services/appointment_request_service.dart' as RequestService;
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../widgets/provider/availability_toggle.dart';
import '../../routes/app_routes.dart';

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
  List<RequestService.AppointmentRequest> _pendingRequests = [];  // NEW: Use appointment_requests service
  
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isStatusChanging = false;
  Timer? _statusTimer;
  
  // Dashboard stats
  DashboardService.DashboardStats? _dashboardStats;
  bool _isLoadingStats = true;
  
  // NEW: Upcoming appointments (replaces today's schedule)
  List<RequestService.UpcomingAppointment> _upcomingAppointments = [];
  bool _isLoadingAppointments = true;
  StreamSubscription<List<RequestService.UpcomingAppointment>>? _appointmentsSubscription;
  StreamSubscription<List<RequestService.AppointmentRequest>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProviderData(); // This now starts request and appointments streams
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
    _requestsSubscription?.cancel(); // ✅ Cancel requests stream
    _appointmentsSubscription?.cancel(); // ✅ Cancel appointments stream
    
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
      
      // ✅ Load real INSTANT requests only from appointment_requests collection  
      final providerId = providerProfile.uid; // Use uid instead of userId
      final requests = await RequestService.AppointmentRequestService.getProviderInstantRequests(providerId);
      
      print('DEBUG: Legacy provider loaded: $provider');
      print('DEBUG: Provider status: ${provider?.currentStatus}');
      print('📋 Loaded ${requests.length} INSTANT requests from appointment_requests collection');
      print('🔍 Provider ID used for query: $providerId');
      print('🔍 Provider name: ${providerProfile.fullName}');
      
      // Debug: Print each request for debugging
      for (int i = 0; i < requests.length; i++) {
        final request = requests[i];
        print('   Request $i: ${request.patientName} - ${request.service} - ${request.status}');
      }
      
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
        
        // Start real-time updates
        _startRequestsStream(providerId);
        _startAppointmentsStream(providerId);
        
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

  /// Start listening to real-time pending requests updates
  void _startRequestsStream(String providerId) {
    _requestsSubscription = RequestService.AppointmentRequestService
        .getProviderInstantRequestsStream(providerId)
        .listen(
      (requests) {
        if (mounted) {
          setState(() {
            _pendingRequests = requests;
          });
          print('📋 STREAM UPDATE: INSTANT requests updated: ${requests.length} requests');
          for (int i = 0; i < requests.length; i++) {
            final request = requests[i];
            print('   Stream Request $i: ${request.patientName} - ${request.service} - Type: ${request.type}');
          }
        }
      },
      onError: (error) {
        print('❌ Error in instant requests stream: $error');
      },
    );
  }

  /// Start listening to real-time upcoming appointments updates
  void _startAppointmentsStream(String providerId) {
    _appointmentsSubscription = RequestService.AppointmentRequestService
        .getProviderUpcomingAppointmentsStream(providerId)
        .listen(
      (appointments) {
        if (mounted) {
          setState(() {
            _upcomingAppointments = appointments;
            _isLoadingAppointments = false;
          });
          print('📅 Upcoming appointments updated: ${appointments.length} appointments');
        }
      },
      onError: (error) {
        print('❌ Error in appointments stream: $error');
        if (mounted) {
          setState(() {
            _isLoadingAppointments = false;
          });
        }
      },
    );
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
              
              // Notification Bell Icon with Unread Badge
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('destinataire', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data?.docs.length ?? 0;
                  
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Navigate to notifications screen
                          Navigator.pushNamed(context, '/notifications');
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: Colors.grey.shade600,
                          size: 26,
                        ),
                      ),
                      // Unread badge
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
          
          // Active Requests Section (replaces Requests button)
          _buildActiveRequestsSection(),
          const SizedBox(height: 24),
          
          // Upcoming Appointments Section (shows future scheduled appointments)
          _buildTodayScheduleSection(),
          const SizedBox(height: 24),
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

  // Fetch user profile data from users collection
  Future<Map<String, String?>> _getUserProfile(String userId) async {
    try {
      print('🔍 Dashboard: Fetching profile for user: $userId');
      
      // Query users collection for patient data  
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        print('✅ Dashboard: Found user profile: ${data['nom']} ${data['prenom']}');
        return {
          'name': '${data['nom'] ?? ''} ${data['prenom'] ?? ''}'.trim(),
          'photo': data['photo_profile'] as String?,
        };
      }
      
      print('❌ Dashboard: No profile found for user: $userId');
      return {'name': null, 'photo': null};
      
    } catch (e) {
      print('❌ Dashboard: Error fetching user profile: $e');
      return {'name': null, 'photo': null};
    }
  }

  /// Build earnings trend chart widget
  Widget _buildEarningsTrend() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earnings Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton.icon(
                onPressed: () => _navigateToAnalytics('earnings'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Simple bar chart visualization using containers
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('professionnelId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                .where('etat', whereIn: ['confirmé', 'terminé'])
                .orderBy('dateRendezVous', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading chart',
                      style: TextStyle(color: Colors.grey.shade600)),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Calculate last 7 days earnings
              final Map<int, double> weeklyEarnings = {};
              final now = DateTime.now();
              
              // Initialize last 7 days
              for (int i = 6; i >= 0; i--) {
                final date = now.subtract(Duration(days: i));
                final dayKey = date.day;
                weeklyEarnings[dayKey] = 0.0;
              }

              // Aggregate earnings by day
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final dateRendezVous = (data['dateRendezVous'] as Timestamp?)?.toDate();
                final tarif = (data['tarif'] as num?)?.toDouble() ?? 100.0;
                
                if (dateRendezVous != null) {
                  final daysDiff = now.difference(dateRendezVous).inDays;
                  if (daysDiff >= 0 && daysDiff < 7) {
                    final dayKey = dateRendezVous.day;
                    weeklyEarnings[dayKey] = (weeklyEarnings[dayKey] ?? 0) + tarif;
                  }
                }
              }

              final maxEarning = weeklyEarnings.values.isEmpty 
                  ? 100.0 
                  : weeklyEarnings.values.reduce((a, b) => a > b ? a : b);
              
              if (maxEarning == 0) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No earnings data yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final date = now.subtract(Duration(days: 6 - index));
                    final dayKey = date.day;
                    final earnings = weeklyEarnings[dayKey] ?? 0.0;
                    final heightPercent = maxEarning > 0 ? earnings / maxEarning : 0.0;
                    
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Earnings amount
                            if (earnings > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '\$${earnings.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            // Bar
                            Container(
                              height: (heightPercent * 120).clamp(4.0, 120.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Day label
                            Text(
                              _getDayLabel(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Get short day label (Mon, Tue, etc.)
  String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
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
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
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

  /// Active Requests Section - replaces Requests button with expandable list
  Widget _buildActiveRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inbox_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          
          if (_pendingRequests.isEmpty)
            _buildEmptyRequestsState()
          else
            Column(
              children: [
                // Debug info
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Text(
                    'DEBUG: Found ${_pendingRequests.length} pending requests',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
                SizedBox(height: 8),
                
                // Show up to 3 requests
                ...(_pendingRequests.take(3).map((request) {
                  print('🎨 Rendering request card for: ${request.patientName}');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRequestCard(request),
                  );
                }).toList()),
                
                // View All button
                if (_pendingRequests.isNotEmpty)
                  const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, AppRoutes.providerIncomingRequests);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _pendingRequests.length > 3
                              ? 'View All ${_pendingRequests.length} Requests'
                              : 'View Details',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New instant appointment requests will appear here',
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

  Widget _buildRequestCard(RequestService.AppointmentRequest request) {
    print('🎨 Building request card for: ${request.patientName}');
    try {
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      request.service,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                  '${request.totalAmount} MAD',
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
                Icons.access_time_outlined,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.appointmentTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // View Details Button - Navigate to request page
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, AppRoutes.providerIncomingRequests);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text(
                'View Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('❌ Error building request card: $e');
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              'Error displaying appointment',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            Text(
              'Patient: ${request.patientName}',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  /// Upcoming Appointments Section - shows scheduled appointments for future dates
  Widget _buildTodayScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              if (_upcomingAppointments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_upcomingAppointments.length}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingAppointments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_upcomingAppointments.isEmpty)
            _buildEmptyScheduleState()
          else
            Column(
              children: _upcomingAppointments.map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScheduleCard(appointment),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Appointments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your schedule for today is clear',
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

  Widget _buildScheduleCard(RequestService.UpcomingAppointment appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appointment.isToday 
            ? Colors.green.withOpacity(0.05)
            : appointment.isTomorrow
                ? Colors.blue.withOpacity(0.05)
                : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appointment.isToday 
              ? Colors.green.withOpacity(0.3)
              : appointment.isTomorrow
                  ? Colors.blue.withOpacity(0.3)
                  : AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Time indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  appointment.appointmentTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Appointment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, String?>>(
                  future: _getUserProfile(appointment.patientId),
                  builder: (context, snapshot) {
                    String patientName = appointment.patientName;
                    if (snapshot.hasData && snapshot.data!['name'] != null) {
                      patientName = snapshot.data!['name']!;
                    }
                    
                    return Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appointment.service,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    appointment.relativeDate,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${appointment.prix.round()} MAD',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF43A047),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF2196F3);
      case 'confirmed':
      case 'confirmé':
        return AppTheme.primaryColor;
      case 'completed':
      case 'terminé':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }

  // Quick Actions removed - replaced with Active Requests and Today's Schedule sections

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

  /// Handle appointment request response (Accept or Reject)
  Future<void> _handleRequestResponse(String requestId, bool accept) async {
    try {
      // Find the request to get patient name
      final request = _pendingRequests.firstWhere(
        (req) => req.id == requestId,
        orElse: () => _pendingRequests.first,
      );

      if (accept) {
        // Show confirmation dialog for acceptance
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Accept Request'),
            content: Text(
              'Accept appointment request from ${request.patientName}?\n\n'
              'Date: ${request.formattedDate}\n'
              'Time: ${request.appointmentTime}\n'
              'Service: ${request.service}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Call service to accept request
        final success = await RequestService.AppointmentRequestService
            .acceptAppointmentRequest(requestId);

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('✅ Accepted appointment with ${request.patientName}'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          // Reload dashboard stats
          await _loadDashboardStats();

          // Navigate to appointments tab
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _handleNavigationTap(1);
          });
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to accept appointment request'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Show confirmation dialog for decline
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Decline Request'),
            content: Text(
              'Decline appointment request from ${request.patientName}?\n\n'
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Decline'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Call service to reject request
        final success = await RequestService.AppointmentRequestService
            .rejectAppointmentRequest(requestId);

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Declined appointment with ${request.patientName}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to decline appointment request'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error handling request response: $e');
      
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
