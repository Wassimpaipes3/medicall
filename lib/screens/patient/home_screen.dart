import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../widgets/patient/patient_navigation_bar.dart';
import '../../core/theme.dart';
import '../../debug/quick_provider_check.dart';
import '../../debug/route_test_utility.dart';
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
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // State Variables
  final TextEditingController _searchController = TextEditingController();
  int _selectedBottomIndex = 0;
  
  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Real-time data streams
  Stream<QuerySnapshot>? _topDoctorsStream;
  Stream<int>? _doctorsCountStream;
  Stream<int>? _appointmentsCountStream;
  
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
    _initializeFirestoreStreams();
  }

  void _initializeFirestoreStreams() {
    // Stream for top 5 doctors & nurses ordered by rating
    _topDoctorsStream = _firestore
        .collection('professionals')
        .where('profession', whereIn: ['medecin', 'doctor', 'docteur', 'infirmier', 'nurse'])
        .orderBy('rating', descending: true)
        .limit(5)
        .snapshots();
    
    // Stream for total doctors count
    _doctorsCountStream = _firestore
        .collection('professionals')
        .where('profession', whereIn: ['medecin', 'doctor', 'docteur'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
    
    // Stream for user's appointments count
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      _appointmentsCountStream = _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: currentUserId)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    }
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
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    
    // Stagger staff animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "route_test",
            onPressed: () {
              RouteTestUtility.testRoutesConsistency(context);
              // Test navigation to tracking with sample ID
              RouteTestUtility.testTrackingNavigation(context, 'sample_test_123');
            },
            backgroundColor: Colors.blue,
            mini: true,
            child: const Icon(Icons.route, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "provider_test", 
            onPressed: _testProviderAccess,
            backgroundColor: Colors.red,
            child: const Icon(Icons.bug_report, color: Colors.white),
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            // Doctors Count
            Expanded(
              child: StreamBuilder<int>(
                stream: _doctorsCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem(
                    icon: Icons.medical_services_rounded,
                    label: 'Doctors',
                    value: count.toString(),
                    color: AppTheme.primaryColor,
                  );
                },
              ),
            ),
            
            Container(
              width: 1,
              height: 50,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            
            // Appointments Count
            Expanded(
              child: StreamBuilder<int>(
                stream: _appointmentsCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Appointments',
                    value: count.toString(),
                    color: AppTheme.secondaryColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: 11,
            ),
          ),
        ],
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
                'Top Providers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        
        StreamBuilder<QuerySnapshot>(
          stream: _topDoctorsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final doctors = snapshot.data!.docs;

            if (doctors.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No doctors available'),
                ),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctorData = doctors[index].data() as Map<String, dynamic>;
                  final name = doctorData['name'] ?? doctorData['fullName'] ?? 'Doctor';
                  final specialty = doctorData['specialization'] ?? doctorData['specialty'] ?? 'General';
                  final rating = (doctorData['rating'] ?? 0.0).toDouble();
                  final yearsExp = doctorData['yearsOfExperience'] ?? doctorData['experience'] ?? 0;
                  final isAvailable = doctorData['isOnline'] ?? false;
                  final profileImage = doctorData['profileImage'] ?? doctorData['avatar'];
              
                  return Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 16),
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
                          // Handle doctor selection
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar with availability indicator
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.secondaryColor,
                                            ],
                                          ),
                                        ),
                                        child: profileImage != null
                                            ? ClipOval(
                                                child: Image.network(
                                                  profileImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 25,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 25,
                                              ),
                                      ),
                                      if (isAvailable)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: AppTheme.successColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.medicalOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: AppTheme.medicalOrange,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.medicalOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Name
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Specialty
                              Text(
                                specialty,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Experience
                              Row(
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    size: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$yearsExp years exp',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Availability
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isAvailable 
                                          ? AppTheme.successColor 
                                          : AppTheme.textSecondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAvailable ? 'Available' : 'Offline',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isAvailable 
                                          ? AppTheme.successColor 
                                          : AppTheme.textSecondaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
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
                        'Book Healthcare Professional',
                        style: TextStyle(
                          fontSize: 17,
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
