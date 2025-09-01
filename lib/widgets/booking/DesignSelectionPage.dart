import 'package:flutter/material.dart';
import 'package:firstv/widgets/booking/ServiceSelectionPage.dart';
import 'package:firstv/widgets/booking/ServiceSelectionPageNew.dart';

class DesignSelectionPage extends StatelessWidget {
  const DesignSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ).createShader(bounds),
                        child: const Text(
                          'Choose Your Design',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Experience different UI/UX approaches for healthcare booking',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Expanded(
                  child: Column(
                    children: [
                      // Classic Modern Design
                      Expanded(
                        child: _buildDesignOption(
                          context: context,
                          title: 'GLASSMORPHIC MODERN',
                          subtitle: 'Sophisticated design with glassmorphism effects, vibrant gradients, and modern interactions',
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFF59E0B)],
                          icon: Icons.auto_awesome,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ServiceSelectionPage()),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Futuristic Neural Design
                      Expanded(
                        child: _buildDesignOption(
                          context: context,
                          title: 'QUANTUM NEURAL',
                          subtitle: 'Futuristic dark theme with holographic elements, neural networks, and cyberpunk aesthetics',
                          colors: [Color(0xFF58A6FF), Color(0xFF7C3AED), Color(0xFFF7931E)],
                          icon: Icons.psychology,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ServiceSelectionPageNew()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Back button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              colors.first.withOpacity(0.05),
              colors.last.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.first.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon section with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: colors,
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                height: 1.4,
                letterSpacing: 0.1,
              ),
            ),
            
            const Spacer(),
            
            // Action indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TAP TO EXPLORE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.first,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.first,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
