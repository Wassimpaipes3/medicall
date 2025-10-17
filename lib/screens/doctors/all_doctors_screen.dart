import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../core/services/call_service.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _doctorsStream;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Cardiologist',
    'Neurologist',
    'Pediatrician',
    'Orthopedic',
  ];

  // Fetch user profile from users collection
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
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
    _initializeFirestoreStream();
  }

  void _initializeFirestoreStream() {
    // Fetch all healthcare providers (doctors and nurses) from professionals collection
    _doctorsStream = _firestore
        .collection('professionals')
        .where('profession', whereIn: ['medecin', 'doctor', 'docteur', 'infirmier', 'nurse'])
        .orderBy('rating', descending: true)
        .snapshots();
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

  void _bookAppointment(Map<String, dynamic> staff, String doctorId) async {
    HapticFeedback.lightImpact();
    
    // Show schedule appointment dialog directly
    final scheduleData = await _showScheduleAppointmentDialog(staff);
    
    if (scheduleData == null) return;
    
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get current user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(currentUser.uid)
          .get();
      
      final userData = userDoc.data() ?? {};
      
      print('🔍 Patient document exists: ${userDoc.exists}');
      print('🔍 Patient data keys: ${userData.keys.toList()}');
      if (userData.containsKey('location')) {
        print('🔍 Location field type: ${userData['location'].runtimeType}');
        print('🔍 Location value: ${userData['location']}');
      }
      
      // Get patient location as GeoPoint
      GeoPoint? patientLocation;
      if (userData['location'] != null && userData['location'] is GeoPoint) {
        patientLocation = userData['location'] as GeoPoint;
        print('✅ Using patient location from user data');
      } else {
        patientLocation = const GeoPoint(0.0, 0.0);
        print('⚠️ No patient location found in patients collection, using default (0,0)');
        print('   Available fields: ${userData.keys.toList()}');
      }
      print('📍 Final patient location: ${patientLocation.latitude}, ${patientLocation.longitude}');

      // Use the doctorId parameter (Firestore document ID)
      final providerId = doctorId;
      
      print('✅ Using Provider ID from Firestore document: $providerId');
      print('🔍 Staff data keys: ${staff.keys.toList()}');
      
      // Get provider location as GeoPoint (from staff data or fetch from professionals)
      GeoPoint? providerLocation;
      if (staff['location'] != null && staff['location'] is GeoPoint) {
        providerLocation = staff['location'] as GeoPoint;
        print('✅ Using provider location from staff data');
      } else {
        try {
          // Fetch provider location from professionals collection
          print('🔍 Fetching provider location from Firestore...');
          final providerDoc = await FirebaseFirestore.instance
              .collection('professionals')
              .doc(providerId)
              .get();
              
          if (providerDoc.exists) {
            final providerData = providerDoc.data();
            if (providerData != null && providerData['location'] != null) {
              providerLocation = providerData['location'] as GeoPoint;
              print('✅ Found provider location in professionals collection');
            } else {
              print('⚠️ Provider document exists but no location found');
            }
          } else {
            print('⚠️ Provider document not found in professionals collection');
          }
        } catch (e) {
          print('❌ Error fetching provider location: $e');
        }
      }
      providerLocation ??= const GeoPoint(0.0, 0.0);
      print('📍 Final provider location: ${providerLocation.latitude}, ${providerLocation.longitude}');
      
      // Get service and price
      final service = staff['specialty'] ?? 'consultation';
      final prix = (staff['prix'] ?? staff['consultationFee'] ?? 100.0).toDouble();

      print('📅 Creating SCHEDULED appointment for ${scheduleData['date']} at ${scheduleData['time']}');
      
      // Use the complete date/time from the dialog (already contains both date and time)
      final scheduledDateTime = scheduleData['date'] as DateTime;
      
      // Create appointment request directly in Firestore with your exact schema
      final appointmentData = {
        'idpat': currentUser.uid,
        'idpro': providerId,
        'patientName': userData['nom'] ?? userData['name'] ?? 'Unknown Patient', // Add patient name
        'patientPhone': userData['telephone'] ?? userData['phone'] ?? '', // Add patient phone
        'patientlocation': patientLocation,
        'providerlocation': providerLocation,
        'patientAddress': userData['adresse'], // Can be null
        'service': service,
        'prix': prix.toInt(), // Convert to integer
        'serviceFee': 0, // Set to 0 as per your schema
        'paymentMethod': 'Cash',
        'type': 'scheduled', // 'scheduled' instead of 'instant'
        'appointmentTime': scheduleData['time'], // Time is already formatted as string
        'notes': scheduleData['notes'] ?? '',
        'status': 'pending', // Will be 'accepted' after provider accepts
        'scheduledDate': Timestamp.fromDate(scheduledDateTime), // Added scheduledDate field
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📝 Appointment data to create:');
      print('   idpat: ${appointmentData['idpat']}');
      print('   idpro: ${appointmentData['idpro']}');
      print('   service: ${appointmentData['service']}');
      print('   prix: ${appointmentData['prix']}');
      print('   type: ${appointmentData['type']}');

      final docRef = await FirebaseFirestore.instance
          .collection('appointment_requests')
          .add(appointmentData);
          
      print('✅ Document created with ID: ${docRef.id}');

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ Appointment request sent!\nWaiting for ${staff['name']} to confirm.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      print('❌ Error creating scheduled appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create appointment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Show date/time picker dialog for scheduling appointments
  Future<Map<String, dynamic>?> _showScheduleAppointmentDialog(Map<String, dynamic> staff) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String notes = '';

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule Appointment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'With ${staff['name']}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Selector
                _buildSectionTitle('Select Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppTheme.primaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Choose appointment date'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(
                              color: selectedDate == null ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Selector
                _buildSectionTitle('Select Time'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppTheme.primaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedTime == null
                                ? 'Choose appointment time'
                                : selectedTime!.format(context),
                            style: TextStyle(
                              color: selectedTime == null ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes Field
                _buildSectionTitle('Notes (Optional)'),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special requests or information...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDate == null || selectedTime == null
                  ? null
                  : () {
                      // Combine date and time
                      final appointmentDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:'
                          '${selectedTime!.minute.toString().padLeft(2, '0')}';

                      Navigator.pop(context, {
                        'date': appointmentDateTime,
                        'time': timeString,
                        'notes': notes.isEmpty ? null : notes,
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondaryColor,
        letterSpacing: 0.5,
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
                CallService.makeCall(
                  staff['phone'],
                  context: context,
                );
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
            if (staff['available'])
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
          'Top Providers',
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
    return StreamBuilder<QuerySnapshot>(
      stream: _doctorsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading providers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No providers found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter providers based on search and category
        final allDoctors = snapshot.data!.docs;
        final filteredDoctors = allDoctors.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final specialty = data['specialite'] ?? data['service'] ?? '';
          final login = data['login'] ?? '';
          
          // Category filter
          final matchesCategory = _selectedCategory == 'All' ||
              specialty.toLowerCase().contains(_selectedCategory.toLowerCase());
          
          // Search filter
          final matchesSearch = _searchQuery.isEmpty ||
              login.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              specialty.toLowerCase().contains(_searchQuery.toLowerCase());
          
          return matchesCategory && matchesSearch;
        }).toList();

        if (filteredDoctors.isEmpty) {
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
                  'No providers found',
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
          itemCount: filteredDoctors.length,
          itemBuilder: (context, index) {
            final doctorDoc = filteredDoctors[index];
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            final doctorId = doctorDoc.id;
            return _buildStaffCard(doctorData, doctorId, index);
          },
        );
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff, String doctorId, int index) {
    // Map Firestore fields to UI
    final userId = staff['id_user'] as String?;
    final specialty = staff['specialite'] ?? staff['service'] ?? 'General';
    final rating = ((staff['rating'] ?? 0.0) is int)
        ? (staff['rating'] as int).toDouble()
        : (staff['rating'] ?? 0.0).toDouble();
    final isAvailable = staff['disponible'] ?? false;
    final fee = staff['prix'] ?? 100;
    final type = staff['profession'] ?? 'medecin';
    
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
                // Avatar - fetch from users collection or show icon
                Stack(
                  children: [
                    userId != null
                        ? FutureBuilder<Map<String, dynamic>?>(
                            future: _getUserProfile(userId),
                            builder: (context, snapshot) {
                              final userData = snapshot.data;
                              final photoUrl = userData?['photo_profile'];
                              
                              if (photoUrl != null && photoUrl.toString().trim().isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    photoUrl.toString(),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultAvatar(type);
                                    },
                                  ),
                                );
                              }
                              return _buildDefaultAvatar(type);
                            },
                          )
                        : _buildDefaultAvatar(type),
                    if (isAvailable)
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
                // Info - fetch name from users collection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: userId != null
                                ? FutureBuilder<Map<String, dynamic>?>(
                                    future: _getUserProfile(userId),
                                    builder: (context, snapshot) {
                                      // Get title prefix based on profession
                                      final isNurse = type.contains('nurse') || type.contains('infirmier');
                                      final titlePrefix = isNurse ? '' : 'Dr. ';
                                      String displayName = '$titlePrefix${staff['login'] ?? 'Professional'}';
                                      
                                      if (snapshot.connectionState == ConnectionState.done &&
                                          snapshot.hasData) {
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      );
                                    },
                                  )
                                : Text(
                                    '${type.contains('nurse') || type.contains('infirmier') ? '' : 'Dr. '}${staff['login'] ?? 'Professional'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                          ),
                          _buildRatingBadge(rating),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 years • $specialty',
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
                _buildStatusBadge(isAvailable ? 'Available Now' : 'Unavailable', isAvailable),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consultation • \$$fee',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Languages placeholder
            Wrap(
              children: ['English', 'Arabic'].map<Widget>((language) {
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
                    onPressed: () => _bookAppointment(staff, doctorId),
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
          _buildDetailSection('Consultation Fee', '\$${staff['consultationFee']}'),
          
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

  Widget _buildDefaultAvatar(String type) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(type),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getGradientColors(type)[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _getStaffIcon(type),
        color: Colors.white,
        size: 28,
      ),
    );
  }

  List<Color> _getGradientColors(String type) {
    // Handle both French and English profession names
    final lowerType = type.toLowerCase();
    if (lowerType.contains('medecin') || lowerType.contains('doctor') || lowerType.contains('docteur')) {
      return [AppTheme.primaryColor, AppTheme.secondaryColor];
    } else if (lowerType.contains('infirmier') || lowerType.contains('nurse')) {
      return [Colors.green, Colors.teal];
    } else if (lowerType.contains('specialist')) {
      return [Colors.purple, Colors.pink];
    } else if (lowerType.contains('emergency') || lowerType.contains('urgence')) {
      return [Colors.red, Colors.orange];
    }
    return [AppTheme.primaryColor, AppTheme.secondaryColor];
  }

  IconData _getStaffIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('medecin') || lowerType.contains('doctor') || lowerType.contains('docteur')) {
      return Icons.medical_services_rounded;
    } else if (lowerType.contains('infirmier') || lowerType.contains('nurse')) {
      return Icons.local_hospital_rounded;
    } else if (lowerType.contains('specialist')) {
      return Icons.psychology_rounded;
    } else if (lowerType.contains('emergency') || lowerType.contains('urgence')) {
      return Icons.emergency_rounded;
    }
    return Icons.person_rounded;
  }
}
