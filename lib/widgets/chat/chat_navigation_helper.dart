import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../screens/chat/patient_chat_screen.dart';
import '../../screens/provider/comprehensive_provider_chat_screen.dart';

class ChatNavigationHelper {
  /// Navigate from patient side to chat with a doctor
  static void navigateToPatientChat({
    required BuildContext context,
    required Map<String, dynamic> doctorInfo,
    String? appointmentId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientChatScreen(
          doctorInfo: doctorInfo,
          appointmentId: appointmentId,
        ),
      ),
    );
  }

  /// Navigate from provider side to chat with a patient
  static void navigateToProviderChat({
    required BuildContext context,
    required Map<String, dynamic> patientInfo,
    String? appointmentId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComprehensiveProviderChatScreen(
          conversation: patientInfo,
        ),
      ),
    );
  }

  /// Create a chat button widget for patient side
  static Widget buildPatientChatButton({
    required BuildContext context,
    required Map<String, dynamic> doctorInfo,
    String? appointmentId,
    String? buttonText,
    IconData? icon,
    Color? color,
    bool isFloating = false,
  }) {
    final buttonColor = color ?? AppTheme.primaryColor;
    final text = buttonText ?? 'Chat with Doctor';
    final iconData = icon ?? Icons.chat;

    if (isFloating) {
      return FloatingActionButton.extended(
        onPressed: () => navigateToPatientChat(
          context: context,
          doctorInfo: doctorInfo,
          appointmentId: appointmentId,
        ),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        icon: Icon(iconData),
        label: Text(text),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => navigateToPatientChat(
        context: context,
        doctorInfo: doctorInfo,
        appointmentId: appointmentId,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(iconData),
      label: Text(text),
    );
  }

  /// Create a chat button widget for provider side
  static Widget buildProviderChatButton({
    required BuildContext context,
    required Map<String, dynamic> patientInfo,
    String? appointmentId,
    String? buttonText,
    IconData? icon,
    Color? color,
    bool isFloating = false,
  }) {
    final buttonColor = color ?? AppTheme.primaryColor;
    final text = buttonText ?? 'Chat with Patient';
    final iconData = icon ?? Icons.chat;

    if (isFloating) {
      return FloatingActionButton.extended(
        onPressed: () => navigateToProviderChat(
          context: context,
          patientInfo: patientInfo,
          appointmentId: appointmentId,
        ),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        icon: Icon(iconData),
        label: Text(text),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => navigateToProviderChat(
        context: context,
        patientInfo: patientInfo,
        appointmentId: appointmentId,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(iconData),
      label: Text(text),
    );
  }

  /// Create a chat icon button for quick access
  static Widget buildChatIconButton({
    required BuildContext context,
    required bool isProvider,
    required Map<String, dynamic> userInfo,
    String? appointmentId,
    Color? color,
    double? size,
  }) {
    return IconButton(
      onPressed: () {
        if (isProvider) {
          navigateToProviderChat(
            context: context,
            patientInfo: userInfo,
            appointmentId: appointmentId,
          );
        } else {
          navigateToPatientChat(
            context: context,
            doctorInfo: userInfo,
            appointmentId: appointmentId,
          );
        }
      },
      icon: Icon(
        Icons.chat_bubble_outline,
        color: color ?? AppTheme.primaryColor,
        size: size ?? 24,
      ),
    );
  }

  /// Create a chat tile for lists (like appointment lists, contact lists)
  static Widget buildChatTile({
    required BuildContext context,
    required bool isProvider,
    required Map<String, dynamic> userInfo,
    String? appointmentId,
    String? subtitle,
  }) {
    final name = isProvider 
        ? userInfo['patientName'] ?? 'Patient'
        : 'Dr. ${userInfo['name'] ?? 'Doctor'}';
    
    final subtitleText = subtitle ?? 
        (isProvider ? 'Tap to chat with patient' : 'Tap to chat with doctor');

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          isProvider ? Icons.person : Icons.local_hospital,
          color: Colors.white,
          size: 28,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitleText),
      trailing: const Icon(
        Icons.chat_bubble_outline,
        color: AppTheme.primaryColor,
      ),
      onTap: () {
        if (isProvider) {
          navigateToProviderChat(
            context: context,
            patientInfo: userInfo,
            appointmentId: appointmentId,
          );
        } else {
          navigateToPatientChat(
            context: context,
            doctorInfo: userInfo,
            appointmentId: appointmentId,
          );
        }
      },
    );
  }

  /// Show a bottom sheet with chat options
  static void showChatOptions({
    required BuildContext context,
    required bool isProvider,
    required Map<String, dynamic> userInfo,
    String? appointmentId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Communication Options',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCommunicationOption(
                            context: context,
                            icon: Icons.chat,
                            title: 'Message',
                            subtitle: 'Send a message',
                            color: AppTheme.primaryColor,
                            onTap: () {
                              Navigator.pop(context);
                              if (isProvider) {
                                navigateToProviderChat(
                                  context: context,
                                  patientInfo: userInfo,
                                  appointmentId: appointmentId,
                                );
                              } else {
                                navigateToPatientChat(
                                  context: context,
                                  doctorInfo: userInfo,
                                  appointmentId: appointmentId,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCommunicationOption(
                            context: context,
                            icon: Icons.call,
                            title: 'Call',
                            subtitle: 'Voice call',
                            color: Colors.green,
                            onTap: () {
                              Navigator.pop(context);
                              _showCallDialog(context, 'Voice Call', Icons.call);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCommunicationOption(
                            context: context,
                            icon: Icons.videocam,
                            title: 'Video',
                            subtitle: 'Video call',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.pop(context);
                              _showCallDialog(context, 'Video Call', Icons.videocam);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCommunicationOption(
                            context: context,
                            icon: Icons.emergency,
                            title: 'Emergency',
                            subtitle: 'Urgent help',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              _showEmergencyDialog(context, isProvider);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCommunicationOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showCallDialog(BuildContext context, String title, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text('$title feature will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showEmergencyDialog(BuildContext context, bool isProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency'),
          ],
        ),
        content: Text(
          isProvider 
              ? 'Emergency protocols will be activated. This will alert emergency services and relevant medical staff.'
              : 'This will send an emergency alert to your doctor and emergency services if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Activate Emergency', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}