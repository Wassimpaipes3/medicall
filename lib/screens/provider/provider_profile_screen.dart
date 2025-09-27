import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../core/theme.dart';
import '../../models/provider/provider_model.dart';
import '../../routes/app_routes.dart';
import '../../services/provider/provider_service.dart';
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../widgets/provider/availability_toggle.dart';
import '../../utils/responsive_button_layout.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  ProviderUser? _currentProvider;
  bool _isLoading = true;
  int _selectedIndex = 3; // Profile tab

  // Profile sections
  final List<Map<String, dynamic>> _profileOptions = [
    {
      'icon': Icons.person_rounded,
      'title': 'Personal Information',
      'subtitle': 'Update your professional details',
      'color': Colors.blue,
      'hasNew': false,
    },
    {
      'icon': Icons.medical_information_rounded,
      'title': 'Professional Credentials',
      'subtitle': 'Licenses, certifications, specialties',
      'color': Colors.red,
      'hasNew': false,
    },
    {
      'icon': Icons.schedule_rounded,
      'title': 'Working Hours',
      'subtitle': 'Set your availability schedule',
      'color': Colors.green,
      'hasNew': true,
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Earnings & Analytics',
      'subtitle': 'View income, reports, and analytics',
      'color': Colors.amber,
      'hasNew': false,
    },
    {
      'icon': Icons.location_on_rounded,
      'title': 'Service Areas',
      'subtitle': 'Manage coverage locations',
      'color': Colors.orange,
      'hasNew': false,
    },
    {
      'icon': Icons.payment_rounded,
      'title': 'Payment Settings',
      'subtitle': 'Bank accounts and pricing',
      'color': Colors.purple,
      'hasNew': false,
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Notification Preferences',
      'subtitle': 'Manage alerts and updates',
      'color': Colors.indigo,
      'hasNew': false,
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Privacy & Security',
      'subtitle': 'Account security settings',
      'color': Colors.teal,
      'hasNew': false,
    },
    {
      'icon': Icons.help_center_rounded,
      'title': 'Help & Support',
      'subtitle': 'Get help and contact support',
      'color': Colors.grey,
      'hasNew': false,
    },
    {
      'icon': Icons.logout_rounded,
      'title': 'Logout',
      'subtitle': 'Sign out of your account',
      'color': Colors.red,
      'hasNew': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProviderData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    try {
      final provider = await _providerService.getCurrentProvider();
      
      if (mounted) {
        setState(() {
          _currentProvider = provider;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile picture'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    _buildProfileHeader(),
                    _buildQuickStats(),
                    _buildAvailabilityToggle(),
                    _buildProfileOptions(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleNavigation(index);
        },
        hasNotification: false,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 30, 20, 20), // Added extra top margin
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              const Color(0xFF10B981),
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
            // Profile Picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(46),
                      child: _profileImage != null
                          ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Provider Info
            Text(
              _currentProvider?.fullName ?? 'Dr. Healthcare Provider',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentProvider?.specialty.toString().split('.').last.replaceAll('_', ' ').toUpperCase() ?? 'HEALTHCARE PROFESSIONAL',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentProvider?.specialty ?? 'Metro Area',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Rating',
                value: '4.8',
                subtitle: '127 reviews',
                icon: Icons.star,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Services',
                value: '28',
                subtitle: 'This month',
                icon: Icons.medical_services,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Earnings',
                value: '\$3.2K',
                subtitle: 'This month',
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Availability Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AvailabilityToggle(
              currentStatus: _currentProvider?.currentStatus ?? ProviderStatus.offline,
              onToggle: (isOnline) {
                final newStatus = isOnline ? ProviderStatus.online : ProviderStatus.offline;
                setState(() {
                  _currentProvider = _currentProvider?.copyWith(currentStatus: newStatus);
                });
                _updateProviderStatus(newStatus);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptions() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final option = _profileOptions[index];
            return _buildProfileOptionCard(option);
          },
          childCount: _profileOptions.length,
        ),
      ),
    );
  }

  Widget _buildProfileOptionCard(Map<String, dynamic> option) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () => _handleOptionTap(option['title']),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                option['color'].withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: option['color'].withOpacity(0.1),
              width: 1,
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
                      gradient: LinearGradient(
                        colors: [
                          option['color'].withOpacity(0.8),
                          option['color'],
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: option['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      option['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (option['hasNew'])
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              option['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              option['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _updateProviderStatus(ProviderStatus status) async {
    try {
      await _providerService.updateProviderStatus(status);
      
      String statusText = status.toString().split('.').last;
      statusText = statusText.replaceAll('_', ' ');
      statusText = statusText[0].toUpperCase() + statusText.substring(1).toLowerCase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to: $statusText'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleOptionTap(String title) {
    HapticFeedback.lightImpact();
    
    switch (title) {
      case 'Personal Information':
        _showPersonalInfoDialog();
        break;
      case 'Professional Credentials':
        _showCredentialsDialog();
        break;
      case 'Working Hours':
        _showWorkingHoursDialog();
        break;
      case 'Earnings & Analytics':
        Navigator.pushNamed(context, AppRoutes.providerEarnings);
        break;
      case 'Service Areas':
        _showServiceAreasDialog();
        break;
      case 'Payment Settings':
        _showPaymentSettingsDialog();
        break;
      case 'Notification Preferences':
        _showNotificationPreferencesDialog();
        break;
      case 'Privacy & Security':
        _showPrivacySecurityDialog();
        break;
      case 'Help & Support':
        _showHelpSupportDialog();
        break;
      case 'Logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showPersonalInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: _currentProvider?.fullName ?? '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: _currentProvider?.phoneNumber ?? '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: _currentProvider?.email ?? '',
              ),
            ),
          ],
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Personal information updated!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Save'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Professional Credentials'),
        content: const Text(
          'Manage your medical licenses, certifications, and professional qualifications.',
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Manage'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Working Hours'),
        content: const Text(
          'Set your availability schedule for different days of the week.',
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Configure'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showServiceAreasDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Areas'),
        content: const Text(
          'Define the geographical areas where you provide services.',
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Manage Areas'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showPaymentSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Settings'),
        content: const Text(
          'Configure your bank accounts, pricing, and payment preferences.',
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Configure'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showNotificationPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preferences'),
        content: const Text(
          'Manage how and when you receive notifications about appointments and messages.',
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Configure'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showPrivacySecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Manage your account security settings, password, and privacy preferences.',
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Manage'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get help with:'),
            const SizedBox(height: 8),
            const Text('• Account setup'),
            const Text('• Technical issues'),
            const Text('• Payment problems'),
            const Text('• General questions'),
            const SizedBox(height: 16),
            const Text('Contact: support@healthcare.com'),
            const Text('Phone: +1 (555) 123-HELP'),
          ],
        ),
        actions: [
          ResponsiveButtonLayout.adaptiveButtonRow(
            buttons: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Contact Support'),
              ),
            ],
            spacing: 8.0,
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.providerMessages);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.providerAppointments);
        break;
      case 3:
        // Already in profile
        break;
    }
  }

  void _showLogoutDialog() {
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
        content: const Text('Are you sure you want to logout from your provider account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
