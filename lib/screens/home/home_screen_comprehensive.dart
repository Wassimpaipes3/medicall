import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/top_doctors_section.dart';
import '../../widgets/navigation/material3_bottom_navigation.dart';
import '../../widgets/navigation/advanced_floating_nav.dart';
import '../chat/chat_screen.dart';
import '../appointments/appointment_screen.dart';
import '../profile/enhanced_profile_screen.dart';
import '../doctors/all_doctors_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggerController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _staggerAnimation;
  
  // State Variables
  int _selectedBottomIndex = 0;
  final PageController _pageController = PageController();
  final bool _useFloatingNav = true; // Toggle between navigation styles
  
  // Mock Data for Top Doctors
  final List<Map<String, dynamic>> _topDoctors = [
    {
      'id': 'dr_sarah',
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'rating': 4.9,
      'experience': '15 years',
      'avatar': 'assets/images/doctor1.png',
      'available': true,
      'consultationFee': 150,
      'reviews': 2847,
    },
    {
      'id': 'dr_ahmed',
      'name': 'Dr. Ahmed Hassan',
      'specialty': 'Neurologist', 
      'rating': 4.8,
      'experience': '12 years',
      'avatar': 'assets/images/doctor2.png',
      'available': true,
      'consultationFee': 200,
      'reviews': 1923,
    },
    {
      'id': 'dr_maria',
      'name': 'Dr. Maria Garcia',
      'specialty': 'Pediatrician',
      'rating': 4.9,
      'experience': '10 years',
      'avatar': 'assets/images/doctor3.png',
      'available': false,
      'consultationFee': 120,
      'reviews': 3156,
    },
    {
      'id': 'dr_james',
      'name': 'Dr. James Wilson',
      'specialty': 'Orthopedic',
      'rating': 4.7,
      'experience': '18 years',
      'avatar': 'assets/images/doctor4.png',
      'available': true,
      'consultationFee': 180,
      'reviews': 2234,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
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

    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutQuad,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Navigate to appropriate screen
    switch (index) {
      case 0:
        // Already on home, do nothing - just update the selected index
        break;
      case 1:
        // Navigate to Chat (index 1 = Chat)
        Navigator.push(
          context,
          _createRoute(const ChatScreen()),
        );
        break;
      case 2:
        // Navigate to Appointments (index 2 = Appointments)
        Navigator.push(
          context,
          _createRoute(const AppointmentScreen()),
        );
        break;
      case 3:
        // Navigate to Profile (index 3 = Profile)
        Navigator.push(
          context,
          _createRoute(const EnhancedProfileScreen()),
        );
        break;
    }
  }

  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _navigateToAllDoctors() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const AllDoctorsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _bookDoctor(Map<String, dynamic> doctor) {
    _navigateToBookingFlow(); // Use the new healthcare booking system
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            CustomAppBar(
              onNotificationTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        const NotificationsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
              fadeAnimation: _fadeAnimation,
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(),
                    
                    // Quick Stats Section
                    _buildQuickStatsSection(),
                    
                    // Top Doctors Section
                    TopDoctorsSection(
                      doctors: _topDoctors,
                      onViewAll: _navigateToAllDoctors,
                      onBookDoctor: _bookDoctor,
                      staggerAnimation: _staggerAnimation,
                    ),
                    
                    // Healthcare Booking Section - New comprehensive system
                    _buildHealthcareBookingSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Additional Content Section
                    _buildAdditionalContentSection(),
                    
                    // Bottom spacing for navigation bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar - Modern Floating Style
      bottomNavigationBar: _useFloatingNav ? null : Material3BottomNavigation(
        currentIndex: _selectedBottomIndex,
        onTap: _onBottomNavTapped,
      ),
      
      // Floating Navigation Bar
      floatingActionButtonLocation: _useFloatingNav 
          ? FloatingActionButtonLocation.centerFloat 
          : null,
      floatingActionButton: _useFloatingNav 
          ? AdvancedFloatingNavBar(
              currentIndex: _selectedBottomIndex,
              onTap: _onBottomNavTapped,
              items: DefaultNavigationItems.healthcare,
            )
          : null,
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.waving_hand,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Your health journey continues here',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
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
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsSection() {
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildStatCard(
                'Appointments',
                '12',
                Icons.calendar_today,
                AppTheme.primaryColor,
                0.0,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Doctors',
                '8',
                Icons.local_hospital,
                AppTheme.secondaryColor,
                0.2,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Reports',
                '24',
                Icons.assignment,
                Colors.green,
                0.4,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, double delay) {
    double animationValue = (_staggerAnimation.value - delay).clamp(0.0, 1.0);
    
    return Expanded(
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - animationValue)),
        child: Opacity(
          opacity: animationValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalContentSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Tips',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthTipCard(),
        ],
      ),
    );
  }

  Widget _buildHealthcareBookingSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big bold title to make it obvious
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.new_releases, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NEW: ALGERIA HEALTHCARE BOOKING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Healthcare Booking',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Book qualified healthcare professionals at your location',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildBookingCard(),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
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
                      'Professional Healthcare at Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Algeria-wide service with real-time tracking',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '• Distance-based pricing\n• Real-time tracking\n• Qualified professionals\n• Available across Algeria',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildServiceButton(
                  'Book Doctor',
                  Icons.local_hospital,
                  () => _navigateToBookingFlow(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceButton(
                  'Book Nurse',
                  Icons.health_and_safety,
                  () => _navigateToBookingFlow(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBookingFlow() {
    HapticFeedback.mediumImpact();
    
    // Debug: Show a dialog to confirm the button works
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Healthcare Booking'),
          content: Text('Navigation to Service Selection would happen here.\n\nFeatures:\n• Doctor/Nurse Selection\n• Algeria Location Map\n• Distance-based Pricing\n• Real-time Tracking'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try to navigate
                try {
                  Navigator.pushNamed(context, '/service-selection');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigation error: $e')),
                  );
                }
              },
              child: Text('Continue to Booking'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHealthTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Hydrated',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Drink at least 8 glasses of water daily for optimal health.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
