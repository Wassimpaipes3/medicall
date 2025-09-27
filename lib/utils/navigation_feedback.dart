import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced feedback system for navigation actions
class NavigationFeedback {
  
  /// Provides haptic feedback for navigation actions
  static void navigationTap() {
    HapticFeedback.lightImpact();
  }
  
  /// Provides haptic feedback for successful navigation
  static void navigationSuccess() {
    HapticFeedback.selectionClick();
  }
  
  /// Provides haptic feedback for navigation errors
  static void navigationError() {
    HapticFeedback.vibrate();
  }
  
  /// Shows a loading indicator during navigation
  static OverlayEntry showNavigationLoading(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => const NavigationLoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    return overlayEntry;
  }
  
  /// Shows a brief success toast for navigation actions
  static void showNavigationToast(
    BuildContext context, 
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => NavigationToast(
        message: message,
        isError: isError,
      ),
    );
    overlay.insert(overlayEntry);
    
    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

/// Loading overlay shown during navigation transitions
class NavigationLoadingOverlay extends StatelessWidget {
  const NavigationLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toast notification for navigation feedback
class NavigationToast extends StatefulWidget {
  final String message;
  final bool isError;
  
  const NavigationToast({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  State<NavigationToast> createState() => _NavigationToastState();
}

class _NavigationToastState extends State<NavigationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: widget.isError ? Colors.red.shade600 : Colors.green.shade600,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isError ? Icons.error : Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
