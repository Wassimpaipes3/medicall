import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/booking/modern_select_provider_screen.dart';

/// Example showing how to integrate the modern SelectProviderScreen
/// This replaces your old SelectProviderScreen with the new healthcare UI
class ModernSelectProviderExample extends StatefulWidget {
  const ModernSelectProviderExample({super.key});

  @override
  State<ModernSelectProviderExample> createState() => _ModernSelectProviderExampleState();
}

class _ModernSelectProviderExampleState extends State<ModernSelectProviderExample> {
  
  // Sample patient location (replace with real patient location)
  final GeoPoint _patientLocation = const GeoPoint(36.7538, 3.0588); // Algiers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Provider Selection Demo'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Demo Introduction
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: Color(0xFF1565C0),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Modern Healthcare UI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'This demonstrates the new provider selection screen with:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ..._buildFeatureList([
                      '✓ Modern healthcare-themed UI (blue + white)',
                      '✓ Real-time provider updates from Firestore',
                      '✓ Star ratings with flutter_rating_bar',
                      '✓ Distance calculation using geolocator',
                      '✓ Provider details modal with full information',
                      '✓ Lottie animations for loading and empty states',
                      '✓ Responsive design for all screen sizes',
                      '✓ Professional medical app appearance',
                    ]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Demo Buttons
            _buildDemoButton(
              'Consultation Service',
              'consultation',
              'General Medicine',
              100.0,
              Icons.healing,
            ),
            
            const SizedBox(height: 12),
            
            _buildDemoButton(
              'Home Visit',
              'home_visit',
              'Cardiology',
              200.0,
              Icons.home_filled,
            ),
            
            const SizedBox(height: 12),
            
            _buildDemoButton(
              'Emergency Care',
              'emergency',
              null,
              300.0,
              Icons.emergency,
            ),
            
            const Spacer(),
            
            // Integration Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.integration_instructions,
                        color: Color(0xFF1565C0),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Integration Guide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Replace your current SelectProviderScreen import with:\n'
                    'import \'../screens/booking/modern_select_provider_screen.dart\';',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton(
    String title,
    String service,
    String? specialty,
    double price,
    IconData icon,
  ) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectProviderScreen(
              service: service,
              specialty: specialty,
              prix: price,
              paymentMethod: 'cash',
              patientLocation: _patientLocation,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 2,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF1565C0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    if (specialty != null) ...[
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Text(' • '),
                    ],
                    Text(
                      '${price.toStringAsFixed(0)} DZD',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList(List<String> features) {
    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    )).toList();
  }
}

/// Example showing how to integrate with your existing booking flow
class BookingFlowExample extends StatelessWidget {
  const BookingFlowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Flow Integration'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration Steps:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildIntegrationStep(
              '1.',
              'Replace SelectProviderScreen import',
              'Update your imports to use the new modern version',
              Icons.edit,
            ),
            
            _buildIntegrationStep(
              '2.',
              'Update navigation calls',
              'Ensure you pass all required parameters (service, specialty, price, etc.)',
              Icons.navigation,
            ),
            
            _buildIntegrationStep(
              '3.',
              'Update Firestore data',
              'Make sure your professionals collection has the required fields',
              Icons.database,
            ),
            
            _buildIntegrationStep(
              '4.',
              'Test real-time updates',
              'Verify providers appear/disappear when disponible status changes',
              Icons.stream,
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Required Firestore Fields',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ..._buildRequiredFields(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationStep(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          Icon(
            icon,
            color: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRequiredFields() {
    final fields = [
      'login or nom (provider name)',
      'specialite (specialty)',
      'disponible (availability status)',
      'currentlocation (GeoPoint)',
      'rating (double, default 4.0)',
      'price or tarif (service price)',
      'profile_picture (optional)',
      'bio (optional)',
      'experience (optional)',
      'address (optional)',
      'contact (optional)',
    ];

    return fields.map((field) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              field,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}