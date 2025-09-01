import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Doctors',
    'Nurses',
    'Specialists',
    'Emergency',
  ];

  final List<Map<String, dynamic>> _medicalStaff = [
    // Doctors
    {
      'id': '1',
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'type': 'Doctor',
      'rating': 4.9,
      'experience': '15 years',
      'location': 'Cardiology Wing, Floor 2',
      'availability': 'Available Now',
      'image': null,
      'phone': '+1 (555) 123-4567',
      'email': 'sarah.johnson@hospital.com',
      'languages': ['English', 'Spanish'],
      'education': 'MD from Harvard Medical School',
      'isOnline': true,
      'nextSlot': '10:30 AM',
      'consultationFee': '\$150',
    },
    {
      'id': '2',
      'name': 'Dr. Michael Chen',
      'specialty': 'Neurologist',
      'type': 'Doctor',
      'rating': 4.8,
      'experience': '12 years',
      'location': 'Neurology Department',
      'availability': 'Busy',
      'image': null,
      'phone': '+1 (555) 234-5678',
      'email': 'michael.chen@hospital.com',
      'languages': ['English', 'Mandarin'],
      'education': 'MD from Johns Hopkins',
      'isOnline': false,
      'nextSlot': '2:15 PM',
      'consultationFee': '\$180',
    },
    {
      'id': '3',
      'name': 'Dr. Emily Rodriguez',
      'specialty': 'Pediatrician',
      'type': 'Doctor',
      'rating': 4.9,
      'experience': '10 years',
      'location': 'Pediatrics Wing',
      'availability': 'Available Now',
      'image': null,
      'phone': '+1 (555) 345-6789',
      'email': 'emily.rodriguez@hospital.com',
      'languages': ['English', 'Spanish', 'French'],
      'education': 'MD from UCLA Medical School',
      'isOnline': true,
      'nextSlot': '11:00 AM',
      'consultationFee': '\$120',
    },
    // Nurses
    {
      'id': '4',
      'name': 'Nurse Lisa Thompson',
      'specialty': 'ICU Nurse',
      'type': 'Nurse',
      'rating': 4.7,
      'experience': '8 years',
      'location': 'ICU, Floor 3',
      'availability': 'On Duty',
      'image': null,
      'phone': '+1 (555) 456-7890',
      'email': 'lisa.thompson@hospital.com',
      'languages': ['English'],
      'education': 'BSN from State University',
      'isOnline': true,
      'nextSlot': 'On Call',
      'consultationFee': 'Covered',
    },
    {
      'id': '5',
      'name': 'Nurse David Park',
      'specialty': 'Emergency Nurse',
      'type': 'Nurse',
      'rating': 4.8,
      'experience': '6 years',
      'location': 'Emergency Department',
      'availability': 'On Duty',
      'image': null,
      'phone': '+1 (555) 567-8901',
      'email': 'david.park@hospital.com',
      'languages': ['English', 'Korean'],
      'education': 'BSN from Medical University',
      'isOnline': true,
      'nextSlot': 'On Call',
      'consultationFee': 'Covered',
    },
    // Specialists
    {
      'id': '6',
      'name': 'Dr. Amanda Wilson',
      'specialty': 'Dermatologist',
      'type': 'Specialist',
      'rating': 4.9,
      'experience': '14 years',
      'location': 'Dermatology Clinic',
      'availability': 'Available Tomorrow',
      'image': null,
      'phone': '+1 (555) 678-9012',
      'email': 'amanda.wilson@hospital.com',
      'languages': ['English', 'German'],
      'education': 'MD from Mayo Clinic',
      'isOnline': false,
      'nextSlot': '9:00 AM Tomorrow',
      'consultationFee': '\$200',
    },
    {
      'id': '7',
      'name': 'Dr. Robert Kim',
      'specialty': 'Orthopedic Surgeon',
      'type': 'Specialist',
      'rating': 4.8,
      'experience': '18 years',
      'location': 'Orthopedic Surgery',
      'availability': 'Available Now',
      'image': null,
      'phone': '+1 (555) 789-0123',
      'email': 'robert.kim@hospital.com',
      'languages': ['English', 'Korean'],
      'education': 'MD from Stanford Medical',
      'isOnline': true,
      'nextSlot': '1:30 PM',
      'consultationFee': '\$250',
    },
    // Emergency Staff
    {
      'id': '8',
      'name': 'Dr. Jessica Martinez',
      'specialty': 'Emergency Medicine',
      'type': 'Emergency',
      'rating': 4.9,
      'experience': '11 years',
      'location': 'Emergency Department',
      'availability': 'On Call 24/7',
      'image': null,
      'phone': '+1 (555) 890-1234',
      'email': 'jessica.martinez@hospital.com',
      'languages': ['English', 'Spanish'],
      'education': 'MD from Emergency Medicine Institute',
      'isOnline': true,
      'nextSlot': 'Available Now',
      'consultationFee': 'Emergency Rate',
    },
  ];

  List<Map<String, dynamic>> get _filteredStaff {
    return _medicalStaff.where((staff) {
      final matchesCategory = _selectedCategory == 'All' || 
                              staff['type'].toLowerCase() == _selectedCategory.toLowerCase() ||
                              (_selectedCategory == 'Specialists' && staff['type'] == 'Specialist') ||
                              (_selectedCategory == 'Emergency' && staff['type'] == 'Emergency');
      
      final matchesSearch = _searchQuery.isEmpty ||
                           staff['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           staff['specialty'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesCategory && matchesSearch;
    }).toList();
  }

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
    _searchController.dispose();
    super.dispose();
  }

  void _bookAppointment(Map<String, dynamic> staff) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            Expanded(
              child: _buildStaffDetails(staff),
            ),
          ],
        ),
      ),
    );
  }

  void _contactStaff(Map<String, dynamic> staff) {
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Contact ${staff['name']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_rounded, color: Colors.white),
              ),
              title: const Text('Call', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(staff['phone']),
              onTap: () {
                Navigator.pop(context);
                // Handle phone call
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.indigo],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email_rounded, color: Colors.white),
              ),
              title: const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(staff['email']),
              onTap: () {
                Navigator.pop(context);
                // Handle email
              },
            ),
            if (staff['isOnline'])
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Colors.white),
                ),
                title: const Text('Start Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Available now'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to chat
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Medical Staff Directory',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 114, // Increased from 88 to 114 for much lower positioning from top
        titleSpacing: 12, // Added proper title spacing
        centerTitle: true,
        leading: IconButton(
          iconSize: 24, // Added icon size
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Handle filter options
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: _buildStaffList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search doctors, nurses, specialists...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    final filteredStaff = _filteredStaff;
    
    if (filteredStaff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No staff found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = filteredStaff[index];
        return _buildStaffCard(staff, index);
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getGradientColors(staff['type']),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getGradientColors(staff['type'])[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getStaffIcon(staff['type']),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (staff['isOnline'])
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              staff['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          _buildRatingBadge(staff['rating']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff['specialty'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${staff['experience']} • ${staff['location']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status and Details
            Row(
              children: [
                _buildStatusBadge(staff['availability'], staff['isOnline']),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Next: ${staff['nextSlot']} • ${staff['consultationFee']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Languages
            Wrap(
              children: staff['languages'].map<Widget>((language) {
                return Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    language,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bookAppointment(staff),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Book Appointment ⚡',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _contactStaff(staff),
                    icon: Icon(Icons.chat_rounded, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffDetails(Map<String, dynamic> staff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientColors(staff['type']),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getStaffIcon(staff['type']),
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      staff['specialty'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        _buildRatingBadge(staff['rating']),
                        const SizedBox(width: 8),
                        Text(
                          staff['experience'],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Education & Details
          _buildDetailSection('Education', staff['education']),
          _buildDetailSection('Location', staff['location']),
          _buildDetailSection('Languages', staff['languages'].join(', ')),
          _buildDetailSection('Consultation Fee', staff['consultationFee']),
          
          const SizedBox(height: 24),
          
          // Book Appointment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to booking
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Book Appointment with ${staff['name']} ⚡',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOnline) {
    Color color;
    if (status.contains('Available')) {
      color = Colors.green;
    } else if (status.contains('Busy') || status.contains('Tomorrow')) {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String type) {
    switch (type) {
      case 'Doctor':
        return [AppTheme.primaryColor, AppTheme.secondaryColor];
      case 'Nurse':
        return [Colors.green, Colors.teal];
      case 'Specialist':
        return [Colors.purple, Colors.pink];
      case 'Emergency':
        return [Colors.red, Colors.orange];
      default:
        return [AppTheme.primaryColor, AppTheme.secondaryColor];
    }
  }

  IconData _getStaffIcon(String type) {
    switch (type) {
      case 'Doctor':
        return Icons.medical_services_rounded;
      case 'Nurse':
        return Icons.local_hospital_rounded;
      case 'Specialist':
        return Icons.psychology_rounded;
      case 'Emergency':
        return Icons.emergency_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
