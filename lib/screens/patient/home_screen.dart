import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../widgets/patient/patient_navigation_bar.dart';
import '../../core/theme.dart';
import '../../debug/quick_provider_check.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late AnimationController _bounceController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  
  // State Variables
  final TextEditingController _searchController = TextEditingController();
  int _selectedBottomIndex = 0;
  bool _nursingLevelExpanded = false;
  
  // Mock Data
  final List<Map<String, dynamic>> _topMedicalStaff = [
    {
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'rating': 4.9,
      'avatar': 'assets/images/doctor1.png',
      'available': true,
    },
    {
      'name': 'Nurse Lisa Chen',
      'specialty': 'Critical Care',
      'rating': 4.8,
      'avatar': 'assets/images/nurse1.png',
      'available': true,
    },
    {
      'name': 'Dr. Ahmed Hassan',
      'specialty': 'General Medicine',
      'rating': 4.7,
      'avatar': 'assets/images/doctor2.png',
      'available': false,
    },
    {
      'name': 'Nurse Maria Garcia',
      'specialty': 'Pediatric Care',
      'rating': 4.9,
      'avatar': 'assets/images/nurse2.png',
      'available': true,
    },
  ];
  
  final List<Map<String, dynamic>> _healthUpdates = [
    {
      'type': 'appointment',
      'title': 'Upcoming Checkup',
      'subtitle': 'Dr. Johnson - Tomorrow 2:00 PM',
      'icon': Icons.calendar_today_rounded,
      'color': AppTheme.primaryColor,
    },
    {
      'type': 'medication',
      'title': 'Medication Reminder',
      'subtitle': 'Blood pressure medication - Due in 2 hours',
      'icon': Icons.medication_rounded,
      'color': AppTheme.medicalOrange,
    },
    {
      'type': 'health_tip',
      'title': 'Daily Health Tip',
      'subtitle': 'Stay hydrated - Drink 8 glasses of water daily',
      'icon': Icons.lightbulb_outline_rounded,
      'color': AppTheme.secondaryColor,
    },
    {
      'type': 'test_result',
      'title': 'Lab Results Available',
      'subtitle': 'Blood test results from last week',
      'icon': Icons.assignment_turned_in_rounded,
      'color': AppTheme.medicalPurple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Main animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Animation definitions
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    
    // Stagger staff animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _staggerController.forward();
    });
    
    // Bounce animation for staff cards
    Future.delayed(const Duration(milliseconds: 500), () {
      _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    _bounceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(int index) {
    // Handle navigation based on index
    switch (index) {
      case 0: // Home - already on home screen
        break;
      case 1: // Appointments
        Navigator.pushNamed(context, AppRoutes.appointments);
        break;
      case 2: // Messages
        Navigator.pushNamed(context, AppRoutes.chatPage);
        break;
      case 3: // Profile
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  Future<void> _testProviderAccess() async {
    print('\n🔍 TESTING PROVIDER ACCESS FROM HOME SCREEN');
    
    try {
      // Quick check first
      await checkProviders();
      
      final firestore = FirebaseFirestore.instance;
      
      // Test 1: Basic collection access
      print('📊 Testing basic providers collection access...');
      final providersCollection = firestore.collection('professionals');
      final snapshot = await providersCollection.limit(5).get();
      print('   Found ${snapshot.docs.length} providers total');
      
      // Test 2: Available providers with strict filter
      print('🔍 Testing strict disponible=true filter...');
      final availableQuery = providersCollection.where('disponible', isEqualTo: true);
      final availableSnapshot = await availableQuery.get();
      print('   Found ${availableSnapshot.docs.length} disponible=true providers');
      
      // Test 3: Flexible boolean matching
      print('🔄 Testing flexible boolean matching...');
      final flexibleQuery = providersCollection.where('disponible', whereIn: [true, 'true', 1, '1']);
      final flexibleSnapshot = await flexibleQuery.get();
      print('   Found ${flexibleSnapshot.docs.length} providers with flexible boolean');
      
      // Test 4: Show all provider data
      print('📋 Analyzing provider data...');
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        print('   Provider ${i + 1}: ${doc.id}');
        print('     disponible: ${data['disponible']} (${data['disponible'].runtimeType})');
        print('     name: ${data['name']}');
        print('     services: ${data['services']}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug complete! Found ${availableSnapshot.docs.length} available providers. Check console for details.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      print('❌ Error testing provider access: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nursing Level Indicator
                      _buildNursingLevelIndicator(),
                      
                      // Search Bar
                      _buildSearchBar(),
                      
                      // Top Doctors & Nurses Section
                      _buildTopMedicalStaff(),
                      
                      // Health Updates List
                      _buildHealthUpdatesList(),

                      const SizedBox(height: 16),
                      // Move the booking CTA into the scrollable content so it doesn't overlap the bottom nav
                      _buildBookNowButton(),
                      const SizedBox(height: 100), // Space to keep it above the bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PatientNavigationBar(
        selectedIndex: _selectedBottomIndex,
        onTap: (index) {
          setState(() {
            _selectedBottomIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleBottomNavTap(index);
        },
        hasNotification: true, // You can make this dynamic based on actual notification state
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _testProviderAccess,
        backgroundColor: Colors.red,
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 106, // Increased from 80 to 106 for much lower positioning from top
        title: Row(
        children: [
          // Profile Picture
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Patient Name & Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, Sarah',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'How are you feeling today?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notification Icon with Badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textPrimaryColor,
                size: 24,
              ),
              onPressed: () {
                // Handle notification tap
                HapticFeedback.lightImpact();
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.medicalRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      ),
    );
  }

  Widget _buildNursingLevelIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _nursingLevelExpanded = !_nursingLevelExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level 2',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Text(
                      'Intermediate Care',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  
                  AnimatedRotation(
                    turns: _nursingLevelExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              
              // Progress Bar
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.6,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 4,
              ),
              
              // Expanded Details
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _nursingLevelExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'You are receiving intermediate nursing care. Regular monitoring and medication assistance are provided.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              // Could add search functionality here if needed
            });
          },
          decoration: InputDecoration(
            hintText: 'Search doctors, services, or records...',
            hintStyle: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        // Search cleared
                      });
                    },
                  )
                : Icon(
                    Icons.mic_rounded,
                    color: AppTheme.textSecondaryColor,
                    size: 20,
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTopMedicalStaff() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            children: [
              Icon(
                Icons.local_hospital_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Doctors & Nurses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(
          height: 180,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _topMedicalStaff.length,
            itemBuilder: (context, index) {
              final staff = _topMedicalStaff[index];
              
              return AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  double delay = index * 0.2;
                  double animationValue = (_staggerController.value - delay).clamp(0.0, 1.0);
                  
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - animationValue)),
                    child: Opacity(
                      opacity: animationValue,
                      child: ScaleTransition(
                        scale: _bounceAnimation,
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                // Handle staff selection
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor,
                                            AppTheme.secondaryColor,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Name
                                    Text(
                                      staff['name'],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 4),
                                    
                                    // Specialty
                                    Text(
                                      staff['specialty'],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Rating & Availability
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: AppTheme.medicalOrange,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          staff['rating'].toString(),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: staff['available'] 
                                                ? AppTheme.successColor 
                                                : AppTheme.medicalRed,
                                            shape: BoxShape.circle,
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
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthUpdatesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Health Updates',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _healthUpdates.length,
            itemBuilder: (context, index) {
              final update = _healthUpdates[index];
              
              return AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  double delay = index * 0.1 + 0.3;
                  double animationValue = (_staggerController.value - delay).clamp(0.0, 1.0);
                  
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - animationValue)),
                    child: Opacity(
                      opacity: animationValue,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              // Handle update tap
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: update['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      update['icon'],
                                      color: update['color'],
                                      size: 24,
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          update['title'],
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 4),
                                        
                                        Text(
                                          update['subtitle'],
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Arrow
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppTheme.textSecondaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLightColor,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => _handleBookNow(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Book an Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Navigation methods
  void _handleBookNow() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServiceSelectionPage()),
    );
  }
}
