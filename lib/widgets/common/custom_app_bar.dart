import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../profile/profile_picture_widget.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final Animation<double> fadeAnimation;
  
  const CustomAppBar({
    super.key,
    required this.onNotificationTap,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 10), // Added top margin to lower from top
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16), // Reduced horizontal padding since parent has 16px
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ), // Added rounded bottom corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // App Logo/Icon
                Container(
                  padding: const EdgeInsets.all(12), // Increased from 6 to 12
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16), // Increased from 10 to 16
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12, // Increased shadow
                        offset: const Offset(0, 4), // Increased offset
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 32, // Increased from 24 to 32
                  ),
                ),
                
                const SizedBox(width: 20), // Increased from 12 to 20
                
                // App Title
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HealthCare',
                        style: TextStyle(
                          fontSize: 26, // Increased from 22 to 26
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 2), // Added spacing between texts
                      Text(
                        'Your Health Partner',
                        style: TextStyle(
                          fontSize: 15, // Increased from 13 to 15
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Profile Picture
                RealtimeProfilePictureWidget(
                  size: 40,
                  onTap: () {
                    // Navigate to profile screen
                    Navigator.pushNamed(context, '/profile');
                  },
                  showEditIcon: false,
                  isCircular: true,
                  borderColor: AppTheme.primaryColor,
                  borderWidth: 2,
                ),
                
                const SizedBox(width: 12),
                
                // Notification Button
                _buildNotificationButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16), // Increased from 12 to 16
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16), // Increased from 12 to 16
              onTap: () {
                HapticFeedback.lightImpact();
                onNotificationTap();
              },
              child: Container(
                padding: const EdgeInsets.all(12), // Increased from 8 to 12
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.primaryColor,
                  size: 24, // Increased from 20 to 24
                ),
              ),
            ),
          ),
        ),
        
        // Notification Badge
        Positioned(
          right: 8, // Increased from 6 to 8
          top: 8, // Increased from 6 to 8
          child: Container(
            padding: const EdgeInsets.all(4), // Increased from 3 to 4
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8), // Increased from 6 to 8
            ),
            constraints: const BoxConstraints(
              minWidth: 16, // Increased from 14 to 16
              minHeight: 16, // Increased from 14 to 16
            ),
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10, // Increased from 9 to 10
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
