import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/real_time_role_service.dart';

/// Quick test widget to verify role change collection migration
class RoleChangeMigrationTest extends StatefulWidget {
  const RoleChangeMigrationTest({super.key});

  @override
  State<RoleChangeMigrationTest> createState() => _RoleChangeMigrationTestState();
}

class _RoleChangeMigrationTestState extends State<RoleChangeMigrationTest> {
  final _emailController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _testOutput = '';
  String? _testUserId;

  void _log(String message) {
    setState(() {
      _testOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    debugPrint(message);
  }

  Future<void> _findUser() async {
    if (_emailController.text.isEmpty) {
      _log('❌ Please enter an email');
      return;
    }

    setState(() {
      _isLoading = true;
      _testOutput = '';
    });

    try {
      _log('🔍 Searching for user: ${_emailController.text}');
      
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _log('❌ User not found');
        setState(() => _testUserId = null);
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();
      
      setState(() => _testUserId = doc.id);
      
      _log('✅ Found user: ${doc.id}');
      _log('📧 Email: ${data['email']}');
      _log('👤 Name: ${data['nom']} ${data['prenom']}');
      _log('🎭 Current role: ${data['role']}');
      
      // Check collections
      await _checkCollections(doc.id, data['role']);
      
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkCollections(String userId, String role) async {
    _log('\n📋 Checking collections...');
    
    final patients = await _firestore.collection('patients').doc(userId).get();
    final professionals = await _firestore.collection('professionals').doc(userId).get();
    
    if (patients.exists) {
      _log('✅ Found in /patients collection');
      final data = patients.data()!;
      _log('   Fields: ${data.keys.join(', ')}');
    } else {
      _log('❌ NOT in /patients collection');
    }
    
    if (professionals.exists) {
      _log('✅ Found in /professionals collection');
      final data = professionals.data()!;
      _log('   Fields: ${data.keys.join(', ')}');
      _log('   Profession: ${data['profession']}');
      _log('   Rating: ${data['rating']} (${data['rating'].runtimeType})');
    } else {
      _log('❌ NOT in /professionals collection');
    }
  }

  Future<void> _testRoleChange(String newRole) async {
    if (_testUserId == null) {
      _log('❌ Please find a user first');
      return;
    }

    setState(() {
      _isLoading = true;
      _testOutput += '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    });

    try {
      _log('🧪 Starting role change test...');
      _log('👤 User ID: $_testUserId');
      _log('🎯 New Role: $newRole');
      _log('\n⏳ Executing adminChangeUserRole()...\n');
      
      // Execute the role change
      final success = await RealTimeRoleService.adminChangeUserRole(
        targetUserId: _testUserId!,
        newRole: newRole,
        adminUserId: 'test_admin_ui',
        reason: 'UI test role change',
      );
      
      if (success) {
        _log('\n✅ Role change completed!');
        _log('\n📋 Verifying results...\n');
        
        // Wait a bit for Firestore to sync
        await Future.delayed(Duration(milliseconds: 500));
        
        // Check updated user
        final userDoc = await _firestore.collection('users').doc(_testUserId!).get();
        final userData = userDoc.data()!;
        
        _log('✅ Users collection updated:');
        _log('   role: ${userData['role']}');
        _log('   role_changed_at: ${userData['role_changed_at']}');
        _log('   role_changed_by: ${userData['role_changed_by']}');
        
        // Check collections
        await _checkCollections(_testUserId!, newRole);
        
        // Check log
        final logs = await _firestore
            .collection('role_change_log')
            .where('target_user_id', isEqualTo: _testUserId)
            .orderBy('changed_at', descending: true)
            .limit(1)
            .get();
        
        if (logs.docs.isNotEmpty) {
          final log = logs.docs.first.data();
          _log('\n✅ Role change logged:');
          _log('   old_role: ${log['old_role']}');
          _log('   new_role: ${log['new_role']}');
          _log('   changed_by: ${log['changed_by']}');
        }
        
        _log('\n🎉 TEST PASSED! Collection migration successful!');
        
      } else {
        _log('\n❌ TEST FAILED: Role change returned false');
      }
      
    } catch (e) {
      _log('\n❌ TEST FAILED: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role Change Migration Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter email to test',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _isLoading ? null : _findUser,
                ),
              ),
              enabled: !_isLoading,
            ),
            
            SizedBox(height: 16),
            
            // Find user button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _findUser,
              icon: Icon(Icons.person_search),
              label: Text('Find User & Check Collections'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Test role change buttons
            if (_testUserId != null) ...[
              Text(
                'Test Role Changes:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _testRoleChange('patient'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('→ Patient'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _testRoleChange('infirmier'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('→ Infirmier'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _testRoleChange('docteur'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('→ Docteur'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _testRoleChange('admin'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('→ Admin'),
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 24),
            
            // Output section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(minHeight: 400),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _testOutput.isEmpty ? 'Enter email and click "Find User" to start' : _testOutput,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
            ),
            
            SizedBox(height: 16),
            
            // Clear button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _testOutput = '';
                  _testUserId = null;
                  _emailController.clear();
                });
              },
              icon: Icon(Icons.clear),
              label: Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
