import 'package:flutter/material.dart';
import '../../services/role_redirect_service.dart';
import '../../services/real_time_role_service.dart';

/// Debug screen to test role changes and document creation
class RoleDebugScreen extends StatefulWidget {
  const RoleDebugScreen({super.key});

  @override
  State<RoleDebugScreen> createState() => _RoleDebugScreenState();
}

class _RoleDebugScreenState extends State<RoleDebugScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _output = '';

  void _log(String message) {
    setState(() {
      _output += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print(message);
  }

  Future<void> _testRoleChange(String newRole) async {
    if (_emailController.text.isEmpty) {
      _log('❌ Please enter an email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      _log('🧪 Testing role change to: $newRole');
      _log('📧 Email: ${_emailController.text}');

      // Test role change
      final success = await RealTimeRoleService.adminChangeUserRole(
        targetUserId: 'test_user_id', // In real app, get user ID from email
        newRole: newRole,
        adminUserId: 'debug_admin',
        reason: 'Debug test role change',
      );

      if (success) {
        _log('✅ Role change initiated successfully');
      } else {
        _log('❌ Role change failed');
      }

      // Test document creation directly
      _log('📋 Testing document creation...');
      await RoleRedirectService.ensureRoleDocument('test_user_id', newRole);
      _log('✅ Document creation test completed');

    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role Change Debug'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter user email to test',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Role change buttons
            Text(
              'Test Role Changes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testRoleChange('patient'),
                    child: Text('→ Patient'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testRoleChange('doctor'),
                    child: Text('→ Docteur'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testRoleChange('professional'),
                    child: Text('→ Professional'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testRoleChange('admin'),
                    child: Text('→ Admin'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Output log
            Text(
              'Debug Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'No output yet...' : _output,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Clear button
            if (_output.isNotEmpty)
              ElevatedButton(
                onPressed: () => setState(() => _output = ''),
                child: Text('Clear Output'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
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