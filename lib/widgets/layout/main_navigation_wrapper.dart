import 'package:flutter/material.dart';
import '../patient/patient_navigation_bar.dart';
import '../../services/notification_service.dart';
import '../../controllers/navigation_controller.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/appointments/appointment_screen.dart';
import '../../screens/profile/enhanced_profile_screen.dart';


class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late PageController _pageController;
  late int _currentIndex;
  final NavigationController _navController = NavigationController();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Listen to navigation controller changes
    _navController.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navController.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    _navController.setCurrentIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Handle specific navigation logic
    switch (index) {
      case 1: // Chat
        break;
      case 2: // Schedule 
        break;
      case 3: // Profile
        _navController.setCurrentRoute('/profile');
        break;
      default:
        _navController.resetProfileState();
        break;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _navController.setCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: MainNavigationWrapper build called, currentIndex: $_currentIndex');
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          HomeScreen(),
          ChatScreen(),
          AppointmentScreen(),
          EnhancedProfileScreen(),
        ],
      ),
      bottomNavigationBar: PatientNavigationBar(
        selectedIndex: _currentIndex,
        onTap: _onNavBarTapped,
        hasNotification: _notificationService.unreadCount > 0,
      ),
    );
  }
}
