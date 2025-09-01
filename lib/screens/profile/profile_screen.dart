import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User data (mock)
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@email.com',
    'phone': '+1 (555) 123-4567',
    'dateOfBirth': '1990-05-15',
    'bloodType': 'O+',
    'emergencyContact': '+1 (555) 987-6543',
    'address': '123 Main St, City, State 12345',
    'insuranceProvider': 'HealthCare Plus',
    'avatar': 'assets/images/user_avatar.png',
  };

  final List<Map<String, dynamic>> _profileOptions = [
    {
      'icon': Icons.person_outline_rounded,
      'title': 'Personal Information',
      'subtitle': 'Update your personal details',
      'color': Colors.blue,
      'route': '/personal-info',
    },
    {
      'icon': Icons.medical_information_outlined,
      'title': 'Medical History',
      'subtitle': 'View your medical records',
      'color': Colors.red,
      'route': '/medical-history',
    },
    {
      'icon': Icons.assignment_outlined,
      'title': 'Lab Reports',
      'subtitle': 'Access your test results',
      'color': Colors.green,
      'route': '/lab-reports',
    },
    {
      'icon': Icons.credit_card_rounded,
      'title': 'Payment Methods',
      'subtitle': 'Manage your payment options',
      'color': Colors.orange,
      'route': '/payment-methods',
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Notifications',
      'subtitle': 'Configure your preferences',
      'color': Colors.purple,
      'route': '/notification-settings',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Privacy & Security',
      'subtitle': 'Manage your privacy settings',
      'color': Colors.indigo,
      'route': '/privacy-security',
    },
    {
      'icon': Icons.help_outline_rounded,
      'title': 'Help & Support',
      'subtitle': 'Get help and contact support',
      'color': Colors.teal,
      'route': '/help-support',
    },
    {
      'icon': Icons.info_outline_rounded,
      'title': 'About',
      'subtitle': 'App version and information',
      'color': Colors.grey,
      'route': '/about',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToOption(String route) {
    // TODO: Implement navigation to respective screens
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $route'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 110, // Increased from 84 to 110 for much lower positioning from top
        titleSpacing: 8, // Added title spacing
        leading: IconButton(
          iconSize: 24, // Increased from 20 to 24
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22, // Increased from 18 to 22
            height: 1.2,
          ),
        ),
        actions: [
          IconButton(
            iconSize: 26, // Increased from 22 to 26
            icon: Icon(
              Icons.edit_rounded,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              // TODO: Navigate to edit profile
              _navigateToOption('/edit-profile');
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Main scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Updated to 16px horizontal padding
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          _buildQuickStats(),
                          _buildProfileOptions(),
                          const SizedBox(height: 40), // Spacing before bottom button
                        ],
                      ),
                    ),
                  ),
                  // Fixed logout button at bottom
                  _buildLogoutButton(),
                  const SizedBox(height: 20), // Bottom safe area padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 15, 10, 20), // Reduced side margins, added top margin
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
        children: [
          // Profile Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(47), // Slightly smaller to fit within border
                  child: Image.asset(
                    'assets/images/avatar.png',
                    fit: BoxFit.cover,
                    width: 94,
                    height: 94,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image fails to load
                      return const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User Name
          Text(
            _userData['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // User Email
          Text(
            _userData['email'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickInfo('Blood Type', _userData['bloodType']),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildQuickInfo('Age', '33 years'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildQuickInfo('Height', '5\'8"'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 20, 10, 15), // Reduced side margins, adjusted top/bottom
      child: Row(
        children: [
          _buildStatCard(
            'Appointments',
            '12',
            Icons.calendar_today_rounded,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Reports',
            '8',
            Icons.assignment_rounded,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Prescriptions',
            '24',
            Icons.medication_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
                fontSize: 20,
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
    );
  }

  Widget _buildProfileOptions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 20), // Reduced side margins
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12), // Increased spacing
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _profileOptions.length,
            itemBuilder: (context, index) {
              final option = _profileOptions[index];
              return _buildOptionCard(option, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToOption(option['route']);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: option['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option['icon'],
                    color: option['color'],
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        option['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10), // Increased side margins for fixed bottom button
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.mediumImpact();
              _logout();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}
