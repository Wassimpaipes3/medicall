import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount--;
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      if (!_notifications[index].isRead) {
        _unreadCount--;
      }
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  // Initialize with mock data
  void initializeMockData() {
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Appointment Reminder',
        message: 'Your appointment with Dr. Sarah Johnson is tomorrow at 10:00 AM',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.appointment,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Lab Results Available',
        message: 'Your recent blood test results are now available in your profile',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.labResults,
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Prescription Reminder',
        message: 'Time to refill your prescription for Lisinopril',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.prescription,
        isRead: true,
      ),
    ];
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }
}

enum NotificationType {
  appointment,
  labResults,
  prescription,
  general,
  emergency,
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
