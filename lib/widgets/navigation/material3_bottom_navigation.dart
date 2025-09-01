import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Material3BottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Material3BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<Material3BottomNavigation> createState() => _Material3BottomNavigationState();
}

class _Material3BottomNavigationState extends State<Material3BottomNavigation>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.flash_on_outlined),
      selectedIcon: Icon(Icons.flash_on),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
    const NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Appointments',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _itemControllers = List.generate(
      _destinations.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _scaleAnimations = _itemControllers.map((controller) =>
      Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      ),
    ).toList();

    _opacityAnimations = _itemControllers.map((controller) =>
      Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    ).toList();

    // Animate current selection
    _itemControllers[widget.currentIndex].forward();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(Material3BottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _itemControllers[oldWidget.currentIndex].reverse();
      _itemControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      )),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: widget.currentIndex,
            onDestinationSelected: _handleTap,
            backgroundColor: theme.colorScheme.surface,
            indicatorColor: theme.colorScheme.primaryContainer,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withOpacity(0.1),
            elevation: 0,
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _destinations.asMap().entries.map((entry) {
              final index = entry.key;
              final destination = entry.value;
              final isSelected = widget.currentIndex == index;
              
              return NavigationDestination(
                icon: AnimatedBuilder(
                  animation: Listenable.merge([
                    _scaleAnimations[index],
                    _opacityAnimations[index],
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimations[index].value,
                      child: AnimatedOpacity(
                        opacity: _opacityAnimations[index].value,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Icon(
                            _getIcon(destination, isSelected),
                            size: 24,
                            color: isSelected 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getSelectedIcon(destination),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                label: destination.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NavigationDestination destination, bool isSelected) {
    if (isSelected && destination.selectedIcon != null) {
      return (destination.selectedIcon as Icon).icon!;
    }
    return (destination.icon as Icon).icon!;
  }

  IconData _getSelectedIcon(NavigationDestination destination) {
    if (destination.selectedIcon != null) {
      return (destination.selectedIcon as Icon).icon!;
    }
    return (destination.icon as Icon).icon!;
  }
}

// Alternative Floating Action Button Style Navigation
class FloatingMaterial3Navigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingMaterial3Navigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingMaterial3Navigation> createState() => _FloatingMaterial3NavigationState();
}

class _FloatingMaterial3NavigationState extends State<FloatingMaterial3Navigation>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.flash_on_outlined,
      'selectedIcon': Icons.flash_on,
      'label': 'Home',
    },
    {
      'icon': Icons.notifications_outlined,
      'selectedIcon': Icons.notifications,
      'label': 'Alerts',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'selectedIcon': Icons.chat_bubble,
      'label': 'Chat',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'selectedIcon': Icons.calendar_month,
      'label': 'Schedule',
    },
    {
      'icon': Icons.person_outline,
      'selectedIcon': Icons.person,
      'label': 'Profile',
    },
  ];

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

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = widget.currentIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTap(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isSelected ? item['selectedIcon'] : item['icon'],
                          key: ValueKey('$index-$isSelected'),
                          size: 24,
                          color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                        child: Text(item['label']),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
