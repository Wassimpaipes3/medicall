import 'package:flutter/material.dart';

/// Navigation State Controller for managing app-wide navigation state
class NavigationController extends ChangeNotifier {
  static final NavigationController _instance = NavigationController._internal();
  factory NavigationController() => _instance;
  NavigationController._internal();

  int _currentIndex = 0;
  int _notificationCount = 0;
  bool _isProfileActive = false;
  String _currentRoute = '/home';

  // Getters
  int get currentIndex => _currentIndex;
  int get notificationCount => _notificationCount;
  bool get isProfileActive => _isProfileActive;
  String get currentRoute => _currentRoute;

  // Setters with notification
  void setCurrentIndex(int index) {
    _currentIndex = index;
    _isProfileActive = (index == 3); // Profile is now at index 3
    notifyListeners();
  }

  void setCurrentRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  void updateNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }

  void decrementNotificationCount() {
    if (_notificationCount > 0) {
      _notificationCount--;
      notifyListeners();
    }
  }

  void resetProfileState() {
    _isProfileActive = false;
    notifyListeners();
  }

  // Navigation helpers
  void navigateToHome(BuildContext context) {
    setCurrentIndex(0);
    setCurrentRoute('/home');
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void navigateToProfile(BuildContext context) {
    setCurrentIndex(3);
    setCurrentRoute('/profile');
    _isProfileActive = true;
    Navigator.pushNamed(context, '/profile');
  }

  void navigateToLogin(BuildContext context) {
    setCurrentIndex(0);
    setCurrentRoute('/login');
    resetProfileState();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
