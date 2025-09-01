import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/enhanced_theme.dart';
import '../../data/services/appointment_storage.dart';
import 'personal_information_screen.dart';
import 'medical_history_screen.dart';
import '../doctors/all_doctors_screen.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _userAppointments = [];

  // Enhanced user data
  final Map<String, dynamic> _userData = {
    'name': 'Wassim Ahmed',
    'email': 'wassim@healthcare.com',
    'phone': '+1 (555) 123-4567',
    'dateOfBirth': '1990-05-15',
    'bloodType': 'O+',
    'emergencyContact': '+1 (555) 987-6543',
    'address': '123 Healthcare St, Medical City',
    'insuranceProvider': 'HealthCare Plus Premium',
    'membershipTier': 'Gold Member',
    'joinDate': '2023-01-15',
  };

  final List<Map<String, dynamic>> _profileOptions = [
    {
      'icon': Icons.person_rounded,
      'title': 'Personal Information',
      'subtitle': 'Update your personal details',
      'color': Colors.blue,
      'hasNew': false,
    },
    {
      'icon': Icons.medical_information_rounded,
      'title': 'Medical History',
      'subtitle': 'View your medical records',
      'color': Colors.red,
      'hasNew': true,
    },
    {
      'icon': Icons.description_rounded,
      'title': 'Lab Reports',
      'subtitle': 'Access your test results',
      'color': Colors.green,
      'hasNew': false,
    },
    {
      'icon': Icons.shield_rounded,
      'title': 'Insurance Details',
      'subtitle': 'Manage your insurance info',
      'color': Colors.indigo,
      'hasNew': false,
    },
    {
      'icon': Icons.credit_card_rounded,
      'title': 'Payment Methods',
      'subtitle': 'Manage payment options',
      'color': Colors.orange,
      'hasNew': false,
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Notification Settings',
      'subtitle': 'Configure preferences',
      'color': Colors.purple,
      'hasNew': false,
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Privacy & Security',
      'subtitle': 'Security settings',
      'color': Colors.teal,
      'hasNew': false,
    },
    {
      'icon': Icons.help_center_rounded,
      'title': 'Help & Support',
      'subtitle': 'Get help and support',
      'color': Colors.grey,
      'hasNew': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserAppointments();
    _animationController.forward();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadUserAppointments() async {
    try {
      final appointments = await AppointmentStorage.getUpcomingAppointments();
      setState(() {
        _userAppointments = appointments;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Update Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: EnhancedAppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Capture with camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Colors.white),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Select from photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Use default avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Profile picture updated successfully! ⚡'),
              ],
            ),
            backgroundColor: EnhancedAppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile picture: $e'),
          backgroundColor: EnhancedAppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile picture removed'),
        backgroundColor: Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _logout() {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to login screen - replace with your login route
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    _logout(); // Call the existing logout method
  }

  void _navigateToOption(int index) {
    HapticFeedback.lightImpact();
    
    switch (index) {
      case 0: // Personal Information
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const PersonalInformationScreen(),
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
        break;
      case 1: // Medical History
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const MedicalHistoryScreen(),
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
        break;
      default:
        // Show coming soon for other features
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_profileOptions[index]['title']} - Coming Soon! ⚡'),
            backgroundColor: EnhancedAppTheme.primaryIndigo,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  void _viewAllDoctors() {
    // Navigate to all doctors screen
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

  Widget _buildProfileOptionCard(int index) {
    final option = _profileOptions[index];
    return GestureDetector(
      onTap: () => _navigateToOption(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: option['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    option['icon'],
                    color: option['color'],
                    size: 16,
                  ),
                ),
                if (option['hasNew'])
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              option['title'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              option['subtitle'],
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildProfileHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 30), // Reduced side padding, added top padding, increased bottom
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickStatsCards(),
                    const SizedBox(height: 24),
                    _buildUpcomingAppointments(),
                    const SizedBox(height: 24),
                    _buildProfileOptions(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverAppBar(
      expandedHeight: 220, // Increased from 200 to 220 for more space
      toolbarHeight: 110, // Increased from 84 to 110 for much lower positioning from top
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 18,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Show logout confirmation
            _showLogoutDialog();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.logout,
              color: Colors.red,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                EnhancedAppTheme.primaryIndigo.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20), // Further reduced from 30 to 20
                  Stack(
                  children: [
                    Container(
                      width: 85, // Further reduced from 100 to 85
                      height: 85, // Further reduced from 100 to 85
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: EnhancedAppTheme.primaryIndigo.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _profileImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(42.5), // Adjusted for new size
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(42.5), // Adjusted for new size
                              child: Image.asset(
                                'assets/images/avatar.png',
                                fit: BoxFit.cover,
                                width: 85,
                                height: 85,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to icon if image fails to load
                                  return const Icon(
                                    Icons.person_rounded,
                                    size: 42, // Reduced from 50 to 42
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 32, // Reduced from 36 to 32
                          height: 32, // Reduced from 36 to 32
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [EnhancedAppTheme.primaryPurple, Colors.green],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12 to 8
                Text(
                  _userData['name'],
                  style: const TextStyle(
                    fontSize: 20, // Reduced from 22 to 20
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 3 to 2
                Text(
                  _userData['membershipTier'],
                  style: TextStyle(
                    fontSize: 11, // Reduced from 12 to 11
                    fontWeight: FontWeight.w600,
                    color: EnhancedAppTheme.primaryIndigo,
                  ),
                ),
                const SizedBox(height: 4), // Reduced from 6 to 4
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Further reduced padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userData['email'],
                    style: const TextStyle(
                      fontSize: 11, // Further reduced from 12 to 11
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Appointments',
            count: _userAppointments.length.toString(),
            icon: Icons.calendar_month_rounded,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Health Score',
            count: '98%',
            icon: Icons.favorite_rounded,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Check-ups',
            count: '12',
            icon: Icons.medical_services_rounded,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16 to 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added to prevent unnecessary expansion
        children: [
          Container(
            width: 36, // Reduced from 40 to 36
            height: 36, // Reduced from 40 to 36
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18), // Reduced from 20 to 18
          ),
          const SizedBox(height: 6), // Reduced from 8 to 6
          Text(
            count,
            style: const TextStyle(
              fontSize: 16, // Reduced from 18 to 16
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4 to 2
          Flexible( // Added Flexible to handle text overflow
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10, // Reduced from 11 to 10
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_userAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No Upcoming Appointments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your next appointment to see it here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Appointments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _userAppointments.length > 2 ? 2 : _userAppointments.length,
          itemBuilder: (context, index) {
            final appointment = _userAppointments[index];
            return _buildAppointmentCard(appointment);
          },
        ),
        if (_userAppointments.length > 2)
          TextButton(
            onPressed: () {
              // Navigate to appointments screen
            },
            child: const Text('View All Appointments ⚡'),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14), // Reduced from 16 to 14
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Added to center align content
        children: [
          Container(
            width: 44, // Reduced from 48 to 44
            height: 44, // Reduced from 48 to 44
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 22, // Reduced from 24 to 22
            ),
          ),
          const SizedBox(width: 12), // Reduced from 16 to 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
                Text(
                  appointment['service'] ?? 'Medical Appointment',
                  style: const TextStyle(
                    fontSize: 15, // Reduced from 16 to 15
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1, // Added to prevent overflow
                  overflow: TextOverflow.ellipsis, // Added to handle overflow
                ),
                const SizedBox(height: 2), // Reduced from 4 to 2
                Text(
                  appointment['specialty'] ?? 'General',
                  style: TextStyle(
                    fontSize: 13, // Reduced from 14 to 13
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1, // Added to prevent overflow
                  overflow: TextOverflow.ellipsis, // Added to handle overflow
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            children: [
              Text(
                _formatAppointmentDate(appointment['date']),
                style: const TextStyle(
                  fontSize: 11, // Reduced from 12 to 11
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2), // Reduced from 4 to 2
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // Reduced from 12 to 8
                ),
                child: Text(
                  'Confirmed',
                  style: TextStyle(
                    fontSize: 9, // Reduced from 10 to 9
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (_profileOptions.length / 2).ceil(),
          itemBuilder: (context, rowIndex) {
            final leftIndex = rowIndex * 2;
            final rightIndex = leftIndex + 1;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Left card
                  Expanded(
                    child: _buildProfileOptionCard(leftIndex),
                  ),
                  const SizedBox(width: 12),
                  // Right card (if exists)
                  Expanded(
                    child: rightIndex < _profileOptions.length
                        ? _buildProfileOptionCard(rightIndex)
                        : Container(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: EnhancedAppTheme.primaryIndigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  title: 'View All\nDoctors',
                  icon: Icons.people_rounded,
                  onTap: _viewAllDoctors,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  title: 'Emergency\nContact',
                  icon: Icons.emergency_rounded,
                  onTap: () {
                    // Handle emergency contact
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAppointmentDate(String? dateStr) {
    if (dateStr == null) return 'TBD';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Tomorrow';
      if (difference < 7) return '${difference}d';
      
      return '${date.day}/${date.month}';
    } catch (e) {
      return 'TBD';
    }
  }
}
