import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../models/provider/provider_model.dart';

class AvailabilityToggle extends StatefulWidget {
  final ProviderStatus currentStatus;
  final ValueChanged<bool> onToggle;
  final bool isLoading;

  const AvailabilityToggle({
    super.key,
    required this.currentStatus,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  State<AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends State<AvailabilityToggle>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));

    if (widget.currentStatus == ProviderStatus.online) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AvailabilityToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStatus != oldWidget.currentStatus) {
      if (widget.currentStatus == ProviderStatus.online) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.currentStatus == ProviderStatus.online;
    final isBusy = widget.currentStatus == ProviderStatus.busy ||
        widget.currentStatus == ProviderStatus.enRoute ||
        widget.currentStatus == ProviderStatus.inService;

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _tapController]),
      builder: (context, child) {
        return Transform.scale(
          scale: (isOnline ? _scaleAnimation.value : 1.0) * _tapAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              if (!widget.isLoading && !isBusy) {
                _tapController.forward();
              }
            },
            onTapUp: (_) {
              _tapController.reverse();
            },
            onTapCancel: () {
              _tapController.reverse();
            },
            onTap: widget.isLoading || isBusy ? null : () {
              print('DEBUG: AvailabilityToggle tapped. Current: ${widget.currentStatus}, isOnline: $isOnline');
              HapticFeedback.mediumImpact();
              widget.onToggle(!isOnline);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getBackgroundGradient(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isOnline) ...[
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                  ] else ...[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusSubtitle(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isLoading && !isBusy)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOnline ? Icons.power_settings_new : Icons.power_settings_new_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getBackgroundGradient() {
    switch (widget.currentStatus) {
      case ProviderStatus.online:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
            const Color(0xFF10B981),
          ],
        );
      case ProviderStatus.busy:
      case ProviderStatus.enRoute:
      case ProviderStatus.inService:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
          ],
        );
      case ProviderStatus.break_:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        );
      case ProviderStatus.offline:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade600,
            Colors.grey.shade700,
          ],
        );
    }
  }

  IconData _getStatusIcon() {
    switch (widget.currentStatus) {
      case ProviderStatus.online:
        return Icons.check_circle;
      case ProviderStatus.busy:
        return Icons.schedule;
      case ProviderStatus.enRoute:
        return Icons.directions_car;
      case ProviderStatus.inService:
        return Icons.medical_services;
      case ProviderStatus.break_:
        return Icons.coffee;
      case ProviderStatus.offline:
        return Icons.power_settings_new;
    }
  }

  String _getStatusTitle() {
    switch (widget.currentStatus) {
      case ProviderStatus.online:
        return 'Available Online';
      case ProviderStatus.busy:
        return 'Busy';
      case ProviderStatus.enRoute:
        return 'En Route to Patient';
      case ProviderStatus.inService:
        return 'Providing Service';
      case ProviderStatus.break_:
        return 'On Break';
      case ProviderStatus.offline:
        return 'Offline';
    }
  }

  String _getStatusSubtitle() {
    switch (widget.currentStatus) {
      case ProviderStatus.online:
        return 'Ready to accept appointments';
      case ProviderStatus.busy:
        return 'Processing appointment request';
      case ProviderStatus.enRoute:
        return 'Traveling to patient location';
      case ProviderStatus.inService:
        return 'Currently with patient';
      case ProviderStatus.break_:
        return 'Taking a short break';
      case ProviderStatus.offline:
        return 'Tap to go online';
    }
  }
}
