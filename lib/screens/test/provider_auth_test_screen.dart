import 'package:flutter/material.dart';
import '../../services/provider_auth_service.dart';
import '../../services/auth_service.dart';
import '../../data/models/provider_profile.dart';

class ProviderAuthTestScreen extends StatefulWidget {
  const ProviderAuthTestScreen({super.key});

  @override
  _ProviderAuthTestScreenState createState() => _ProviderAuthTestScreenState();
}

class _ProviderAuthTestScreenState extends State<ProviderAuthTestScreen> {
  final _emailController = TextEditingController(text: 'test.provider@example.com');
  final _passwordController = TextEditingController(text: 'testpass123');
  
  ProviderProfile? _currentProvider;
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Auth Test'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider Authentication Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Provider Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testProviderLogin,
                            child: _isLoading 
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Test Provider Login'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testGetCurrentProvider,
                            child: Text('Get Current Provider'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testIsProvider,
                            child: Text('Check Is Provider'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testCreateProfile,
                            child: Text('Create Test Profile'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Current Provider Info
            if (_currentProvider != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Provider Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow('Login', _currentProvider!.login),
                      _buildInfoRow('Profession', _currentProvider!.profession),
                      _buildInfoRow('Specialité', _currentProvider!.specialite),
                      _buildInfoRow('Service', _currentProvider!.service),
                      _buildInfoRow('Rating', _currentProvider!.rating.toString()),
                      _buildInfoRow('Disponible', _currentProvider!.disponible ? 'Oui' : 'Non'),
                      _buildInfoRow('Bio', _currentProvider!.bio),
                      _buildInfoRow('User ID', _currentProvider!.idUser),
                      _buildInfoRow('Pro ID', _currentProvider!.idpro ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Test Results
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResults.isEmpty ? 'Run tests to see results...' : _testResults,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _testResults = '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: Text('Clear Results'),
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
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  void _addTestResult(String result) {
    setState(() {
      _testResults += '${DateTime.now().toString().substring(11, 19)} - $result\n';
    });
  }
  
  Future<void> _testProviderLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addTestResult('🧪 Testing Provider Login...');
      
      final result = await ProviderAuthService.providerLogin(
        _emailController.text,
        _passwordController.text,
      );
      
      if (result['success'] == true) {
        _addTestResult('✅ Login successful');
        _addTestResult('👤 User: ${result['user']?.email}');
        
        // Get provider profile after login
        final profile = await ProviderAuthService.getCurrentProviderProfile();
        if (profile != null) {
          setState(() {
            _currentProvider = profile;
          });
          _addTestResult('📋 Provider profile loaded successfully');
          _addTestResult('🏥 Profession: ${profile.profession}');
          _addTestResult('⚕️ Specialité: ${profile.specialite}');
        } else {
          _addTestResult('⚠️ Provider profile not found');
        }
      } else {
        _addTestResult('❌ Login failed: ${result['error']}');
      }
      
    } catch (e) {
      _addTestResult('💥 Login error: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _testGetCurrentProvider() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addTestResult('🧪 Testing Get Current Provider...');
      
      final profile = await ProviderAuthService.getCurrentProviderProfile();
      
      if (profile != null) {
        setState(() {
          _currentProvider = profile;
        });
        _addTestResult('✅ Provider profile retrieved successfully');
        _addTestResult('👤 Login: ${profile.login}');
        _addTestResult('🏥 Profession: ${profile.profession}');
      } else {
        _addTestResult('❌ No provider profile found');
      }
      
    } catch (e) {
      _addTestResult('💥 Get provider error: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _testIsProvider() async {
    try {
      _addTestResult('🧪 Testing Is Provider Check...');
      
      final isProvider = await ProviderAuthService.isCurrentUserProvider();
      
      if (isProvider) {
        _addTestResult('✅ Current user IS a provider');
      } else {
        _addTestResult('❌ Current user is NOT a provider');
      }
      
    } catch (e) {
      _addTestResult('💥 Is provider check error: $e');
    }
  }
  
  Future<void> _testCreateProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addTestResult('🧪 Testing Create Provider Profile...');
      
      // First check if user is authenticated
      final authService = AuthService();
      final currentUser = authService.getCurrentUser();
      
      if (currentUser == null) {
        _addTestResult('❌ No authenticated user found');
        return;
      }
      
      // Create a test profile
      final testProfile = ProviderProfile(
        bio: 'Test provider bio - Experienced healthcare professional',
        disponible: true,
        idUser: currentUser.uid,
        idpro: 'PRO_${DateTime.now().millisecondsSinceEpoch}',
        login: currentUser.email ?? 'test@provider.com',
        profession: 'Médecin généraliste',
        rating: 4.5,
        service: 'Consultation générale',
        specialite: 'Médecine générale',
      );
      
      await ProviderAuthService.updateProviderProfile(testProfile);
      
      _addTestResult('✅ Provider profile created/updated successfully');
      
      // Refresh the current profile
      await _testGetCurrentProvider();
      
    } catch (e) {
      _addTestResult('💥 Create profile error: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
}