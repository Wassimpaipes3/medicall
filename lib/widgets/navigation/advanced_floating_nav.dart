import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class AdvancedFloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;

  const AdvancedFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<AdvancedFloatingNavBar> createState() => _AdvancedFloatingNavBarState();
}

class _AdvancedFloatingNavBarState extends State<AdvancedFloatingNavBar>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late List<AnimationController> _itemControllers;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late List<Animation<double>> _itemScaleAnimations;
  late List<Animation<double>> _itemOpacityAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    // Main slide and bounce controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Individual item controllers
    _itemControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    // Animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _itemScaleAnimations = _itemControllers.map((controller) =>
      Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      ),
    ).toList();

    _itemOpacityAnimations = _itemControllers.map((controller) =>
      Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    ).toList();
  }

  void _startEntryAnimation() async {
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _bounceController.forward();
    _itemControllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(AdvancedFloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _itemControllers[oldWidget.currentIndex].reverse();
      _itemControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    
    // Bounce animation for the navbar
    _bounceController.reverse().then((_) {
      _bounceController.forward();
    });
    
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 5),
                  spreadRadius: -5,
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = widget.currentIndex == index;

                return _buildNavItem(item, index, isSelected, theme);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _itemScaleAnimations[index],
          _itemOpacityAnimations[index],
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _itemScaleAnimations[index].value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: isSelected ? 26 : 24,
                      color: isSelected 
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected 
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Glass morphism navigation bar
class GlassMorphismNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;

  const GlassMorphismNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<GlassMorphismNavBar> createState() => _GlassMorphismNavBarState();
}

class _GlassMorphismNavBarState extends State<GlassMorphismNavBar>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _rippleControllers;
  late List<Animation<double>> _rippleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _rippleControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _rippleAnimations = _rippleControllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      ),
    ).toList();

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (var controller in _rippleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    
    // Trigger ripple effect
    _rippleControllers[index].forward().then((_) {
      _rippleControllers[index].reset();
    });
    
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = widget.currentIndex == index;

                  return _buildGlassNavItem(item, index, isSelected, theme);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavItem(NavigationItem item, int index, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect
          AnimatedBuilder(
            animation: _rippleAnimations[index],
            builder: (context, child) {
              return Container(
                width: 50 * _rippleAnimations[index].value,
                height: 50 * _rippleAnimations[index].value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(
                    0.3 * (1 - _rippleAnimations[index].value),
                  ),
                ),
              );
            },
          ),
          
          // Nav item
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: isSelected ? 26 : 22,
                  color: isSelected 
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color? color;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.color,
  });
}

// Default navigation items
class DefaultNavigationItems {
  static const List<NavigationItem> healthcare = [
    NavigationItem(
      icon: Icons.flash_on_outlined,
      selectedIcon: Icons.flash_on,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Schedule',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];
}
