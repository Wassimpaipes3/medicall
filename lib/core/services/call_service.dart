import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Universal call service that handles phone calls consistently across the app
class CallService {
  static const String _emergencyNumber = '911';
  
  /// Make a call to the provided phone number
  /// Returns true if call was initiated successfully, false otherwise
  static Future<bool> makeCall(
    String phoneNumber, {
    BuildContext? context,
    bool showFeedback = true,
  }) async {
    try {
      // Validate phone number
      if (phoneNumber.trim().isEmpty) {
        if (context != null && showFeedback) {
          _showSnackBar(
            context,
            'Phone number is not available',
            Colors.orange,
          );
        }
        return false;
      }

      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      // Create phone URI
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

      // Provide haptic feedback
      if (showFeedback) {
        HapticFeedback.lightImpact();
      }

      // Attempt to launch the phone app
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return true;
      } else {
        if (context != null && showFeedback) {
          _showSnackBar(
            context,
            'Unable to make phone call. Please check if your device supports calling.',
            Colors.red,
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null && showFeedback) {
        _showSnackBar(
          context,
          'Error making phone call: ${e.toString()}',
          Colors.red,
        );
      }
      return false;
    }
  }

  /// Make an emergency call (911)
  static Future<bool> makeEmergencyCall({
    BuildContext? context,
    bool showConfirmation = true,
  }) async {
    if (context != null && showConfirmation) {
      // Show confirmation dialog for emergency calls
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text(
                  'Emergency Call',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Do you need to contact emergency services? This will call 911 immediately.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Call 911'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return false;
      }
    }

    return await makeCall(
      _emergencyNumber,
      context: context,
      showFeedback: true,
    );
  }

  /// Check if the device can make phone calls
  static Future<bool> canMakePhoneCalls() async {
    try {
      final Uri testUri = Uri(scheme: 'tel', path: '');
      return await canLaunchUrl(testUri);
    } catch (e) {
      return false;
    }
  }

  /// Clean and format phone number for calling
  static String _cleanPhoneNumber(String phoneNumber) {
    // Remove common formatting characters
    return phoneNumber
        .replaceAll(RegExp(r'[^\d+]'), '') // Keep only digits and +
        .trim();
  }

  /// Show a snackbar with the given message
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Create a standardized call button widget
  static Widget createCallButton({
    required String phoneNumber,
    required VoidCallback? onPressed,
    String? label,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? size,
    bool isEmergency = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? (isEmergency ? Colors.red : Colors.green),
        borderRadius: BorderRadius.circular(size != null ? size / 2 : 28),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? (isEmergency ? Colors.red : Colors.green))
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size != null ? size / 2 : 28),
          child: Container(
            width: size ?? 56,
            height: size ?? 56,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon ?? (isEmergency ? Icons.emergency : Icons.call),
                  color: foregroundColor ?? Colors.white,
                  size: (size != null ? size * 0.4 : 24),
                ),
                if (label != null && size != null && size > 80) ...[
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Create a call button specifically for provider/doctor calls
  static Widget createDoctorCallButton({
    required String phoneNumber,
    required BuildContext context,
    String doctorName = 'Doctor',
    double? size,
  }) {
    return createCallButton(
      phoneNumber: phoneNumber,
      onPressed: phoneNumber.isNotEmpty
          ? () => makeCall(phoneNumber, context: context)
          : null,
      label: 'Call',
      icon: Icons.call,
      backgroundColor: Colors.green,
      size: size,
    );
  }

  /// Create an emergency call button
  static Widget createEmergencyCallButton({
    required BuildContext context,
    double? size,
  }) {
    return createCallButton(
      phoneNumber: _emergencyNumber,
      onPressed: () => makeEmergencyCall(context: context),
      label: 'Emergency',
      icon: Icons.emergency,
      backgroundColor: Colors.red,
      isEmergency: true,
      size: size,
    );
  }
}