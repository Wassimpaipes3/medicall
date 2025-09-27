import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class PatientNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool hasNotification;

  const PatientNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate if navigation items fit properly
            final availableWidth = constraints.maxWidth - 32; // Account for padding
            final minItemWidth = 55.0; // Minimum width per nav item for patient
            final totalMinWidth = minItemWidth * 4; // 4 navigation items
            
            // Determine if we need compact layout
            final useCompactLayout = availableWidth < totalMinWidth + 40; // Extra buffer
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildNavItem(
                    context,
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    isCompact: useCompactLayout,
                  ),
                ),
                Flexible(
                  child: _buildNavItem(
                    context,
                    index: 1,
                    icon: Icons.chat_outlined,
                    activeIcon: Icons.chat_rounded,
                    label: 'Chat',
                    isCompact: useCompactLayout,
                  ),
                ),
                Flexible(
                  child: _buildNavItem(
                    context,
                    index: 2,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month_rounded,
                    label: 'Schedule',
                    hasNotification: hasNotification,
                    isCompact: useCompactLayout,
                  ),
                ),
                Flexible(
                  child: _buildNavItem(
                    context,
                    index: 3,
                    icon: Icons.person_outlined,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    isCompact: useCompactLayout,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool hasNotification = false,
    bool isCompact = false,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? AppTheme.primaryColor : Colors.grey.shade600;

    final double iconSize = isCompact ? 20.0 : 24.0;
    final double fontSize = isCompact ? 10.0 : 12.0;
    final EdgeInsets padding = isCompact 
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        print('DEBUG: Patient navigation tapped - $label (index: $index)');
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: iconSize,
                ),
                // Active indicator bar
                if (isSelected)
                  Positioned(
                    bottom: -8,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: isCompact ? 3 : 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                // Notification badge for appointments
                if (hasNotification && index == 1)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.medicalOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 6 : 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // Notification badge for messages
                if (hasNotification && index == 2)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isCompact ? 6 : 8,
                      height: isCompact ? 6 : 8,
                      decoration: BoxDecoration(
                        color: AppTheme.medicalRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isCompact ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}