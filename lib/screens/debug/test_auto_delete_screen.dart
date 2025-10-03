import 'package:flutter/material.dart';
import 'package:firstv/utils/test_auto_delete.dart';

/// Simple test screen to verify auto-deletion works
class TestAutoDeleteScreen extends StatefulWidget {
  const TestAutoDeleteScreen({super.key});

  @override
  State<TestAutoDeleteScreen> createState() => _TestAutoDeleteScreenState();
}

class _TestAutoDeleteScreenState extends State<TestAutoDeleteScreen> {
  String _result = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Auto-Delete'),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 80,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 24),
            const Text(
              'Auto-Delete Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ How it works:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Creates document that expires in 2 minutes\n'
                    '2. Cloud Function runs every 5 minutes\n'
                    '3. Function deletes expired documents\n'
                    '4. Document disappears in 2-7 minutes',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _result = '';
                      });

                      await testAutoDeleteFunction();

                      setState(() {
                        _isLoading = false;
                        _result = '✅ Test document created!\n\n'
                            'Wait 2-7 minutes and check:\n'
                            '• Firebase Console\n'
                            '• Function logs\n'
                            '• Tap "Check Status" below';
                      });
                    },
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_alarm),
              label: Text(_isLoading ? 'Creating...' : 'Create Test Document (2 min)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                setState(() => _result = 'Loading...');
                await listAllRequestsWithExpiry();
                setState(() => _result = '✅ Check console for results');
              },
              icon: const Icon(Icons.list),
              label: const Text('List All Requests'),
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  _result,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[900],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 Console Commands:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'firebase functions:log | Select-String "cleanupExpiredRequests"',
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
}
