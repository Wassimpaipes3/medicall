import 'package:flutter/material.dart';
import 'package:firstv/services/provider_request_cleanup_helper.dart';

/// Simple button widget to trigger manual cleanup of provider_requests
/// Add this anywhere in your app (settings screen, debug menu, etc.)
class CleanupRequestsButton extends StatefulWidget {
  const CleanupRequestsButton({super.key});

  @override
  State<CleanupRequestsButton> createState() => _CleanupRequestsButtonState();
}

class _CleanupRequestsButtonState extends State<CleanupRequestsButton> {
  bool _isLoading = false;

  Future<void> _handleCleanup() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Cleanup'),
        content: const Text(
          'This will delete ALL provider_requests documents.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Call the cleanup function
      final result = await ProviderRequestCleanupHelper.cleanupAllRequests();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${result['message']}\nDeleted: ${result['deleted']} documents',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleCleanup,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.delete_sweep),
      label: Text(_isLoading ? 'Cleaning...' : 'Clean Old Requests'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Floating Action Button version for quick access
class CleanupRequestsFAB extends StatefulWidget {
  const CleanupRequestsFAB({super.key});

  @override
  State<CleanupRequestsFAB> createState() => _CleanupRequestsFABState();
}

class _CleanupRequestsFABState extends State<CleanupRequestsFAB> {
  bool _isLoading = false;

  Future<void> _handleCleanup() async {
    setState(() => _isLoading = true);

    try {
      final result = await ProviderRequestCleanupHelper.cleanupAllRequests();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Deleted ${result['deleted']} old requests'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _handleCleanup,
      backgroundColor: Colors.red[700],
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.cleaning_services),
      label: Text(_isLoading ? 'Cleaning...' : 'Cleanup'),
    );
  }
}
