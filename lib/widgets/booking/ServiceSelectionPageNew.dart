import 'package:flutter/material.dart';
import 'package:firstv/data/services/healthcare_service_provider.dart';

enum ServiceType { doctor, nurse }

class ServiceSelectionPageNew extends StatefulWidget {
  const ServiceSelectionPageNew({super.key});

  @override
  State<ServiceSelectionPageNew> createState() => _ServiceSelectionPageNewState();
}

class _ServiceSelectionPageNewState extends State<ServiceSelectionPageNew> 
    with TickerProviderStateMixin {
  ServiceType? _selectedService;
  String? _selectedSpecialty;
  bool _showSpecialtySelection = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1A1E23),
              Color(0xFF0D1117),
              Color(0xFF010409),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      _buildFuturisticHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildHolographicServiceCards(),
                              if (_showSpecialtySelection) ...[
                                const SizedBox(height: 32),
                                _buildHolographicSpecialtySection(),
                              ],
                              const SizedBox(height: 40),
                              if (_selectedService != null && _selectedSpecialty != null)
                                _buildQuantumContinueButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF161B22),
            Color(0xFF21262D),
            Color(0xFF0D1117),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58A6FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF58A6FF).withOpacity(0.8 + _pulseAnimation.value * 0.2),
                        Color(0xFF7C3AED).withOpacity(0.8 + _pulseAnimation.value * 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF58A6FF).withOpacity(0.3 + _pulseAnimation.value * 0.2),
                        blurRadius: 12 + _pulseAnimation.value * 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF58A6FF), Color(0xFF7C3AED), Color(0xFFF7931E)],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'QUANTUM HEALTH',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Next-gen AI healthcare ecosystem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8B949E),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Holographic indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF58A6FF).withOpacity(_pulseAnimation.value),
                      Color(0xFF7C3AED).withOpacity(1.0 - _pulseAnimation.value),
                      Color(0xFFF7931E).withOpacity(_pulseAnimation.value),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicServiceCards() {
    return Column(
      children: [
        _buildHolographicServiceCard(
          serviceType: ServiceType.doctor,
          title: 'NEURAL DOCTOR',
          subtitle: 'Quantum diagnostics • AI-driven treatment protocols',
          icon: Icons.psychology,
          primaryColor: const Color(0xFF58A6FF),
          secondaryColor: const Color(0xFF7C3AED),
          accentColor: const Color(0xFFF7931E),
        ),
        const SizedBox(height: 24),
        _buildHolographicServiceCard(
          serviceType: ServiceType.nurse,
          title: 'CYBER NURSE',
          subtitle: 'Bio-monitoring • Adaptive care algorithms',
          icon: Icons.biotech,
          primaryColor: const Color(0xFF39D353),
          secondaryColor: const Color(0xFF00D4AA),
          accentColor: const Color(0xFF1F6FEB),
        ),
      ],
    );
  }

  Widget _buildHolographicServiceCard({
    required ServiceType serviceType,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
    final isSelected = _selectedService == serviceType;
    final availableProviders = serviceType == ServiceType.doctor 
        ? HealthcareServiceProvider.getAvailableMedicalSpecialties().length
        : HealthcareServiceProvider.getAvailableNursingServices().length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      transform: isSelected
          ? (Matrix4.identity()
              ..scale(1.05)
              ..translate(0.0, -8.0))
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
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.15),
                      secondaryColor.withOpacity(0.10),
                      accentColor.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      const Color(0xFF161B22).withOpacity(0.8),
                      const Color(0xFF21262D).withOpacity(0.6),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected 
                  ? primaryColor.withOpacity(0.5)
                  : const Color(0xFF30363D),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected) ...[
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: secondaryColor.withOpacity(0.2),
                  blurRadius: 60,
                  spreadRadius: -10,
                  offset: const Offset(0, 25),
                ),
              ],
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Holographic icon with energy field
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? RadialGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    secondaryColor.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                )
                              : RadialGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? primaryColor : primaryColor.withOpacity(0.8),
                          size: 42,
                        ),
                      ),
                      // Energy particles
                      if (isSelected) 
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.1 + _pulseAnimation.value * 0.2),
                                      blurRadius: 20 + _pulseAnimation.value * 20,
                                      spreadRadius: _pulseAnimation.value * 10,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  
                  // Enhanced content with holographic text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isSelected 
                                ? [primaryColor, secondaryColor, accentColor]
                                : [const Color(0xFFF0F6FC), const Color(0xFF8B949E)],
                          ).createShader(bounds),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected 
                                ? const Color(0xFFCDD9E5)
                                : const Color(0xFF8B949E),
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quantum selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isSelected ? 48 : 24,
                    height: isSelected ? 48 : 24,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? RadialGradient(
                              colors: [
                                primaryColor,
                                secondaryColor,
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF30363D),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(isSelected ? 24 : 12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFF30363D),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected 
                          ? Colors.white
                          : const Color(0xFF8B949E),
                      size: isSelected ? 28 : 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Neural data visualization
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            secondaryColor.withOpacity(0.05),
                          ],
                        )
                      : const LinearGradient(
                          colors: [
                            Color(0xFF161B22),
                            Color(0xFF0D1117),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor.withOpacity(0.3)
                        : const Color(0xFF30363D),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDataPoint(
                      icon: Icons.analytics,
                      value: '$availableProviders',
                      label: 'EXPERTS',
                      isSelected: isSelected,
                      color: primaryColor,
                    ),
                    _buildDataDivider(isSelected, primaryColor),
                    _buildDataPoint(
                      icon: Icons.schedule,
                      value: '24/7',
                      label: 'ACTIVE',
                      isSelected: isSelected,
                      color: primaryColor,
                    ),
                    _buildDataDivider(isSelected, primaryColor),
                    _buildDataPoint(
                      icon: Icons.trending_up,
                      value: '99.9%',
                      label: 'UPTIME',
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

  Widget _buildDataPoint({
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
              ? color
              : const Color(0xFF8B949E),
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isSelected 
                ? const Color(0xFFF0F6FC)
                : const Color(0xFF8B949E),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? color.withOpacity(0.8)
                : const Color(0xFF8B949E),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDataDivider(bool isSelected, Color color) {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isSelected ? color : const Color(0xFF30363D)).withOpacity(0.5),
            (isSelected ? color : const Color(0xFF30363D)).withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildHolographicSpecialtySection() {
    if (_selectedService == null) return const SizedBox.shrink();

    final specialties = _selectedService == ServiceType.doctor
        ? HealthcareServiceProvider.getAvailableMedicalSpecialties()
        : HealthcareServiceProvider.getAvailableNursingServices();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT NEURAL PATHWAY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF0F6FC),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your specialized care protocol',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF8B949E),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: specialties.map((specialty) {
            final specialtyName = specialty.toString();
            final isSelected = _selectedSpecialty == specialtyName;
            return GestureDetector(
              onTap: () => setState(() => _selectedSpecialty = specialtyName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? const LinearGradient(
                          colors: [Color(0xFF58A6FF), Color(0xFF7C3AED)],
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFF161B22).withOpacity(0.8),
                            const Color(0xFF21262D).withOpacity(0.6),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF58A6FF)
                        : const Color(0xFF30363D),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF58A6FF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  specialtyName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected 
                        ? Colors.white
                        : const Color(0xFF8B949E),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantumContinueButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF58A6FF), Color(0xFF7C3AED), Color(0xFFF7931E)],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58A6FF).withOpacity(0.4 + _pulseAnimation.value * 0.3),
                blurRadius: 30 + _pulseAnimation.value * 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.3 + _pulseAnimation.value * 0.2),
                blurRadius: 50 + _pulseAnimation.value * 30,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/location_selection',
                arguments: {
                  'serviceType': _selectedService,
                  'specialty': _selectedSpecialty,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'INITIATE QUANTUM CARE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
