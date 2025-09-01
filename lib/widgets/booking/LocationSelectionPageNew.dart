import 'ServiceSummaryPage.dart';
import 'package:flutter/material.dart';
import 'ServiceSelectionPage.dart';
import 'LocationSelectionPage.dart';

class LocationSelectionPage extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;

  const LocationSelectionPage({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
  });

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage>
    with TickerProviderStateMixin {
  LocationData? _selectedLocation;
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customAddressController = TextEditingController();
  bool _showCustomLocationForm = false;
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Pre-saved locations
  final List<LocationData> _preSavedLocations = [
    LocationData(
      name: 'Home',
      address: '123 Main Street, City, State',
      latitude: 40.7128,
      longitude: -74.0060,
    ),
    LocationData(
      name: 'Office',
      address: '456 Business Ave, Downtown, State',
      latitude: 40.7589,
      longitude: -73.9851,
    ),
    LocationData(
      name: 'Hospital',
      address: '789 Medical Center Dr, Healthcare District',
      latitude: 40.7505,
      longitude: -73.9934,
    ),
    LocationData(
      name: 'Clinic',
      address: '321 Health Plaza, Medical Complex',
      latitude: 40.7614,
      longitude: -73.9776,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

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
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _customNameController.dispose();
    _customAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEnhancedPreSavedLocations(),
                          const SizedBox(height: 24),
                          _buildEnhancedAddCustomLocationButton(),
                          if (_showCustomLocationForm) ...[
                            const SizedBox(height: 24),
                            _buildEnhancedCustomLocationForm(),
                          ],
                          const SizedBox(height: 32),
                          _buildEnhancedNextButton(),
                        ],
                      ),
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

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ).createShader(bounds),
                  child: const Text(
                    'Choose Location',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where would you like to receive care?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPreSavedLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ).createShader(bounds),
          child: const Text(
            'Saved Locations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose from your frequently used locations',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _preSavedLocations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final location = _preSavedLocations[index];
            final isSelected = _selectedLocation == location;
            return _buildEnhancedLocationCard(location, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedLocationCard(LocationData location, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      transform: isSelected
          ? (Matrix4.identity()
              ..scale(1.03)
              ..translate(0.0, -3.0))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedLocation = location;
            _showCustomLocationForm = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFF59E0B),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                      const Color(0xFF6366F1).withOpacity(0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFF6366F1).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              if (isSelected) ...[
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
              ],
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Enhanced location icon
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? RadialGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9),
                              ],
                            )
                          : RadialGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.15),
                                const Color(0xFF6366F1).withOpacity(0.05),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? Colors.black.withOpacity(0.1)
                              : const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isSelected 
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                  // Floating particle for selected
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Enhanced location details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isSelected 
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.address,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 32 : 20,
                height: isSelected ? 32 : 20,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? RadialGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.95),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF6366F1).withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(isSelected ? 16 : 10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFF6366F1).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.radio_button_unchecked,
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6366F1).withOpacity(0.5),
                  size: isSelected ? 20 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAddCustomLocationButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showCustomLocationForm = !_showCustomLocationForm;
            if (_showCustomLocationForm) {
              _selectedLocation = null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _showCustomLocationForm
                  ? [
                      const Color(0xFFEF4444).withOpacity(0.1),
                      const Color(0xFFDC2626).withOpacity(0.05),
                    ]
                  : [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF059669).withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showCustomLocationForm
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : const Color(0xFF10B981).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (_showCustomLocationForm 
                    ? const Color(0xFFEF4444) 
                    : const Color(0xFF10B981)).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showCustomLocationForm
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (_showCustomLocationForm 
                          ? const Color(0xFFEF4444) 
                          : const Color(0xFF10B981)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _showCustomLocationForm ? Icons.close : Icons.add_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _showCustomLocationForm ? 'Cancel' : 'Add Custom Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _showCustomLocationForm
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCustomLocationForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFAFBFC),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ).createShader(bounds),
              child: const Text(
                'Custom Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Enhanced Name Input
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFF6366F1).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customNameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., My Home, My Office',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.edit_location,
                      color: const Color(0xFF6366F1).withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: const Color(0xFF6366F1).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Enhanced Address Input
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFF6366F1).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customAddressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter the full address',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.location_on,
                      color: const Color(0xFF6366F1).withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: const Color(0xFF6366F1).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Enhanced Save Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _customNameController.text.isNotEmpty &&
                           _customAddressController.text.isNotEmpty && !_isLoading
                    ? _saveCustomLocation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
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

  Widget _buildEnhancedNextButton() {
    final canProceed = _selectedLocation != null;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: canProceed
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFF59E0B),
                  ],
                  stops: [0.0, 0.6, 1.0],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade400,
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: canProceed
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: canProceed ? _navigateToServiceSummary : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  canProceed ? Icons.medical_services : Icons.location_off,
                  color: canProceed ? Colors.white : Colors.grey.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                canProceed ? 'Continue to Summary' : 'Select Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: canProceed ? Colors.white : Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              if (canProceed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveCustomLocation() async {
    if (_customNameController.text.isNotEmpty && 
        _customAddressController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate geocoding delay
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // For demo purposes, use mock coordinates
        final customLocation = LocationData(
          name: _customNameController.text,
          address: _customAddressController.text,
          latitude: 40.7128 + (0.001 * DateTime.now().millisecond),
          longitude: -74.0060 + (0.001 * DateTime.now().millisecond),
          isCustom: true,
        );

        setState(() {
          _selectedLocation = customLocation;
          _showCustomLocationForm = false;
          _isLoading = false;
        });

        // Clear the form
        _customNameController.clear();
        _customAddressController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location saved successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save location. Please try again.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _navigateToServiceSummary() {
    if (_selectedLocation != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ServiceSummaryPage(
                selectedService: widget.selectedService,
                selectedSpecialty: widget.selectedSpecialty,
                selectedLocation: _selectedLocation!,
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
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }
}
