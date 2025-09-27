import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'provider/provider_service.dart';
import '../data/models/location_models.dart' as location_models;

enum NotificationType {
  newAppointmentRequest,
  appointmentAccepted,
  appointmentCancelled,
  emergencyRequest,
  messageReceived,
  paymentReceived,
}

class NotificationData {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;

  const NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.data = const {},
    this.isRead = false,
  });

  NotificationData copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<NotificationData> _notificationController = 
      StreamController<NotificationData>.broadcast();
  final StreamController<List<NotificationData>> _notificationListController = 
      StreamController<List<NotificationData>>.broadcast();

  Stream<NotificationData> get notificationStream => _notificationController.stream;
  Stream<List<NotificationData>> get notificationListStream => _notificationListController.stream;

  final List<NotificationData> _notifications = [];
  GlobalKey<NavigatorState>? navigatorKey;

  List<NotificationData> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// Show new appointment request notification
  void showNewAppointmentRequest(AppointmentRequest request) {
    final notification = NotificationData(
      id: 'appointment_${request.id}',
      title: request.isEmergency ? '🚨 Emergency Request!' : '📋 New Appointment Request',
      message: '${request.patientName} requested ${request.serviceType}',
      type: request.isEmergency ? NotificationType.emergencyRequest : NotificationType.newAppointmentRequest,
      timestamp: DateTime.now(),
      data: {
        'appointmentId': request.id,
        'patientId': request.patientId,
        'patientName': request.patientName,
        'patientPhone': request.patientPhone,
        'serviceType': request.serviceType,
        'location': request.patientLocationString,
        'estimatedFee': request.estimatedFee,
        'estimatedDuration': request.estimatedDuration,
        'isEmergency': request.isEmergency,
        'specialInstructions': request.specialInstructions,
      },
    );

    _addNotification(notification);
    _showInAppNotification(notification);
    _triggerHapticFeedback(request.isEmergency);
  }

  /// Send notification to provider about new patient booking
  Future<void> notifyProviderOfNewBooking({
    required String patientName,
    required String serviceType,
    required String appointmentId,
    required DateTime appointmentTime,
    required String location,
    double? estimatedFee,
    bool isEmergency = false,
  }) async {
    try {
      // Create notification for providers
      final notification = NotificationData(
        id: 'booking_$appointmentId',
        title: isEmergency ? '🚨 Emergency Booking!' : '📅 New Appointment Booking',
        message: '$patientName booked $serviceType for ${_formatDateTime(appointmentTime)}',
        type: isEmergency ? NotificationType.emergencyRequest : NotificationType.newAppointmentRequest,
        timestamp: DateTime.now(),
        data: {
          'appointmentId': appointmentId,
          'patientName': patientName,
          'serviceType': serviceType,
          'appointmentTime': appointmentTime.toIso8601String(),
          'location': location,
          'estimatedFee': estimatedFee,
          'isEmergency': isEmergency,
        },
      );

      _addNotification(notification);
      _showInAppNotification(notification);
      
      if (isEmergency) {
        _triggerHapticFeedback(true);
        // Show priority notification for emergency
        _showEmergencyNotificationOverlay(notification);
      }

      // TODO: In a real implementation, this would:
      // 1. Send push notification to relevant providers
      // 2. Store notification in backend database
      // 3. Use real-time messaging (WebSocket/Firebase)
      
      print('Provider notification sent for booking: $appointmentId');
      
    } catch (e) {
      print('Error sending provider notification: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (appointmentDate == today) {
      return 'Today at $timeStr';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month} at $timeStr';
    }
  }

  void _showEmergencyNotificationOverlay(NotificationData notification) {
    // Show a full-screen emergency overlay for critical notifications
    if (navigatorKey?.currentContext != null) {
      showDialog(
        context: navigatorKey!.currentContext!,
        barrierDismissible: false,
        builder: (context) => _buildEmergencyOverlay(notification),
      );
    }
  }

  Widget _buildEmergencyOverlay(NotificationData notification) {
    return Material(
      color: Colors.red.withOpacity(0.95),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                notification.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                notification.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(navigatorKey!.currentContext!).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(navigatorKey!.currentContext!).pop();
                        // TODO: Navigate to appointment details
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show appointment accepted notification (for patients)
  void showAppointmentAccepted(AppointmentRequest request, String providerName) {
    final notification = NotificationData(
      id: 'accepted_${request.id}',
      title: '✅ Appointment Accepted',
      message: 'Dr. $providerName accepted your appointment request',
      type: NotificationType.appointmentAccepted,
      timestamp: DateTime.now(),
      data: {
        'appointmentId': request.id,
        'providerName': providerName,
      },
    );

    _addNotification(notification);
    _showInAppNotification(notification);
  }

  /// Show message notification
  void showMessageReceived(String senderName, String message) {
    final notification = NotificationData(
      id: 'message_${DateTime.now().millisecondsSinceEpoch}',
      title: '💬 New Message',
      message: '$senderName: $message',
      type: NotificationType.messageReceived,
      timestamp: DateTime.now(),
      data: {
        'senderName': senderName,
        'messageContent': message,
      },
    );

    _addNotification(notification);
    _showInAppNotification(notification);
  }

  /// Add notification to list
  void _addNotification(NotificationData notification) {
    _notifications.insert(0, notification);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }
    _notificationController.add(notification);
    _notificationListController.add(_notifications);
  }

  /// Show in-app notification overlay
  void _showInAppNotification(NotificationData notification) {
    if (navigatorKey?.currentContext == null) return;

    final context = navigatorKey!.currentContext!;
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        notification: notification,
        onTap: () {
          overlayEntry.remove();
          _handleNotificationTap(notification, context);
        },
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 5 seconds (or 8 seconds for emergency)
    Timer(Duration(seconds: notification.type == NotificationType.emergencyRequest ? 8 : 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationData notification, BuildContext context) {
    markAsRead(notification.id);

    switch (notification.type) {
      case NotificationType.newAppointmentRequest:
      case NotificationType.emergencyRequest:
        // Navigate to appointment details
        Navigator.of(context).pushNamed(
          '/provider-appointment-details',
          arguments: {
            'appointmentId': notification.data['appointmentId'],
            'patientData': notification.data,
          },
        );
        break;
      case NotificationType.messageReceived:
        // Navigate to messages
        Navigator.of(context).pushNamed('/provider-messages');
        break;
      case NotificationType.appointmentAccepted:
        // Navigate to appointments
        Navigator.of(context).pushNamed('/provider-appointments');
        break;
      default:
        break;
    }
  }

  /// Trigger haptic feedback
  void _triggerHapticFeedback(bool isEmergency) {
    if (isEmergency) {
      HapticFeedback.heavyImpact();
      // Additional vibration pattern for emergency
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationListController.add(_notifications);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notificationListController.add(_notifications);
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _notificationListController.add(_notifications);
  }

  /// Simulate receiving a new appointment request (for testing)
  void simulateNewAppointmentRequest() {
    final request = AppointmentRequest(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'patient_123',
      patientName: 'John Smith',
      patientPhone: '+1 234 567 8900',
      patientLocation: location_models.UserLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        address: '123 Main St, San Francisco, CA',
        timestamp: DateTime.now(),
      ),
      serviceType: 'General Consultation',
      requestedDateTime: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      estimatedFee: 150.0,
      estimatedDuration: 30,
      isEmergency: false,
      specialInstructions: 'Patient has mild fever and headache',
    );

    showNewAppointmentRequest(request);
  }

  /// Initialize with mock data
  void initializeMockData() {
    // Mock data could be added here if needed for testing
  }

  void dispose() {
    _notificationController.close();
    _notificationListController.close();
  }
}

/// In-app notification widget
class _InAppNotificationWidget extends StatefulWidget {
  final NotificationData notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationWidget({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getNotificationColor(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getNotificationIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.notification.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (widget.notification.type) {
      case NotificationType.emergencyRequest:
        return const Color(0xFFEF4444);
      case NotificationType.newAppointmentRequest:
        return const Color(0xFF3B82F6);
      case NotificationType.appointmentAccepted:
        return const Color(0xFF10B981);
      case NotificationType.messageReceived:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case NotificationType.emergencyRequest:
        return Icons.emergency;
      case NotificationType.newAppointmentRequest:
        return Icons.calendar_today;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle;
      case NotificationType.messageReceived:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? actionUrl;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.actionUrl,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? actionUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}
