import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';

class HomeScreenUpgraded extends StatefulWidget {
  const HomeScreenUpgraded({super.key});

  @override
  State<HomeScreenUpgraded> createState() => _HomeScreenUpgradedState();
}

class _HomeScreenUpgradedState extends State<HomeScreenUpgraded> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _staggerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  // State Variables
  final TextEditingController _searchController = TextEditingController();
  int _selectedBottomIndex = 0;
  bool _nursingLevelExpanded = false;
  
  // Enhanced Mock Data
  
  final List<Map<String, dynamic>> _topDoctors = [
    {
      'id': 'dr_sarah',
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'rating': 4.9,
      'experience': '15 years',
      'available': true,
      'avatar': 'assets/images/doctor1.png',
      'consultationFee': 150,
    },
    {
      'id': 'dr_ahmed',
      'name': 'Dr. Ahmed Hassan',
      'specialty': 'Neurologist',
      'rating': 4.8,
      'experience': '12 years',
      'available': true,
      'avatar': 'assets/images/doctor2.png',
      'consultationFee': 200,
    },
    {
      'id': 'dr_maria',
      'name': 'Dr. Maria Garcia',
      'specialty': 'Pediatrician',
      'rating': 4.9,
      'experience': '10 years',
      'available': false,
      'avatar': 'assets/images/doctor3.png',
      'consultationFee': 120,
    },
  ];
  
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'type': 'appointment',
      'title': 'Upcoming Appointment',
      'subtitle': 'Dr. Johnson - Tomorrow 2:00 PM',
      'time': '1 day',
      'icon': Icons.calendar_today_rounded,
      'color': AppTheme.primaryColor,
    },
    {
      'type': 'medication',
      'title': 'Medication Reminder',
      'subtitle': 'Blood pressure medication',
      'time': '2 hours',
      'icon': Icons.medication_rounded,
      'color': AppTheme.medicalOrange,
    },
    {
      'type': 'report',
      'title': 'Lab Results Ready',
      'subtitle': 'Blood test results available',
      'time': '3 hours',
      'icon': Icons.assignment_turned_in_rounded,
      'color': AppTheme.secondaryColor,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPeriodicAnimations();
  }

  void _initializeAnimations() {
    // Animation Controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Animation Definitions
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));
  }

  void _startPeriodicAnimations() {
    _fadeController.forward();
    _slideController.forward();
    
    // Start staggered animations with delays
    Future.delayed(const Duration(milliseconds: 300), () {
      _staggerController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _scaleController.forward();
    });
    
    // Repeating animations
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBody: true,
      appBar: _buildEnhancedAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Health Status Card
                SliverToBoxAdapter(child: _buildHealthStatusCard()),
                
                // Quick Actions Grid
                SliverToBoxAdapter(child: _buildQuickActionsGrid()),
                
                // Search Bar
                SliverToBoxAdapter(child: _buildAdvancedSearchBar()),
                
                // Top Doctors Section
                SliverToBoxAdapter(child: _buildTopDoctorsSection()),
                
                // Recent Activities
                SliverToBoxAdapter(child: _buildRecentActivities()),
                
                // Bottom spacing for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildEnhancedBottomNav(),
      floatingActionButton: _buildEnhancedBookButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                // Enhanced Profile Avatar
                GestureDetector(
                  onTap: () => _navigateToProfile(),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.white.withOpacity(0.9)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Enhanced Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Good ${_getTimeGreeting()}, Sarah! 👋',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready for your health journey?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Enhanced Notification Bell
                GestureDetector(
                  onTap: () => _navigateToNotifications(),
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _rotateAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value * 0.1,
                            child: child,
                          );
                        },
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _nursingLevelExpanded = !_nursingLevelExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.secondaryColor.withOpacity(0.1),
                AppTheme.primaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 20,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Level 2 Care',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Intermediate Care Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _nursingLevelExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Enhanced Progress Indicator
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                '65% Progress - Good Recovery',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Expandable Details
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 400),
                crossFadeState: _nursingLevelExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildHealthMetric('Next Checkup', 'Feb 25, 2025', Icons.event),
                      const SizedBox(height: 8),
                      _buildHealthMetric('Care Team', 'Dr. Johnson & Team', Icons.group),
                      const SizedBox(height: 8),
                      _buildHealthMetric('Recovery Goal', 'Full Recovery by Mar', Icons.flag),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final quickActions = [
      {'icon': Icons.emergency, 'title': 'Emergency', 'color': Colors.red, 'onTap': () => _navigateToEmergency()},
      {'icon': Icons.video_call, 'title': 'Video Call', 'color': Colors.blue, 'onTap': () => _navigateToVideoCall()},
      {'icon': Icons.local_pharmacy, 'title': 'Pharmacy', 'color': Colors.green, 'onTap': () => _navigateToPharmacy()},
      {'icon': Icons.assignment, 'title': 'Reports', 'color': Colors.purple, 'onTap': () => _navigateToReports()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _staggerAnimation,
        builder: (context, child) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              double delay = index * 0.1;
              double animationValue = (_staggerAnimation.value - delay).clamp(0.0, 1.0);
              
              return Transform.scale(
                scale: animationValue,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    action['onTap'] as VoidCallback;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (action['color'] as Color).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          size: 28,
                          color: action['color'] as Color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdvancedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search doctors, services, medicines...',
            hintStyle: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.mic_rounded,
                    color: AppTheme.textSecondaryColor,
                  ),
                  onPressed: () => _handleVoiceSearch(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: AppTheme.textSecondaryColor,
                  ),
                  onPressed: () => _showSearchFilters(),
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTopDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: AppTheme.secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Doctors',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToAllDoctors(),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _topDoctors.length,
          itemBuilder: (context, index) {
            final doctor = _topDoctors[index];
            return AnimatedBuilder(
              animation: _staggerAnimation,
              builder: (context, child) {
                double delay = index * 0.1 + 0.3;
                double animationValue = (_staggerAnimation.value - delay).clamp(0.0, 1.0);
                
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - animationValue)),
                  child: Opacity(
                    opacity: animationValue,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Doctor Avatar
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLightColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Doctor Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doctor['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: doctor['available'] 
                                            ? Colors.green 
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor['specialty'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber[600],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doctor['rating']} • ${doctor['experience']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${doctor['consultationFee']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Book Button
                          ElevatedButton(
                            onPressed: () => _bookDoctorAppointment(doctor),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.medicalOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: AppTheme.medicalOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _recentActivities.length,
          itemBuilder: (context, index) {
            final activity = _recentActivities[index];
            return AnimatedBuilder(
              animation: _staggerAnimation,
              builder: (context, child) {
                double delay = index * 0.1 + 0.5;
                double animationValue = (_staggerAnimation.value - delay).clamp(0.0, 1.0);
                
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - animationValue)),
                  child: Opacity(
                    opacity: animationValue,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: activity['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              activity['icon'],
                              color: activity['color'],
                              size: 24,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity['subtitle'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Text(
                            activity['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          currentIndex: _selectedBottomIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedBottomIndex = index;
            });
            _handleBottomNavTap(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondaryColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_selectedBottomIndex == 0 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _selectedBottomIndex == 0 
                      ? AppTheme.primaryColor.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedBottomIndex == 0 
                      ? Icons.home_rounded 
                      : Icons.home_outlined,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_selectedBottomIndex == 1 ? 8 : 4),
                    decoration: BoxDecoration(
                      color: _selectedBottomIndex == 1 
                          ? AppTheme.primaryColor.withOpacity(0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedBottomIndex == 1 
                          ? Icons.chat_rounded 
                          : Icons.chat_outlined,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_selectedBottomIndex == 2 ? 8 : 4),
                    decoration: BoxDecoration(
                      color: _selectedBottomIndex == 2 
                          ? AppTheme.primaryColor.withOpacity(0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedBottomIndex == 2 
                          ? Icons.calendar_today_rounded 
                          : Icons.calendar_today_outlined,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.medicalOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_selectedBottomIndex == 3 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _selectedBottomIndex == 3 
                      ? AppTheme.primaryColor.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedBottomIndex == 3 
                      ? Icons.person_rounded 
                      : Icons.person_outline_rounded,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBookButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryLightColor,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(37.5),
            onTap: () {
              HapticFeedback.heavyImpact();
              _navigateToBooking();
            },
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Utility Methods
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      // Refresh data here
    });
  }

  // Navigation Methods
  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _navigateToEmergency() {
    Navigator.pushNamed(context, '/emergency');
  }

  void _navigateToVideoCall() {
    Navigator.pushNamed(context, '/video-call');
  }

  void _navigateToPharmacy() {
    Navigator.pushNamed(context, '/pharmacy');
  }

  void _navigateToReports() {
    Navigator.pushNamed(context, '/reports');
  }

  void _navigateToAllDoctors() {
    Navigator.pushNamed(context, AppRoutes.doctors);
  }

  void _bookDoctorAppointment(Map<String, dynamic> doctor) {
    Navigator.pushNamed(context, '/book-appointment', arguments: doctor);
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServiceSelectionPage()),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/chatPage');
        break;
      case 2:
        Navigator.pushNamed(context, '/schedule');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void _handleVoiceSearch() {
    // Implement voice search functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voice search activated'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Filters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Add filter options here
            const Text('Filter options coming soon...'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
