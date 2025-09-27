import 'package:flutter/material.dart';

/// Centralized navigation configuration for consistent navigation behavior
class NavigationConfig {
  
  /// Patient navigation configuration
  static const patientNavigation = PatientNavigationConfig();
  
  /// Provider navigation configuration  
  static const providerNavigation = ProviderNavigationConfig();
}

class PatientNavigationConfig {
  const PatientNavigationConfig();
  
  /// Patient navigation items in display order
  List<NavigationItem> get items => [
    NavigationItem(
      index: 0,
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: '/home',
      semanticLabel: 'Navigate to Home dashboard',
    ),
    NavigationItem(
      index: 1,
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat_rounded,
      label: 'Chat',
      route: '/chat',
      semanticLabel: 'Access messages and chat',
    ),
    NavigationItem(
      index: 2,
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Schedule',
      route: '/appointments',
      semanticLabel: 'View and manage appointments',
    ),
    NavigationItem(
      index: 3,
      icon: Icons.person_outlined,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
      semanticLabel: 'View and edit profile',
    ),
  ];
}

class ProviderNavigationConfig {
  const ProviderNavigationConfig();
  
  /// Provider navigation items in display order
  List<NavigationItem> get items => [
    NavigationItem(
      index: 0,
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Dashboard',
      route: '/provider-dashboard',
      semanticLabel: 'Provider dashboard overview',
    ),
    NavigationItem(
      index: 1,
      icon: Icons.message_outlined,
      activeIcon: Icons.message_rounded,
      label: 'Messages',
      route: '/provider-messages',
      semanticLabel: 'Patient messages and communication',
    ),
    NavigationItem(
      index: 2,
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Schedule',
      route: '/provider-appointments',
      semanticLabel: 'Appointment scheduling and management',
    ),
    NavigationItem(
      index: 3,
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/provider-profile',
      semanticLabel: 'Provider profile and settings',
    ),
  ];
}

class NavigationItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String semanticLabel;
  
  const NavigationItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.semanticLabel,
  });
}

/// Navigation behavior configuration
class NavigationBehavior {
  /// Animation duration for navigation transitions
  static const Duration transitionDuration = Duration(milliseconds: 300);
  
  /// Animation curve for navigation transitions
  static const Curve transitionCurve = Curves.easeInOut;
  
  /// Haptic feedback enabled
  static const bool enableHapticFeedback = true;
  
  /// Visual feedback enabled
  static const bool enableVisualFeedback = true;
  
  /// Accessibility features enabled
  static const bool enableAccessibility = true;
}
