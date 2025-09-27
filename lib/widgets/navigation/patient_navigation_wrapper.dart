import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/navigation_config.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/appointments/appointment_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/profile/enhanced_profile_screen.dart';
import '../patient/patient_navigation_bar.dart';


class PatientNavigationWrapper extends StatefulWidget {
  const PatientNavigationWrapper({super.key});

  @override
  State<PatientNavigationWrapper> createState() => _PatientNavigationWrapperState();
}

class _PatientNavigationWrapperState extends State<PatientNavigationWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Get navigation items from config
  final List<NavigationItem> _navItems = NavigationConfig.patientNavigation.items;

  // Define screens corresponding to navigation items
  final List<Widget> _screens = const [
  HomeScreen(),           // Home (index 0)
  ChatScreen(),           // Chat (index 1)
  AppointmentScreen(),    // Schedule/Appointments (index 2)
  EnhancedProfileScreen(), // Profile (index 3)
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    print('DEBUG: Navigation item $index tapped - ${_navItems[index].label}');
    
    if (NavigationBehavior.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: NavigationBehavior.transitionDuration,
      curve: NavigationBehavior.transitionCurve,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: PatientNavigationWrapper building with ${_navItems.length} navigation items');
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: PatientNavigationBar(
        selectedIndex: _currentIndex,
        onTap: _onNavItemTapped,
        hasNotification: false, // You can make this dynamic based on actual notification state
      ),
    );
  }
}