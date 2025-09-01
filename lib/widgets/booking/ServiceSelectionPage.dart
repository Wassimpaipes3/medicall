import 'LocationSelectionPage.dart';
import 'package:flutter/material.dart';
import '../../core/enhanced_theme.dart';
import '../../data/services/healthcare_service_provider.dart';

// Primary service categories - patient-facing
enum ServiceType {
  doctor,
  nurse,
}

// Combined specialty type for backward compatibility and navigation
enum Specialty {
  // Medical specialties
  generalMedicine,
  cardiology,
  neurology,
  pediatrics,
  gynecology,
  orthopedics,
  dermatology,
  psychiatry,
  ophthalmology,
  ent,
  urology,
  gastroenterology,
  oncology,
  emergency,
  // Nursing services
  woundCare,
  medicationAdministration,
  vitalsMonitoring,
  injections,
  bloodDrawing,
  homeHealthAssessment,
  postSurgicalCare,
  chronicDiseaseManagement,
  elderCare,
  mobilityAssistance,
  medicationReminders,
  healthEducation,
}

class SpecialtyInfo {
  final String name;
  final IconData icon;
  final String? description;
  final int? estimatedTime;
  final int? availablePractitioners;

  const SpecialtyInfo({
    required this.name, 
    required this.icon,
    this.description,
    this.estimatedTime,
    this.availablePractitioners,
  });
}

class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage>
    with TickerProviderStateMixin {
  ServiceType? _selectedService;
  Specialty? _selectedSpecialty;
  bool _showSpecialtySelection = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildServiceCards(),
                        if (_showSpecialtySelection) ...[
                          const SizedBox(height: 32),
                          _buildSpecialtySelection(),
                        ],
                        const SizedBox(height: 24), // Reduced from 32
                        _buildNextButton(),
                        const SizedBox(height: 20), // Increased bottom spacing
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Care Provider',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the type of healthcare professional you need',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCards() {
    return Column(
      children: [
        _buildServiceCard(
          serviceType: ServiceType.doctor,
          title: 'Doctor',
          subtitle: 'Medical consultation, diagnosis & treatment',
          icon: Icons.medical_services_rounded,
          color: const Color(0xFF2563EB),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        const SizedBox(height: 20),
        _buildServiceCard(
          serviceType: ServiceType.nurse,
          title: 'Nurse',
          subtitle: 'Nursing care, health monitoring & support',
          icon: Icons.health_and_safety_rounded,
          color: const Color(0xFF059669),
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required ServiceType serviceType,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
  }) {
    final isSelected = _selectedService == serviceType;
    final availableProviders = serviceType == ServiceType.doctor 
        ? HealthcareServiceProvider.getAvailableMedicalSpecialties().length
        : HealthcareServiceProvider.getAvailableNursingServices().length;
    
    // Vibrant color themes with modern palettes
    final Color primaryColor = serviceType == ServiceType.doctor 
        ? const Color(0xFF6366F1) // Indigo
        : const Color(0xFF06B6D4); // Cyan
    
    final Color secondaryColor = serviceType == ServiceType.doctor
        ? const Color(0xFF8B5CF6) // Purple
        : const Color(0xFF10B981); // Emerald
        
    final Color tertiaryColor = serviceType == ServiceType.doctor
        ? const Color(0xFFF59E0B) // Amber
        : const Color(0xFFEC4899); // Pink
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      transform: isSelected
          ? (Matrix4.identity()
              ..scale(1.05)
              ..rotateZ(0.02)
              ..translate(0.0, -5.0))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedService = serviceType;
            _showSpecialtySelection = true;
            _selectedSpecialty = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            // Glassmorphism effect
            gradient: isSelected 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.9),
                      secondaryColor.withOpacity(0.8),
                      tertiaryColor.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : primaryColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              // Neon glow effect
              if (isSelected) ...[
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: secondaryColor.withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: -10,
                  offset: const Offset(0, 25),
                ),
              ],
              // Soft shadow for unselected
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Floating icon with particles effect
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
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
                                    primaryColor.withOpacity(0.15),
                                    primaryColor.withOpacity(0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Colors.black.withOpacity(0.1)
                                  : primaryColor.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: isSelected 
                              ? primaryColor 
                              : primaryColor,
                          size: 38,
                        ),
                      ),
                      // Floating particles
                      if (isSelected) ...[
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 24),
                  
                  // Enhanced content with modern typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isSelected 
                                ? Colors.white 
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                            height: 1.1,
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
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected 
                                ? Colors.white.withOpacity(0.95)
                                : const Color(0xFF475569),
                            height: 1.4,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Morphing selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 40 : 24,
                    height: isSelected ? 40 : 24,
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
                                primaryColor.withOpacity(0.1),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(isSelected ? 20 : 12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected 
                          ? primaryColor 
                          : primaryColor.withOpacity(0.5),
                      size: isSelected ? 24 : 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Interactive stats bar with hover effects
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.08),
                            secondaryColor.withOpacity(0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : primaryColor.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: Icons.medical_services_outlined,
                      value: '$availableProviders+',
                      label: 'Specialists',
                      isSelected: isSelected,
                      color: primaryColor,
                    ),
                    Container(
                      width: 2,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isSelected ? Colors.white : primaryColor).withOpacity(0.3),
                            (isSelected ? Colors.white : primaryColor).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    _buildStatItem(
                      icon: Icons.access_time_rounded,
                      value: '24/7',
                      label: 'Available',
                      isSelected: isSelected,
                      color: primaryColor,
                    ),
                    Container(
                      width: 2,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isSelected ? Colors.white : primaryColor).withOpacity(0.3),
                            (isSelected ? Colors.white : primaryColor).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    _buildStatItem(
                      icon: Icons.star_rounded,
                      value: '4.9★',
                      label: 'Rating',
                      isSelected: isSelected,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isSelected,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isSelected 
              ? Colors.white.withOpacity(0.9)
              : color.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected 
                ? Colors.white 
                : const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Colors.white.withOpacity(0.8)
                : const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtySelection() {
    final isDoctor = _selectedService == ServiceType.doctor;
    final title = isDoctor ? 'Medical Specialty' : 'Nursing Service';
    final subtitle = isDoctor 
        ? 'Choose the medical specialty you need'
        : 'Select the type of nursing care required';
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9, // More consistent aspect ratio
          ),
          itemCount: _getSpecialtiesForService(_selectedService!).length,
          itemBuilder: (context, index) {
            final specialty = _getSpecialtiesForService(_selectedService!)[index];
            return _buildSpecialtyCard(specialty);
          },
        ),
      ],
    );
  }

  Widget _buildSpecialtyCard(Specialty specialty) {
    final isSelected = _selectedSpecialty == specialty;
    final specialtyInfo = _getSpecialtyInfo(specialty);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: isSelected
          ? (Matrix4.identity()..scale(1.02))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSpecialty = specialty;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Glassmorphism effect like doctor/nurse cards
            gradient: isSelected 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.9),
                      const Color(0xFF8B5CF6).withOpacity(0.8),
                      const Color(0xFFF59E0B).withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFF6366F1).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              // Neon glow effect
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
                  spreadRadius: -8,
                  offset: const Offset(0, 20),
                ),
              ],
              // Soft shadow for unselected
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Icon container with glassmorphic effect
              Container(
                padding: const EdgeInsets.all(12),
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
                            const Color(0xFF6366F1).withOpacity(0.2),
                            const Color(0xFF6366F1).withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.black.withOpacity(0.15)
                          : const Color(0xFF6366F1).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  specialtyInfo.icon,
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Enhanced Name with better typography - Fixed overflow
              Expanded(
                child: Text(
                  specialtyInfo.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected 
                        ? Colors.white 
                        : const Color(0xFF1F2937),
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Compact additional info to prevent overflow
              if (specialtyInfo.estimatedTime != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${specialtyInfo.estimatedTime}m',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected 
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF2563EB).withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              
              // Enhanced selection indicator
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Specialty> _getSpecialtiesForService(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.doctor:
        return [
          Specialty.generalMedicine,
          Specialty.cardiology,
          Specialty.neurology,
          Specialty.pediatrics,
          Specialty.gynecology,
          Specialty.orthopedics,
          Specialty.dermatology,
          Specialty.psychiatry,
          Specialty.ophthalmology,
          Specialty.ent,
          Specialty.urology,
          Specialty.gastroenterology,
          Specialty.oncology,
          Specialty.emergency,
        ];
      case ServiceType.nurse:
        return [
          Specialty.woundCare,
          Specialty.medicationAdministration,
          Specialty.vitalsMonitoring,
          Specialty.injections,
          Specialty.bloodDrawing,
          Specialty.homeHealthAssessment,
          Specialty.postSurgicalCare,
          Specialty.chronicDiseaseManagement,
          Specialty.elderCare,
          Specialty.mobilityAssistance,
          Specialty.medicationReminders,
          Specialty.healthEducation,
        ];
    }
  }

  SpecialtyInfo _getSpecialtyInfo(Specialty specialty) {
    final specialtyId = specialty.toString().split('.').last;
    
    // Check if it's a medical specialty
    final medicalSpecialty = HealthcareServiceProvider.getMedicalSpecialty(specialtyId);
    if (medicalSpecialty != null) {
      return SpecialtyInfo(
        name: medicalSpecialty.name,
        icon: medicalSpecialty.icon,
        description: medicalSpecialty.description,
        estimatedTime: medicalSpecialty.averageConsultationTime,
        availablePractitioners: medicalSpecialty.practitioners,
      );
    }
    
    // Check if it's a nursing service
    final nursingService = HealthcareServiceProvider.getNursingService(specialtyId);
    if (nursingService != null) {
      return SpecialtyInfo(
        name: nursingService.name,
        icon: nursingService.icon,
        description: nursingService.description,
        estimatedTime: nursingService.averageServiceTime,
        availablePractitioners: nursingService.practitioners,
      );
    }
    
    // Fallback for any missing specialties
    return SpecialtyInfo(
      name: specialtyId.replaceAllMapped(
        RegExp(r'([A-Z])'), 
        (match) => ' ${match.group(1)}'
      ).trim(),
      icon: Icons.medical_services_rounded,
    );
  }

  Widget _buildNextButton() {
    final canProceed = _selectedService != null && _selectedSpecialty != null;
    final buttonText = _selectedService == null 
        ? 'Select Care Provider'
        : _selectedSpecialty == null 
            ? 'Choose Specialty'
            : 'Continue to Location';
            
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        transform: canProceed
            ? (Matrix4.identity()
                ..scale(1.02)
                ..translate(0.0, -2.0))
            : Matrix4.identity(),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: canProceed
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA), // Soft Blue
                      Color(0xFF764BA2), // Purple
                      Color(0xFF6B73FF), // Indigo
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canProceed 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: canProceed
                ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF764BA2).withOpacity(0.3),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                      spreadRadius: -10,
                    ),
                    // Inner glow effect
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                      spreadRadius: -5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canProceed ? _navigateToLocation : null,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Leading Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canProceed 
                            ? Colors.white.withOpacity(0.25)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _selectedService == null 
                            ? Icons.medical_services_outlined
                            : _selectedSpecialty == null
                                ? Icons.psychology_outlined
                                : Icons.location_on_outlined,
                        color: canProceed ? Colors.white : Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Button Text
                    Expanded(
                      child: Text(
                        buttonText,
                        textAlign: TextAlign.center,
                        style: EnhancedAppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: canProceed ? Colors.white : Colors.grey.shade500,
                          letterSpacing: 0.3,
                          shadows: canProceed
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Trailing Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canProceed 
                            ? Colors.white.withOpacity(0.25)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: canProceed ? 0 : -0.5,
                        child: Icon(
                          canProceed 
                              ? Icons.arrow_forward_rounded
                              : Icons.close_rounded,
                          color: canProceed ? Colors.white : Colors.grey.shade500,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLocation() {
    if (_selectedService != null && _selectedSpecialty != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LocationSelectionPage(
                selectedService: _selectedService!,
                selectedSpecialty: _selectedSpecialty!,
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
