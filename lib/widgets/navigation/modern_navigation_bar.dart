import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class ModernNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int notificationCount;

  const ModernNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  State<ModernNavigationBar> createState() => _ModernNavigationBarState();
}

class _ModernNavigationBarState extends State<ModernNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int badgeCount = 0,
    bool isCompact = false,
  }) {
    final isActive = widget.currentIndex == index;
    
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        print('🔥 NAV BAR DEBUG: Tapped $label (index $index)');
        widget.onTap(index);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _scaleAnimation.value : 1.0,
            child: Container(
              constraints: BoxConstraints(
                minWidth: isCompact ? 50 : 60,
                maxWidth: isCompact ? 75 : 120,
              ),
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 6 : 8, 
                horizontal: isCompact ? 6 : 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                color: isActive 
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isCompact ? 6 : 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive 
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? activeIcon : icon,
                            key: ValueKey(isActive),
                            color: isActive 
                              ? AppTheme.primaryColor 
                              : AppTheme.textSecondaryColor,
                            size: isCompact ? 20 : 24,
                          ),
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: AnimatedScale(
                            scale: badgeCount > 0 ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: EdgeInsets.all(isCompact ? 3 : 4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: isCompact ? 16 : 20,
                                minHeight: isCompact ? 16 : 20,
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 8 : AppTheme.fontSizeXSmall,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXSmall,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive 
                          ? AppTheme.primaryColor 
                          : AppTheme.textSecondaryColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else if (isActive) ...[
                    // Show abbreviated label only for active item in compact mode
                    const SizedBox(height: 2),
                    Text(
                      label.length > 6 ? '${label.substring(0, 6)}.' : label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: ModernNavigationBar build called, currentIndex: ${widget.currentIndex}');
    return Container(
      height: 80, // Ensure minimum height for visibility
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate if navigation items fit properly
            final availableWidth = constraints.maxWidth - 32; // Account for padding
            final minItemWidth = 60.0; // Minimum width per nav item
            final totalMinWidth = minItemWidth * 4; // 4 navigation items
            
            // Determine if we need compact layout
            final useCompactLayout = availableWidth < totalMinWidth + 60; // Extra buffer
            
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: useCompactLayout ? 8 : 16, 
                vertical: useCompactLayout ? 6 : 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Index 0 - Home
                  Flexible(
                    child: _buildNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      index: 0,
                      isCompact: useCompactLayout,
                    ),
                  ),
                  // Index 1 - Chat
                  Flexible(
                    child: _buildNavItem(
                      icon: Icons.chat_outlined,
                      activeIcon: Icons.chat_rounded,
                      label: 'Chat',
                      index: 1,
                      isCompact: useCompactLayout,
                    ),
                  ),
                  // Index 2 - Schedule  
                  Flexible(
                    child: _buildNavItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: 'Schedule',
                      index: 2,
                      isCompact: useCompactLayout,
                    ),
                  ),
                  // Index 3 - Profile
                  Flexible(
                    child: _buildNavItem(
                      icon: Icons.person_outlined,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      index: 3,
                      isCompact: useCompactLayout,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
