import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../core/services/call_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../controllers/navigation_controller.dart';
import '../../data/services/appointment_storage.dart';
import '../../widgets/chat/chat_navigation_helper.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../widgets/booking/LocationSelectionPage.dart';
import '../../widgets/booking/ProviderTrackingScreen.dart';
import '../doctors/all_doctors_screen.dart';
import '../notifications/notifications_screen.dart';
import '../patient/patient_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggerController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _staggerAnimation;
  
  // State Variables
  final PageController _pageController = PageController();
  
  // Services
  final NavigationController _navController = NavigationController();
  
  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Dynamic Stats
  int _appointmentCount = 0;
  int _doctorsCount = 0;
  
  // Firestore Streams
  Stream<QuerySnapshot>? _topDoctorsStream;
  Stream<int>? _doctorsCountStream;
  Stream<int>? _appointmentsCountStream;
  
  // Mock Data for Top Providers (fallback - doctors & nurses)
  final List<Map<String, dynamic>> _topDoctors = [
    {
      'id': 'dr_sarah',
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'rating': 4.9,
      'experience': '15 years',
      'avatar': 'assets/images/avatar.png',
      'available': true,
      'consultationFee': 150,
      'reviews': 2847,
      'location': 'Algiers',
      'address': 'Algiers Medical Center, Algiers, Algeria',
      'latitude': 36.7538,
      'longitude': 3.0588,
      'phone': '+213-21-123456',
    },
    {
      'id': 'dr_ahmed',
      'name': 'Dr. Ahmed Hassan',
      'specialty': 'Neurologist', 
      'rating': 4.8,
      'experience': '12 years',
      'avatar': 'assets/images/avatar.png',
      'available': true,
      'consultationFee': 200,
      'reviews': 1923,
      'location': 'Oran',
      'address': 'Oran Neurology Center, Oran, Algeria',
      'latitude': 35.6976,
      'longitude': -0.6187,
      'phone': '+213-41-234567',
    },
    {
      'id': 'dr_maria',
      'name': 'Dr. Maria Garcia',
      'specialty': 'Pediatrician',
      'rating': 4.9,
      'experience': '10 years',
      'avatar': 'assets/images/avatar.png',
      'available': false,
      'consultationFee': 120,
      'reviews': 3156,
      'location': 'Constantine',
      'address': 'Constantine Children Hospital, Constantine, Algeria',
      'latitude': 36.3650,
      'longitude': 6.6147,
      'phone': '+213-31-345678',
    },
    {
      'id': 'dr_james',
      'name': 'Dr. James Wilson',
      'specialty': 'Orthopedic',
      'rating': 4.7,
      'experience': '18 years',
      'avatar': 'assets/images/avatar.png',
      'available': true,
      'consultationFee': 180,
      'reviews': 2234,
      'location': 'Annaba',
      'address': 'Annaba Orthopedic Clinic, Annaba, Algeria',
      'latitude': 36.9000,
      'longitude': 7.7667,
      'phone': '+213-38-456789',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadAppointmentCount();
    _initializeFirestoreStreams();
    
    // Listen to navigation controller changes
    _navController.addListener(_onNavigationStateChanged);
    
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Reset navigation state when home screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navController.setCurrentIndex(0); // Set home as active
    });
  }
  
  void _initializeFirestoreStreams() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    // Stream for top doctors & nurses (top 5 by rating)
    // We'll need to enrich this with user data for profile images
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
    _appointmentsCountStream = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
    
    // Listen to doctors count
    _doctorsCountStream?.listen((count) {
      if (mounted) {
        setState(() {
          _doctorsCount = count;
        });
      }
    });
  }
  
  // Fetch user profile data to get photo_profile
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      print('Error fetching user profile for $userId: $e');
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh appointment count when app is resumed
      _loadAppointmentCount();
    }
  }
  
  void _onNavigationStateChanged() {
    if (mounted) {
      // Refresh appointment count when home tab is selected
      if (_navController.currentIndex == 0) {
        _loadAppointmentCount();
      }
    }
  }

  Future<void> _loadAppointmentCount() async {
    try {
      // Successfully cleared! Now comment out the clearing to prevent auto-clearing
      // await AppointmentStorage.clearAllAppointments();
      
      final appointments = await AppointmentStorage.getAllAppointments();
      if (mounted) {
        setState(() {
          _appointmentCount = appointments.length;
        });
      }
      print('DEBUG: Appointment count updated to: $_appointmentCount');
    } catch (e) {
      print('Error loading appointment count: $e');
      // Keep default value of 0 on error
    }
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
    _navController.removeListener(_onNavigationStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    // Navigate directly to location selection since doctor is already chosen
    _navigateDirectToLocation(doctor);
  }

  void _chatWithDoctor(Map<String, dynamic> doctor) {
    // Use ChatNavigationHelper to navigate to the same chat interface as Messages tab
    ChatNavigationHelper.navigateToPatientChat(
      context: context,
      doctorInfo: doctor,
    );
  }

  void _callDoctor(Map<String, dynamic> doctor) {
    final phoneNumber = doctor['phone']?.toString() ?? '';
    if (phoneNumber.isNotEmpty) {
      CallService.makeCall(
        phoneNumber,
        context: context,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available for this doctor'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateDirectToLocation(Map<String, dynamic> doctor) {
    // Convert doctor specialty to ServiceType and Specialty
    ServiceType serviceType = ServiceType.doctor; // Since we're booking a doctor
    
    // Map doctor specialties to the appropriate Specialty enum
    Specialty specialty = _mapDoctorSpecialtyToEnum(doctor['specialty']);
    
    // Create LocationData based on doctor's location
    LocationData doctorLocation = LocationData(
      name: doctor['location'] ?? 'Doctor Location',
      address: doctor['address'] ?? '${doctor['location']}, Algeria',
      latitude: doctor['latitude'] ?? 36.7538, // Default to Algiers if not provided
      longitude: doctor['longitude'] ?? 3.0588, // Default to Algiers if not provided
    );
    
    // Generate a temporary appointment ID for tracking
    String appointmentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Navigate directly to tracking screen with the selected doctor
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProviderTrackingScreen(
              selectedService: serviceType,
              selectedSpecialty: specialty,
              selectedLocation: doctorLocation,
              appointmentId: appointmentId,
              preSelectedDoctor: doctor,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  Specialty _mapDoctorSpecialtyToEnum(String specialty) {
    // Map the doctor's specialty string to the Specialty enum
    switch (specialty.toLowerCase()) {
      case 'cardiologist':
        return Specialty.cardiology;
      case 'neurologist':
        return Specialty.neurology;
      case 'pediatrician':
        return Specialty.pediatrics;
      case 'orthopedic':
        return Specialty.orthopedics;
      default:
        return Specialty.generalMedicine; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomAppBar(
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
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(),
                      
                      // Quick Stats Section
                      _buildQuickStatsSection(),
                    
                    // Top Providers Section (Doctors & Nurses - Real-time Firestore)
                    _buildTopDoctorsSection(),
                    
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
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
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.secondaryColor.withOpacity(0.2),
                      ],
                    ),
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
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _buildStatCard(
                'Appointments',
                _appointmentCount.toString(),
                Icons.calendar_today,
                AppTheme.primaryColor,
                0.0,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Doctors',
                _doctorsCount.toString(),
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
                  style: TextStyle(
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
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Tips',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
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
      margin: const EdgeInsets.symmetric(vertical: 20),
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
          SizedBox(
            width: double.infinity,
            child: _buildServiceButton(
              'Book Healthcare Professional',
              Icons.medical_services_rounded,
              () => _navigateToBookingFlow(),
            ),
          ),
          const SizedBox(height: 12),
          // Test Notification Button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientRequestScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Test Notification System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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

  Widget _buildTopDoctorsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _topDoctorsStream,
      builder: (context, snapshot) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Providers',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: _navigateToAllDoctors,
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Loading/Error/Data States
              if (!snapshot.hasData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else if (snapshot.hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error loading doctors: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (snapshot.data!.docs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No doctors available',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final doctorData = doc.data() as Map<String, dynamic>;
                      print('DEBUG: Doctor card data for ${doctorData['name']}: $doctorData');
                      return _buildDoctorCard(doctorData, doc.id);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFallbackAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 40,
        color: AppTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildDoctorCard(Map<String, dynamic> doctor, String doctorId) {
    // Handle actual Firestore field names from your database
    final userId = doctor['id_user'] as String?;
    
    // Get specialty from professionals collection
    final specialty = doctor['specialite'] 
        ?? doctor['service']
        ?? doctor['specialization'] 
        ?? doctor['specialty']
        ?? 'General';
    
    final profession = doctor['profession'] ?? 'medecin';
    final rating = ((doctor['rating'] ?? 0.0) is int) ? (doctor['rating'] as int).toDouble() : (doctor['rating'] ?? 0.0).toDouble();
    final experience = doctor['yearsOfExperience'] ?? doctor['experience'] ?? doctor['annees_experience'] ?? 5;
    final isOnline = doctor['disponible'] ?? doctor['isOnline'] ?? false;
    
    // The profile image will be fetched from users collection using id_user
    final profileImageFromDoc = doctor['photo_profile'] ?? doctor['profileImage'] ?? doctor['avatar'] ?? doctor['photoURL'] ?? doctor['photo'] ?? doctor['image_url'];
    
    // Validate image URL
    String? profileImage;
    if (profileImageFromDoc != null) {
      final imageStr = profileImageFromDoc.toString().trim();
      if (imageStr.isNotEmpty && imageStr != 'null') {
        profileImage = imageStr;
      }
    }
    
    // Format profession display
    String professionDisplay = profession;
    if (profession == 'medecin' || profession == 'doctor' || profession == 'docteur') {
      professionDisplay = 'Doctor';
    } else if (profession == 'infirmier' || profession == 'nurse') {
      professionDisplay = 'Nurse';
    }
    
    return GestureDetector(
      onTap: () => _showDoctorActionsBottomSheet(doctor),
      child: Container(
        width: 180,
        height: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Doctor Image with Rating Badge and Online Status
          Stack(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.secondaryColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  // If we have userId but no image in current doc, fetch from users collection
                  child: userId != null && profileImage == null
                      ? FutureBuilder<Map<String, dynamic>?>(
                          future: _getUserProfile(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            final userData = snapshot.data;
                            final userImage = userData?['photo_profile'];
                            
                            if (userImage != null && userImage.toString().trim().isNotEmpty) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Image.network(
                                  userImage.toString(),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ Image load error: $error (URL: $userImage)');
                                    return _buildFallbackAvatar();
                                  },
                                ),
                              );
                            }
                            
                            return _buildFallbackAvatar();
                          },
                        )
                      : profileImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: Image.network(
                                profileImage,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Image load error: $error (URL: $profileImage)');
                                  return _buildFallbackAvatar();
                                },
                              ),
                            )
                          : _buildFallbackAvatar(),
                ),
              ),
              // Rating Badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Online Status
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? Colors.green : Colors.grey).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 8),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Available' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Doctor Info Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name from users collection
                  userId != null
                      ? FutureBuilder<Map<String, dynamic>?>(
                          future: _getUserProfile(userId),
                          builder: (context, snapshot) {
                            // Get title prefix based on profession
                            final isNurse = profession.contains('nurse') || profession.contains('infirmier');
                            final titlePrefix = isNurse ? '' : 'Dr. ';
                            String displayName = '$titlePrefix${doctor['login'] ?? 'Professional'}';
                            
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              final userData = snapshot.data;
                              final nom = userData?['nom'] ?? '';
                              final prenom = userData?['prenom'] ?? '';
                              
                              if (nom.isNotEmpty && prenom.isNotEmpty) {
                                displayName = '$titlePrefix$prenom $nom';
                              } else if (nom.isNotEmpty) {
                                displayName = '$titlePrefix$nom';
                              } else if (prenom.isNotEmpty) {
                                displayName = '$titlePrefix$prenom';
                              }
                            }
                            
                            return Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        )
                      : Text(
                          '${profession.contains('nurse') || profession.contains('infirmier') ? '' : 'Dr. '}${doctor['login'] ?? 'Professional'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  const SizedBox(height: 4),
                  
                  // Profession Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profession.contains('nurse') || profession.contains('infirmier')
                              ? Icons.health_and_safety_rounded
                              : Icons.local_hospital_rounded,
                          size: 10,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          professionDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Specialty
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined, 
                          size: 11, 
                          color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          specialty,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Experience
                  Row(
                    children: [
                      Icon(Icons.work_outline_rounded, 
                          size: 11, 
                          color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 3),
                      Text(
                        '$experience years exp.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
  
  void _showDoctorActionsBottomSheet(Map<String, dynamic> doctor) {
    final userId = doctor['id_user'] as String?;
    final specialty = doctor['specialite'] ?? doctor['service'] ?? doctor['specialization'] ?? doctor['specialty'] ?? 'General';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fetch name from users collection
              userId != null
                  ? FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserProfile(userId),
                      builder: (context, snapshot) {
                        // Get title prefix based on profession
                        final isNurse = specialty.toLowerCase().contains('infirm') || 
                                       specialty.toLowerCase().contains('nurse') ||
                                       specialty.toLowerCase().contains('soins');
                        final titlePrefix = isNurse ? '' : 'Dr. ';
                        String displayName = '$titlePrefix${doctor['login'] ?? 'Professional'}';
                        
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          final userData = snapshot.data;
                          final nom = userData?['nom'] ?? '';
                          final prenom = userData?['prenom'] ?? '';
                          
                          if (nom.isNotEmpty && prenom.isNotEmpty) {
                            displayName = '$titlePrefix$prenom $nom';
                          } else if (nom.isNotEmpty) {
                            displayName = '$titlePrefix$nom';
                          } else if (prenom.isNotEmpty) {
                            displayName = '$titlePrefix$prenom';
                          }
                        }
                        
                        return Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    )
                  : Text(
                      '${specialty.toLowerCase().contains('infirm') || specialty.toLowerCase().contains('nurse') || specialty.toLowerCase().contains('soins') ? '' : 'Dr. '}${doctor['login'] ?? 'Professional'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              Text(
                specialty,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.medical_services, color: AppTheme.primaryColor),
                title: const Text('Book Appointment'),
                onTap: () {
                  Navigator.pop(context);
                  _bookDoctor(doctor);
                },
              ),
              ListTile(
                leading: Icon(Icons.chat, color: AppTheme.primaryColor),
                title: const Text('Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _chatWithDoctor(doctor);
                },
              ),
              ListTile(
                leading: Icon(Icons.phone, color: AppTheme.primaryColor),
                title: const Text('Call'),
                onTap: () {
                  Navigator.pop(context);
                  _callDoctor(doctor);
                },
              ),
            ],
          ),
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
