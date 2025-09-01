import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  success,
  warning,
  danger,
  gradient,
  glassmorphic,
}

class EnhancedCustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final double? width;
  final EdgeInsets? padding;
  final double borderRadius;
  final List<Color>? customGradient;
  final double? elevation;
  final bool enablePulse;

  const EnhancedCustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = 16.0,
    this.customGradient,
    this.elevation,
    this.enablePulse = false,
  });

  @override
  State<EnhancedCustomButton> createState() => _EnhancedCustomButtonState();
}

class _EnhancedCustomButtonState extends State<EnhancedCustomButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _pressController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _pressController.reverse();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _pressController.reverse();
            },
            child: Container(
              width: widget.isFullWidth ? double.infinity : widget.width,
              height: widget.height ?? 52,
              decoration: _buildDecoration(),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
                child: _buildButtonContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildDecoration() {
    final baseColors = _getVariantColors();
    final pulseIntensity = widget.enablePulse ? (0.1 + _pulseAnimation.value * 0.2) : 0.3;

    return BoxDecoration(
      gradient: widget.customGradient != null 
          ? LinearGradient(colors: widget.customGradient!)
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: baseColors,
            ),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      boxShadow: widget.onPressed != null ? [
        // Primary shadow
        BoxShadow(
          color: baseColors.first.withOpacity(pulseIntensity),
          blurRadius: 20 + (_pulseAnimation.value * 10),
          offset: Offset(0, 8 + (_pulseAnimation.value * 4)),
          spreadRadius: _isPressed ? 0 : 2,
        ),
        // Ambient shadow
        BoxShadow(
          color: baseColors.last.withOpacity(0.15),
          blurRadius: 30 + (_pulseAnimation.value * 15),
          offset: const Offset(0, 15),
          spreadRadius: -8,
        ),
      ] : null,
      border: widget.variant == ButtonVariant.glassmorphic 
          ? Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            )
          : null,
    );
  }

  List<Color> _getVariantColors() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case ButtonVariant.secondary:
        return [const Color(0xFF64748B), const Color(0xFF475569)];
      case ButtonVariant.success:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case ButtonVariant.warning:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case ButtonVariant.danger:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case ButtonVariant.gradient:
        return [
          const Color(0xFF6366F1), 
          const Color(0xFF8B5CF6), 
          const Color(0xFFF59E0B)
        ];
      case ButtonVariant.glassmorphic:
        return [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ];
    }
  }

  Widget _buildButtonContent() {
    final textColor = widget.variant == ButtonVariant.glassmorphic 
        ? Colors.white 
        : Colors.white;

    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.leadingIcon!,
              color: textColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
        ],
        
        Flexible(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.trailingIcon!,
              color: textColor,
              size: 18,
            ),
          ),
        ],
      ],
    );
  }
}

class EnhancedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final double size;
  final bool enablePulse;
  final String? tooltip;
  final List<Color>? customGradient;

  const EnhancedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = 48.0,
    this.enablePulse = false,
    this.tooltip,
    this.customGradient,
  });

  @override
  State<EnhancedIconButton> createState() => _EnhancedIconButtonState();
}

class _EnhancedIconButtonState extends State<EnhancedIconButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColors = _getVariantColors();
    final pulseIntensity = widget.enablePulse ? (0.1 + _pulseAnimation.value * 0.2) : 0.3;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Tooltip(
            message: widget.tooltip ?? '',
            child: GestureDetector(
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _pressController.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _pressController.reverse();
                widget.onPressed?.call();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _pressController.reverse();
              },
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: widget.customGradient != null 
                      ? LinearGradient(colors: widget.customGradient!)
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: baseColors,
                        ),
                  borderRadius: BorderRadius.circular(widget.size * 0.3),
                  boxShadow: widget.onPressed != null ? [
                    BoxShadow(
                      color: baseColors.first.withOpacity(pulseIntensity),
                      blurRadius: 15 + (_pulseAnimation.value * 8),
                      offset: Offset(0, 6 + (_pulseAnimation.value * 3)),
                      spreadRadius: _isPressed ? 0 : 1,
                    ),
                  ] : null,
                  border: widget.variant == ButtonVariant.glassmorphic 
                      ? Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size * 0.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getVariantColors() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case ButtonVariant.secondary:
        return [const Color(0xFF64748B), const Color(0xFF475569)];
      case ButtonVariant.success:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case ButtonVariant.warning:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case ButtonVariant.danger:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case ButtonVariant.gradient:
        return [
          const Color(0xFF6366F1), 
          const Color(0xFF8B5CF6), 
          const Color(0xFFF59E0B)
        ];
      case ButtonVariant.glassmorphic:
        return [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ];
    }
  }
}
