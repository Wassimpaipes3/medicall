import 'package:flutter/material.dart';

/// Utility class to handle responsive button layouts and prevent overflow
class ResponsiveButtonLayout {
  
  /// Creates a responsive row of buttons that wraps or stacks on small screens
  static Widget adaptiveButtonRow({
    required List<Widget> buttons,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 8.0,
    double minButtonWidth = 120.0,
    bool forceVertical = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate if buttons fit horizontally
        final availableWidth = constraints.maxWidth;
        final totalButtonMinWidth = buttons.length * minButtonWidth;
        final totalSpacing = (buttons.length - 1) * spacing;
        final requiredWidth = totalButtonMinWidth + totalSpacing;
        
        final shouldStack = forceVertical || requiredWidth > availableWidth;
        
        if (shouldStack) {
          // Stack buttons vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons.map((button) => Container(
              margin: EdgeInsets.only(bottom: spacing),
              child: button,
            )).toList()..removeLast(), // Remove spacing from last item
          );
        } else {
          // Arrange buttons horizontally
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: buttons.map((button) => Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: button,
              ),
            )).toList(),
          );
        }
      },
    );
  }

  /// Creates a wrap layout for multiple buttons that overflow gracefully
  static Widget buttonWrap({
    required List<Widget> buttons,
    WrapAlignment alignment = WrapAlignment.center,
    double spacing = 8.0,
    double runSpacing = 8.0,
  }) {
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      children: buttons.map((button) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 120),
        child: button,
      )).toList(),
    );
  }

  /// Creates a responsive button that adjusts text size based on available space
  static Widget responsiveButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double maxWidth = double.infinity,
    double minWidth = 120.0,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Creates a compact button for limited space scenarios
  static Widget compactButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isOutlined = false,
  }) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            side: BorderSide(color: foregroundColor ?? Colors.blue),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: child,
          );
  }

  /// Creates a dialog with responsive button layout
  static void showResponsiveDialog({
    required BuildContext context,
    required String title,
    required String content,
    required List<ResponsiveDialogAction> actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          adaptiveButtonRow(
            buttons: actions.map((action) => compactButton(
              text: action.text,
              onPressed: () {
                Navigator.of(context).pop();
                action.onPressed?.call();
              },
              backgroundColor: action.backgroundColor,
              foregroundColor: action.foregroundColor,
              isOutlined: action.isOutlined,
            )).toList(),
            forceVertical: actions.length > 2,
            spacing: 8,
          ),
        ],
      ),
    );
  }
}

class ResponsiveDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;

  const ResponsiveDialogAction({
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
  });
}
