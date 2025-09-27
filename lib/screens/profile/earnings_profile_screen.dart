import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../screens/provider/enhanced_earnings_screen.dart';

class EarningsProfileScreen extends StatefulWidget {
  const EarningsProfileScreen({super.key});

  @override
  State<EarningsProfileScreen> createState() => _EarningsProfileScreenState();
}

class _EarningsProfileScreenState extends State<EarningsProfileScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // User data (mock for now)
  final Map<String, dynamic> _userData = {
    'name': 'Dr. Sarah Johnson',
    'email': 'sarah.johnson@hospital.com',
    'phone': '+1 (555) 123-4567',
    'specialty': 'Cardiologist',
    'experience': '15 years',
    'license': 'MD-12345',
    'avatar': 'assets/images/doctor_avatar.png',
  };

  // Quick earnings data
  final Map<String, dynamic> _quickEarnings = {
    'todayEarnings': '\$450',
    'weekEarnings': '\$2,340',
    'monthEarnings': '\$9,850',
    'totalPatients': '47',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile & Earnings',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Profile',
            ),
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'Earnings',
            ),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildEarningsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          _buildQuickStatsSection(),
          
          const SizedBox(height: 24),
          
          // Profile Options
          _buildProfileOptions(),
          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return const EnhancedEarningsScreen();
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(47),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
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
          
          // Specialty
          Text(
            _userData['specialty'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Experience
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_userData['experience']} Experience',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                Icons.analytics_outlined,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Earnings Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Today',
                  _quickEarnings['todayEarnings'],
                  Icons.today_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'This Week',
                  _quickEarnings['weekEarnings'],
                  Icons.date_range_outlined,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'This Month',
                  _quickEarnings['monthEarnings'],
                  Icons.calendar_month_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Patients',
                  _quickEarnings['totalPatients'],
                  Icons.people_outline,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    final options = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Personal Information',
        'subtitle': 'Update your professional details',
        'color': Colors.blue,
        'route': '/personal-info',
      },
      {
        'icon': Icons.medical_information_outlined,
        'title': 'Professional Credentials',
        'subtitle': 'Licenses, certifications, specialties',
        'color': Colors.red,
        'route': '/credentials',
      },
      {
        'icon': Icons.schedule_rounded,
        'title': 'Working Hours',
        'subtitle': 'Set your availability schedule',
        'color': Colors.green,
        'route': '/working-hours',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Service Areas',
        'subtitle': 'Define your service locations',
        'color': Colors.orange,
        'route': '/service-areas',
      },
      {
        'icon': Icons.payment_outlined,
        'title': 'Payment Settings',
        'subtitle': 'Bank accounts and pricing',
        'color': Colors.purple,
        'route': '/payment-settings',
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Manage notification preferences',
        'color': Colors.teal,
        'route': '/notifications',
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Privacy & Security',
        'subtitle': 'Account security settings',
        'color': Colors.indigo,
        'route': '/privacy-security',
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'color': Colors.grey,
        'route': '/help-support',
      },
    ];

    return Column(
      children: options.map((option) => Container(
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
              _navigateToOption(option['route'] as String);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (option['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: option['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
      )).toList(),
    );
  }

  void _navigateToOption(String route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $route'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
