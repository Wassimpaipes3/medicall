import 'package:flutter/material.dart';

/// A decorative card widget with gradient and shadow support
class DecorativeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? elevation;

  const DecorativeCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.gradient,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBoxShadow = elevation != null
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: elevation! * 2,
              offset: Offset(0, elevation! / 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? Theme.of(context).cardColor) : null,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: boxShadow ?? defaultBoxShadow,
      ),
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );
  }
}
