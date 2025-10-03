import 'package:flutter/material.dart';
import 'package:firstv/services/provider_request_cleanup_helper.dart';

/// Debug screen to manually cleanup provider_requests
/// Add this to your app temporarily to run cleanup
class CleanupProviderRequestsScreen extends StatefulWidget {
  const CleanupProviderRequestsScreen({super.key});

  @override
  State<CleanupProviderRequestsScreen> createState() => _CleanupProviderRequestsScreenState();
}

class _CleanupProviderRequestsScreenState extends State<CleanupProviderRequestsScreen> {
  bool _isLoading = false;
  String _result = '';
  int _currentCount = -1;

  @override
  void initState() {
    super.initState();
    _checkCount();
  }

  Future<void> _checkCount() async {
    final count = await ProviderRequestCleanupHelper.countProviderRequests();
    setState(() {
      _currentCount = count;
    });
  }

  Future<void> _runCleanup() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final result = await ProviderRequestCleanupHelper.cleanupAllRequests();
      
      setState(() {
        _result = '✅ Success!\n${result['message']}\nDeleted: ${result['deleted']} documents';
        _isLoading = false;
      });

      // Recount after cleanup
      await _checkCount();
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleanup Provider Requests'),
        backgroundColor: Colors.red[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_sweep,
                size: 80,
                color: Colors.red[700],
              ),
              const SizedBox(height: 24),
              const Text(
                'Manual Cleanup Tool',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current documents: ${_currentCount == -1 ? 'Loading...' : _currentCount}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _currentCount > 0 ? _runCleanup : null,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Delete All Provider Requests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
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
              TextButton.icon(
                onPressed: _checkCount,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Count'),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: After cleanup, automatic deletion will work for new requests (10 min expiry)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
