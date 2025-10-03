import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test screen to verify provider_requests collection recreation
class TestProviderRequestScreen extends StatefulWidget {
  const TestProviderRequestScreen({super.key});

  @override
  State<TestProviderRequestScreen> createState() => _TestProviderRequestScreenState();
}

class _TestProviderRequestScreenState extends State<TestProviderRequestScreen> {
  bool _isCreating = false;
  String _result = '';
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _checkCount();
  }

  Future<void> _checkCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('provider_requests')
          .get();
      
      setState(() {
        _currentCount = snapshot.docs.length;
      });
      
      debugPrint('📊 Current count: $_currentCount documents');
    } catch (e) {
      debugPrint('❌ Error counting: $e');
      setState(() {
        _currentCount = -1;
      });
    }
  }

  Future<void> _createTestRequest() async {
    setState(() {
      _isCreating = true;
      _result = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      debugPrint('🆕 Creating test request...');

      // Calculate expireAt: 10 minutes from now
      final now = DateTime.now();
      final expireAt = Timestamp.fromDate(now.add(const Duration(minutes: 10)));

      final data = {
        'patientId': user.uid,
        'idpat': user.uid,
        'providerId': 'test_provider_123',
        'service': 'Test Service',
        'specialty': 'Test Specialty',
        'prix': 100.0,
        'paymentMethod': 'test',
        'patientLocation': const GeoPoint(33.5731, -7.5898), // Casablanca
        'status': 'pending',
        'appointmentId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'expireAt': expireAt,
      };

      final doc = await FirebaseFirestore.instance
          .collection('provider_requests')
          .add(data);

      debugPrint('✅ Test request created: ${doc.id}');

      setState(() {
        _result = '✅ Success!\n'
            'Document ID: ${doc.id}\n'
            'Collection exists: YES\n'
            'ExpireAt: ${expireAt.toDate()}';
        _isCreating = false;
      });

      // Recount
      await _checkCount();
    } catch (e) {
      debugPrint('❌ Error creating test request: $e');
      
      setState(() {
        _result = '❌ Error: $e';
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Provider Requests'),
        backgroundColor: Colors.blue[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report,
                size: 80,
                color: Colors.blue[700],
              ),
              const SizedBox(height: 24),
              const Text(
                'Test Collection Recreation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current documents:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currentCount == -1 ? 'Error' : '$_currentCount',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _currentCount == 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentCount == 0 
                          ? '⚠️ Collection empty or doesn\'t exist'
                          : '✅ Collection exists with documents',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_isCreating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _createTestRequest,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Test Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _isCreating ? null : _checkCount,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Count'),
              ),
              const SizedBox(height: 24),
              if (_result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result.startsWith('✅') 
                        ? Colors.green[50] 
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _result.startsWith('✅') 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: 14,
                      color: _result.startsWith('✅') 
                          ? Colors.green[900] 
                          : Colors.red[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'How it works:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Tap "Create Test Request"\n'
                      '2. Collection auto-recreates\n'
                      '3. Document expires in 10 minutes\n'
                      '4. Auto-deleted by Cloud Function',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
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
}
